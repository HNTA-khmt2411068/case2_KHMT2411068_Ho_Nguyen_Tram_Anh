const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');
const User = require('../models/User');
const Notification = require('../models/Notification');
const TaskActivity = require('../models/TaskActivity');
const emailService = require('../services/emailService');

exports.getTasks = async (req, res) => {
  try {
    if (!req.user || !req.user.id) {
      return res.status(401).json({ message: 'Không tìm thấy thông tin xác thực!' });
    }

    const userId = req.user.id;
    const sharedRecords = await TaskShare.find({ userId });
    const sharedTaskIds = sharedRecords.map((s) => s.taskId);
    const sharePermMap = {};
    sharedRecords.forEach((s) => {
      sharePermMap[s.taskId.toString()] = s.permission;
    });

    const tasks = await Task.find({
      $or: [
        { createdBy: userId },
        { assigneeIds: userId },
        { _id: { $in: sharedTaskIds } }
      ]
    })
      .populate('createdBy', 'fullName email')
      .populate('assigneeIds', 'fullName email')
      .sort({ createdAt: -1 });

    const enrichedTasks = tasks.map((t) => {
      const obj = t.toObject();
      const creatorId = obj.createdBy?._id
        ? obj.createdBy._id.toString()
        : obj.createdBy?.toString();
      const primaryId = obj.primaryAssigneeId ? obj.primaryAssigneeId.toString() : null;
      const isAssignee = (obj.assigneeIds || []).some((u) => {
        const id = u?._id ? u._id.toString() : u.toString();
        return id === userId;
      });

      let userRole = 'viewer';
      if (creatorId === userId) {
        userRole = 'owner';
      } else if (primaryId === userId) {
        userRole = 'primary_assignee';
      } else if (isAssignee) {
        userRole = 'assignee';
      } else if (sharePermMap[obj._id.toString()]) {
        userRole = sharePermMap[obj._id.toString()]; // 'editor' hoặc 'viewer'
      }

      return { ...obj, userRole };
    });

    res.json(enrichedTasks);
  } catch (error) {
    console.error('Lỗi getTasks:', error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.getTaskById = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id)
      .populate('createdBy', 'fullName email')
      .populate('assigneeIds', 'fullName email');
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc!' });
    }
    res.json(task);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.createTask = async (req, res) => {
  try {
    const { title, description, startDate, dueDate, priority, status } = req.body;

    if (!title) {
      return res.status(400).json({ message: 'Vui lòng nhập tên công việc!' });
    }

    const task = new Task({
      title,
      description: description || '',
      startDate,
      dueDate,
      priority: priority || 'medium',
      status: status || 'todo',
      createdBy: req.user.id,
      assigneeIds: [req.user.id],
      primaryAssigneeId: req.user.id
    });

    await task.save();

    await TaskActivity.create({
      taskId: task._id,
      userId: req.user.id,
      action: `Đã tạo công việc: "${task.title}"`
    });

    await Notification.create({
      userId: req.user.id,
      taskId: task._id,
      type: 'TASK_CREATED',
      title: 'Tạo công việc mới',
      message: `Bạn đã tạo công việc "${task.title}" thành công.`
    });

    res.status(201).json({ message: 'Tạo công việc thành công!', task });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.updateTask = async (req, res) => {
  try {
    const oldTask = await Task.findById(req.params.id);
    if (!oldTask) {
      return res.status(404).json({ message: 'Không tìm thấy công việc!' });
    }

    const isOwner = oldTask.createdBy.toString() === req.user.id;
    const shareRecord = await TaskShare.findOne({ taskId: oldTask._id, userId: req.user.id });
    const isEditor = shareRecord && shareRecord.permission === 'editor';

    if (!isOwner && !isEditor) {
      return res.status(403).json({
        message: 'Bạn không có quyền chỉnh sửa thông tin công việc này!'
      });
    }

    const oldDueDate = oldTask.dueDate ? new Date(oldTask.dueDate).toISOString() : null;
    const allowedUpdates = {};
    if (req.body.title !== undefined) allowedUpdates.title = req.body.title;
    if (req.body.description !== undefined) allowedUpdates.description = req.body.description;
    if (req.body.priority !== undefined) allowedUpdates.priority = req.body.priority;
    if (req.body.status !== undefined) allowedUpdates.status = req.body.status;
    if (req.body.startDate !== undefined) allowedUpdates.startDate = req.body.startDate;
    if (req.body.dueDate !== undefined) allowedUpdates.dueDate = req.body.dueDate;

    const task = await Task.findByIdAndUpdate(req.params.id, allowedUpdates, {
      returnDocument: 'after'
    });
    const newDueDate = task.dueDate ? new Date(task.dueDate).toISOString() : null;
    const isDueDateChanged = oldDueDate !== newDueDate;

    await TaskActivity.create({
      taskId: task._id,
      userId: req.user.id,
      action: isDueDateChanged
        ? `Đã cập nhật hạn hoàn thành và chi tiết công việc: "${task.title}"`
        : `Đã cập nhật chi tiết công việc: "${task.title}"`
    });

    await Notification.create({
      userId: req.user.id,
      taskId: task._id,
      type: 'TASK_UPDATED',
      title: 'Cập nhật công việc',
      message: `Bạn đã cập nhật công việc "${task.title}".`
    });

    const recipientIds = new Set([
      task.createdBy.toString(),
      ...(task.assigneeIds || []).map((id) => id.toString())
    ]);
    recipientIds.delete(req.user.id);

    if (recipientIds.size > 0) {
      const users = await User.find({ _id: { $in: Array.from(recipientIds) } });
      for (const user of users) {
        await Notification.create({
          userId: user._id,
          taskId: task._id,
          type: 'TASK_UPDATED',
          title: isDueDateChanged ? 'Thay đổi hạn hoàn thành' : 'Công việc được cập nhật',
          message: isDueDateChanged
            ? `Hạn hoàn thành của công việc "${task.title}" vừa được thay đổi.`
            : `Công việc "${task.title}" vừa được cập nhật thông tin.`
        });

        try {
          await emailService.sendTaskEmail(
            user.email,
            isDueDateChanged
              ? `Thông báo: Thay đổi hạn hoàn thành - "${task.title}"`
              : `Thông báo: Cập nhật công việc - "${task.title}"`,
            `Xin chào ${user.fullName},\n\nCông việc "${task.title}" vừa được cập nhật${isDueDateChanged ? ' hạn hoàn thành mới' : ' thông tin'}.\nHãy mở ứng dụng TaskManager để kiểm tra chi tiết!`
          );
        } catch (emailErr) {
          console.error('Bỏ qua lỗi email service:', emailErr.message);
        }
      }
    }

    res.json({ message: 'Cập nhật công việc thành công!', task });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.deleteTask = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc!' });
    }

    if (task.createdBy.toString() !== req.user.id) {
      return res.status(403).json({
        message: 'Chỉ người tạo công việc mới có quyền xóa!'
      });
    }

    await Task.findByIdAndDelete(req.params.id);
    await TaskShare.deleteMany({ taskId: req.params.id });

    await Notification.create({
      userId: req.user.id,
      taskId: task._id,
      type: 'TASK_DELETED',
      title: 'Xóa công việc',
      message: `Bạn đã xóa công việc "${task.title}".`
    });

    if (task.assigneeIds && task.assigneeIds.length > 0) {
      for (const assigneeId of task.assigneeIds) {
        if (assigneeId.toString() !== req.user.id) {
          await Notification.create({
            userId: assigneeId,
            taskId: task._id,
            type: 'TASK_DELETED',
            title: 'Công việc đã bị xóa',
            message: `Công việc "${task.title}" mà bạn tham gia đã bị xóa.`
          });
        }
      }
    }

    res.json({ message: 'Đã xóa công việc thành công!' });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.updateTaskStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const task = await Task.findById(req.params.id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc!' });
    }

    const isOwner = task.createdBy.toString() === req.user.id;
    const isAssignee = (task.assigneeIds || []).some((id) => id.toString() === req.user.id);
    const shareRecord = await TaskShare.findOne({ taskId: task._id, userId: req.user.id });
    const isEditor = shareRecord && shareRecord.permission === 'editor';

    if (!isOwner && !isAssignee && !isEditor) {
      return res.status(403).json({
        message: 'Bạn chỉ có quyền xem, không thể cập nhật trạng thái công việc!'
      });
    }

    task.status = status;
    await task.save();

    const statusText =
      status === 'completed'
        ? 'Đã hoàn thành'
        : status === 'in_progress'
        ? 'Đang thực hiện'
        : 'Chưa thực hiện';

    await TaskActivity.create({
      taskId: task._id,
      userId: req.user.id,
      action: `Đã đổi trạng thái công việc sang "${statusText}"`
    });

    await Notification.create({
      userId: req.user.id,
      taskId: task._id,
      type: 'STATUS_UPDATED',
      title: 'Cập nhật trạng thái',
      message: `Bạn đã chuyển trạng thái công việc "${task.title}" sang "${statusText}".`
    });

    const recipientIds = new Set([
      task.createdBy.toString(),
      ...(task.assigneeIds || []).map((id) => id.toString())
    ]);
    recipientIds.delete(req.user.id);

    if (recipientIds.size > 0) {
      const users = await User.find({ _id: { $in: Array.from(recipientIds) } });
      for (const user of users) {
        await Notification.create({
          userId: user._id,
          taskId: task._id,
          type: 'STATUS_UPDATED',
          title: status === 'completed' ? 'Công việc đã hoàn thành' : 'Cập nhật trạng thái công việc',
          message: `Công việc "${task.title}" đã chuyển sang trạng thái "${statusText}".`
        });

        if (status === 'completed') {
          try {
            await emailService.sendTaskEmail(
              user.email,
              `Thông báo: Công việc "${task.title}" đã hoàn thành`,
              `Xin chào ${user.fullName},\n\nCông việc "${task.title}" đã được đánh dấu hoàn thành.\nHãy kiểm tra ứng dụng TaskManager để xem chi tiết!`
            );
          } catch (emailErr) {
            console.error('Bỏ qua lỗi email service:', emailErr.message);
          }
        }
      }
    }

    res.json({ message: 'Cập nhật trạng thái thành công!', task });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.assignTask = async (req, res) => {
  try {
    const { assigneeIds, primaryAssigneeId } = req.body;
    const task = await Task.findById(req.params.id);

    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc!' });
    }

    if (task.createdBy.toString() !== req.user.id) {
      return res.status(403).json({
        message: 'Chỉ người tạo công việc mới có quyền phân công!'
      });
    }

    if (assigneeIds) task.assigneeIds = assigneeIds;
    if (primaryAssigneeId) {
      task.primaryAssigneeId = primaryAssigneeId;
    } else if (assigneeIds && assigneeIds.length === 0) {
      task.primaryAssigneeId = null;
    }

    await task.save();

    const count = assigneeIds ? assigneeIds.length : 0;

    await TaskActivity.create({
      taskId: task._id,
      userId: req.user.id,
      action: `Đã giao công việc cho ${count} thành viên`
    });

    await Notification.create({
      userId: req.user.id,
      taskId: task._id,
      type: 'ASSIGNMENT_SENT',
      title: 'Giao việc thành công',
      message: `Bạn đã phân công công việc "${task.title}" cho ${count} thành viên.`
    });

    if (assigneeIds && assigneeIds.length > 0) {
      const users = await User.find({ _id: { $in: assigneeIds } });
      for (const user of users) {
        if (user._id.toString() !== req.user.id) {
          await Notification.create({
            userId: user._id,
            taskId: task._id,
            type: 'ASSIGNED',
            title: 'Công việc mới được giao',
            message: `Bạn đã được giao công việc: "${task.title}"`
          });

          try {
            await emailService.sendTaskEmail(
              user.email,
              'Thông báo: Bạn có công việc mới được giao',
              `Xin chào ${user.fullName},\n\nBạn vừa được phân công công việc: "${task.title}".\nHãy kiểm tra ứng dụng TaskManager để xem chi tiết!`
            );
          } catch (emailErr) {
            console.error('Bỏ qua lỗi email service:', emailErr.message);
          }
        }
      }
    }

    res.json({ message: 'Phân công công việc thành công!', task });
  } catch (error) {
    console.error('Lỗi assignTask:', error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.getTaskActivities = async (req, res) => {
  try {
    const activities = await TaskActivity.find({ taskId: req.params.id }).sort({ createdAt: -1 });
    res.json(activities);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};
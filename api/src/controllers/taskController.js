const Task = require('../models/Task');
const User = require('../models/User');
const Notification = require('../models/Notification');
const TaskActivity = require('../models/TaskActivity');
const emailService = require('../services/emailService');

exports.getTasks = async (req, res) => {
  try {
    if (!req.user || !req.user.id) {
      return res.status(401).json({ message: 'Không tìm thấy thông tin xác thực!' });
    }

    const tasks = await Task.find({
      $or: [
        { createdBy: req.user.id },
        { assigneeIds: req.user.id }
      ]
    }).populate('createdBy', 'fullName email').sort({ createdAt: -1 });

    res.json(tasks || []);
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

    res.status(201).json({ message: 'Tạo công việc thành công!', task });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.updateTask = async (req, res) => {
  try {
    const task = await Task.findByIdAndUpdate(req.params.id, req.body, { returnDocument: 'after' });
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc!' });
    }

    await TaskActivity.create({
      taskId: task._id,
      userId: req.user.id,
      action: `Đã cập nhật chi tiết công việc: "${task.title}"`
    });

    res.json({ message: 'Cập nhật công việc thành công!', task });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.deleteTask = async (req, res) => {
  try {
    const task = await Task.findByIdAndDelete(req.params.id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc!' });
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
    task.status = status;
    await task.save();

    const statusText = status === 'completed' ? 'Đã hoàn thành' : (status === 'in_progress' ? 'Đang thực hiện' : 'Chưa thực hiện');

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
      message: `Bạn đã chuyển trạng thái công việc "${task.title}" sang "${statusText}".`,
    });

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

    if (assigneeIds) task.assigneeIds = assigneeIds;
    if (primaryAssigneeId) task.primaryAssigneeId = primaryAssigneeId;

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
      message: `Bạn đã phân công công việc "${task.title}" cho ${count} thành viên.`,
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
            message: `Bạn đã được giao công việc: "${task.title}"`,
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
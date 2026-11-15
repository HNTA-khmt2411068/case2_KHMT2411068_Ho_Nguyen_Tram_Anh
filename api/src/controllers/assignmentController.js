const Task = require('../models/Task');
const User = require('../models/User');
const Notification = require('../models/Notification');
const TaskActivity = require('../models/TaskActivity');
const emailService = require('../services/emailService');

const getUid = (req) => (req.user && (req.user.id || req.user.userId || req.user._id)) || null;

exports.getAssignees = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id).populate('assigneeIds', 'fullName email');
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }
    return res.status(200).json({
      assignees: task.assigneeIds || [],
      primaryAssigneeId: task.primaryAssigneeId || null,
    });
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ nội bộ', error: error.message });
  }
};

exports.assignTask = async (req, res) => {
  try {
    const uid = getUid(req);
    const rawIds =
      req.body.assigneeIds || req.body.userIds || (req.body.userId ? [req.body.userId] : []);
    const { primaryAssigneeId } = req.body;

    const task = await Task.findById(req.params.id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    const oldAssigneeIds = (task.assigneeIds || []).map((id) => id.toString());
    const creatorId = task.createdBy ? task.createdBy.toString() : '';

    const assigneeIds = [...new Set((Array.isArray(rawIds) ? rawIds : []).map(String))].filter(
      (id) => id && id !== String(uid) && id !== creatorId
    );

    const removedIds = oldAssigneeIds.filter((id) => !assigneeIds.includes(id));

    task.assigneeIds = assigneeIds;
    if (assigneeIds.length === 0) {
      task.primaryAssigneeId = null;
    } else if (primaryAssigneeId && assigneeIds.includes(String(primaryAssigneeId))) {
      task.primaryAssigneeId = primaryAssigneeId;
    } else {
      task.primaryAssigneeId = assigneeIds[0];
    }
    await task.save();

    try {
      await TaskActivity.create({
        taskId: task._id,
        userId: uid,
        action:
          assigneeIds.length > 0
            ? `Đã phân công công việc cho ${assigneeIds.length} thành viên`
            : 'Đã thu hồi giao việc (gỡ toàn bộ người được giao)',
      });
    } catch (e) {
      console.error('Lỗi ghi TaskActivity:', e.message);
    }

    if (uid) {
      try {
        await Notification.create({
          userId: uid,
          taskId: task._id,
          type: assigneeIds.length > 0 ? 'ASSIGNMENT_SENT' : 'ASSIGNMENT_REVOKED',
          title: assigneeIds.length > 0 ? 'Phân công công việc' : 'Thu hồi giao việc',
          message:
            assigneeIds.length > 0
              ? `Bạn đã giao công việc "${task.title}" cho ${assigneeIds.length} thành viên.`
              : `Bạn đã thu hồi toàn bộ phân công của công việc "${task.title}".`,
        });
      } catch (e) {
        console.error('Lỗi tạo Notification cho người giao:', e.message);
      }
    }

    if (assigneeIds.length > 0) {
      const users = await User.find({ _id: { $in: assigneeIds } });
      for (const user of users) {
        if (user._id.toString() === String(uid) || user._id.toString() === creatorId) continue;

        try {
          await Notification.create({
            userId: user._id,
            taskId: task._id,
            type: 'ASSIGNED',
            title: 'Công việc mới được giao',
            message: `Bạn đã được giao công việc: "${task.title}"`,
          });
        } catch (e) {
          console.error('Lỗi tạo Notification cho người nhận:', e.message);
        }

        await emailService.sendTaskEmail(
          user.email,
          'Thông báo: Bạn có công việc mới được giao',
          `Xin chào ${user.fullName},\n\nBạn vừa được phân công công việc: "${task.title}".\nHãy mở ứng dụng TaskManager để xem chi tiết!`,
          { taskId: task._id, eventType: 'TASK_ASSIGNED' }
        );
      }
    }

    if (removedIds.length > 0) {
      for (const removedId of removedIds) {
        if (removedId === String(uid) || removedId === creatorId) continue;
        try {
          await Notification.create({
            userId: removedId,
            taskId: task._id,
            type: 'ASSIGNMENT_REVOKED',
            title: 'Thu hồi phân công',
            message: `Bạn đã được gỡ khỏi công việc: "${task.title}"`,
          });
        } catch (e) {
          console.error('Lỗi tạo Notification thu hồi:', e.message);
        }
      }
    }

    const updatedTask = await Task.findById(req.params.id).populate('assigneeIds', 'fullName email');
    return res.status(200).json({
      message:
        assigneeIds.length > 0
          ? 'Giao việc thành công!'
          : 'Đã thu hồi giao việc thành công!',
      task: updatedTask,
    });
  } catch (error) {
    console.error('Lỗi assignTask:', error);
    return res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.updateAssigneeRole = async (req, res) => {
  try {
    const uid = getUid(req);
    const { id, userId } = req.params;
    const primaryAssigneeId = req.body.primaryAssigneeId || (req.body.isPrimary ? userId : null);

    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    if (primaryAssigneeId) {
      task.primaryAssigneeId = primaryAssigneeId;
      await task.save();

      try {
        await TaskActivity.create({
          taskId: task._id,
          userId: uid,
          action: 'Đã cập nhật người phụ trách chính',
        });
      } catch (_) {}
    }

    const updatedTask = await Task.findById(id).populate('assigneeIds', 'fullName email');
    return res.status(200).json({
      message: 'Cập nhật vai trò thành công',
      task: updatedTask,
    });
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ nội bộ', error: error.message });
  }
};

exports.removeAssignee = async (req, res) => {
  try {
    const uid = getUid(req);
    const { userId } = req.params;
    const task = await Task.findById(req.params.id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    task.assigneeIds = (task.assigneeIds || []).filter((id) => id.toString() !== userId);
    if (task.primaryAssigneeId && task.primaryAssigneeId.toString() === userId) {
      task.primaryAssigneeId = task.assigneeIds.length > 0 ? task.assigneeIds[0] : null;
    }
    await task.save();

    try {
      await TaskActivity.create({
        taskId: task._id,
        userId: uid,
        action: 'Đã thu hồi giao việc cho 1 thành viên',
      });
    } catch (_) {}

    if (uid) {
      try {
        await Notification.create({
          userId: uid,
          taskId: task._id,
          type: 'ASSIGNMENT_REVOKED',
          title: 'Thu hồi giao việc',
          message: `Bạn đã gỡ 1 thành viên khỏi công việc "${task.title}".`,
        });
      } catch (_) {}
    }

    if (userId && userId !== String(uid)) {
      try {
        await Notification.create({
          userId,
          taskId: task._id,
          type: 'ASSIGNMENT_REVOKED',
          title: 'Thu hồi phân công',
          message: `Bạn đã được gỡ khỏi công việc: "${task.title}"`,
        });
      } catch (_) {}
    }

    return res.status(200).json({ message: 'Đã thu hồi giao việc thành công!', task });
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.unassignUser = exports.removeAssignee;
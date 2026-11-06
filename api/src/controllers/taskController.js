const User = require('../models/User');
const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');
const Notification = require('../models/Notification');
const TaskActivity = require('../models/TaskActivity');
const { logActivity } = require('../services/activityService');

const getTasks = async (req, res) => {
  try {
    const currentUserId = (req.user?.id || req.user?._id || req.user?.userId || req.user || '').toString();
    const shares = await TaskShare.find({ userId: currentUserId });
    const sharedTaskIds = shares.map(s => s.taskId);

    const tasks = await Task.find({
      $or: [
        { createdBy: currentUserId },
        { assigneeIds: currentUserId },
        { _id: { $in: sharedTaskIds } }
      ]
    }).sort({ createdAt: -1 });

    return res.status(200).json(tasks);
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

const createTask = async (req, res) => {
  try {
    const currentUserId = (req.user?.id || req.user?._id || req.user?.userId || req.user || '').toString();
    const taskData = { ...req.body, createdBy: currentUserId };

    const task = await Task.create(taskData);

    await logActivity({
      taskId: task._id,
      userId: currentUserId,
      action: 'Tạo công việc',
      details: `Đã tạo công việc "${task.title}"`,
    });

    await Notification.create({
      userId: currentUserId,
      taskId: task._id,
      type: 'task_created',
      title: 'Tạo công việc thành công',
      message: `Bạn đã tạo thành công công việc "${task.title}"`,
      isRead: false
    });

    if (Array.isArray(task.assigneeIds) && task.assigneeIds.length > 0) {
      for (const assigneeId of task.assigneeIds) {
        const aIdStr = assigneeId.toString();
        if (aIdStr && aIdStr !== currentUserId) {
          await Notification.create({
            userId: aIdStr,
            taskId: task._id,
            type: 'task_assigned',
            title: 'Công việc mới được giao',
            message: `Bạn vừa được giao công việc "${task.title}"`,
            isRead: false
          });
        }
      }
    }

    return res.status(201).json(task);
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

const getTaskById = async (req, res) => {
  try {
    const { id } = req.params;
    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }
    return res.status(200).json(task);
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

const updateTask = async (req, res) => {
  try {
    const { id } = req.params;
    const currentUserId = (req.user?.id || req.user?._id || req.user?.userId || req.user || '').toString();

    const task = await Task.findByIdAndUpdate(id, req.body, { new: true });
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    await logActivity({
      taskId: task._id,
      userId: currentUserId,
      action: req.body.status ? `Đổi trạng thái sang ${req.body.status}` : 'Cập nhật thông tin',
      details: `Đã cập nhật công việc "${task.title}"`,
    });

    await Notification.create({
      userId: currentUserId,
      taskId: task._id,
      type: 'task_updated_sender',
      title: 'Đã cập nhật công việc',
      message: `Bạn đã cập nhật thông tin công việc "${task.title}"`,
      isRead: false
    });

    const shares = await TaskShare.find({ taskId: id });
    const sharedUserIds = shares.map(s => s.userId.toString());
    const assigneeIds = (task.assigneeIds || []).map(a => a.toString());
    const creatorId = task.createdBy ? task.createdBy.toString() : '';

    const relatedUserIds = [...new Set([...sharedUserIds, ...assigneeIds, creatorId])]
      .filter(uId => uId && uId !== currentUserId);

    for (const rId of relatedUserIds) {
      await Notification.create({
        userId: rId,
        taskId: task._id,
        type: 'task_updated',
        title: 'Công việc đã được cập nhật',
        message: `Công việc "${task.title}" vừa được cập nhật thông tin mới`,
        isRead: false
      });
    }

    return res.status(200).json(task);
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

const deleteTask = async (req, res) => {
  try {
    const { id } = req.params;
    const currentUserId = (req.user?.id || req.user?._id || req.user?.userId || req.user || '').toString();

    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    const taskTitle = task.title;

    const shares = await TaskShare.find({ taskId: id });
    const sharedUserIds = shares.map(s => s.userId.toString());
    const assigneeIds = (task.assigneeIds || []).map(a => a.toString());
    const creatorId = task.createdBy ? task.createdBy.toString() : '';

    await Notification.create({
      userId: currentUserId,
      taskId: null,
      type: 'task_deleted_sender',
      title: 'Đã xóa công việc',
      message: `Bạn đã xóa công việc "${taskTitle}"`,
      isRead: false
    });

    const relatedUserIds = [...new Set([...sharedUserIds, ...assigneeIds, creatorId])]
      .filter(uId => uId && uId !== currentUserId);

    for (const rId of relatedUserIds) {
      await Notification.create({
        userId: rId,
        taskId: null,
        type: 'task_deleted',
        title: 'Công việc đã bị xóa',
        message: `Công việc "${taskTitle}" liên quan đến bạn đã bị xóa`,
        isRead: false
      });
    }

    await TaskShare.deleteMany({ taskId: id });
    await TaskActivity.deleteMany({ taskId: id });
    await Task.findByIdAndDelete(id);

    return res.status(200).json({ message: 'Xóa công việc thành công' });
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

const getTaskActivities = async (req, res) => {
  try {
    const { id } = req.params;
    const activities = await TaskActivity.find({ taskId: id })
      .populate('userId', 'fullName email')
      .sort({ createdAt: -1 });
    return res.status(200).json(activities);
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

const assignTask = async (req, res) => {
  try {
    const { id } = req.params;
    const { assigneeIds = [] } = req.body;
    const currentUserId = (req.user?.id || req.user?._id || req.user?.userId || req.user || '').toString();

    const task = await Task.findByIdAndUpdate(id, { assigneeIds }, { new: true });
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    const assignedUsers = await User.find({ _id: { $in: assigneeIds } });
    const assignedNames = assignedUsers.map(u => u.fullName).join(', ');

    await logActivity({
      taskId: task._id,
      userId: currentUserId,
      action: 'Giao việc',
      details: assignedNames ? `Đã giao việc cho: ${assignedNames}` : 'Đã hủy phân công công việc',
    });

    if (Array.isArray(assigneeIds) && assigneeIds.length > 0) {
      for (const assigneeId of assigneeIds) {
        if (assigneeId.toString() !== currentUserId) {
          await Notification.create({
            userId: assigneeId,
            taskId: task._id,
            type: 'task_assigned',
            title: 'Bạn được giao công việc mới',
            message: `Bạn vừa được giao công việc "${task.title}"`,
            isRead: false
          });
        }
      }
    }

    return res.status(200).json(task);
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

module.exports = {
  getTasks,
  createTask,
  getTaskById,
  updateTask,
  deleteTask,
  getTaskActivities,
  assignTask,
};
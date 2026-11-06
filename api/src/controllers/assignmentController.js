const Task = require('../models/Task');
const Notification = require('../models/Notification');

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
    const taskId = req.params.id;
    const assigneeIds = req.body.assigneeIds || req.body.userIds || [];

    if (!assigneeIds || assigneeIds.length === 0) {
      return res.status(400).json({ message: 'Danh sách người được giao không được rỗng' });
    }

    const updatedTask = await Task.findByIdAndUpdate(
      taskId,
      { $addToSet: { assigneeIds: { $each: assigneeIds } } },
      { new: true }
    ).populate('assigneeIds', 'fullName email');

    if (!updatedTask) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    for (const userId of assigneeIds) {
      await Notification.create({
        userId: userId,
        taskId: updatedTask._id,
        type: 'task_assigned',
        title: 'Công việc mới được giao',
        message: `Bạn vừa được giao công việc: ${updatedTask.title}`,
        isRead: false
      });
    }

    return res.status(200).json({
      message: 'Giao việc thành công',
      task: updatedTask
    });
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ nội bộ', error: error.message });
  }
};

exports.updateAssigneeRole = async (req, res) => {
  try {
    const { id, userId } = req.params;
    const { isPrimary } = req.body;

    const task = await Task.findById(id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    if (isPrimary) {
      task.primaryAssigneeId = userId;
      await task.save();
    }

    const updatedTask = await Task.findById(id).populate('assigneeIds', 'fullName email');
    return res.status(200).json({
      message: 'Cập nhật vai trò thành công',
      task: updatedTask
    });
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ nội bộ', error: error.message });
  }
};

exports.removeAssignee = async (req, res) => {
  try {
    const { id, userId } = req.params;
    const updatedTask = await Task.findByIdAndUpdate(
      id,
      { $pull: { assigneeIds: userId } },
      { new: true }
    ).populate('assigneeIds', 'fullName email');

    if (!updatedTask) return res.status(404).json({ message: 'Không tìm thấy công việc' });
    return res.status(200).json({ message: 'Hủy giao việc thành công', task: updatedTask });
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ nội bộ', error: error.message });
  }
};

exports.unassignUser = exports.removeAssignee;
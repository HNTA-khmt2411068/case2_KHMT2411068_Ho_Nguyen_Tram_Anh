const Task = require('../models/Task');
const User = require('../models/User');
const Notification = require('../models/Notification');
const TaskActivity = require('../models/TaskActivity');
const emailService = require('../services/emailService');

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
    const task = await Task.findById(req.params.id).populate('assigneeIds', 'fullName email');
    if (!task) return res.status(404).json({ message: 'Không tìm thấy công việc' });
    res.json(task.assigneeIds || []);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
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
    const { assigneeIds, primaryAssigneeId } = req.body;
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ message: 'Không tìm thấy công việc' });

    if (assigneeIds) task.assigneeIds = assigneeIds;
    if (primaryAssigneeId) task.primaryAssigneeId = primaryAssigneeId;

    await task.save();

    await TaskActivity.create({
      taskId: task._id,
      userId: req.user.id,
      action: `Đã phân công công việc cho ${assigneeIds ? assigneeIds.length : 0} thành viên`,
    });

    if (assigneeIds && assigneeIds.length > 0) {
      const users = await User.find({ _id: { $in: assigneeIds } });
      for (const user of users) {
        await Notification.create({
          userId: user._id,
          taskId: task._id,
          type: 'ASSIGNED',
          title: 'Công việc mới được giao',
          message: `Bạn đã được giao công việc: "${task.title}"`,
        });

        await emailService.sendTaskEmail(
          user.email,
          'Thông báo: Bạn có công việc mới được giao',
          `Xin chào ${user.fullName},\n\nBạn vừa được phân công công việc: "${task.title}".\nHãy kiểm tra ứng dụng TaskManager để xem chi tiết!`
        );
      }
    }

    res.json({ message: 'Giao việc thành công', task });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.updateAssigneeRole = async (req, res) => {
  try {
    const { primaryAssigneeId } = req.body;
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ message: 'Không tìm thấy công việc' });

    if (primaryAssigneeId) task.primaryAssigneeId = primaryAssigneeId;
    await task.save();

    await TaskActivity.create({
      taskId: task._id,
      userId: req.user.id,
      action: 'Đã cập nhật người phụ trách chính',
    });

    res.json({ message: 'Cập nhật vai trò thành công', task });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.removeAssignee = async (req, res) => {
  try {
    const { userId } = req.params;
    const task = await Task.findById(req.params.id);
    if (!task) return res.status(404).json({ message: 'Không tìm thấy công việc' });

    task.assigneeIds = task.assigneeIds.filter(id => id.toString() !== userId);
    await task.save();

    await TaskActivity.create({
      taskId: task._id,
      userId: req.user.id,
      action: 'Đã hủy giao việc cho 1 thành viên',
    });

    res.json({ message: 'Đã hủy giao việc', task });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.unassignUser = exports.removeAssignee;
const Task = require('../models/Task');
const User = require('../models/User');
const Notification = require('../models/Notification');
const emailService = require('../services/emailService');

exports.getTasks = async (req, res) => {
  try {
    const tasks = await Task.find({
      $or: [
        { createdBy: req.user.id },
        { assigneeIds: req.user.id }
      ]
    }).populate('createdBy', 'fullName email').sort({ createdAt: -1 });
    res.json(tasks);
  } catch (error) {
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
    const task = new Task({
      title,
      description,
      startDate,
      dueDate,
      priority,
      status,
      createdBy: req.user.id,
    });
    await task.save();
    res.status(201).json({ message: 'Tạo công việc thành công!', task });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.updateTask = async (req, res) => {
  try {
    const task = await Task.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc!' });
    }
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

    res.json({ message: 'Phân công công việc và gửi thông báo thành công!', task });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};
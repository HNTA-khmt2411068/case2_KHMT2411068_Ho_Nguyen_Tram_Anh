const Task = require('../models/Task');
const User = require('../models/User');
const Notification = require('../models/Notification');
const emailService = require('../services/emailService');

exports.createTask = async (req, res) => {
  try {
    const { title, description, startDate, dueDate, priority, status } = req.body;

    if (!title) {
      return res.status(400).json({ message: 'Tiêu đề công việc là bắt buộc!' });
    }

    const newTask = new Task({
      title,
      description,
      startDate,
      dueDate,
      priority,
      status,
      createdBy: req.user.id,
    });

    await newTask.save();
    res.status(201).json({ message: 'Tạo công việc thành công!', task: newTask });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.getTasks = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status, priority, q } = req.query;

    let query = {
      $or: [{ createdBy: userId }, { assigneeIds: userId }],
    };

    if (status) query.status = status;
    if (priority) query.priority = priority;
    if (q) query.title = { $regex: q, $options: 'i' };

    const tasks = await Task.find(query).sort({ createdAt: -1 });
    res.json(tasks);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.getTaskById = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id)
      .populate('createdBy', 'fullName email')
      .populate('assigneeIds', 'fullName email')
      .populate('primaryAssigneeId', 'fullName email');

    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc!' });
    }

    res.json(task);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.updateTask = async (req, res) => {
  try {
    const { title, description, startDate, dueDate, priority, status } = req.body;
    const task = await Task.findById(req.params.id);

    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc!' });
    }

    if (title) task.title = title;
    if (description !== undefined) task.description = description;
    if (startDate) task.startDate = startDate;
    if (dueDate) task.dueDate = dueDate;
    if (priority) task.priority = priority;
    if (status) task.status = status;

    await task.save();
    res.json({ message: 'Cập nhật công việc thành công!', task });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.updateStatus = async (req, res) => {
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

exports.deleteTask = async (req, res) => {
  try {
    const task = await Task.findByIdAndDelete(req.params.id);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc!' });
    }

    res.json({ message: 'Xóa công việc thành công!' });
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
};
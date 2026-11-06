const TaskShare = require('../models/TaskShare');
const Task = require('../models/Task');
const User = require('../models/User');
const Notification = require('../models/Notification');
const emailService = require('../services/emailService');

exports.shareTask = async (req, res) => {
  try {
    const { userId, permission } = req.body;
    const taskId = req.params.id;

    const task = await Task.findById(taskId);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc!' });
    }

    const share = await TaskShare.findOneAndUpdate(
      { taskId, userId },
      { permission: permission || 'viewer', sharedBy: req.user.id },
      { upsert: true, new: true }
    );

    const recipient = await User.findById(userId);
    if (recipient) {
      await Notification.create({
        userId: recipient._id,
        taskId: task._id,
        type: 'SHARED',
        title: 'Công việc được chia sẻ',
        message: `Bạn được chia sẻ công việc: "${task.title}" với quyền ${permission === 'editor' ? 'Chỉnh sửa' : 'Chỉ xem'}`,
      });

      await emailService.sendTaskEmail(
        recipient.email,
        'Thông báo: Công việc mới được chia sẻ với bạn',
        `Xin chào ${recipient.fullName},\n\nCông việc "${task.title}" đã được chia sẻ với bạn (Quyền: ${permission === 'editor' ? 'Chỉnh sửa' : 'Chỉ xem'}).`
      );
    }

    res.json({ message: 'Chia sẻ công việc thành công!', share });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.getTaskShares = async (req, res) => {
  try {
    const shares = await TaskShare.find({ taskId: req.params.id })
      .populate('userId', 'fullName email avatarUrl')
      .populate('sharedBy', 'fullName email');
    res.json(shares);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.updateSharePermission = async (req, res) => {
  try {
    const { permission } = req.body;
    const share = await TaskShare.findById(req.params.shareId);

    if (!share) {
      return res.status(404).json({ message: 'Không tìm thấy thông tin chia sẻ!' });
    }

    share.permission = permission;
    await share.save();
    res.json({ message: 'Cập nhật quyền thành công!', share });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.revokeShare = async (req, res) => {
  try {
    const share = await TaskShare.findByIdAndDelete(req.params.shareId);
    if (!share) {
      return res.status(404).json({ message: 'Không tìm thấy thông tin chia sẻ!' });
    }
    res.json({ message: 'Thu hồi quyền chia sẻ thành công!' });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

const Notification = require('../models/Notification');

exports.getNotifications = async (req, res) => {
  try {
    const notifications = await Notification.find({ userId: req.user.id })
      .populate('taskId', 'title status')
      .sort({ createdAt: -1 });
    res.json(notifications);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.markAsRead = async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);
    if (!notification) return res.status(404).json({ message: 'Không tìm thấy thông báo!' });

    notification.isRead = true;
    await notification.save();
    res.json({ message: 'Đã đánh dấu đã đọc!' });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

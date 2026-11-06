const Notification = require('../models/Notification');

const getNotifications = async (req, res) => {
  try {
    const currentUserId = (req.user?.id || req.user?._id || req.user?.userId || req.user || '').toString();
    const notifications = await Notification.find({ userId: currentUserId }).sort({ createdAt: -1 });
    return res.status(200).json(notifications);
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi lấy danh sách thông báo', error: error.message });
  }
};

const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    await Notification.findByIdAndUpdate(id, { isRead: true });
    return res.status(200).json({ message: 'Đã đánh dấu đã đọc' });
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

module.exports = {
  getNotifications,
  markAsRead,
};
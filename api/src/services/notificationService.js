const TaskActivity = require('../models/TaskActivity');
const Notification = require('../models/Notification');

exports.logActivity = async (taskId, userId, action, details = {}) => {
  try {
    await TaskActivity.create({ taskId, userId, action, details });
  } catch (err) {
    console.error('Lỗi logActivity:', err);
  }
};

exports.notifyUser = async (userId, taskId, type, title, message) => {
  try {
    await Notification.create({ userId, taskId, type, title, message });
  } catch (err) {
    console.error('Lỗi notifyUser:', err);
  }
};
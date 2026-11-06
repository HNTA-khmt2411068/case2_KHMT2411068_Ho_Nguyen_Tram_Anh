const TaskActivity = require('../models/TaskActivity');

const logActivity = async ({ taskId, userId, action, details = '' }) => {
  try {
    if (!taskId || !userId) return;
    await TaskActivity.create({ taskId, userId, action, details });
  } catch (error) {
    console.error('Lỗi ghi nhật ký hoạt động:', error.message);
  }
};

module.exports = { logActivity };
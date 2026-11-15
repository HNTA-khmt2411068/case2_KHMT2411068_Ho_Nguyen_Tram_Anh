const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');

const checkTaskPermission = (requiredLevel = 'view') => {
  return async (req, res, next) => {
    try {
      const taskId = req.params.id || req.params.taskId;
      const userId = String(req.user._id || req.user.id || req.user.userId);

      const task = await Task.findById(taskId);
      if (!task) {
        return res.status(404).json({ message: 'Không tìm thấy công việc' });
      }

      const isOwner = String(task.createdBy) === userId;
      const isAssignee =
        task.assigneeIds.some((id) => String(id) === userId) ||
        String(task.primaryAssigneeId) === userId;

      const share = await TaskShare.findOne({ taskId, userId });
      const isEditor = share && share.permission === 'editor';
      const isViewer = share && share.permission === 'viewer';

      if (requiredLevel === 'owner' && !isOwner) {
        return res.status(403).json({ message: 'Chỉ người tạo công việc mới có quyền thực hiện thao tác này' });
      }

      if (requiredLevel === 'edit' && !isOwner && !isAssignee && !isEditor) {
        return res.status(403).json({ message: 'Bạn không có quyền chỉnh sửa công việc này' });
      }

      if (requiredLevel === 'view' && !isOwner && !isAssignee && !isEditor && !isViewer) {
        return res.status(403).json({ message: 'Bạn không có quyền truy cập công việc này' });
      }

      req.task = task;
      next();
    } catch (error) {
      res.status(500).json({ message: 'Lỗi kiểm tra quyền truy cập', error: error.message });
    }
  };
};

module.exports = { checkTaskPermission };
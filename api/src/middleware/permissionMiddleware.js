const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');


const checkTaskPermission = (requiredRole = 'viewer') => {
  return async (req, res, next) => {
    try {
      const taskId = req.params.id || req.params.taskId;
      const userId = req.user._id;


      const task = await Task.findById(taskId);
      if (!task) {
        return res.status(404).json({ message: 'Không tìm thấy công việc' });
      }


      if (task.createdBy.toString() === userId.toString()) {
        req.task = task;
        req.userRole = 'owner';
        return next();
      }


      if (requiredRole === 'owner') {
        return res.status(403).json({
          message: 'Chỉ người tạo công việc mới có quyền thực hiện thao tác này'
        });
      }


      const isAssignee = task.assigneeIds.some(
        (id) => id.toString() === userId.toString()
      );


      const shareRecord = await TaskShare.findOne({ taskId, userId });

      let userPermission = null;
      if (shareRecord) {
        userPermission = shareRecord.permission;
      } else if (isAssignee) {
        userPermission = 'editor';
      }


      if (!userPermission) {
        return res.status(403).json({ message: 'Bạn không có quyền truy cập công việc này' });
      }


      if (requiredRole === 'editor' && userPermission === 'viewer') {
        return res.status(403).json({
          message: 'Bạn chỉ có quyền xem (Viewer), không được chỉnh sửa nội dung'
        });
      }

      req.task = task;
      req.userRole = userPermission;
      next();
    } catch (error) {
      res.status(500).json({
        message: 'Lỗi kiểm tra phân quyền backend',
        error: error.message
      });
    }
  };
};

module.exports = { checkTaskPermission };
const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');

const getTaskStatistics = async (req, res) => {
  try {
    const currentUserId = (req.user?.id || req.user?._id || req.user?.userId || req.user || '').toString();

    const shares = await TaskShare.find({ userId: currentUserId });
    const sharedTaskIds = shares.map(s => s.taskId);

    const allAccessibleTasks = await Task.find({
      $or: [
        { createdBy: currentUserId },
        { assigneeIds: currentUserId },
        { _id: { $in: sharedTaskIds } }
      ]
    });

    const now = new Date();

    const stats = {
      total: allAccessibleTasks.length,
      todo: allAccessibleTasks.filter(t => t.status === 'todo').length,
      inProgress: allAccessibleTasks.filter(t => t.status === 'in_progress').length,
      completed: allAccessibleTasks.filter(t => t.status === 'completed').length,
      overdue: allAccessibleTasks.filter(t => t.dueDate && new Date(t.dueDate) < now && t.status !== 'completed').length,
      createdCount: allAccessibleTasks.filter(t => t.createdBy && t.createdBy.toString() === currentUserId).length,
      assignedCount: allAccessibleTasks.filter(t => t.assigneeIds && t.assigneeIds.map(a => a.toString()).includes(currentUserId)).length,
    };

    return res.status(200).json(stats);
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

module.exports = {
  getTaskStatistics,
};
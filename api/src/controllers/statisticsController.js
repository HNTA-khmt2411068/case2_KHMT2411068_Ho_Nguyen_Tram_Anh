const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');

const getAccessibleFilter = async (userId) => {
  const shares = await TaskShare.find({ userId }).select('taskId');
  const sharedTaskIds = shares.map((s) => s.taskId);

  return {
    $or: [
      { createdBy: userId },
      { assigneeIds: userId },
      { primaryAssigneeId: userId },
      { _id: { $in: sharedTaskIds } },
    ],
  };
};

exports.getTaskStatistics = async (req, res) => {
  try {
    const userId = req.user._id || req.user.id || req.user.userId;
    const filter = await getAccessibleFilter(userId);
    const tasks = await Task.find(filter).select('status');

    const stats = {
      total: tasks.length,
      todo: 0,
      in_progress: 0,
      completed: 0,
    };

    tasks.forEach((task) => {
      if (stats[task.status] !== undefined) {
        stats[task.status] += 1;
      }
    });

    res.status(200).json(stats);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi lấy thống kê trạng thái công việc', error: error.message });
  }
};

exports.getAssignmentStatistics = async (req, res) => {
  try {
    const userId = req.user._id || req.user.id || req.user.userId;

    const [createdCount, assignedCount, primaryAssignedCount, sharedCount] = await Promise.all([
      Task.countDocuments({ createdBy: userId }),
      Task.countDocuments({ assigneeIds: userId }),
      Task.countDocuments({ primaryAssigneeId: userId }),
      TaskShare.countDocuments({ userId }),
    ]);

    res.status(200).json({
      created: createdCount,
      assigned: assignedCount,
      primaryAssigned: primaryAssignedCount,
      shared: sharedCount,
    });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi lấy thống kê phân công', error: error.message });
  }
};

exports.getDeadlineStatistics = async (req, res) => {
  try {
    const userId = req.user._id || req.user.id || req.user.userId;
    const filter = await getAccessibleFilter(userId);

    const now = new Date();
    const next24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    const activeTasks = await Task.find({
      ...filter,
      status: { $ne: 'completed' },
      dueDate: { $ne: null },
    }).select('title dueDate status priority');

    const overdueTasks = [];
    const dueSoonTasks = [];

    activeTasks.forEach((task) => {
      const due = new Date(task.dueDate);
      if (due < now) {
        overdueTasks.push(task);
      } else if (due <= next24Hours) {
        dueSoonTasks.push(task);
      }
    });

    res.status(200).json({
      overdueCount: overdueTasks.length,
      dueSoonCount: dueSoonTasks.length,
      overdueTasks,
      dueSoonTasks,
    });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi lấy thống kê thời hạn', error: error.message });
  }
};
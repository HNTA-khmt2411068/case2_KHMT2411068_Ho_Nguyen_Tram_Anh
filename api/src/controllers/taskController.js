const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');

exports.getTasks = async (req, res) => {
  try {
    const userId = req.user.userId;
    const shared = await TaskShare.find({ userId }).select('taskId');
    const sharedTaskIds = shared.map(s => s.taskId);

    const tasks = await Task.find({
      $or: [
        { createdBy: userId },
        { assigneeIds: userId },
        { _id: { $in: sharedTaskIds } }
      ]
    })
    .populate('createdBy', 'fullName email')
    .sort({ createdAt: -1 });

    res.json(tasks);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getTaskById = async (req, res) => {
  try {
    const task = await Task.findById(req.params.id)
      .populate('createdBy', 'fullName email')
      .populate('assigneeIds', 'fullName email');

    if (!task) return res.status(404).json({ message: 'Không tìm thấy công việc' });
    res.json(task);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
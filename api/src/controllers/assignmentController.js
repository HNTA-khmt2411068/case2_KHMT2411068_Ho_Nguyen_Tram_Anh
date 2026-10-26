const Task = require('../models/Task');

exports.assignTask = async (req, res) => {
  try {
    const { assigneeIds, primaryAssigneeId } = req.body;
    const task = req.task;
    if (assigneeIds && Array.isArray(assigneeIds)) {

      const uniqueAssignees = new Set([
        ...task.assigneeIds.map((id) => id.toString()),
        ...assigneeIds,
      ]);
      task.assigneeIds = Array.from(uniqueAssignees);
    }

    if (primaryAssigneeId) {
      task.primaryAssigneeId = primaryAssigneeId;
    }

    await task.save();
    res.status(200).json({ message: 'Giao việc thành công', task });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi giao việc', error: error.message });
  }
};

exports.unassignUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const task = req.task;

    task.assigneeIds = task.assigneeIds.filter(
      (id) => id.toString() !== userId.toString()
    );

    if (task.primaryAssigneeId?.toString() === userId.toString()) {
      task.primaryAssigneeId = null;
    }

    await task.save();
    res.status(200).json({ message: 'Đã hủy giao việc', task });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi hủy giao việc', error: error.message });
  }
};
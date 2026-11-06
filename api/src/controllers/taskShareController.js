const TaskShare = require('../models/TaskShare');
const Task = require('../models/Task');

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
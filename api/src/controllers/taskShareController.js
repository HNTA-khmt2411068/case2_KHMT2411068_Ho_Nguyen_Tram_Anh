const TaskShare = require('../models/TaskShare');


exports.getShares = async (req, res) => {
  try {
    const taskId = req.params.id || req.params.taskId;
    const shares = await TaskShare.find({ taskId })
      .populate('userId', 'fullName email')
      .populate('sharedBy', 'fullName email');
    res.status(200).json(shares);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi lấy danh sách chia sẻ', error: error.message });
  }
};


exports.shareTask = async (req, res) => {
  try {
    const taskId = req.params.id || req.params.taskId;
    const { userId, permission } = req.body;

    const share = await TaskShare.findOneAndUpdate(
      { taskId, userId },
      { permission, sharedBy: req.user._id },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    res.status(200).json({ message: 'Cập nhật chia sẻ thành công', share });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi chia sẻ công việc', error: error.message });
  }
};


exports.revokeShare = async (req, res) => {
  try {
    const { shareId } = req.params;
    await TaskShare.findByIdAndDelete(shareId);
    res.status(200).json({ message: 'Thu hồi quyền chia sẻ thành công' });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi thu hồi quyền chia sẻ', error: error.message });
  }
};
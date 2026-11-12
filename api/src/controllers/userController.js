const User = require('../models/User');

exports.searchUsers = async (req, res) => {
  try {
    const { q } = req.query;
    const currentUserId = req.user.id;

    const users = await User.find({
      _id: { $ne: currentUserId },
      $or: [
        { fullName: { $regex: q || '', $options: 'i' } },
        { email: { $regex: q || '', $options: 'i' } }
      ]
    }).select('-passwordHash');

    res.json(users);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-passwordHash');
    if (!user) {
      return res.status(404).json({ message: 'Không tìm thấy người dùng' });
    }
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};
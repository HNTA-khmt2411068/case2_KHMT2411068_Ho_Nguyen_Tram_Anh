const User = require('../models/User');
exports.searchUsers = async (req, res) => {
  try {
    const { q } = req.query;
    if (!q) {
      return res.status(200).json([]);
    }

    const users = await User.find({
      $or: [
        { fullName: { $regex: q, $options: 'i' } },
        { email: { $regex: q, $options: 'i' } },
      ],
    }).select('_id fullName email avatarUrl');

    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi khi tìm kiếm người dùng', error: error.message });
  }
};
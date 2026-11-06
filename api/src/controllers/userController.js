const User = require('../models/User');

exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find({}).select('-passwordHash');
    return res.status(200).json(users);
  } catch (error) {
    console.error('❌ [BACKEND] Loi lay danh sach nguoi dung:', error.message);
    return res.status(500).json({ message: 'Lỗi server', error: error.message });
  }
};

exports.searchUsers = async (req, res) => {
  try {
    const query = req.query.q || '';
    console.log('🔍 [BACKEND] Nhan request tim kiem:', query);

    if (!query.trim()) {
      return res.status(200).json([]);
    }

    const users = await User.find({
      $or: [
        { fullName: { $regex: query, $options: 'i' } },
        { email: { $regex: query, $options: 'i' } }
      ]
    }).select('-passwordHash');

    console.log('✅ [BACKEND] Tim thay:', users.length, 'nguoi dung');
    return res.status(200).json(users);
  } catch (error) {
    console.error('❌ [BACKEND] Loi tim kiem:', error.message);
    return res.status(500).json({ message: 'Lỗi server khi tìm kiếm', error: error.message });
  }
};

exports.getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-passwordHash');
    if (!user) {
      return res.status(404).json({ message: 'Không tìm thấy người dùng' });
    }
    return res.status(200).json(user);
  } catch (error) {
    console.error('❌ [BACKEND] Loi lay nguoi dung theo ID:', error.message);
    return res.status(500).json({ message: 'Lỗi server' });
  }
};
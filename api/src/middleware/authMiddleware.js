const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Không có quyền truy cập, vui lòng đăng nhập!' });
    }

    const token = authHeader.split(' ')[1];
    const secret = process.env.JWT_SECRET || 'super_secret_jwt_key_123';
    const decoded = jwt.verify(token, secret);

    const uid = decoded.id || decoded.userId || decoded._id;
    req.user = {
      ...decoded,
      id: uid,
      userId: uid,
      _id: uid,
    };

    next();
  } catch (error) {
    return res.status(401).json({ message: 'Token không hợp lệ hoặc đã hết hạn!' });
  }
};
const mongoose = require('mongoose');
const User = require('../models/User');

const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGO_URI ||
      'mongodb+srv://hntanhkhmt2411068_db_user:20052006@hnta-khmt2411068.le5mxxp.mongodb.net/task_manager?retryWrites=true&w=majority';

    const conn = await mongoose.connect(mongoURI);
    console.log('MongoDB Atlas đã kết nối thành công!');

    const users = await User.find({});
    let updatedCount = 0;

    for (let u of users) {
      const cleanedEmail = u.email ? u.email.trim().toLowerCase() : u.email;
      const cleanedName = u.fullName ? u.fullName.trim() : u.fullName;

      if (u.email !== cleanedEmail || u.fullName !== cleanedName) {
        u.email = cleanedEmail;
        u.fullName = cleanedName;
        await u.save();
        updatedCount++;
      }
    }

    if (updatedCount > 0) {
      console.log(`✅ Đã dọn sạch khoảng trắng email cho ${updatedCount} tài khoản (Mật khẩu gốc giữ nguyên)!`);
    } else {
      console.log(`✅ Dữ liệu tất cả tài khoản đã chuẩn hóa!`);
    }
  } catch (error) {
    console.error(`❌ Lỗi kết nối MongoDB: ${error.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;
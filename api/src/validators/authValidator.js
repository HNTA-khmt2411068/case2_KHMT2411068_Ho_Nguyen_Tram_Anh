const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const validateRegister = (data) => {
  const errors = [];
  if (!data.fullName || data.fullName.trim().length < 2) {
    errors.push('Họ tên phải có ít nhất 2 ký tự');
  }
  if (!data.email || !emailRegex.test(data.email)) {
    errors.push('Email không hợp lệ');
  }
  if (!data.password || data.password.length < 6) {
    errors.push('Mật khẩu phải có ít nhất 6 ký tự');
  }
  return errors;
};

const validateLogin = (data) => {
  const errors = [];
  if (!data.email || !emailRegex.test(data.email)) {
    errors.push('Email không hợp lệ');
  }
  if (!data.password) {
    errors.push('Vui lòng nhập mật khẩu');
  }
  return errors;
};

const validateChangePassword = (data) => {
  const errors = [];
  if (!data.oldPassword && !data.currentPassword) {
    errors.push('Vui lòng nhập mật khẩu hiện tại');
  }
  if (!data.newPassword || data.newPassword.length < 6) {
    errors.push('Mật khẩu mới phải có ít nhất 6 ký tự');
  }
  return errors;
};

module.exports = {
  validateRegister,
  validateLogin,
  validateChangePassword,
};
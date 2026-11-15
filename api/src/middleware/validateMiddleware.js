const validate = (validatorFn) => {
  return (req, res, next) => {
    const errors = validatorFn(req.body);
    if (errors && errors.length > 0) {
      return res.status(400).json({
        message: 'Dữ liệu đầu vào không hợp lệ',
        errors,
      });
    }
    next();
  };
};

module.exports = { validate };
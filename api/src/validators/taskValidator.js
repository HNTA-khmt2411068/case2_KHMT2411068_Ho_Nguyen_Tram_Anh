const validPriorities = ['low', 'medium', 'high'];
const validStatuses = ['todo', 'in_progress', 'completed'];

const validateCreateTask = (data) => {
  const errors = [];
  if (!data.title || data.title.trim().length === 0) {
    errors.push('Tên công việc không được để trống');
  }
  if (data.priority && !validPriorities.includes(data.priority)) {
    errors.push('Mức độ ưu tiên phải là low, medium hoặc high');
  }
  if (data.status && !validStatuses.includes(data.status)) {
    errors.push('Trạng thái phải là todo, in_progress hoặc completed');
  }
  if (data.startDate && data.dueDate && new Date(data.dueDate) < new Date(data.startDate)) {
    errors.push('Hạn hoàn thành không được nhỏ hơn ngày bắt đầu');
  }
  return errors;
};

const validateUpdateTask = (data) => {
  const errors = [];
  if (data.title !== undefined && data.title.trim().length === 0) {
    errors.push('Tên công việc không được để trống');
  }
  if (data.priority && !validPriorities.includes(data.priority)) {
    errors.push('Mức độ ưu tiên không hợp lệ');
  }
  if (data.status && !validStatuses.includes(data.status)) {
    errors.push('Trạng thái không hợp lệ');
  }
  if (data.startDate && data.dueDate && new Date(data.dueDate) < new Date(data.startDate)) {
    errors.push('Hạn hoàn thành không được nhỏ hơn ngày bắt đầu');
  }
  return errors;
};

module.exports = {
  validateCreateTask,
  validateUpdateTask,
};
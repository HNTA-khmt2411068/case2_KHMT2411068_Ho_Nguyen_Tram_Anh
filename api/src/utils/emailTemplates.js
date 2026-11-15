const formatDate = (date) => {
  if (!date) return 'Không giới hạn';
  return new Date(date).toLocaleString('vi-VN');
};

const taskAssignedTemplate = (task, assignerName) => ({
  subject: `[TaskManager] Bạn được giao công việc mới: ${task.title}`,
  text: `Xin chào,\n\n${assignerName} vừa giao cho bạn công việc "${task.title}".\n- Mức độ ưu tiên: ${task.priority}\n- Hạn hoàn thành: ${formatDate(task.dueDate)}\n\nVui lòng mở ứng dụng TaskManager để xem chi tiết.`,
});

const taskSharedTemplate = (task, sharerName, permission) => ({
  subject: `[TaskManager] Công việc được chia sẻ với bạn: ${task.title}`,
  text: `Xin chào,\n\n${sharerName} đã chia sẻ công việc "${task.title}" với bạn (Quyền: ${permission}).\n- Hạn hoàn thành: ${formatDate(task.dueDate)}\n\nVui lòng mở ứng dụng TaskManager để theo dõi.`,
});

const taskUpdatedTemplate = (task, updaterName) => ({
  subject: `[TaskManager] Cập nhật công việc: ${task.title}`,
  text: `Xin chào,\n\n${updaterName} vừa cập nhật thông tin công việc "${task.title}".\n- Trạng thái hiện tại: ${task.status}\n- Hạn hoàn thành: ${formatDate(task.dueDate)}\n\nVui lòng kiểm tra trên ứng dụng TaskManager.`,
});

const taskCompletedTemplate = (task, completerName) => ({
  subject: `[TaskManager] Hoàn thành công việc: ${task.title}`,
  text: `Xin chào,\n\nCông việc "${task.title}" đã được ${completerName} đánh dấu hoàn thành.\n\nCảm ơn bạn đã đồng hành!`,
});

const taskReminderTemplate = (task) => ({
  subject: `[TaskManager] Nhắc nhở sắp đến hạn: ${task.title}`,
  text: `Xin chào,\n\nCông việc "${task.title}" của bạn sắp đến hạn hoàn thành vào lúc ${formatDate(task.dueDate)}.\n\nVui lòng hoàn tất đúng tiến độ nhé!`,
});

module.exports = {
  taskAssignedTemplate,
  taskSharedTemplate,
  taskUpdatedTemplate,
  taskCompletedTemplate,
  taskReminderTemplate,
};
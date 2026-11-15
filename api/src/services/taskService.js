const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { sendTaskEmail } = require('./emailService');
const { taskReminderTemplate } = require('../utils/emailTemplates');

const buildAccessibleTasksFilter = async (userId) => {
  const shares = await TaskShare.find({ userId }).select('taskId');
  const sharedTaskIds = shares.map((s) => s.taskId);

  return {
    $or: [
      { createdBy: userId },
      { assigneeIds: userId },
      { primaryAssigneeId: userId },
      { _id: { $in: sharedTaskIds } },
    ],
  };
};

const sendUpcomingDeadlineReminders = async () => {
  const now = new Date();
  const next24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);

  const upcomingTasks = await Task.find({
    status: { $ne: 'completed' },
    dueDate: { $gte: now, $lte: next24Hours },
  });

  for (const task of upcomingTasks) {
    const existingReminder = await Notification.findOne({
      taskId: task._id,
      type: 'deadline_reminder',
    });

    if (existingReminder) continue;

    const recipientIds = new Set([
      String(task.createdBy),
      ...(task.assigneeIds || []).map((id) => String(id)),
    ]);
    if (task.primaryAssigneeId) {
      recipientIds.add(String(task.primaryAssigneeId));
    }

    const users = await User.find({ _id: { $in: Array.from(recipientIds) } });
    const template = taskReminderTemplate(task);

    for (const user of users) {
      await Notification.create({
        userId: user._id,
        taskId: task._id,
        type: 'deadline_reminder',
        title: 'Sắp đến hạn hoàn thành',
        message: `Công việc "${task.title}" sắp đến hạn trong vòng 24 giờ tới.`,
      });

      if (user.email) {
        await sendTaskEmail(user.email, template.subject, template.text, {
          taskId: task._id,
          eventType: 'deadline_reminder',
        });
      }
    }
  }
};

module.exports = {
  buildAccessibleTasksFilter,
  sendUpcomingDeadlineReminders,
};
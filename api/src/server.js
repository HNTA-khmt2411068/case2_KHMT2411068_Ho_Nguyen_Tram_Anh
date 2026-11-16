require('dotenv').config();
const app = require('./app');
const connectDB = require('./config/database');
const Task = require('./models/Task');
const User = require('./models/User');
const Notification = require('./models/Notification');
const emailService = require('./services/emailService');

const PORT = process.env.PORT || 5000;
const REMINDER_BEFORE_HOURS = Number(process.env.REMINDER_BEFORE_HOURS) || 24;
const REMINDER_INTERVAL_MINUTES =
  Number(process.env.REMINDER_INTERVAL_MINUTES) || 1;

const checkUpcomingDueTasks = async () => {
  try {
    const now = new Date();
    const reminderWindowMs = REMINDER_BEFORE_HOURS * 60 * 60 * 1000;
    const upcomingLimit = new Date(now.getTime() + reminderWindowMs);
    const dedupeSince = new Date(now.getTime() - reminderWindowMs);

    const upcomingTasks = await Task.find({
      status: { $ne: 'completed' },
      dueDate: { $gt: now, $lte: upcomingLimit },
    });

    for (const task of upcomingTasks) {
      const recipientIds = [
        ...new Set(
          [
            ...(task.assigneeIds || []).map((id) => id.toString()),
            task.createdBy ? task.createdBy.toString() : '',
          ].filter(Boolean)
        ),
      ];

      if (recipientIds.length === 0) continue;

      const users = await User.find({ _id: { $in: recipientIds } });
      const formattedDue = new Date(task.dueDate).toLocaleString('vi-VN');

      for (const user of users) {
        const alreadyReminded = await Notification.findOne({
          userId: user._id,
          taskId: task._id,
          type: 'DUE_SOON_REMINDER',
          createdAt: { $gte: dedupeSince },
        });

        if (alreadyReminded) continue;

        await Notification.create({
          userId: user._id,
          taskId: task._id,
          type: 'DUE_SOON_REMINDER',
          title: 'Nhắc nhở công việc sắp đến hạn',
          message: `Công việc "${task.title}" sẽ đến hạn hoàn thành vào lúc ${formattedDue}.`,
        });

        try {
          const sent = await emailService.sendTaskEmail(
            user.email,
            `Nhắc nhở: Công việc "${task.title}" sắp đến hạn`,
            `Xin chào ${user.fullName},\n\nCông việc "${task.title}" của bạn sắp đến hạn hoàn thành vào lúc: ${formattedDue}.\nVui lòng mở ứng dụng TaskManager để kiểm tra và hoàn tất đúng tiến độ!`,
            { taskId: task._id, eventType: 'TASK_DUE_SOON' }
          );
          if (sent) {
            console.log(
              `⏰ Đã gửi email nhắc hạn "${task.title}" tới ${user.email}`
            );
          }
        } catch (mailErr) {
          console.error('Lỗi gửi email nhắc hạn:', mailErr.message);
        }
      }
    }
  } catch (error) {
    console.error('Lỗi bộ quét nhắc việc tự động:', error.message);
  }
};

connectDB().then(() => {
  app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(
      `⏱️ Bộ nhắc hạn tự động: quét mỗi ${REMINDER_INTERVAL_MINUTES} phút (nhắc trước ${REMINDER_BEFORE_HOURS} giờ)`
    );
    checkUpcomingDueTasks();
    setInterval(checkUpcomingDueTasks, REMINDER_INTERVAL_MINUTES * 60 * 1000);
  });
});
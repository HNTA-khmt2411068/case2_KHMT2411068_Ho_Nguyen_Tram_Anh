const TaskShare = require('../models/TaskShare');
const Task = require('../models/Task');
const User = require('../models/User');
const Notification = require('../models/Notification');
const TaskActivity = require('../models/TaskActivity');
const emailService = require('../services/emailService');

exports.shareTask = async (req, res) => {
  try {
    const { userId, permission } = req.body;
    const taskId = req.params.id;

    const task = await Task.findById(taskId);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc!' });
    }

    const share = await TaskShare.findOneAndUpdate(
      { taskId, userId },
      { permission: permission || 'viewer', sharedBy: req.user.id },
      { upsert: true, returnDocument: 'after' }
    );

    const permText = permission === 'editor' ? 'Chỉnh sửa' : 'Chỉ xem';

    await TaskActivity.create({
      taskId: task._id,
      userId: req.user.id,
      action: `Đã chia sẻ công việc (Quyền: ${permText})`
    });

    await Notification.create({
      userId: req.user.id,
      taskId: task._id,
      type: 'SHARE_SENT',
      title: 'Chia sẻ công việc thành công',
      message: `Bạn đã chia sẻ công việc "${task.title}" (Quyền: ${permText}) thành công.`,
    });

    const recipient = await User.findById(userId);
    if (recipient && recipient._id.toString() !== req.user.id) {
      await Notification.create({
        userId: recipient._id,
        taskId: task._id,
        type: 'SHARED',
        title: 'Công việc được chia sẻ',
        message: `Bạn vừa được chia sẻ công việc: "${task.title}" (Quyền: ${permText})`,
      });

      try {
        await emailService.sendTaskEmail(
          recipient.email,
          'Thông báo: Công việc mới được chia sẻ với bạn',
          `Xin chào ${recipient.fullName},\n\nCông việc "${task.title}" đã được chia sẻ với bạn (Quyền: ${permText}).`
        );
      } catch (emailErr) {
        console.error('Bỏ qua lỗi gửi email:', emailErr.message);
      }
    }

    res.json({ message: 'Chia sẻ công việc thành công!', share });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.getTaskShares = async (req, res) => {
  try {
    const taskId = req.params.id;
    const shares = await TaskShare.find({ taskId }).populate('userId', 'fullName email');
    res.json(shares);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

exports.revokeShare = async (req, res) => {
  try {
    const { shareId } = req.params;

    const share = await TaskShare.findById(shareId);
    if (!share) {
      return res.status(404).json({ message: 'Không tìm thấy quyền chia sẻ!' });
    }

    const task = await Task.findById(share.taskId);
    const taskTitle = task ? task.title : 'công việc';

    await Notification.create({
      userId: req.user.id,
      taskId: share.taskId,
      type: 'REVOKE_SENT',
      title: 'Thu hồi quyền thành công',
      message: `Bạn đã thu hồi quyền truy cập công việc "${taskTitle}" thành công.`,
    });

    if (share.userId && share.userId.toString() !== req.user.id) {
      await Notification.create({
        userId: share.userId,
        taskId: share.taskId,
        type: 'SHARE_REVOKED',
        title: 'Thu hồi quyền chia sẻ',
        message: `Quyền truy cập công việc "${taskTitle}" của bạn đã bị thu hồi.`,
      });
    }

    await TaskActivity.create({
      taskId: share.taskId,
      userId: req.user.id,
      action: `Đã thu hồi quyền chia sẻ công việc "${taskTitle}"`,
    });

    await TaskShare.findByIdAndDelete(shareId);

    res.json({ message: 'Đã thu hồi quyền chia sẻ thành công!' });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};
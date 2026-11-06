const TaskShare = require('../models/TaskShare');
const Task = require('../models/Task');
const User = require('../models/User');
const Notification = require('../models/Notification');
const { sendEmail } = require('../services/emailService');
const { logActivity } = require('../services/activityService');

const shareTask = async (req, res) => {
  try {
    const { taskId } = req.params;
    const { userId, permission = 'viewer' } = req.body;
    const currentUserId = (req.user?.id || req.user?._id || req.user?.userId || req.user || '').toString();

    const task = await Task.findById(taskId);
    if (!task) {
      return res.status(404).json({ message: 'Không tìm thấy công việc' });
    }

    let share = await TaskShare.findOne({ taskId, userId });
    if (share) {
      share.permission = permission;
      await share.save();
    } else {
      share = await TaskShare.create({
        taskId,
        userId,
        permission,
        sharedBy: currentUserId,
      });
    }

    const recipient = await User.findById(userId);
    if (recipient) {
      await logActivity({
        taskId,
        userId: currentUserId,
        action: 'Chia sẻ công việc',
        details: `Đã chia sẻ công việc với: ${recipient.fullName || recipient.email}`,
      });

      await Notification.create({
        userId: recipient._id,
        taskId: task._id,
        type: 'task_shared',
        title: 'Công việc mới được chia sẻ',
        message: `Bạn vừa được chia sẻ công việc "${task.title}" với quyền ${permission.toUpperCase()}`,
        isRead: false,
      });

      if (currentUserId) {
        await Notification.create({
          userId: currentUserId,
          taskId: task._id,
          type: 'task_shared_sender',
          title: 'Đã chia sẻ công việc',
          message: `Bạn đã chia sẻ công việc "${task.title}" cho ${recipient.fullName || recipient.email} với quyền ${permission.toUpperCase()}`,
          isRead: false,
        });
      }

      if (recipient.email) {
        sendEmail({
          recipientEmail: recipient.email,
          eventType: 'task_shared',
          taskId: task._id,
          subject: `[Task Manager] Bạn được chia sẻ công việc: ${task.title}`,
          text: `Xin chào ${recipient.fullName || 'bạn'},\n\nCông việc "${task.title}" vừa được chia sẻ với bạn (Quyền: ${permission.toUpperCase()}).\n\nVui lòng đăng nhập ứng dụng để xem chi tiết.`,
        });
      }
    }

    return res.status(200).json({ message: 'Chia sẻ công việc thành công', share });
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

const getShares = async (req, res) => {
  try {
    const { taskId } = req.params;
    const shares = await TaskShare.find({ taskId }).populate('userId', 'fullName email');
    return res.status(200).json(shares);
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ' });
  }
};

const revokeShare = async (req, res) => {
  try {
    const shareId = req.params.shareId || req.params.id;
    const currentUserId = (req.user?.id || req.user?._id || req.user?.userId || req.user || '').toString();

    const share = await TaskShare.findById(shareId).populate('taskId').populate('userId');

    if (!share) {
      return res.status(404).json({ message: 'Không tìm thấy bản ghi chia sẻ' });
    }

    let recipientId = '';
    let recipientName = 'người dùng';
    let recipientEmail = '';

    if (share.userId) {
      if (typeof share.userId === 'object' && share.userId._id) {
        recipientId = share.userId._id.toString();
        recipientName = share.userId.fullName || share.userId.email || 'người dùng';
        recipientEmail = share.userId.email || '';
      } else {
        recipientId = share.userId.toString();
        const recipientUser = await User.findById(share.userId);
        if (recipientUser) {
          recipientName = recipientUser.fullName || recipientUser.email || 'người dùng';
          recipientEmail = recipientUser.email || '';
        }
      }
    }

    let taskIdVal = share.taskId?._id || share.taskId;
    let taskTitle = 'Công việc';
    if (typeof share.taskId === 'object' && share.taskId.title) {
      taskTitle = share.taskId.title;
    } else if (share.taskId) {
      const t = await Task.findById(share.taskId);
      if (t) taskTitle = t.title;
    }

    await logActivity({
      taskId: taskIdVal,
      userId: currentUserId,
      action: 'Thu hồi chia sẻ',
      details: `Đã thu hồi quyền chia sẻ của: ${recipientName}`,
    });

    if (recipientId) {
      await Notification.create({
        userId: recipientId,
        taskId: taskIdVal,
        type: 'task_share_revoked',
        title: 'Quyền chia sẻ đã bị thu hồi',
        message: `Quyền truy cập công việc "${taskTitle}" của bạn đã bị thu hồi`,
        isRead: false,
      });

      if (recipientEmail) {
        sendEmail({
          recipientEmail: recipientEmail,
          eventType: 'task_share_revoked',
          taskId: taskIdVal,
          subject: `[Task Manager] Thu hồi quyền chia sẻ: ${taskTitle}`,
          text: `Xin chào ${recipientName},\n\nQuyền truy cập công việc "${taskTitle}" của bạn đã bị thu hồi.`,
        });
      }
    }

    if (currentUserId) {
      await Notification.create({
        userId: currentUserId,
        taskId: taskIdVal,
        type: 'task_share_revoked_sender',
        title: 'Đã thu hồi chia sẻ',
        message: `Bạn đã thu hồi quyền chia sẻ công việc "${taskTitle}" của ${recipientName}`,
        isRead: false,
      });
    }

    await TaskShare.findByIdAndDelete(shareId);
    return res.status(200).json({ message: 'Đã thu hồi quyền chia sẻ thành công' });
  } catch (error) {
    return res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

module.exports = {
  shareTask,
  getShares,
  revokeShare,
};
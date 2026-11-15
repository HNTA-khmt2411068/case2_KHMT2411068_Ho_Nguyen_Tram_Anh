const transporter = require('../config/email');
const EmailLog = require('../models/EmailLog');

exports.sendTaskEmail = async (toEmail, subject, textContent, options = {}) => {
  const { taskId = null, eventType = 'TASK_NOTIFICATION' } = options;
  let log = null;

  try {
    log = await EmailLog.create({
      taskId,
      recipientEmail: toEmail,
      eventType,
      subject,
      status: 'pending',
      attempts: 1,
    });
  } catch (logErr) {
    console.error('Không thể tạo bản ghi EmailLog:', logErr.message);
  }

  try {
    const mailOptions = {
      from: process.env.EMAIL_FROM || process.env.EMAIL_USER || 'TaskManager App <no-reply@taskmanager.com>',
      to: toEmail,
      subject,
      text: textContent,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('Email sent successfully:', info.response);

    if (log) {
      log.status = 'sent';
      log.sentAt = new Date();
      await log.save();
    }
    return true;
  } catch (error) {
    console.error('Error sending email:', error.message);

    if (log) {
      log.status = 'failed';
      log.errorMessage = error.message;
      await log.save();
    }
    return false;
  }
};
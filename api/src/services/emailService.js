const transporter = require('../config/email');
const EmailLog = require('../models/EmailLog');

const sendEmail = async ({ recipientEmail, subject, text, html, eventType, taskId = null }) => {
  let log;
  try {
    log = await EmailLog.create({
      taskId,
      recipientEmail,
      eventType,
      subject,
      status: 'pending',
    });

    const mailOptions = {
      from: `"Task Manager App" <${process.env.EMAIL_USER}>`,
      to: recipientEmail,
      subject,
      text,
      html,
    };

    await transporter.sendMail(mailOptions);

    log.status = 'sent';
    log.sentAt = new Date();
    await log.save();
    return true;
  } catch (error) {
    if (log) {
      log.status = 'failed';
      log.errorMessage = error.message;
      await log.save();
    }
    console.error('Lỗi gửi email:', error.message);
    return false;
  }
};

module.exports = {
  sendEmail,
};
const transporter = require('../config/email');

exports.sendTaskEmail = async (toEmail, subject, textContent) => {
  try {
    const mailOptions = {
      from: process.env.EMAIL_USER || 'TaskManager App <no-reply@taskmanager.com>',
      to: toEmail,
      subject: subject,
      text: textContent,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('Email sent successfully:', info.response);
    return true;
  } catch (error) {
    console.error('Error sending email:', error.message);
    return false;
  }
};
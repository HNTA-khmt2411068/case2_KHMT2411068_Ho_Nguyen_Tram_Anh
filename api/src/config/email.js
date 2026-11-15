const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: Number(process.env.SMTP_PORT) || 587,
  secure: false,
  auth: {
    user: (process.env.SMTP_USER || process.env.EMAIL_USER || '').trim(),
    pass: (process.env.SMTP_PASS || process.env.EMAIL_PASS || '').trim(),
  },
});

module.exports = transporter;
const mongoose = require('mongoose');

const taskActivitySchema = new mongoose.Schema(
  {
    taskId: { type: mongoose.Schema.Types.ObjectId, ref: 'Task', required: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    action: { type: String, required: true },
    details: { type: String, default: '' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('TaskActivity', taskActivitySchema);
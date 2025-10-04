// models/Assignment.js
const mongoose = require('mongoose');

const assignmentSchema = new mongoose.Schema({
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', required: true },
  title: { type: String, required: true },
  description: String,
  groupIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Group', required: true }],
  startDate: { type: Date, required: true },
  deadline: { type: Date, required: true },
  allowLateSubmission: { type: Boolean, default: false },
  lateDeadline: Date,
  maxAttempts: { type: Number, default: 1 },
  allowedFileTypes: [String],
  maxFileSize: { type: Number, default: 10485760 },
  attachments: [{
    fileName: String,
    fileUrl: String,
    fileSize: Number,
    mimeType: String
  }]
}, { timestamps: true });

assignmentSchema.index({ courseId: 1 });
assignmentSchema.index({ deadline: 1 });

module.exports = mongoose.model('Assignment', assignmentSchema);
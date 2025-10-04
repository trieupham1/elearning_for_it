// models/Announcement.js
const mongoose = require('mongoose');

const announcementSchema = new mongoose.Schema({
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', required: true },
  title: { type: String, required: true },
  content: { type: String, required: true },
  authorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  groupIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Group' }],
  attachments: [{
    fileName: String,
    fileUrl: String,
    fileSize: Number,
    mimeType: String
  }],
  viewedBy: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    viewedAt: Date
  }],
  downloadedBy: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    fileName: String,
    downloadedAt: Date
  }]
}, { timestamps: true });

announcementSchema.index({ courseId: 1 });

module.exports = mongoose.model('Announcement', announcementSchema);
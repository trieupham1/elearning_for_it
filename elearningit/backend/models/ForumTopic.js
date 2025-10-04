// models/ForumTopic.js
const mongoose = require('mongoose');

const forumTopicSchema = new mongoose.Schema({
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', required: true },
  authorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  content: String,
  attachments: [{
    fileName: String,
    fileUrl: String,
    fileSize: Number,
    mimeType: String
  }],
  isPinned: { type: Boolean, default: false }
}, { timestamps: true });

forumTopicSchema.index({ courseId: 1 });

module.exports = mongoose.model('ForumTopic', forumTopicSchema);
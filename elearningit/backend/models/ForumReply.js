// models/ForumReply.js
const mongoose = require('mongoose');

const forumReplySchema = new mongoose.Schema({
  topicId: { type: mongoose.Schema.Types.ObjectId, ref: 'ForumTopic', required: true },
  authorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  content: { type: String, required: true },
  parentReplyId: { type: mongoose.Schema.Types.ObjectId, ref: 'ForumReply' },
  attachments: [{
    fileName: String,
    fileUrl: String,
    fileSize: Number,
    mimeType: String
  }]
}, { timestamps: true });

forumReplySchema.index({ topicId: 1 });

module.exports = mongoose.model('ForumReply', forumReplySchema);
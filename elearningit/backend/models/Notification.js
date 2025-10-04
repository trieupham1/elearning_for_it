// models/Notification.js
const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  type: { 
    type: String, 
    enum: ['announcement', 'assignment', 'quiz', 'grade', 'message', 'deadline', 'material'],
    required: true 
  },
  title: { type: String, required: true },
  content: String,
  relatedId: mongoose.Schema.Types.ObjectId,
  relatedType: String,
  isRead: { type: Boolean, default: false },
  readAt: Date
}, { timestamps: true });

notificationSchema.index({ userId: 1, isRead: 1, createdAt: -1 });

module.exports = mongoose.model('Notification', notificationSchema);
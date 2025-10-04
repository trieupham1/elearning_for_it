// models/Material.js
const mongoose = require('mongoose');

const materialSchema = new mongoose.Schema({
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', required: true },
  title: { type: String, required: true },
  description: String,
  files: [{
    fileName: String,
    fileUrl: String,
    fileSize: Number,
    mimeType: String
  }],
  links: [String],
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

materialSchema.index({ courseId: 1 });

module.exports = mongoose.model('Material', materialSchema);
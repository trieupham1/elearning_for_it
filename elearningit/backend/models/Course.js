// models/Course.js
const mongoose = require('mongoose');

const courseSchema = new mongoose.Schema({
  code: { type: String, required: true },
  name: { type: String, required: true },
  semesterId: { type: mongoose.Schema.Types.ObjectId, ref: 'Semester', required: true },
  sessions: { type: Number, enum: [10, 15], required: true },
  instructorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  coverImage: String,
  color: String,
  description: String
}, { timestamps: true });

courseSchema.index({ semesterId: 1 });
courseSchema.index({ code: 1 });

module.exports = mongoose.model('Course', courseSchema);
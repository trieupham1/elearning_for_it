// models/Semester.js
const mongoose = require('mongoose');

const semesterSchema = new mongoose.Schema({
  code: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  startDate: Date,
  endDate: Date,
  isCurrent: { type: Boolean, default: false }
}, { timestamps: true });

semesterSchema.index({ code: 1 });
semesterSchema.index({ isCurrent: 1 });

module.exports = mongoose.model('Semester', semesterSchema);
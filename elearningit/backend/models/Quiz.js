// models/Quiz.js
const mongoose = require('mongoose');

const quizSchema = new mongoose.Schema({
  courseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', required: true },
  title: { type: String, required: true },
  description: String,
  groupIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Group', required: true }],
  openDate: { type: Date, required: true },
  closeDate: { type: Date, required: true },
  duration: { type: Number, required: true },
  maxAttempts: { type: Number, default: 1 },
  questionStructure: {
    easy: Number,
    medium: Number,
    hard: Number
  },
  selectedQuestions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Question' }]
}, { timestamps: true });

quizSchema.index({ courseId: 1 });
quizSchema.index({ openDate: 1, closeDate: 1 });

module.exports = mongoose.model('Quiz', quizSchema);
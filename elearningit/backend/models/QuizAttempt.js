// models/QuizAttempt.js
const mongoose = require('mongoose');

const quizAttemptSchema = new mongoose.Schema({
  quizId: { type: mongoose.Schema.Types.ObjectId, ref: 'Quiz', required: true },
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  attemptNumber: { type: Number, default: 1 },
  answers: [{
    questionId: { type: mongoose.Schema.Types.ObjectId, ref: 'Question' },
    selectedChoice: Number,
    isCorrect: Boolean
  }],
  startedAt: { type: Date, required: true },
  submittedAt: Date,
  score: Number,
  totalQuestions: Number
});

quizAttemptSchema.index({ quizId: 1, studentId: 1 });

module.exports = mongoose.model('QuizAttempt', quizAttemptSchema);
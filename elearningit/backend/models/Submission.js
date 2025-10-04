// models/Submission.js
const mongoose = require('mongoose');

const submissionSchema = new mongoose.Schema({
  assignmentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Assignment', required: true },
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  attemptNumber: { type: Number, default: 1 },
  files: [{
    fileName: String,
    fileUrl: String,
    fileSize: Number,
    mimeType: String
  }],
  submittedAt: { type: Date, default: Date.now },
  isLate: Boolean,
  grade: Number,
  feedback: String,
  gradedAt: Date,
  gradedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
});

submissionSchema.index({ assignmentId: 1, studentId: 1 });
submissionSchema.index({ studentId: 1 });

module.exports = mongoose.model('Submission', submissionSchema);
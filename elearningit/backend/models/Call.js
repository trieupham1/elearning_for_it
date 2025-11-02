// models/Call.js
const mongoose = require('mongoose');

const callSchema = new mongoose.Schema({
  caller: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  callee: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  type: {
    type: String,
    enum: ['voice', 'video'],
    required: true
  },
  status: {
    type: String,
    enum: ['initiated', 'ringing', 'accepted', 'rejected', 'ended', 'missed', 'busy'],
    default: 'initiated'
  },
  startedAt: {
    type: Date
  },
  endedAt: {
    type: Date
  },
  duration: {
    type: Number, // in seconds
    default: 0
  },
  isScreenSharing: {
    type: Boolean,
    default: false
  },
  screenShareStartedAt: {
    type: Date
  },
  connectionQuality: {
    type: String,
    enum: ['excellent', 'good', 'fair', 'poor'],
    default: 'good'
  }
}, {
  timestamps: true
});

// Calculate duration when call ends
callSchema.pre('save', function(next) {
  if (this.endedAt && this.startedAt) {
    this.duration = Math.floor((this.endedAt - this.startedAt) / 1000);
  }
  next();
});

// Get call history for a user
callSchema.statics.getHistory = async function(userId, limit = 50) {
  return this.find({
    $or: [
      { caller: userId },
      { callee: userId }
    ]
  })
    .populate('caller', 'firstName lastName username profilePicture')
    .populate('callee', 'firstName lastName username profilePicture')
    .sort({ createdAt: -1 })
    .limit(limit);
};

// Get active calls for a user
callSchema.statics.getActiveCalls = async function(userId) {
  return this.find({
    $or: [
      { caller: userId },
      { callee: userId }
    ],
    status: { $in: ['initiated', 'ringing', 'accepted'] }
  })
    .populate('caller', 'firstName lastName username profilePicture')
    .populate('callee', 'firstName lastName username profilePicture');
};

module.exports = mongoose.model('Call', callSchema);

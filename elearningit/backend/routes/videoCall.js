const express = require('express');
const router = express.Router();
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');
const auth = require('../middleware/auth');
const User = require('../models/User');
const Course = require('../models/Course');

// Agora credentials
const APP_ID = 'afa109d795eb450db1793f9f0b5f0ec9';
const APP_CERTIFICATE = 'ca04017022db42a48745e123b3c009b8';

// Store active call sessions (in production, use Redis or database)
const activeCalls = new Map();

/**
 * @route   POST /api/video-call/token
 * @desc    Generate Agora RTC token for video call
 * @access  Private
 */
router.post('/token', auth, async (req, res) => {
  try {
    const { channelName, uid } = req.body;

    if (!channelName || uid === undefined) {
      return res.status(400).json({ 
        message: 'Channel name and uid are required' 
      });
    }

    // Token expiration time (24 hours)
    const expirationTimeInSeconds = 3600 * 24;
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

    // Build token
    const token = RtcTokenBuilder.buildTokenWithUid(
      APP_ID,
      APP_CERTIFICATE,
      channelName,
      uid,
      RtcRole.PUBLISHER,
      privilegeExpiredTs
    );

    res.json({
      token,
      channelName,
      uid,
      appId: APP_ID,
      expiresAt: privilegeExpiredTs,
    });
  } catch (error) {
    console.error('Error generating token:', error);
    res.status(500).json({ 
      message: 'Server error generating token',
      error: error.message 
    });
  }
});

/**
 * @route   POST /api/video-call/join
 * @desc    Notify that user joined a call
 * @access  Private
 */
router.post('/join', auth, async (req, res) => {
  try {
    const { courseId, channelName } = req.body;
    const userId = req.user.userId;

    // Verify user is enrolled in the course
    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({ message: 'Course not found' });
    }

    const isEnrolled = course.students.includes(userId) || 
                       course.instructor.toString() === userId;
    
    if (!isEnrolled) {
      return res.status(403).json({ 
        message: 'You are not enrolled in this course' 
      });
    }

    // Get user info
    const user = await User.findById(userId).select('firstName lastName username');
    
    // Store active call info
    if (!activeCalls.has(channelName)) {
      activeCalls.set(channelName, new Map());
    }
    
    const callParticipants = activeCalls.get(channelName);
    callParticipants.set(userId, {
      userId,
      userName: `${user.firstName} ${user.lastName}`,
      uid: userId.hashCode || userId,
      joinedAt: new Date(),
    });

    res.json({ 
      message: 'Joined call successfully',
      participants: Array.from(callParticipants.values()),
    });
  } catch (error) {
    console.error('Error joining call:', error);
    res.status(500).json({ 
      message: 'Server error',
      error: error.message 
    });
  }
});

/**
 * @route   POST /api/video-call/leave
 * @desc    Notify that user left a call
 * @access  Private
 */
router.post('/leave', auth, async (req, res) => {
  try {
    const { channelName } = req.body;
    const userId = req.user.userId;

    if (activeCalls.has(channelName)) {
      const callParticipants = activeCalls.get(channelName);
      callParticipants.delete(userId);

      // Remove channel if no participants left
      if (callParticipants.size === 0) {
        activeCalls.delete(channelName);
      }
    }

    res.json({ message: 'Left call successfully' });
  } catch (error) {
    console.error('Error leaving call:', error);
    res.status(500).json({ 
      message: 'Server error',
      error: error.message 
    });
  }
});

/**
 * @route   GET /api/video-call/user/:uid
 * @desc    Get user name by UID
 * @access  Private
 */
router.get('/user/:uid', auth, async (req, res) => {
  try {
    const { uid } = req.params;

    // Try to find user by ID
    let user;
    
    // If uid looks like a MongoDB ID, search by ID
    if (uid.match(/^[0-9a-fA-F]{24}$/)) {
      user = await User.findById(uid).select('firstName lastName username profilePicture');
    }
    
    // If not found or not a valid MongoDB ID, search through active calls
    if (!user) {
      // Search through active calls to find the user by UID
      for (const [channelName, participants] of activeCalls.entries()) {
        for (const [userId, participant] of participants.entries()) {
          if (participant.uid == uid || participant.userId == uid) {
            user = await User.findById(userId).select('firstName lastName username profilePicture');
            break;
          }
        }
        if (user) break;
      }
    }
    
    if (!user) {
      return res.json({ 
        userName: 'Unknown User',
        profilePicture: null 
      });
    }

    res.json({ 
      userName: `${user.firstName} ${user.lastName}`.trim() || user.username,
      userId: user._id,
      profilePicture: user.profilePicture,
    });
  } catch (error) {
    console.error('Error getting user:', error);
    res.json({ userName: 'Unknown User', profilePicture: null });
  }
});

/**
 * @route   GET /api/video-call/channel/:channelName
 * @desc    Get participant info for a specific channel
 * @access  Private
 */
router.get('/channel/:channelName', auth, async (req, res) => {
  try {
    const { channelName } = req.params;
    
    if (!activeCalls.has(channelName)) {
      return res.json({ participants: [] });
    }
    
    const participants = activeCalls.get(channelName);
    const participantList = [];
    
    for (const [userId, participant] of participants.entries()) {
      const user = await User.findById(userId).select('firstName lastName profilePicture');
      if (user) {
        participantList.push({
          uid: participant.uid,
          userId: userId,
          userName: `${user.firstName} ${user.lastName}`.trim(),
          profilePicture: user.profilePicture,
          joinedAt: participant.joinedAt,
        });
      }
    }
    
    res.json({ participants: participantList });
  } catch (error) {
    console.error('Error getting channel participants:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

/**
 * @route   GET /api/video-call/participants/:courseId
 * @desc    Get active participants in a course call
 * @access  Private
 */
router.get('/participants/:courseId', auth, async (req, res) => {
  try {
    const { courseId } = req.params;
    const channelName = `course_${courseId}`;

    let participants = [];
    if (activeCalls.has(channelName)) {
      participants = Array.from(activeCalls.get(channelName).values());
    }

    res.json({ 
      channelName,
      count: participants.length,
      participants,
    });
  } catch (error) {
    console.error('Error getting participants:', error);
    res.status(500).json({ 
      message: 'Server error',
      error: error.message 
    });
  }
});

module.exports = router;

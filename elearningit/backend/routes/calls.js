// routes/calls.js
const express = require('express');
const router = express.Router();
const Call = require('../models/Call');
const auth = require('../middleware/auth');
const { getIO, getUserSockets } = require('../utils/webrtcSignaling');

// Initiate a call
router.post('/initiate', auth, async (req, res) => {
  try {
    const { calleeId, type } = req.body;
    const callerId = req.user.userId;

    if (!calleeId || !type) {
      return res.status(400).json({ message: 'Callee ID and type are required' });
    }

    if (callerId === calleeId) {
      return res.status(400).json({ message: 'Cannot call yourself' });
    }

    // First, clean up stale calls (older than 20 seconds in initiated/ringing state)
    const twentySecondsAgo = new Date(Date.now() - 20 * 1000);
    await Call.updateMany(
      {
        $or: [
          { caller: callerId },
          { callee: callerId }
        ],
        status: { $in: ['initiated', 'ringing'] },
        createdAt: { $lt: twentySecondsAgo }
      },
      { status: 'missed', endedAt: new Date() }
    );

    // Now check for active calls
    const activeCall = await Call.findOne({
      $or: [
        { caller: callerId },
        { callee: callerId }
      ],
      status: { $in: ['initiated', 'ringing', 'accepted'] }
    });

    if (activeCall) {
      return res.status(409).json({ message: 'Already in a call' });
    }

    // Create new call
    const call = new Call({
      caller: callerId,
      callee: calleeId,
      type,
      status: 'initiated'
    });

    await call.save();
    await call.populate('caller', 'firstName lastName username profilePicture');
    await call.populate('callee', 'firstName lastName username profilePicture');

    // Emit socket event to notify the callee
    const io = getIO();
    const userSockets = getUserSockets();
    
    // DEBUG: Enhanced logging
    console.log('🔍 ==== CALL INITIATION DEBUG ====');
    console.log('🔍 Caller ID:', callerId);
    console.log('🔍 Callee ID:', calleeId);
    console.log('🔍 Call Type:', type);
    console.log('🔍 Looking up socketId for callee...');
    
    const calleeSocketId = userSockets.get(calleeId);
    console.log('🔍 Callee socketId found:', calleeSocketId || 'NULL');
    console.log('🔍 Total registered sockets:', userSockets.size);
    console.log('🔍 All registered user IDs:', Array.from(userSockets.keys()));
    
    if (calleeSocketId && io) {
      const callerFullName = `${call.caller.firstName || ''} ${call.caller.lastName || ''}`.trim();
      const calleeFullName = `${call.callee.firstName || ''} ${call.callee.lastName || ''}`.trim();
      
      const eventData = {
        callId: call._id.toString(),
        callerId: callerId,
        callerName: callerFullName,
        caller: call.caller,
        type: type,
        channelName: `call_${[callerId, calleeId].sort().join('_')}`
      };
      
      console.log('� Emitting incoming_call event to socket:', calleeSocketId);
      console.log('📤 Event data:', JSON.stringify(eventData, null, 2));
      
      io.to(calleeSocketId).emit('incoming_call', eventData);
      
      console.log(`📞 ✅ Call initiated: ${callerFullName} -> ${calleeFullName}`);
    } else {
      console.log(`⚠️ ❌ Callee ${calleeId} is offline or socket not found`);
      console.log(`⚠️ IO instance exists:`, !!io);
      console.log(`⚠️ Socket ID exists:`, !!calleeSocketId);
    }
    console.log('🔍 ==== END CALL INITIATION DEBUG ====');

    res.status(201).json({
      message: 'Call initiated',
      call
    });
  } catch (error) {
    console.error('Error initiating call:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Update call status
router.patch('/:id/status', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const userId = req.user.userId;

    const call = await Call.findById(id);
    if (!call) {
      return res.status(404).json({ message: 'Call not found' });
    }

    // Verify user is part of the call
    if (call.caller.toString() !== userId && call.callee.toString() !== userId) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    // Update status
    call.status = status;

    if (status === 'accepted' && !call.startedAt) {
      call.startedAt = new Date();
    }

    if (status === 'ended' || status === 'rejected') {
      call.endedAt = new Date();
      
      // If call was rejected, create a message record
      if (status === 'rejected') {
        const Message = require('../models/Message');
        const messageType = call.type === 'video' ? 'video_call' : 'audio_call';
        
        const callMessage = new Message({
          senderId: call.caller,
          receiverId: call.callee,
          content: 'Declined',
          messageType: messageType,
          callDuration: 0,
          callStatus: 'rejected',
          isRead: false
        });

        await callMessage.save();
        await callMessage.populate('senderId', 'firstName lastName username profilePicture');
        await callMessage.populate('receiverId', 'firstName lastName username profilePicture');

        // Emit socket event to both users
        const { getIO, getUserSockets } = require('../utils/webrtcSignaling');
        const io = getIO();
        const userSockets = getUserSockets();

        const callerSocketId = userSockets.get(call.caller.toString());
        const calleeSocketId = userSockets.get(call.callee.toString());

        if (io) {
          if (callerSocketId) {
            io.to(callerSocketId).emit('new_message', callMessage);
          }
          if (calleeSocketId) {
            io.to(calleeSocketId).emit('new_message', callMessage);
          }
        }
        
        console.log('📞 Call rejected message created and sent');
      }
    }

    await call.save();
    await call.populate('caller', 'firstName lastName username profilePicture');
    await call.populate('callee', 'firstName lastName username profilePicture');

    res.json({
      message: 'Call status updated',
      call
    });
  } catch (error) {
    console.error('Error updating call status:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// End a call
router.post('/:id/end', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const { duration } = req.body; // Duration in seconds
    const userId = req.user.userId;

    const call = await Call.findById(id);
    if (!call) {
      return res.status(404).json({ message: 'Call not found' });
    }

    // Verify user is part of the call
    if (call.caller.toString() !== userId && call.callee.toString() !== userId) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    call.status = 'ended';
    call.endedAt = new Date();

    await call.save();
    await call.populate('caller', 'firstName lastName username profilePicture');
    await call.populate('callee', 'firstName lastName username profilePicture');

    // Save call history as a message
    const Message = require('../models/Message');
    
    // Determine call status
    let callStatus = 'completed';
    if (duration && duration > 0) {
      callStatus = 'completed';
    } else if (call.status === 'rejected') {
      callStatus = 'rejected';
    } else if (call.status === 'missed') {
      callStatus = 'missed';
    } else {
      callStatus = 'no_answer';
    }

    // Format duration for display
    let durationText = '';
    if (duration && duration > 0) {
      const minutes = Math.floor(duration / 60);
      const seconds = duration % 60;
      durationText = minutes > 0 
        ? `${minutes} min${minutes > 1 ? 's' : ''}`
        : `${seconds} sec${seconds > 1 ? 's' : ''}`;
    } else {
      durationText = callStatus === 'rejected' ? 'Declined' : 
                     callStatus === 'missed' ? 'Missed call' : 'No answer';
    }

    const messageType = call.type === 'video' ? 'video_call' : 'audio_call';
    const callMessage = new Message({
      senderId: call.caller,
      receiverId: call.callee,
      content: durationText,
      messageType: messageType,
      callDuration: duration || 0,
      callStatus: callStatus,
      isRead: false
    });

    await callMessage.save();
    await callMessage.populate('senderId', 'firstName lastName username profilePicture');
    await callMessage.populate('receiverId', 'firstName lastName username profilePicture');

    // Emit socket event to both users
    const { getIO, getUserSockets } = require('../utils/webrtcSignaling');
    const io = getIO();
    const userSockets = getUserSockets();

    const callerSocketId = userSockets.get(call.caller._id.toString());
    const calleeSocketId = userSockets.get(call.callee._id.toString());

    if (io) {
      if (callerSocketId) {
        io.to(callerSocketId).emit('new_message', callMessage);
      }
      if (calleeSocketId) {
        io.to(calleeSocketId).emit('new_message', callMessage);
      }
    }

    res.json({
      message: 'Call ended',
      call
    });
  } catch (error) {
    console.error('Error ending call:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get call history
router.get('/history', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    const limit = parseInt(req.query.limit) || 50;

    const calls = await Call.getHistory(userId, limit);

    res.json({
      calls,
      count: calls.length
    });
  } catch (error) {
    console.error('Error fetching call history:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get active calls
router.get('/active', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    const calls = await Call.getActiveCalls(userId);

    res.json({
      calls,
      count: calls.length
    });
  } catch (error) {
    console.error('Error fetching active calls:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Cleanup stale calls (useful for debugging)
router.post('/cleanup', auth, async (req, res) => {
  try {
    const userId = req.user.userId;
    
    // Clean up all stale calls for this user
    const result = await Call.updateMany(
      {
        $or: [
          { caller: userId },
          { callee: userId }
        ],
        status: { $in: ['initiated', 'ringing'] }
      },
      { status: 'missed', endedAt: new Date() }
    );

    res.json({
      message: 'Stale calls cleaned up',
      updated: result.modifiedCount
    });
  } catch (error) {
    console.error('Error cleaning up calls:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Toggle screen sharing
router.patch('/:id/screen-share', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const { isScreenSharing } = req.body;
    const userId = req.user.userId;

    const call = await Call.findById(id);
    if (!call) {
      return res.status(404).json({ message: 'Call not found' });
    }

    // Verify user is part of the call
    if (call.caller.toString() !== userId && call.callee.toString() !== userId) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    call.isScreenSharing = isScreenSharing;
    if (isScreenSharing) {
      call.screenShareStartedAt = new Date();
    }

    await call.save();

    res.json({
      message: 'Screen sharing updated',
      call
    });
  } catch (error) {
    console.error('Error updating screen sharing:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;

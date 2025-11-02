// routes/calls.js
const express = require('express');
const router = express.Router();
const Call = require('../models/Call');
const auth = require('../middleware/auth');

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

    // Check if user is already in a call
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

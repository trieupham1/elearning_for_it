const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Course = require('../models/Course');
const auth = require('../middleware/auth');

// Get all users (admin only)
router.get('/', auth, async (req, res) => {
  try {
    if (req.userRole !== 'admin') {
      return res.status(403).json({ message: 'Access denied' });
    }

    const users = await User.find().select('-password');
    res.json(users);
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get user by ID
router.get('/:id', auth, async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json(user);
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get student's courses
router.get('/:id/courses', auth, async (req, res) => {
  try {
    const courses = await Course.find({ students: req.params.id })
      .populate('instructor', 'username email firstName lastName')
      .populate('semester', 'name year');
    
    res.json({ courses });
  } catch (error) {
    console.error('Get student courses error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get instructor's taught courses
router.get('/:id/taught-courses', auth, async (req, res) => {
  try {
    const courses = await Course.find({ instructor: req.params.id })
      .populate('instructor', 'username email firstName lastName')
      .populate('semester', 'name year');
    
    res.json({ courses });
  } catch (error) {
    console.error('Get taught courses error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Update user (admin or self)
router.put('/:id', auth, async (req, res) => {
  try {
    if (req.userId !== req.params.id && req.userRole !== 'admin') {
      return res.status(403).json({ message: 'Access denied' });
    }

    const { password, ...updateData } = req.body;
    
    const user = await User.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Delete user (admin only)
router.delete('/:id', auth, async (req, res) => {
  try {
    if (req.userRole !== 'admin') {
      return res.status(403).json({ message: 'Access denied' });
    }

    const user = await User.findByIdAndDelete(req.params.id);
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
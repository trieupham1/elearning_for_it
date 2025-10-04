const express = require('express');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const Group = require('../models/Group');
const Course = require('../models/Course');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// Get user's enrolled courses (for students)
router.get('/:id/courses', authMiddleware, async (req, res) => {
  try {
    const userId = req.params.id;
    
    // Find groups where user is enrolled
    const groups = await Group.find({ studentIds: userId })
      .populate({
        path: 'courseId',
        populate: {
          path: 'semesterId instructorId',
          select: 'name year term fullName email'
        }
      });
    
    // Extract unique courses
    const courses = groups.map(g => g.courseId).filter(Boolean);
    const uniqueCourses = courses.filter((course, index, self) => 
      index === self.findIndex(c => c._id.toString() === course._id.toString())
    );
    
    res.json(uniqueCourses);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get instructor's taught courses
router.get('/:id/taught-courses', authMiddleware, async (req, res) => {
  try {
    const instructorId = req.params.id;
    
    const courses = await Course.find({ instructorId })
      .populate('semesterId', 'name year term');
    
    res.json(courses);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Update user profile
router.put('/profile', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { fullName, email, avatar } = req.body;
    
    const user = await User.findByIdAndUpdate(
      userId,
      { fullName, email, avatar },
      { new: true }
    ).select('-password');
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json(user);
  } catch (error) {
    res.status(400).json({ message: 'Error updating profile', error: error.message });
  }
});

module.exports = router;
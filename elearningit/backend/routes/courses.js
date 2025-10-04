const express = require('express');
const Course = require('../models/Course');
const Group = require('../models/Group');
const { authMiddleware, instructorOnly } = require('../middleware/auth');

const router = express.Router();

// Get courses by semester
router.get('/', authMiddleware, async (req, res) => {
  try {
    const { semesterId } = req.query;
    
    let query = {};
    if (semesterId) {
      query.semesterId = semesterId;
    }
    
    if (req.user.role === 'student') {
      // Get courses where student is enrolled
      const groups = await Group.find({ studentIds: req.user.userId });
      const courseIds = groups.map(g => g.courseId);
      query._id = { $in: courseIds };
    }
    // Admin can see all courses
    
    const courses = await Course.find(query)
      .populate('semesterId')
      .populate('instructorId', 'fullName email'); // Keep field name for backward compatibility
    
    // Add group and student counts
    const coursesWithStats = await Promise.all(courses.map(async (course) => {
      const groups = await Group.find({ courseId: course._id });
      const studentCount = groups.reduce((sum, g) => sum + g.studentIds.length, 0);
      
      return {
        ...course.toObject(),
        groupCount: groups.length,
        studentCount
      };
    }));
    
    res.json(coursesWithStats);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get single course
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const course = await Course.findById(req.params.id)
      .populate('semesterId')
      .populate('instructorId', 'fullName email');
    
    if (!course) {
      return res.status(404).json({ message: 'Course not found' });
    }
    
    res.json(course);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Create course
router.post('/', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const course = new Course({
      ...req.body,
      instructorId: req.user.userId
    });
    await course.save();
    res.status(201).json(course);
  } catch (error) {
    res.status(400).json({ message: 'Error creating course', error: error.message });
  }
});

// Update course
router.put('/:id', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const course = await Course.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );
    
    if (!course) {
      return res.status(404).json({ message: 'Course not found' });
    }
    
    res.json(course);
  } catch (error) {
    res.status(400).json({ message: 'Error updating course', error: error.message });
  }
});

// Delete course
router.delete('/:id', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const course = await Course.findByIdAndDelete(req.params.id);
    
    if (!course) {
      return res.status(404).json({ message: 'Course not found' });
    }
    
    res.json({ message: 'Course deleted successfully' });
  } catch (error) {
    res.status(400).json({ message: 'Error deleting course', error: error.message });
  }
});

module.exports = router;
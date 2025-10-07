const express = require('express');
const router = express.Router();
const Course = require('../models/Course');
const auth = require('../middleware/auth');

// Get all courses
router.get('/', auth, async (req, res) => {
  try {
    const { semesterId } = req.query;
    const query = semesterId ? { semester: semesterId } : {};
    
    const courses = await Course.find(query)
      .populate({
        path: 'instructor',
        select: 'username email firstName lastName',
        strictPopulate: false
      })
      .populate({
        path: 'semester',
        select: 'name year',
        strictPopulate: false
      });
    
    res.json(courses);
  } catch (error) {
    console.error('Get courses error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get single course
router.get('/:id', auth, async (req, res) => {
  try {
    const course = await Course.findById(req.params.id)
      .populate({
        path: 'instructor',
        select: 'username email firstName lastName',
        strictPopulate: false
      })
      .populate({
        path: 'semester',
        select: 'name year',
        strictPopulate: false
      })
      .populate({
        path: 'students',
        select: 'username email firstName lastName studentId',
        strictPopulate: false
      });
    
    if (!course) {
      return res.status(404).json({ message: 'Course not found' });
    }
    
    res.json(course);
  } catch (error) {
    console.error('Get course error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Create course (instructor only)
router.post('/', auth, async (req, res) => {
  try {
    if (req.userRole !== 'instructor' && req.userRole !== 'admin') {
      return res.status(403).json({ message: 'Only instructors can create courses' });
    }

    const course = await Course.create({
      ...req.body,
      instructor: req.userId
    });

    const populatedCourse = await Course.findById(course._id)
      .populate({
        path: 'instructor',
        select: 'username email firstName lastName',
        strictPopulate: false
      })
      .populate({
        path: 'semester',
        select: 'name year',
        strictPopulate: false
      });

    res.status(201).json(populatedCourse);
  } catch (error) {
    console.error('Create course error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Update course
router.put('/:id', auth, async (req, res) => {
  try {
    const course = await Course.findById(req.params.id);
    
    if (!course) {
      return res.status(404).json({ message: 'Course not found' });
    }

    if (course.instructor.toString() !== req.userId && req.userRole !== 'admin') {
      return res.status(403).json({ message: 'Not authorized to update this course' });
    }

    const updatedCourse = await Course.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    )
      .populate({
        path: 'instructor',
        select: 'username email firstName lastName',
        strictPopulate: false
      })
      .populate({
        path: 'semester',
        select: 'name year',
        strictPopulate: false
      });

    res.json(updatedCourse);
  } catch (error) {
    console.error('Update course error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Delete course
router.delete('/:id', auth, async (req, res) => {
  try {
    const course = await Course.findById(req.params.id);
    
    if (!course) {
      return res.status(404).json({ message: 'Course not found' });
    }

    if (course.instructor.toString() !== req.userId && req.userRole !== 'admin') {
      return res.status(403).json({ message: 'Not authorized to delete this course' });
    }

    await Course.findByIdAndDelete(req.params.id);
    res.json({ message: 'Course deleted successfully' });
  } catch (error) {
    console.error('Delete course error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Enroll student in course
router.post('/:id/enroll', auth, async (req, res) => {
  try {
    const course = await Course.findById(req.params.id);
    
    if (!course) {
      return res.status(404).json({ message: 'Course not found' });
    }

    const studentId = req.body.studentId || req.userId;

    if (course.students.includes(studentId)) {
      return res.status(400).json({ message: 'Student already enrolled' });
    }

    course.students.push(studentId);
    await course.save();

    const updatedCourse = await Course.findById(course._id)
      .populate({
        path: 'instructor',
        select: 'username email firstName lastName',
        strictPopulate: false
      })
      .populate({
        path: 'students',
        select: 'username email firstName lastName studentId',
        strictPopulate: false
      });

    res.json(updatedCourse);
  } catch (error) {
    console.error('Enroll student error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Unenroll student from course
router.post('/:id/unenroll', auth, async (req, res) => {
  try {
    const course = await Course.findById(req.params.id);
    
    if (!course) {
      return res.status(404).json({ message: 'Course not found' });
    }

    const studentId = req.body.studentId || req.userId;

    course.students = course.students.filter(
      id => id.toString() !== studentId
    );
    await course.save();

    const updatedCourse = await Course.findById(course._id)
      .populate({
        path: 'instructor',
        select: 'username email firstName lastName',
        strictPopulate: false
      })
      .populate({
        path: 'students',
        select: 'username email firstName lastName studentId',
        strictPopulate: false
      });

    res.json(updatedCourse);
  } catch (error) {
    console.error('Unenroll student error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get courses for a specific instructor
router.get('/instructor/:instructorId', auth, async (req, res) => {
  try {
    const courses = await Course.find({ instructor: req.params.instructorId })
      .populate({
        path: 'instructor',
        select: 'username email firstName lastName',
        strictPopulate: false
      })
      .populate({
        path: 'semester',
        select: 'name year',
        strictPopulate: false
      });
    
    res.json(courses);
  } catch (error) {
    console.error('Get instructor courses error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
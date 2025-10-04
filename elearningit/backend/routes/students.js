const express = require('express');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const { authMiddleware, instructorOnly } = require('../middleware/auth');

const router = express.Router();

// Get all students
router.get('/', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const students = await User.find({ role: 'student' })
      .select('-password');
    res.json(students);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get single student
router.get('/:id', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const student = await User.findById(req.params.id)
      .select('-password');
    
    if (!student || student.role !== 'student') {
      return res.status(404).json({ message: 'Student not found' });
    }
    
    res.json(student);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Create student
router.post('/', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const { username, password, fullName, email, studentId } = req.body;
    
    // Check if student exists
    const existing = await User.findOne({ $or: [{ username }, { email }] });
    if (existing) {
      return res.status(400).json({ message: 'Student already exists' });
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    
    const student = new User({
      username,
      password: hashedPassword,
      fullName,
      email,
      studentId,
      role: 'student'
    });
    
    await student.save();
    res.status(201).json({ ...student.toObject(), password: undefined });
  } catch (error) {
    res.status(400).json({ message: 'Error creating student', error: error.message });
  }
});

// Update student
router.put('/:id', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const updateData = { ...req.body };
    
    // If password is being updated, hash it
    if (updateData.password) {
      updateData.password = await bcrypt.hash(updateData.password, 10);
    }
    
    const student = await User.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true }
    ).select('-password');
    
    if (!student || student.role !== 'student') {
      return res.status(404).json({ message: 'Student not found' });
    }
    
    res.json(student);
  } catch (error) {
    res.status(400).json({ message: 'Error updating student', error: error.message });
  }
});

// Bulk import students
router.post('/import', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const { students } = req.body;
    
    const results = {
      success: [],
      skipped: [],
      errors: []
    };
    
    for (const studentData of students) {
      const existing = await User.findOne({ 
        $or: [{ username: studentData.username }, { email: studentData.email }] 
      });
      
      if (existing) {
        results.skipped.push(studentData.username);
      } else {
        try {
          const hashedPassword = await bcrypt.hash(studentData.password, 10);
          const student = new User({
            ...studentData,
            password: hashedPassword,
            role: 'student'
          });
          await student.save();
          results.success.push(studentData.username);
        } catch (error) {
          results.errors.push({ username: studentData.username, error: error.message });
        }
      }
    }
    
    res.json(results);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Delete student
router.delete('/:id', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const student = await User.findById(req.params.id);
    
    if (!student || student.role !== 'student') {
      return res.status(404).json({ message: 'Student not found' });
    }
    
    await User.findByIdAndDelete(req.params.id);
    res.json({ message: 'Student deleted successfully' });
  } catch (error) {
    res.status(400).json({ message: 'Error deleting student', error: error.message });
  }
});

module.exports = router;
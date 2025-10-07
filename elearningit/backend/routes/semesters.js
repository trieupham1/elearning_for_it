const express = require('express');
const router = express.Router();
const Semester = require('../models/Semester');
const auth = require('../middleware/auth');

// Get all semesters
router.get('/', auth, async (req, res) => {
  try {
    const semesters = await Semester.find().sort({ year: -1, name: -1 });
    res.json(semesters);
  } catch (error) {
    console.error('Get semesters error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Get single semester
router.get('/:id', auth, async (req, res) => {
  try {
    const semester = await Semester.findById(req.params.id);
    
    if (!semester) {
      return res.status(404).json({ message: 'Semester not found' });
    }
    
    res.json(semester);
  } catch (error) {
    console.error('Get semester error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Create semester (admin only)
router.post('/', auth, async (req, res) => {
  try {
    if (req.userRole !== 'admin') {
      return res.status(403).json({ message: 'Only admins can create semesters' });
    }

    const semester = await Semester.create(req.body);
    res.status(201).json(semester);
  } catch (error) {
    console.error('Create semester error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Update semester (admin only)
router.put('/:id', auth, async (req, res) => {
  try {
    if (req.userRole !== 'admin') {
      return res.status(403).json({ message: 'Only admins can update semesters' });
    }

    const semester = await Semester.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    if (!semester) {
      return res.status(404).json({ message: 'Semester not found' });
    }

    res.json(semester);
  } catch (error) {
    console.error('Update semester error:', error);
    res.status(500).json({ message: error.message });
  }
});

// Delete semester (admin only)
router.delete('/:id', auth, async (req, res) => {
  try {
    if (req.userRole !== 'admin') {
      return res.status(403).json({ message: 'Only admins can delete semesters' });
    }

    const semester = await Semester.findByIdAndDelete(req.params.id);
    
    if (!semester) {
      return res.status(404).json({ message: 'Semester not found' });
    }

    res.json({ message: 'Semester deleted successfully' });
  } catch (error) {
    console.error('Delete semester error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
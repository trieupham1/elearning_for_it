const express = require('express');
const Semester = require('../models/Semester');
const { authMiddleware, instructorOnly } = require('../middleware/auth');

const router = express.Router();

// Get all semesters
router.get('/', authMiddleware, async (req, res) => {
  try {
    const semesters = await Semester.find().sort({ createdAt: -1 });
    res.json(semesters);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get current semester
router.get('/current', authMiddleware, async (req, res) => {
  try {
    const semester = await Semester.findOne({ isCurrent: true });
    res.json(semester);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Create semester (Instructor only)
router.post('/', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const semester = new Semester(req.body);
    await semester.save();
    res.status(201).json(semester);
  } catch (error) {
    res.status(400).json({ message: 'Error creating semester', error: error.message });
  }
});

// Bulk import semesters from CSV
router.post('/import', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const { semesters } = req.body; // Array of semester objects
    
    const results = {
      success: [],
      skipped: [],
      errors: []
    };
    
    for (const semesterData of semesters) {
      const existing = await Semester.findOne({ code: semesterData.code });
      if (existing) {
        results.skipped.push(semesterData.code);
      } else {
        try {
          const semester = new Semester(semesterData);
          await semester.save();
          results.success.push(semesterData.code);
        } catch (error) {
          results.errors.push({ code: semesterData.code, error: error.message });
        }
      }
    }
    
    res.json(results);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;
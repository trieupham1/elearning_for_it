const express = require('express');
const Assignment = require('../models/Assignment');
const Quiz = require('../models/Quiz');
const Material = require('../models/Material');
const { authMiddleware, instructorOnly } = require('../middleware/auth');
const { notifyNewAssignment, notifyNewQuiz, notifyNewMaterial } = require('../utils/notificationHelper');

const router = express.Router();

// Get all classwork for a course (unified endpoint)
router.get('/course/:courseId', authMiddleware, async (req, res) => {
  try {
    const { courseId } = req.params;
    const { search, filter } = req.query; // filter can be: 'assignments', 'quizzes', 'materials'
    
    let classwork = [];
    
    // Fetch based on filter
    if (!filter || filter === 'assignments') {
      const assignments = await Assignment.find({ courseId })
        .sort({ deadline: -1 })
        .lean();
      classwork = [...classwork, ...assignments.map(a => ({ ...a, type: 'assignment' }))];
    }
    
    if (!filter || filter === 'quizzes') {
      const quizzes = await Quiz.find({ courseId })
        .sort({ closeDate: -1 })
        .lean();
      classwork = [...classwork, ...quizzes.map(q => ({ ...q, type: 'quiz' }))];
    }
    
    if (!filter || filter === 'materials') {
      const materials = await Material.find({ courseId })
        .sort({ createdAt: -1 })
        .lean();
      classwork = [...classwork, ...materials.map(m => ({ ...m, type: 'material' }))];
    }
    
    // Apply search filter
    if (search) {
      const searchLower = search.toLowerCase();
      classwork = classwork.filter(item => 
        item.title.toLowerCase().includes(searchLower) ||
        (item.description && item.description.toLowerCase().includes(searchLower))
      );
    }
    
    // Sort by date (most recent first)
    classwork.sort((a, b) => {
      const dateA = a.deadline || a.closeDate || a.createdAt;
      const dateB = b.deadline || b.closeDate || b.createdAt;
      return new Date(dateB) - new Date(dateA);
    });
    
    res.json(classwork);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Create assignment
router.post('/assignments', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const assignment = new Assignment(req.body);
    await assignment.save();
    
    // Send notifications to students
    await notifyNewAssignment(
      assignment.courseId,
      assignment._id,
      assignment.title,
      assignment.deadline
    );
    
    res.status(201).json(assignment);
  } catch (error) {
    res.status(400).json({ message: 'Error creating assignment', error: error.message });
  }
});

// Create quiz
router.post('/quizzes', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const quiz = new Quiz(req.body);
    await quiz.save();
    
    // Send notifications to students
    await notifyNewQuiz(
      quiz.courseId,
      quiz._id,
      quiz.title,
      quiz.closeDate
    );
    
    res.status(201).json(quiz);
  } catch (error) {
    res.status(400).json({ message: 'Error creating quiz', error: error.message });
  }
});

// Create material
router.post('/materials', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const material = new Material(req.body);
    await material.save();
    
    // Send notifications to students
    await notifyNewMaterial(
      material.courseId,
      material._id,
      material.title
    );
    
    res.status(201).json(material);
  } catch (error) {
    res.status(400).json({ message: 'Error creating material', error: error.message });
  }
});

// Get single assignment
router.get('/assignments/:id', authMiddleware, async (req, res) => {
  try {
    const assignment = await Assignment.findById(req.params.id);
    if (!assignment) {
      return res.status(404).json({ message: 'Assignment not found' });
    }
    res.json(assignment);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get single quiz
router.get('/quizzes/:id', authMiddleware, async (req, res) => {
  try {
    const quiz = await Quiz.findById(req.params.id);
    if (!quiz) {
      return res.status(404).json({ message: 'Quiz not found' });
    }
    res.json(quiz);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get single material
router.get('/materials/:id', authMiddleware, async (req, res) => {
  try {
    const material = await Material.findById(req.params.id);
    if (!material) {
      return res.status(404).json({ message: 'Material not found' });
    }
    res.json(material);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Update assignment
router.put('/assignments/:id', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const assignment = await Assignment.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );
    if (!assignment) {
      return res.status(404).json({ message: 'Assignment not found' });
    }
    res.json(assignment);
  } catch (error) {
    res.status(400).json({ message: 'Error updating assignment', error: error.message });
  }
});

// Delete assignment
router.delete('/assignments/:id', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const assignment = await Assignment.findByIdAndDelete(req.params.id);
    if (!assignment) {
      return res.status(404).json({ message: 'Assignment not found' });
    }
    res.json({ message: 'Assignment deleted successfully' });
  } catch (error) {
    res.status(400).json({ message: 'Error deleting assignment', error: error.message });
  }
});

module.exports = router;

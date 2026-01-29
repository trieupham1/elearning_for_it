const express = require('express');
const Assignment = require('../models/Assignment');
const Quiz = require('../models/Quiz');
const Material = require('../models/Material');
const QuizAttempt = require('../models/QuizAttempt');
const Course = require('../models/Course');
const Video = require('../models/Video');
const AttendanceSession = require('../models/AttendanceSession');
const CodeSubmission = require('../models/CodeSubmission');
const User = require('../models/User');
const Group = require('../models/Group');
const { authMiddleware, instructorOnly } = require('../middleware/auth');
const { notifyNewAssignment, notifyNewQuiz, notifyNewMaterial } = require('../utils/notificationHelper');

const router = express.Router();

// Get all classwork for a course (unified endpoint)
router.get('/course/:courseId', authMiddleware, async (req, res) => {
  try {
    const { courseId } = req.params;
    const { search, filter } = req.query; // filter: 'assignments', 'quizzes', 'materials', 'videos', 'attendance', 'code_assignments'
    
    console.log(`📚 Classwork request - courseId: ${courseId}, filter: ${filter || 'ALL'}, search: ${search || 'none'}`);
    
    let classwork = [];
    
    // Get user and their group for filtering
    const user = await User.findById(req.user.userId);
    let studentGroupId = null;
    
    if (user.role === 'student') {
      const groups = await Group.find({ courseId });
      for (const group of groups) {
        if (group.members && group.members.some(memberId => memberId.toString() === req.user.userId)) {
          studentGroupId = group._id;
          break;
        }
      }
      console.log(`📚 Classwork for student ${req.user.userId}, groupId: ${studentGroupId}`);
    }
    
    // Fetch based on filter
    if (!filter || filter === 'assignments') {
      let assignmentQuery = { 
        courseId,
        type: { $ne: 'code' } // Exclude code assignments (they're handled separately)
      };
      
      // Filter by group for students
      if (user.role === 'student') {
        if (studentGroupId) {
          // Student has a group - show assignments for all groups OR their specific group
          assignmentQuery.$or = [
            { groupIds: { $size: 0 } }, // All groups
            { groupIds: studentGroupId } // Student's specific group
          ];
        } else {
          // Student has no group - only show assignments for all groups
          assignmentQuery.groupIds = { $size: 0 };
        }
      }
      
      const assignments = await Assignment.find(assignmentQuery)
        .sort({ deadline: -1 })
        .lean();
      console.log(`  Found ${assignments.length} regular assignments`);
      classwork = [...classwork, ...assignments.map(a => ({ ...a, type: 'assignment' }))];
    }
    
    // NEW: Code Assignments (from Assignment model with type='code')
    if (!filter || filter === 'code_assignments') {
      let codeAssignmentQuery = { 
        courseId,
        type: 'code' // Only get code type assignments
      };
      
      // Filter by group for students
      if (user.role === 'student') {
        if (studentGroupId) {
          // Student has a group - show assignments for all groups OR their specific group
          codeAssignmentQuery.$or = [
            { groupIds: { $size: 0 } }, // All groups
            { groupIds: studentGroupId } // Student's specific group
          ];
        } else {
          // Student has no group - only show assignments for all groups
          codeAssignmentQuery.groupIds = { $size: 0 };
        }
      }
      
      const codeAssignments = await Assignment.find(codeAssignmentQuery)
        .sort({ deadline: -1 })
        .lean();
      console.log(`  Found ${codeAssignments.length} code assignments`);
        
      // For students, check submission status
      let codeAssignmentsWithStatus = codeAssignments.map(c => ({ 
        ...c, 
        type: 'code_assignment',
        dueDate: c.deadline // Add dueDate alias for frontend compatibility
      }));
      
      if (req.user.role === 'student') {
        const assignmentIds = codeAssignments.map(c => c._id);
        const submissions = await CodeSubmission.find({
          assignmentId: { $in: assignmentIds },
          studentId: req.user.userId,
          status: 'completed'
        }).select('assignmentId').lean();
        
        const submittedIds = new Set(submissions.map(s => s.assignmentId.toString()));
        
        codeAssignmentsWithStatus = codeAssignments.map(c => ({
          ...c,
          type: 'code_assignment',
          dueDate: c.deadline, // Add dueDate alias
          isSubmitted: submittedIds.has(c._id.toString())
        }));
      }
      
      classwork = [...classwork, ...codeAssignmentsWithStatus];
    }
    
    if (!filter || filter === 'quizzes') {
      const quizzes = await Quiz.find({ courseId })
        .sort({ closeDate: -1 })
        .lean();
      
      // For students, check if they have completed each quiz
      let quizzesWithStatus = quizzes.map(q => ({ ...q, type: 'quiz' }));
      
      if (req.user.role === 'student') {
        // Get completion status for all quizzes for this student
        const quizIds = quizzes.map(q => q._id);
        const completedAttempts = await QuizAttempt.find({
          quizId: { $in: quizIds },
          studentId: req.user.userId,
          status: { $in: ['completed', 'submitted', 'auto_submitted'] }
        }).select('quizId').lean();
        
        const completedQuizIds = new Set(completedAttempts.map(attempt => attempt.quizId.toString()));
        
        quizzesWithStatus = quizzes.map(q => ({
          ...q,
          type: 'quiz',
          isCompleted: completedQuizIds.has(q._id.toString())
        }));
      }
      
      classwork = [...classwork, ...quizzesWithStatus];
    }
    
    if (!filter || filter === 'materials') {
      const materials = await Material.find({ courseId })
        .sort({ createdAt: -1 })
        .lean();
      classwork = [...classwork, ...materials.map(m => ({ ...m, type: 'material' }))];
    }
    
    // NEW: Videos
    if (!filter || filter === 'videos') {
      let videoQuery = { courseId };
      
      // Students can only see published videos
      if (user.role === 'student') {
        videoQuery.isPublished = true;
      }
      
      const videos = await Video.find(videoQuery)
        .sort({ createdAt: -1 })
        .lean();
      console.log(`  Found ${videos.length} videos (filter: ${filter || 'all'})`);
      classwork = [...classwork, ...videos.map(v => ({ ...v, type: 'video' }))];
    }
    
    // NEW: Attendance Sessions
    if (!filter || filter === 'attendance') {
      const sessions = await AttendanceSession.find({ courseId })
        .sort({ sessionDate: -1 })
        .lean();
      classwork = [...classwork, ...sessions.map(s => ({ ...s, type: 'attendance' }))];
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
      const dateA = a.deadline || a.closeDate || a.sessionDate || a.dueDate || a.uploadedAt || a.createdAt;
      const dateB = b.deadline || b.closeDate || b.sessionDate || b.dueDate || b.uploadedAt || b.createdAt;
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
    
    // Get course and enrolled students for notifications
    try {
      const course = await Course.findById(assignment.courseId);
      if (course && course.students && course.students.length > 0) {
        const studentIds = course.students.map(s => s.toString());
        await notifyNewAssignment(
          assignment.courseId.toString(),
          course.title,
          assignment.title,
          assignment.deadline,
          studentIds
        );
        console.log(`📬 Sent assignment notifications to ${studentIds.length} students`);
      }
    } catch (notifError) {
      console.error('Error sending assignment notifications:', notifError);
      // Don't fail the assignment creation if notification fails
    }
    
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
    
    // Get course and enrolled students for notifications
    try {
      const course = await Course.findById(quiz.courseId);
      if (course && course.students && course.students.length > 0) {
        const studentIds = course.students.map(s => s.toString());
        await notifyNewQuiz(
          quiz.courseId.toString(),
          course.title,
          quiz.title,
          studentIds
        );
        console.log(`📬 Sent quiz notifications to ${studentIds.length} students`);
      }
    } catch (notifError) {
      console.error('Error sending quiz notifications:', notifError);
      // Don't fail the quiz creation if notification fails
    }
    
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
    
    // Get course and enrolled students for notifications
    try {
      const course = await Course.findById(material.courseId);
      if (course && course.students && course.students.length > 0) {
        const studentIds = course.students.map(s => s.toString());
        await notifyNewMaterial(
          material.courseId.toString(),
          course.title,
          material.title,
          studentIds
        );
        console.log(`📬 Sent material notifications to ${studentIds.length} students`);
      }
    } catch (notifError) {
      console.error('Error sending material notifications:', notifError);
      // Don't fail the material creation if notification fails
    }
    
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

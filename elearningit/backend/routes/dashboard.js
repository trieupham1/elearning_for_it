const express = require('express');
const mongoose = require('mongoose');
const Assignment = require('../models/Assignment');
const Submission = require('../models/Submission');
const Quiz = require('../models/Quiz');
const QuizAttempt = require('../models/QuizAttempt');
const Course = require('../models/Course');
const Announcement = require('../models/Announcement');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// Get student dashboard summary
router.get('/student/summary', authMiddleware, async (req, res) => {
  try {
    const studentId = req.user.userId;
    console.log(`📊 Getting dashboard summary for student: ${studentId}`);

    // Get all courses the student is enrolled in
    const courses = await Course.find({ students: studentId })
      .select('_id name code')
      .lean();
    
    const courseIds = courses.map(c => c._id);
    console.log(`📚 Student enrolled in ${courses.length} courses:`);
    courses.forEach(c => console.log(`   - ${c.code}: ${c.name} (ID: ${c._id})`));

    // --- ASSIGNMENT STATISTICS ---
    const allAssignments = await Assignment.find({ courseId: { $in: courseIds } })
      .select('_id deadline')
      .lean();
    
    const assignmentIds = allAssignments.map(a => a._id);
    
    const submissions = await Submission.find({
      assignmentId: { $in: assignmentIds },
      studentId: studentId
    }).lean();

    const submittedAssignmentIds = new Set(submissions.map(s => s.assignmentId.toString()));
    const now = new Date();
    
    let submitted = 0;
    let pending = 0;
    let late = 0;
    let graded = 0;

    allAssignments.forEach(assignment => {
      const hasSubmission = submittedAssignmentIds.has(assignment._id.toString());
      const isPastDeadline = assignment.deadline && new Date(assignment.deadline) < now;
      
      if (hasSubmission) {
        submitted++;
        const submission = submissions.find(s => s.assignmentId.toString() === assignment._id.toString());
        if (submission && submission.grade != null) {
          graded++;
        }
      } else {
        if (isPastDeadline) {
          late++;
        } else {
          pending++;
        }
      }
    });

    const assignmentStats = {
      total: allAssignments.length,
      submitted,
      pending,
      late,
      graded
    };

    console.log(`📝 Assignment stats:`, assignmentStats);

    // --- QUIZ STATISTICS ---
    const allQuizzes = await Quiz.find({ courseId: { $in: courseIds } })
      .select('_id title totalPoints')
      .lean();
    
    const quizIds = allQuizzes.map(q => q._id);
    
    const allQuizAttempts = await QuizAttempt.find({
      quizId: { $in: quizIds },
      studentId: studentId,
      status: { $in: ['submitted', 'auto_submitted', 'completed'] }
    })
      .populate('quizId', 'title courseId')
      .sort({ submissionTime: -1 })
      .lean();

    // Group attempts by quizId and keep only the best score for each quiz
    const quizAttemptsMap = new Map();
    allQuizAttempts.forEach(attempt => {
      const quizIdStr = attempt.quizId._id.toString();
      const existing = quizAttemptsMap.get(quizIdStr);
      
      // Keep the attempt with the highest score, or if scores are equal, keep the most recent
      if (!existing || (attempt.score || 0) > (existing.score || 0)) {
        quizAttemptsMap.set(quizIdStr, attempt);
      }
    });

    // Convert map to array and sort by submission time (most recent first)
    const quizAttempts = Array.from(quizAttemptsMap.values())
      .sort((a, b) => {
        const dateA = new Date(a.submissionTime || a.endTime || a.createdAt);
        const dateB = new Date(b.submissionTime || b.endTime || b.createdAt);
        return dateB - dateA;
      });

    console.log(`🎯 Total attempts: ${allQuizAttempts.length}, Best attempts (unique quizzes): ${quizAttempts.length}`);

    // Get unique quizzes completed
    const completedQuizIds = new Set(quizAttempts.map(a => a.quizId._id.toString()));
    const pendingQuizzes = allQuizzes.length - completedQuizIds.size;

    // Calculate average score (using best attempts only)
    const totalScore = quizAttempts.reduce((sum, attempt) => sum + (attempt.score || 0), 0);
    const averageScore = quizAttempts.length > 0 ? totalScore / quizAttempts.length : 0;

    // Get recent quiz scores with course info
    const recentScores = await Promise.all(
      quizAttempts.slice(0, 5).map(async (attempt) => {
        const course = await Course.findById(attempt.quizId.courseId).select('name').lean();
        return {
          quizId: attempt.quizId._id.toString(),
          quizTitle: attempt.quizId.title,
          courseTitle: course?.name || 'Unknown Course',
          score: attempt.pointsEarned || 0,
          maxScore: attempt.totalPoints || 100,
          completedAt: attempt.submissionTime || attempt.endTime || attempt.createdAt
        };
      })
    );

    const quizStats = {
      total: allQuizzes.length,
      completed: completedQuizIds.size,
      pending: pendingQuizzes,
      averageScore: Math.round(averageScore * 10) / 10,
      recentScores
    };

    console.log(`🎯 Quiz stats:`, { ...quizStats, recentScores: `${recentScores.length} scores` });

    // --- UPCOMING DEADLINES ---
    const upcomingDeadlines = [];

    // Get upcoming assignment deadlines with course info
    const upcomingAssignments = await Assignment.find({
      courseId: { $in: courseIds },
      deadline: { $gte: now },
      _id: { $nin: Array.from(submittedAssignmentIds) }
    })
      .populate('courseId', 'name code')
      .sort({ deadline: 1 })
      .limit(10)
      .lean();

    upcomingAssignments.forEach(assignment => {
      // Get course title with fallback to courses array
      let courseTitle = 'Unknown Course';
      if (assignment.courseId && typeof assignment.courseId === 'object') {
        courseTitle = assignment.courseId.name;
        console.log(`✅ Assignment "${assignment.title}" course populated: ${courseTitle}`);
      } else if (assignment.courseId) {
        console.log(`⚠️ Assignment "${assignment.title}" courseId not populated: ${assignment.courseId}`);
        const course = courses.find(c => c._id.toString() === assignment.courseId.toString());
        courseTitle = course?.name || 'Unknown Course';
        console.log(`   Fallback lookup result: ${courseTitle}`);
      }

      upcomingDeadlines.push({
        id: assignment._id.toString(),
        title: assignment.title,
        courseTitle: courseTitle,
        type: 'assignment',
        deadline: assignment.deadline,
        status: 'pending'
      });
    });

    // Get upcoming quiz deadlines with course info
    const upcomingQuizzes = await Quiz.find({
      courseId: { $in: courseIds },
      closeDate: { $gte: now },
      status: 'active'
    })
      .populate('courseId', 'name code')
      .sort({ closeDate: 1 })
      .limit(10)
      .lean();

    // Filter out quizzes already completed
    for (const quiz of upcomingQuizzes) {
      const hasCompleted = quizAttempts.some(a => a.quizId._id.toString() === quiz._id.toString());
      if (!hasCompleted) {
        // Get course title with fallback to courses array
        let courseTitle = 'Unknown Course';
        if (quiz.courseId && typeof quiz.courseId === 'object') {
          courseTitle = quiz.courseId.name;
        } else if (quiz.courseId) {
          const course = courses.find(c => c._id.toString() === quiz.courseId.toString());
          courseTitle = course?.name || 'Unknown Course';
        }

        upcomingDeadlines.push({
          id: quiz._id.toString(),
          title: quiz.title,
          courseTitle: courseTitle,
          type: 'quiz',
          deadline: quiz.closeDate,
          status: 'pending'
        });
      }
    }

    // Sort by deadline
    upcomingDeadlines.sort((a, b) => new Date(a.deadline) - new Date(b.deadline));
    console.log(`⏰ Found ${upcomingDeadlines.length} upcoming deadlines`);

    // --- RECENT ACTIVITY ---
    const recentActivities = [];

    // Get recently graded submissions with course info
    const recentGraded = await Submission.find({
      studentId: studentId,
      grade: { $ne: null },
      gradedAt: { $ne: null }
    })
      .populate({
        path: 'assignmentId',
        select: 'title courseId',
        populate: {
          path: 'courseId',
          select: 'title'
        }
      })
      .sort({ gradedAt: -1 })
      .limit(5)
      .lean();

    for (const submission of recentGraded) {
      if (submission.assignmentId) {
        // Get course title with multiple fallbacks
        let courseTitle = 'Unknown Course';
        if (submission.assignmentId.courseId && typeof submission.assignmentId.courseId === 'object') {
          courseTitle = submission.assignmentId.courseId.name;
        } else if (submission.assignmentId.courseId) {
          const course = courses.find(c => c._id.toString() === submission.assignmentId.courseId.toString());
          courseTitle = course?.name || 'Unknown Course';
        }
        
        recentActivities.push({
          id: submission._id.toString(),
          title: `${submission.assignmentId.title} Graded`,
          type: 'assignment_graded',
          courseTitle: courseTitle,
          message: submission.feedback || 'Assignment has been graded',
          timestamp: submission.gradedAt,
          score: submission.grade
        });
      }
    }

    // Get recently completed quizzes with course info (increased to 5 to match quiz chart)
    for (const attempt of quizAttempts.slice(0, 5)) {
      if (attempt.quizId && attempt.quizId._id) {
        let courseTitle = 'Unknown Course';
        
        // Try to get course title from recentScores first
        const scoreEntry = recentScores.find(s => s.quizId === attempt.quizId._id.toString());
        if (scoreEntry) {
          courseTitle = scoreEntry.courseTitle;
        } else {
          // Fallback: fetch course directly
          try {
            const course = await Course.findById(attempt.quizId.courseId).select('name').lean();
            courseTitle = course?.name || 'Unknown Course';
          } catch (e) {
            console.log('Could not fetch course for quiz:', e);
          }
        }
        
        recentActivities.push({
          id: attempt._id.toString(),
          title: `${attempt.quizId.title} Completed`,
          type: 'quiz_completed',
          courseTitle: courseTitle,
          message: `Score: ${attempt.score}%`,
          timestamp: attempt.submissionTime || attempt.endTime,
          score: attempt.score
        });
      }
    }

    // Get recent announcements with course info
    const recentAnnouncements = await Announcement.find({
      courseId: { $in: courseIds }
    })
      .populate('courseId', 'name code')
      .sort({ createdAt: -1 })
      .limit(3)
      .lean();

    recentAnnouncements.forEach(announcement => {
      const courseTitle = announcement.courseId && typeof announcement.courseId === 'object'
        ? announcement.courseId.name
        : courses.find(c => c._id.toString() === announcement.courseId?.toString())?.name || 'Unknown Course';
      
      recentActivities.push({
        id: announcement._id.toString(),
        title: announcement.title,
        type: 'announcement',
        courseTitle: courseTitle,
        message: 'New announcement posted',
        timestamp: announcement.createdAt
      });
    });

    // Sort by timestamp
    recentActivities.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    console.log(`📢 Found ${recentActivities.length} recent activities`);

    // --- OVERALL PROGRESS ---
    const totalTasks = allAssignments.length + allQuizzes.length;
    const completedTasks = submitted + completedQuizIds.size;
    const overallProgress = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

    // --- BUILD RESPONSE ---
    const dashboardSummary = {
      totalCourses: courses.length,
      assignmentStats,
      quizStats,
      upcomingDeadlines: upcomingDeadlines.slice(0, 10),
      recentActivities: recentActivities.slice(0, 10),
      overallProgress: Math.round(overallProgress * 10) / 10
    };

    console.log(`✅ Dashboard summary prepared with ${overallProgress.toFixed(1)}% progress`);
    res.json(dashboardSummary);

  } catch (error) {
    console.error('❌ Error getting dashboard summary:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get assignment details for dashboard
router.get('/student/assignments', authMiddleware, async (req, res) => {
  try {
    const studentId = req.user.userId;
    const { status } = req.query; // 'pending', 'submitted', 'late', 'graded'

    const courses = await Course.find({ students: studentId }).select('_id').lean();
    const courseIds = courses.map(c => c._id);

    const assignments = await Assignment.find({ courseId: { $in: courseIds } })
      .populate('courseId', 'name code')
      .sort({ deadline: 1 })
      .lean();

    const submissions = await Submission.find({
      studentId: studentId,
      assignmentId: { $in: assignments.map(a => a._id) }
    }).lean();

    const submissionMap = new Map(
      submissions.map(s => [s.assignmentId.toString(), s])
    );

    const now = new Date();
    let result = assignments.map(assignment => {
      const submission = submissionMap.get(assignment._id.toString());
      const isPastDeadline = assignment.deadline && new Date(assignment.deadline) < now;
      
      let assignmentStatus = 'pending';
      if (submission) {
        assignmentStatus = submission.grade != null ? 'graded' : 'submitted';
      } else if (isPastDeadline) {
        assignmentStatus = 'late';
      }

      return {
        ...assignment,
        status: assignmentStatus,
        submission: submission || null
      };
    });

    // Filter by status if requested
    if (status) {
      result = result.filter(a => a.status === status);
    }

    res.json(result);
  } catch (error) {
    console.error('Error getting assignments:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get quiz results for dashboard
router.get('/student/quizzes', authMiddleware, async (req, res) => {
  try {
    const studentId = req.user.userId;

    const courses = await Course.find({ students: studentId }).select('_id').lean();
    const courseIds = courses.map(c => c._id);

    const quizzes = await Quiz.find({ courseId: { $in: courseIds } })
      .populate('courseId', 'name')
      .sort({ closeDate: -1 })
      .lean();

    const attempts = await QuizAttempt.find({
      studentId: studentId,
      quizId: { $in: quizzes.map(q => q._id) },
      status: { $in: ['submitted', 'auto_submitted', 'completed'] }
    }).lean();

    const attemptMap = new Map();
    attempts.forEach(attempt => {
      const quizId = attempt.quizId.toString();
      if (!attemptMap.has(quizId) || attempt.score > attemptMap.get(quizId).score) {
        attemptMap.set(quizId, attempt);
      }
    });

    const result = quizzes.map(quiz => ({
      ...quiz,
      bestAttempt: attemptMap.get(quiz._id.toString()) || null,
      hasCompleted: attemptMap.has(quiz._id.toString())
    }));

    res.json(result);
  } catch (error) {
    console.error('Error getting quizzes:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;


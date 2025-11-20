const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const User = require('../models/User');
const Course = require('../models/Course');
const Assignment = require('../models/Assignment');
const Quiz = require('../models/Quiz');
const QuizAttempt = require('../models/QuizAttempt');
const Department = require('../models/Department');
const ActivityLog = require('../models/ActivityLog');
const AttendanceSession = require('../models/AttendanceSession');
const AttendanceRecord = require('../models/AttendanceRecord');
const Submission = require('../models/Submission');
const { auth, adminOnly } = require('../middleware/auth');

// @route   GET /api/admin/dashboard/overview
// @desc    Get admin dashboard overview metrics
// @access  Admin only
router.get('/overview', auth, adminOnly, async (req, res) => {
  try {
    // Get total counts
    const totalUsers = await User.countDocuments();
    const totalCourses = await Course.countDocuments();
    const totalDepartments = await Department.countDocuments();
    const activeCourses = await Course.countDocuments({
      endDate: { $gte: new Date() }
    });

    // Get user breakdown
    const students = await User.countDocuments({ role: 'student' });
    const instructors = await User.countDocuments({ role: 'instructor' });
    const admins = await User.countDocuments({ role: 'admin' });
    const activeUsers = await User.countDocuments({ isActive: true });

    // Get recent activity
    const recentActivity = await ActivityLog.find()
      .sort({ timestamp: -1 })
      .limit(10)
      .populate('user', 'firstName lastName username email role');

    // Get course enrollments
    const enrollmentStats = await Course.aggregate([
      {
        $project: {
          title: 1,
          studentCount: { $size: '$students' }
        }
      },
      { $sort: { studentCount: -1 } },
      { $limit: 5 }
    ]);

    res.json({
      totalUsers,
      totalCourses,
      totalDepartments,
      activeCourses,
      userBreakdown: {
        students,
        instructors,
        admins,
        activeUsers
      },
      topCoursesByEnrollment: enrollmentStats,
      recentActivity
    });
  } catch (error) {
    console.error('Error fetching dashboard overview:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// @route   GET /api/admin/dashboard/user-growth
// @desc    Get user growth statistics
// @access  Admin only
router.get('/user-growth', auth, adminOnly, async (req, res) => {
  try {
    const { period = 'month' } = req.query; // 'week', 'month', 'year'

    let groupBy;
    let dateRange = new Date();

    switch (period) {
      case 'week':
        dateRange.setDate(dateRange.getDate() - 7);
        groupBy = {
          year: { $year: '$createdAt' },
          month: { $month: '$createdAt' },
          day: { $dayOfMonth: '$createdAt' }
        };
        break;
      case 'month':
        dateRange.setMonth(dateRange.getMonth() - 1);
        groupBy = {
          year: { $year: '$createdAt' },
          month: { $month: '$createdAt' },
          day: { $dayOfMonth: '$createdAt' }
        };
        break;
      case 'year':
        dateRange.setFullYear(dateRange.getFullYear() - 1);
        groupBy = {
          year: { $year: '$createdAt' },
          month: { $month: '$createdAt' }
        };
        break;
      default:
        dateRange.setMonth(dateRange.getMonth() - 1);
        groupBy = {
          year: { $year: '$createdAt' },
          month: { $month: '$createdAt' },
          day: { $dayOfMonth: '$createdAt' }
        };
    }

    const userGrowth = await User.aggregate([
      {
        $match: {
          createdAt: { $gte: dateRange }
        }
      },
      {
        $group: {
          _id: groupBy,
          count: { $sum: 1 },
          roles: {
            $push: '$role'
          }
        }
      },
      { $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 } }
    ]);

    res.json({ period, data: userGrowth });
  } catch (error) {
    console.error('Error fetching user growth:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// @route   GET /api/admin/dashboard/completion-rates
// @desc    Get course completion rates
// @access  Admin only
router.get('/completion-rates', auth, adminOnly, async (req, res) => {
  try {
    // Get completion rates by analyzing quiz attempts and assignments
    const courses = await Course.find()
      .select('title code students')
      .populate('students', 'fullName');

    const completionData = [];

    for (const course of courses) {
      const totalStudents = course.students.length;
      
      if (totalStudents === 0) continue;

      // Get assignments for this course
      const assignments = await Assignment.find({ course: course._id });
      const quizzes = await Quiz.find({ course: course._id });

      // Count students who completed all assignments
      let completedStudents = 0;

      for (const student of course.students) {
        let studentCompleted = true;

        // Check assignments
        for (const assignment of assignments) {
          const submission = assignment.submissions.find(
            sub => sub.studentId.toString() === student._id.toString()
          );
          if (!submission) {
            studentCompleted = false;
            break;
          }
        }

        // Check quizzes if still completed
        if (studentCompleted) {
          for (const quiz of quizzes) {
            const attempt = await QuizAttempt.findOne({
              quiz: quiz._id,
              student: student._id,
              isCompleted: true
            });
            if (!attempt) {
              studentCompleted = false;
              break;
            }
          }
        }

        if (studentCompleted) completedStudents++;
      }

      const completionRate = totalStudents > 0
        ? (completedStudents / totalStudents) * 100
        : 0;

      completionData.push({
        courseId: course._id,
        courseTitle: course.title,
        courseCode: course.code,
        totalStudents,
        completedStudents,
        completionRate: Math.round(completionRate * 100) / 100
      });
    }

    // Sort by completion rate
    completionData.sort((a, b) => b.completionRate - a.completionRate);

    res.json(completionData);
  } catch (error) {
    console.error('Error fetching completion rates:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// @route   GET /api/admin/dashboard/training-progress-by-department
// @desc    Get training progress breakdown by department
// @access  Admin only
router.get('/training-progress-by-department', auth, adminOnly, async (req, res) => {
  try {
    const departments = await Department.find({ isActive: true })
      .populate('courses')
      .populate('employees');

    const departmentProgress = [];

    for (const dept of departments) {
      const deptData = {
        departmentId: dept._id,
        departmentName: dept.name || 'Unknown Department',
        departmentCode: dept.code || dept.name || 'UNKNOWN',
        totalEmployees: dept.employees.length,
        totalCourses: dept.courses.length,
        coursesProgress: []
      };

      // Calculate progress for each course
      for (const course of dept.courses) {
        const fullCourse = await Course.findById(course._id).populate('students');
        
        if (!fullCourse) continue;

        const enrolledDeptEmployees = fullCourse.students.filter(student =>
          dept.employees.some(emp => emp._id.equals(student._id))
        );

        const assignments = await Assignment.find({ course: course._id });
        const quizzes = await Quiz.find({ course: course._id });

        let completedCount = 0;

        // Check completion for department employees
        for (const employee of enrolledDeptEmployees) {
          let hasCompleted = true;

          // Check assignments
          for (const assignment of assignments) {
            const submission = assignment.submissions.find(
              sub => sub.studentId.toString() === employee._id.toString()
            );
            if (!submission) {
              hasCompleted = false;
              break;
            }
          }

          // Check quizzes
          if (hasCompleted) {
            for (const quiz of quizzes) {
              const attempt = await QuizAttempt.findOne({
                quiz: quiz._id,
                student: employee._id,
                isCompleted: true
              });
              if (!attempt) {
                hasCompleted = false;
                break;
              }
            }
          }

          if (hasCompleted) completedCount++;
        }

        deptData.coursesProgress.push({
          courseTitle: fullCourse.title || fullCourse.name || 'Unknown Course',
          courseCode: fullCourse.code || 'N/A',
          enrolledEmployees: enrolledDeptEmployees.length,
          completedEmployees: completedCount,
          completionRate: enrolledDeptEmployees.length > 0
            ? Math.round((completedCount / enrolledDeptEmployees.length) * 100 * 100) / 100
            : 0
        });
      }

      // Calculate overall department completion rate
      const totalEnrollments = deptData.coursesProgress.reduce((sum, cp) => sum + cp.enrolledEmployees, 0);
      const totalCompletions = deptData.coursesProgress.reduce((sum, cp) => sum + cp.completedEmployees, 0);

      deptData.overallCompletionRate = totalEnrollments > 0
        ? Math.round((totalCompletions / totalEnrollments) * 100 * 100) / 100
        : 0;

      departmentProgress.push(deptData);
    }

    res.json(departmentProgress);
  } catch (error) {
    console.error('Error fetching department training progress:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// @route   GET /api/admin/dashboard/top-performers
// @desc    Get top performing students
// @access  Admin only
router.get('/top-performers', auth, adminOnly, async (req, res) => {
  try {
    const { limit = 10 } = req.query;

    // Get all quiz attempts with scores
    const topPerformers = await QuizAttempt.aggregate([
      {
        $match: {
          isCompleted: true,
          score: { $exists: true, $ne: null }
        }
      },
      {
        $group: {
          _id: '$student',
          averageScore: { $avg: '$score' },
          totalQuizzes: { $sum: 1 },
          totalPoints: { $sum: '$score' }
        }
      },
      { $sort: { averageScore: -1 } },
      { $limit: parseInt(limit) }
    ]);

    // Populate student details
    await User.populate(topPerformers, {
      path: '_id',
      select: 'fullName email department profilePicture'
    });

    const formattedPerformers = topPerformers.map(p => ({
      student: p._id,
      averageScore: Math.round(p.averageScore * 100) / 100,
      totalQuizzes: p.totalQuizzes,
      totalPoints: p.totalPoints
    }));

    res.json(formattedPerformers);
  } catch (error) {
    console.error('Error fetching top performers:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// @route   GET /api/admin/dashboard/low-performers
// @desc    Get students who need attention (low scores or incomplete work)
// @access  Admin only
router.get('/low-performers', auth, adminOnly, async (req, res) => {
  try {
    const { threshold = 50, limit = 20 } = req.query;

    const lowPerformers = await QuizAttempt.aggregate([
      {
        $match: {
          isCompleted: true,
          score: { $exists: true, $lte: parseInt(threshold) }
        }
      },
      {
        $group: {
          _id: '$student',
          averageScore: { $avg: '$score' },
          totalQuizzes: { $sum: 1 },
          failedQuizzes: {
            $sum: { $cond: [{ $lte: ['$score', parseInt(threshold)] }, 1, 0] }
          }
        }
      },
      { $sort: { averageScore: 1 } },
      { $limit: parseInt(limit) }
    ]);

    await User.populate(lowPerformers, {
      path: '_id',
      select: 'fullName email department profilePicture'
    });

    const formattedPerformers = lowPerformers.map(p => ({
      student: p._id,
      averageScore: Math.round(p.averageScore * 100) / 100,
      totalQuizzes: p.totalQuizzes,
      failedQuizzes: p.failedQuizzes
    }));

    res.json(formattedPerformers);
  } catch (error) {
    console.error('Error fetching low performers:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// @route   GET /api/admin-dashboard/training-progress/:departmentId/users
// @desc    Get detailed user training progress for a department
// @access  Admin only
router.get('/training-progress/:departmentId/users', auth, adminOnly, async (req, res) => {
  try {
    const { departmentId } = req.params;

    // Find department and populate employees
    const department = await Department.findById(departmentId)
      .populate({
        path: 'employees',
        select: 'fullName email role profilePicture'
      });

    if (!department) {
      return res.status(404).json({ message: 'Department not found' });
    }

    // Process each user in the department
    const usersProgress = await Promise.all(
      department.employees.map(async (user) => {
        // Find all courses the user is enrolled in
        const courses = await Course.find({
          students: user._id
        }).select('_id code name');

        // Process each course for the user
        const coursesProgress = await Promise.all(
          courses.map(async (course) => {
            // Calculate attendance
            const attendanceData = await calculateUserAttendance(course._id, user._id);
            
            // Calculate scores
            const scoresData = await calculateUserScores(course._id, user._id);

            return {
              courseId: course._id,
              courseTitle: course.name,
              courseCode: course.code,
              enrollmentStatus: 'active',
              attendance: attendanceData,
              scores: scoresData
            };
          })
        );

        return {
          userId: user._id,
          fullName: user.fullName,
          email: user.email,
          role: user.role,
          profilePicture: user.profilePicture || null,
          courses: coursesProgress
        };
      })
    );

    res.json({
      departmentId: department._id,
      departmentName: department.name,
      departmentCode: department.code,
      users: usersProgress
    });
  } catch (error) {
    console.error('Error fetching department user progress:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Helper function to calculate attendance for a user in a course
async function calculateUserAttendance(courseId, userId) {
  try {
    // Find all attendance sessions for the course
    const sessions = await mongoose.model('AttendanceSession').find({
      courseId: courseId
    });

    if (sessions.length === 0) {
      return null; // No attendance data
    }

    // Find all attendance records for this user in these sessions
    const sessionIds = sessions.map(s => s._id);
    const records = await mongoose.model('AttendanceRecord').find({
      sessionId: { $in: sessionIds },
      studentId: userId
    });

    // Count attendance statuses
    const attended = records.filter(r => r.status === 'present').length;
    const late = records.filter(r => r.status === 'late').length;
    const absent = sessions.length - attended - late; // Total sessions minus present and late

    const percentage = sessions.length > 0 
      ? ((attended + late) / sessions.length) * 100 
      : 0;

    return {
      totalSessions: sessions.length,
      attended: attended,
      late: late,
      absent: absent,
      percentage: Math.round(percentage * 10) / 10 // Round to 1 decimal
    };
  } catch (error) {
    console.error('Error calculating attendance:', error);
    return null;
  }
}

// Helper function to calculate scores for a user in a course
async function calculateUserScores(courseId, userId) {
  try {
    // Get quiz attempts
    const quizzes = await Quiz.find({ courseId: courseId }).select('_id title maxScore');
    const quizAttempts = await QuizAttempt.find({
      quizId: { $in: quizzes.map(q => q._id) },
      studentId: userId,
      status: 'completed'
    }).populate('quizId', 'title maxScore');

    // Get assignment submissions
    const assignments = await Assignment.find({ courseId: courseId }).select('_id title maxGrade');
    const submissions = await mongoose.model('Submission').find({
      assignmentId: { $in: assignments.map(a => a._id) },
      studentId: userId,
      status: { $in: ['graded', 'returned'] }
    }).populate('assignmentId', 'title maxGrade');

    // Format quizzes
    const quizzesData = quizAttempts.map(attempt => ({
      id: attempt._id,
      title: attempt.quizId?.title || 'Quiz',
      score: attempt.score || 0,
      maxScore: attempt.quizId?.maxScore || 10,
      percentage: attempt.quizId?.maxScore 
        ? (attempt.score / attempt.quizId.maxScore) * 100 
        : 0,
      submittedAt: attempt.completedAt || attempt.createdAt
    }));

    // Format assignments
    const assignmentsData = submissions
      .filter(sub => sub.grade !== null && sub.grade !== undefined)
      .map(sub => ({
        id: sub._id,
        title: sub.assignmentId?.title || 'Assignment',
        score: sub.grade || 0,
        maxScore: sub.assignmentId?.maxGrade || 10,
        percentage: sub.assignmentId?.maxGrade 
          ? (sub.grade / sub.assignmentId.maxGrade) * 100 
          : 0,
        submittedAt: sub.submittedAt
      }));

    const allAssessments = [...quizzesData, ...assignmentsData];

    if (allAssessments.length === 0) {
      return null; // No score data
    }

    // Calculate average score (normalized to /10 scale)
    const totalScore = allAssessments.reduce((sum, assessment) => {
      const normalizedScore = (assessment.score / assessment.maxScore) * 10;
      return sum + normalizedScore;
    }, 0);
    const averageScore = totalScore / allAssessments.length;

    // Calculate score distribution (rounded to nearest integer)
    const scoreDistribution = {};
    for (let i = 0; i <= 10; i++) {
      scoreDistribution[i.toString()] = 0;
    }

    allAssessments.forEach(assessment => {
      const normalizedScore = (assessment.score / assessment.maxScore) * 10;
      const roundedScore = Math.round(normalizedScore);
      scoreDistribution[roundedScore.toString()]++;
    });

    return {
      quizzes: quizzesData,
      assignments: assignmentsData,
      scoreDistribution: scoreDistribution,
      averageScore: Math.round(averageScore * 100) / 100, // Round to 2 decimals
      totalAssessments: allAssessments.length
    };
  } catch (error) {
    console.error('Error calculating scores:', error);
    return null;
  }
}

module.exports = router;

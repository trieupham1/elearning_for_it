const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Course = require('../models/Course');
const Assignment = require('../models/Assignment');
const Submission = require('../models/Submission');
const Quiz = require('../models/Quiz');
const QuizAttempt = require('../models/QuizAttempt');
const Department = require('../models/Department');
const { auth, adminOnly } = require('../middleware/auth');
const ExcelJS = require('exceljs');
const PDFDocument = require('pdfkit');

// @route   POST /api/admin/reports/generate-department-report
// @desc    Generate department training report (Excel/PDF)
// @access  Admin only
router.post('/generate-department-report', auth, adminOnly, async (req, res) => {
  try {
    const { departmentId, format = 'excel' } = req.body; // format: 'excel' or 'pdf'

    if (!departmentId) {
      return res.status(400).json({ message: 'departmentId is required' });
    }

    const department = await Department.findById(departmentId)
      .populate('courses')
      .populate('employees', 'firstName lastName email department studentId');

    if (!department) {
      return res.status(404).json({ message: 'Department not found' });
    }

    // Collect training data
    const reportData = {
      departmentName: department.name,
      departmentCode: department.code,
      totalEmployees: department.employees.length,
      totalCourses: department.courses.length,
      generatedAt: new Date(),
      courseProgress: []
    };

    for (const course of department.courses) {
      const fullCourse = await Course.findById(course._id)
        .populate('students', 'firstName lastName email studentId department')
        .populate('instructor', 'firstName lastName');
      
      const assignments = await Assignment.find({ courseId: course._id });
      const quizzes = await Quiz.find({ courseId: course._id });

      const enrolledEmployees = fullCourse.students.filter(student =>
        department.employees.some(emp => emp._id.equals(student._id))
      );

      const employeeProgress = [];

      for (const employee of enrolledEmployees) {
        let completedAssignments = 0;
        let totalAssignments = assignments.length;
        let totalAssignmentScore = 0;
        let gradedAssignments = 0;

        // Check assignment completion using Submission model
        const submissions = await Submission.find({
          studentId: employee._id,
          assignmentId: { $in: assignments.map(a => a._id) }
        });

        completedAssignments = submissions.length;
        
        // Calculate average assignment score
        for (const submission of submissions) {
          if (submission.grade !== null && submission.grade !== undefined) {
            totalAssignmentScore += submission.grade;
            gradedAssignments++;
          }
        }

        const averageAssignmentScore = gradedAssignments > 0
          ? totalAssignmentScore / gradedAssignments
          : 0;

        // Check quiz attempts
        const quizAttempts = await QuizAttempt.find({
          student: employee._id,
          quiz: { $in: quizzes.map(q => q._id) },
          isCompleted: true
        });

        const averageQuizScore = quizAttempts.length > 0
          ? quizAttempts.reduce((sum, attempt) => sum + (attempt.score || 0), 0) / quizAttempts.length
          : 0;

        // Calculate overall progress
        const totalTasks = totalAssignments + quizzes.length;
        const completedTasks = completedAssignments + quizAttempts.length;
        const overallProgress = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;

        employeeProgress.push({
          employeeName: employee.firstName && employee.lastName ? `${employee.firstName} ${employee.lastName}` : employee.email,
          employeeEmail: employee.email,
          studentId: employee.studentId,
          completedAssignments,
          totalAssignments,
          averageAssignmentScore: Math.round(averageAssignmentScore * 100) / 100,
          completedQuizzes: quizAttempts.length,
          totalQuizzes: quizzes.length,
          averageQuizScore: Math.round(averageQuizScore * 100) / 100,
          overallProgress
        });
      }

      reportData.courseProgress.push({
        courseName: fullCourse.name,
        courseCode: fullCourse.code,
        instructor: fullCourse.instructor ? (fullCourse.instructor.firstName && fullCourse.instructor.lastName ? `${fullCourse.instructor.firstName} ${fullCourse.instructor.lastName}` : fullCourse.instructor.email || 'Unknown') : 'Unknown',
        enrolledCount: enrolledEmployees.length,
        employees: employeeProgress
      });
    }

    if (format === 'excel') {
      // Generate Excel report
      const workbook = new ExcelJS.Workbook();
      const worksheet = workbook.addWorksheet('Department Report');

      // Header with styling
      const titleRow = worksheet.addRow(['Department Training Report']);
      titleRow.font = { size: 16, bold: true };
      titleRow.alignment = { horizontal: 'center' };
      worksheet.mergeCells('A1:G1');
      
      worksheet.addRow(['Department:', reportData.departmentName]);
      worksheet.addRow(['Department Code:', reportData.departmentCode]);
      worksheet.addRow(['Total Employees:', reportData.totalEmployees]);
      worksheet.addRow(['Total Courses:', reportData.totalCourses]);
      worksheet.addRow(['Generated:', reportData.generatedAt.toLocaleString()]);
      worksheet.addRow([]);

      // Course details with styling
      for (const course of reportData.courseProgress) {
        const courseRow = worksheet.addRow([`Course: ${course.courseName} (${course.courseCode})`]);
        courseRow.font = { size: 14, bold: true, color: { argb: 'FF1976D2' } };
        worksheet.mergeCells(`A${courseRow.number}:H${courseRow.number}`);
        
        const instructorRow = worksheet.addRow([`Instructor: ${course.instructor}`, '', '', '', '', '', '', '']);
        instructorRow.font = { italic: true, color: { argb: 'FF666666' } };
        
        const headerRow = worksheet.addRow(['Employee Name', 'Email', 'Student ID', 'Assignments', 'Avg Assignment Score', 'Quizzes', 'Avg Quiz Score', 'Overall Progress']);
        headerRow.font = { bold: true };
        headerRow.fill = {
          type: 'pattern',
          pattern: 'solid',
          fgColor: { argb: 'FFE3F2FD' }
        };
        headerRow.alignment = { horizontal: 'center', vertical: 'middle' };

        for (const emp of course.employees) {
          const dataRow = worksheet.addRow([
            emp.employeeName,
            emp.employeeEmail,
            emp.studentId || 'N/A',
            `${emp.completedAssignments}/${emp.totalAssignments}`,
            emp.averageAssignmentScore > 0 ? `${emp.averageAssignmentScore}` : 'N/A',
            `${emp.completedQuizzes}/${emp.totalQuizzes}`,
            `${emp.averageQuizScore}%`,
            `${emp.overallProgress}%`
          ]);
          dataRow.alignment = { vertical: 'middle' };
        }

        worksheet.addRow([]);
      }
      
      // Auto-fit columns
      worksheet.columns.forEach((column, index) => {
        if (index < 8) {
          column.width = index === 0 ? 25 : index === 1 ? 30 : 20;
        }
      });

      const buffer = await workbook.xlsx.writeBuffer();

      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', `attachment; filename=department_report_${department.code}_${Date.now()}.xlsx`);
      res.send(buffer);

    } else if (format === 'pdf') {
      // Generate PDF report
      const doc = new PDFDocument();
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename=department_report_${department.code}_${Date.now()}.pdf`);

      doc.pipe(res);

      // Title
      doc.fontSize(20).text('Department Training Report', { align: 'center' });
      doc.moveDown();

      // Department info
      doc.fontSize(12);
      doc.text(`Department: ${reportData.departmentName}`);
      doc.text(`Department Code: ${reportData.departmentCode}`);
      doc.text(`Total Employees: ${reportData.totalEmployees}`);
      doc.text(`Total Courses: ${reportData.totalCourses}`);
      doc.text(`Generated: ${reportData.generatedAt.toLocaleString()}`);
      doc.moveDown(2);

      // Course details
      for (const course of reportData.courseProgress) {
        doc.fontSize(14).text(`Course: ${course.courseName} (${course.courseCode})`, { underline: true });
        doc.fontSize(10).fillColor('gray').text(`Instructor: ${course.instructor}`);
        doc.fillColor('black');
        doc.moveDown();

        doc.fontSize(10);
        for (const emp of course.employees) {
          doc.text(`${emp.employeeName} - ${emp.employeeEmail}`);
          doc.text(`  Student ID: ${emp.studentId || 'N/A'}`);
          doc.text(`  Assignments: ${emp.completedAssignments}/${emp.totalAssignments} (Avg Score: ${emp.averageAssignmentScore > 0 ? emp.averageAssignmentScore : 'N/A'})`);
          doc.text(`  Quizzes: ${emp.completedQuizzes}/${emp.totalQuizzes} (Avg Score: ${emp.averageQuizScore}%)`);
          doc.text(`  Overall Progress: ${emp.overallProgress}%`);
          doc.moveDown(0.5);
        }

        doc.moveDown();
      }

      doc.end();
    } else {
      res.status(400).json({ message: 'Invalid format. Use "excel" or "pdf"' });
    }

  } catch (error) {
    console.error('Error generating department report:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// @route   POST /api/admin/reports/generate-individual-report
// @desc    Generate individual student training report
// @access  Admin only
router.post('/generate-individual-report', auth, adminOnly, async (req, res) => {
  try {
    const { userId, format = 'excel' } = req.body;

    if (!userId) {
      return res.status(400).json({ message: 'userId is required' });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Get all courses user is enrolled in
    const courses = await Course.find({ students: userId })
      .populate('instructor', 'firstName lastName email');

    const reportData = {
      userName: user.firstName && user.lastName ? `${user.firstName} ${user.lastName}` : user.email,
      userEmail: user.email,
      studentId: user.studentId,
      department: user.department,
      generatedAt: new Date(),
      courseProgress: []
    };

    for (const course of courses) {
      const assignments = await Assignment.find({ courseId: course._id });
      const quizzes = await Quiz.find({ courseId: course._id });

      let completedAssignments = 0;
      let totalAssignmentScore = 0;
      let gradedAssignments = 0;

      // Check assignments using Submission model
      const submissions = await Submission.find({
        studentId: userId,
        assignmentId: { $in: assignments.map(a => a._id) }
      });

      completedAssignments = submissions.length;
      
      // Calculate average assignment score
      for (const submission of submissions) {
        if (submission.grade !== null && submission.grade !== undefined) {
          totalAssignmentScore += submission.grade;
          gradedAssignments++;
        }
      }

      const averageAssignmentScore = gradedAssignments > 0
        ? totalAssignmentScore / gradedAssignments
        : 0;

      // Check quizzes
      const quizAttempts = await QuizAttempt.find({
        student: userId,
        quiz: { $in: quizzes.map(q => q._id) },
        isCompleted: true
      });

      const quizDetails = [];
      for (const attempt of quizAttempts) {
        const quiz = quizzes.find(q => q._id.equals(attempt.quiz));
        quizDetails.push({
          quizTitle: quiz ? quiz.title : 'Unknown Quiz',
          score: attempt.score || 0,
          completedAt: attempt.completedAt
        });
      }

      const averageQuizScore = quizAttempts.length > 0
        ? quizAttempts.reduce((sum, attempt) => sum + (attempt.score || 0), 0) / quizAttempts.length
        : 0;

      // Calculate overall progress
      const totalTasks = assignments.length + quizzes.length;
      const completedTasks = completedAssignments + quizAttempts.length;
      const overallProgress = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;

      reportData.courseProgress.push({
        courseName: course.name,
        courseCode: course.code,
        instructor: course.instructor ? (course.instructor.firstName && course.instructor.lastName ? `${course.instructor.firstName} ${course.instructor.lastName}` : course.instructor.email || 'Unknown') : 'Unknown',
        completedAssignments,
        totalAssignments: assignments.length,
        averageAssignmentScore: Math.round(averageAssignmentScore * 100) / 100,
        completedQuizzes: quizAttempts.length,
        totalQuizzes: quizzes.length,
        averageQuizScore: Math.round(averageQuizScore * 100) / 100,
        overallProgress,
        quizDetails
      });
    }

    if (format === 'excel') {
      const workbook = new ExcelJS.Workbook();
      const worksheet = workbook.addWorksheet('Individual Report');

      // Header with styling
      const titleRow = worksheet.addRow(['Individual Training Report']);
      titleRow.font = { size: 16, bold: true };
      titleRow.alignment = { horizontal: 'center' };
      worksheet.mergeCells('A1:G1');
      
      worksheet.addRow(['Student Name:', reportData.userName]);
      worksheet.addRow(['Email:', reportData.userEmail]);
      worksheet.addRow(['Student ID:', reportData.studentId || 'N/A']);
      worksheet.addRow(['Department:', reportData.department]);
      worksheet.addRow(['Generated:', reportData.generatedAt.toLocaleString()]);
      worksheet.addRow([]);

      // Course progress with styling
      const headerRow = worksheet.addRow(['Course', 'Instructor', 'Assignments', 'Avg Assignment', 'Quizzes', 'Avg Quiz', 'Progress']);
      headerRow.font = { bold: true };
      headerRow.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FFE8F5E9' }
      };
      headerRow.alignment = { horizontal: 'center', vertical: 'middle' };

      for (const course of reportData.courseProgress) {
        const dataRow = worksheet.addRow([
          `${course.courseName} (${course.courseCode})`,
          course.instructor,
          `${course.completedAssignments}/${course.totalAssignments}`,
          course.averageAssignmentScore > 0 ? `${course.averageAssignmentScore}` : 'N/A',
          `${course.completedQuizzes}/${course.totalQuizzes}`,
          `${course.averageQuizScore}%`,
          `${course.overallProgress}%`
        ]);
        dataRow.alignment = { vertical: 'middle' };
      }
      
      // Auto-fit columns
      worksheet.columns.forEach((column, index) => {
        if (index < 7) {
          column.width = index === 0 ? 35 : 20;
        }
      });

      const buffer = await workbook.xlsx.writeBuffer();

      res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      res.setHeader('Content-Disposition', `attachment; filename=individual_report_${user.username}_${Date.now()}.xlsx`);
      res.send(buffer);

    } else if (format === 'pdf') {
      const doc = new PDFDocument();
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename=individual_report_${user.username}_${Date.now()}.pdf`);

      doc.pipe(res);

      doc.fontSize(20).text('Individual Training Report', { align: 'center' });
      doc.moveDown();

      doc.fontSize(12);
      doc.text(`Student Name: ${reportData.userName}`);
      doc.text(`Email: ${reportData.userEmail}`);
      doc.text(`Student ID: ${reportData.studentId || 'N/A'}`);
      doc.text(`Department: ${reportData.department}`);
      doc.text(`Generated: ${reportData.generatedAt.toLocaleString()}`);
      doc.moveDown(2);

      for (const course of reportData.courseProgress) {
        doc.fontSize(14).text(`${course.courseName} (${course.courseCode})`, { underline: true });
        doc.fontSize(10);
        doc.text(`Instructor: ${course.instructor}`);
        doc.text(`Assignments: ${course.completedAssignments}/${course.totalAssignments} (Avg Score: ${course.averageAssignmentScore > 0 ? course.averageAssignmentScore : 'N/A'})`);
        doc.text(`Quizzes: ${course.completedQuizzes}/${course.totalQuizzes} (Avg Score: ${course.averageQuizScore}%)`);
        doc.text(`Overall Progress: ${course.overallProgress}%`);
        
        if (course.quizDetails && course.quizDetails.length > 0) {
          doc.moveDown(0.5);
          doc.fontSize(9).text('Quiz History:', { underline: true });
          for (const quiz of course.quizDetails.slice(0, 5)) {
            doc.text(`  • ${quiz.quizTitle}: ${quiz.score}% (${new Date(quiz.completedAt).toLocaleDateString()})`);
          }
        }
        doc.moveDown();
      }

      doc.end();
    } else {
      res.status(400).json({ message: 'Invalid format. Use "excel" or "pdf"' });
    }

  } catch (error) {
    console.error('Error generating individual report:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// @route   GET /api/admin/reports/export-all-users
// @desc    Export all users to Excel
// @access  Admin only
router.get('/export-all-users', auth, adminOnly, async (req, res) => {
  try {
    const users = await User.find()
      .select('-password -resetPasswordToken -resetPasswordExpires')
      .sort({ createdAt: -1 });

    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('All Users');

    // Header row
    worksheet.addRow([
      'Username',
      'Email',
      'Full Name',
      'Role',
      'Department',
      'Student ID',
      'Phone',
      'Active',
      'Created At'
    ]);

    // Data rows
    for (const user of users) {
      worksheet.addRow([
        user.username,
        user.email,
        user.fullName,
        user.role,
        user.department,
        user.studentId || '',
        user.phoneNumber || '',
        user.isActive ? 'Yes' : 'No',
        user.createdAt.toLocaleString()
      ]);
    }

    const buffer = await workbook.xlsx.writeBuffer();

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename=all_users_${Date.now()}.xlsx`);
    res.send(buffer);

  } catch (error) {
    console.error('Error exporting users:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;

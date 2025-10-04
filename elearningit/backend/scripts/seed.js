// ====================
// scripts/seed.js
// ====================
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const dotenv = require('dotenv');

dotenv.config();

const User = require('../models/User');
const Semester = require('../models/Semester');
const Course = require('../models/Course');
const Group = require('../models/Group');

async function seed() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Clear existing data
    await User.deleteMany({});
    await Semester.deleteMany({});
    await Course.deleteMany({});
    await Group.deleteMany({});

    console.log('Cleared existing data');

    // Create admin user
    const hashedPassword = await bcrypt.hash('admin123', 10);
    const instructor = await User.create({
      username: 'admin',
      password: hashedPassword,
      role: 'admin',
      firstName: 'Admin',
      lastName: 'User',
      email: 'admin@fit.edu.vn',
      department: 'Information Technology'
    });

    console.log('Created admin account');

    // Create test user for API testing
    const testPassword = await bcrypt.hash('test123', 10);
    const testUser = await User.create({
      username: 'test',
      password: testPassword,
      role: 'student',
      firstName: 'Test',
      lastName: 'User',
      email: 'test@student.edu.vn',
      department: 'Information Technology'
    });

    console.log('Created test user account');

    // Create sample students
    const studentPassword = await bcrypt.hash('student123', 10);
    const students = [];
    
    for (let i = 1; i <= 20; i++) {
      const student = await User.create({
        username: `student${i}`,
        password: studentPassword,
        role: 'student',
        firstName: `Student`,
        lastName: `${i}`,
        email: `student${i}@fit.edu.vn`,
        studentId: `ST2021${String(i).padStart(3, '0')}`,
        department: 'Information Technology',
        year: 3,
        gpa: (Math.random() * 1.5 + 2.5).toFixed(2)
      });
      students.push(student);
    }

    console.log('Created 20 sample students');

    // Create semesters
    const semester1 = await Semester.create({
      code: 'HK1-2025',
      name: 'Semester 1 - 2025-2026',
      startDate: new Date('2025-09-01'),
      endDate: new Date('2026-01-31'),
      isCurrent: true
    });

    const semester2 = await Semester.create({
      code: 'HK2-2024',
      name: 'Semester 2 - 2024-2025',
      startDate: new Date('2025-02-01'),
      endDate: new Date('2025-06-30'),
      isCurrent: false
    });

    console.log('Created semesters');

    // Create courses
    const courses = await Course.insertMany([
      {
        code: 'CPM502071',
        name: 'Cross-Platform Mobile Development',
        semesterId: semester1._id,
        sessions: 15,
        instructorId: instructor._id,
        color: '#2196F3',
        description: 'Learn to build mobile apps with Flutter'
      },
      {
        code: 'DBS401',
        name: 'Database Management Systems',
        semesterId: semester1._id,
        sessions: 15,
        instructorId: instructor._id,
        color: '#4CAF50',
        description: 'Database design and SQL'
      },
      {
        code: 'AI501',
        name: 'Artificial Intelligence',
        semesterId: semester1._id,
        sessions: 15,
        instructorId: instructor._id,
        color: '#9C27B0',
        description: 'Introduction to AI and machine learning'
      },
      {
        code: 'WEB301',
        name: 'Web Programming & Applications',
        semesterId: semester1._id,
        sessions: 15,
        instructorId: instructor._id,
        color: '#FF9800',
        description: 'Full-stack web development'
      }
    ]);

    console.log('Created courses');

    // Create groups and assign students
    for (const course of courses) {
      const studentsPerGroup = Math.floor(students.length / 3);
      
      for (let i = 0; i < 3; i++) {
        const groupStudents = students.slice(
          i * studentsPerGroup,
          (i + 1) * studentsPerGroup
        );

        await Group.create({
          name: `Group ${i + 1}`,
          courseId: course._id,
          studentIds: groupStudents.map(s => s._id)
        });
      }
    }

    console.log('Created groups and assigned students');
    console.log('\n=== Seed Data Summary ===');
    console.log('Instructor: admin / admin');
    console.log('Students: student1-student20 / student123');
    console.log('Courses: 4');
    console.log('Groups per course: 3');
    console.log('========================\n');

    await mongoose.disconnect();
    console.log('Seed completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Seed error:', error);
    process.exit(1);
  }
}

seed();
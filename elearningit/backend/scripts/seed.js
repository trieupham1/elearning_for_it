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

    // Hash password
    const hashedPassword = await bcrypt.hash('admin123', 10);
    const testPassword = await bcrypt.hash('student123', 10);
    const instructorPassword = await bcrypt.hash('instructor123', 10);

    // Create admin account
    const admin = await User.create({
      username: 'admin',
      password: hashedPassword,
      role: 'admin',
      firstName: 'Admin',
      lastName: 'User',
      email: 'admin@fit.edu.vn'
    });
    console.log('Created admin account');

    // Create test student account
    const testStudent = await User.create({
      username: 'student1',
      password: testPassword,
      role: 'student',
      firstName: 'Student',
      lastName: '1',
      email: 'student1@fit.edu.vn',
      studentId: 'ST2021001',
      department: 'Information Technology',
      year: '3'
    });
    console.log('Created test user account');

    // Create test instructor accounts
    const instructor1 = await User.create({
      username: 'instructor1',
      password: instructorPassword,
      role: 'instructor',
      firstName: 'John',
      lastName: 'Smith',
      email: 'john.smith@fit.edu.vn',
      department: 'Information Technology'
    });

    const instructor2 = await User.create({
      username: 'instructor2',
      password: instructorPassword,
      role: 'instructor',
      firstName: 'Jane',
      lastName: 'Doe',
      email: 'jane.doe@fit.edu.vn',
      department: 'Information Technology'
    });
    console.log('Created instructor accounts');

    // Create more sample students
    const students = [];
    for (let i = 2; i <= 20; i++) {
      const student = await User.create({
        username: `student${i}`,
        password: testPassword,
        role: 'student',
        firstName: `Student`,
        lastName: `${i}`,
        email: `student${i}@fit.edu.vn`,
        studentId: `ST202100${i}`.padStart(9, '0'),
        department: 'Information Technology',
        year: String(Math.floor(Math.random() * 4) + 1)
      });
      students.push(student);
    }
    students.unshift(testStudent);
    console.log('Created 20 sample students');

    // Create semesters
    const semester1 = await Semester.create({
      code: 'FALL2024',
      name: 'Fall 2024',
      year: 2024,
      startDate: new Date('2024-09-01'),
      endDate: new Date('2024-12-31'),
      isActive: true
    });

    const semester2 = await Semester.create({
      code: 'SPRING2025',
      name: 'Spring 2025',
      year: 2025,
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-05-31'),
      isActive: true
    });

    const semester3 = await Semester.create({
      code: 'SUMMER2025',
      name: 'Summer 2025',
      year: 2025,
      startDate: new Date('2025-06-01'),
      endDate: new Date('2025-08-31'),
      isActive: false
    });
    console.log('Created semesters');

    // Create courses
    const courses = [
      {
        code: 'CPM502071',
        name: 'Cross-Platform Mobile Development',
        description: 'Learn to build mobile applications using Flutter framework',
        instructor: instructor1._id,
        semester: semester1._id,
        sessions: 15,
        color: '#2196F3',
        students: students.slice(0, 10).map(s => s._id)
      },
      {
        code: 'WEB401',
        name: 'Advanced Web Development',
        description: 'Modern web development with React and Node.js',
        instructor: instructor2._id,
        semester: semester1._id,
        sessions: 15,
        color: '#4CAF50',
        students: students.slice(5, 15).map(s => s._id)
      },
      {
        code: 'DB301',
        name: 'Database Management Systems',
        description: 'Learn SQL, NoSQL, and database design principles',
        instructor: instructor1._id,
        semester: semester1._id,
        sessions: 15,
        color: '#FF9800',
        students: students.slice(0, 12).map(s => s._id)
      },
      {
        code: 'AI501',
        name: 'Artificial Intelligence',
        description: 'Introduction to AI and machine learning concepts',
        instructor: instructor2._id,
        semester: semester2._id,
        sessions: 15,
        color: '#9C27B0',
        students: students.slice(8, 18).map(s => s._id)
      },
      {
        code: 'NET402',
        name: 'Computer Networks',
        description: 'Study network protocols, architecture, and security',
        instructor: instructor1._id,
        semester: semester2._id,
        sessions: 15,
        color: '#F44336',
        students: students.slice(3, 13).map(s => s._id)
      },
      {
        code: 'SEC501',
        name: 'Cybersecurity Fundamentals',
        description: 'Learn about security threats, encryption, and best practices',
        instructor: instructor2._id,
        semester: semester2._id,
        sessions: 15,
        color: '#607D8B',
        students: students.slice(10, 20).map(s => s._id)
      }
    ];

    const createdCourses = await Course.insertMany(courses);
    console.log(`Created ${createdCourses.length} courses`);

    // Create sample groups
    const groups = [
      {
        name: 'Study Group A',
        courseId: createdCourses[0]._id,
        members: students.slice(0, 5).map(s => s._id),
        createdBy: students[0]._id,
        description: 'First study group for mobile development'
      },
      {
        name: 'Study Group B',
        courseId: createdCourses[0]._id,
        members: students.slice(5, 10).map(s => s._id),
        createdBy: students[5]._id,
        description: 'Second study group for mobile development'
      },
      {
        name: 'Web Dev Team',
        courseId: createdCourses[1]._id,
        members: students.slice(8, 13).map(s => s._id),
        createdBy: students[8]._id,
        description: 'Study group for web development course'
      }
    ];

    await Group.insertMany(groups);
    console.log('Created sample groups');

    console.log('\n=== Seed completed successfully! ===');
    console.log('\nTest Accounts:');
    console.log('Admin:');
    console.log('  Username: admin');
    console.log('  Password: admin123');
    console.log('\nInstructor 1:');
    console.log('  Username: instructor1');
    console.log('  Password: instructor123');
    console.log('\nInstructor 2:');
    console.log('  Username: instructor2');
    console.log('  Password: instructor123');
    console.log('\nStudent:');
    console.log('  Username: student1');
    console.log('  Password: student123');
    console.log('\nOther students: student2 - student20');
    console.log('  Password: student123');
    console.log('\nSemesters: FALL2024, SPRING2025, SUMMER2025');
    console.log('\nCourses: 6 courses created');
    console.log('Groups: 3 study groups created');

    process.exit(0);
  } catch (error) {
    console.error('Seed error:', error);
    process.exit(1);
  }
}

seed();
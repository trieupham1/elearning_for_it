const mongoose = require('mongoose');
require('dotenv').config();

const courseId = '6917f24473ecbb704436a60b';
const instructorId = '68ea917c8f7467f25bbfaea1';
const instructorName = 'Nguyen Van B';
const studentId = '68ecf7b0f4bd21c6f0414b1f';

async function seedData() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const Announcement = require('../models/Announcement');
    const Assignment = require('../models/Assignment');
    const Quiz = require('../models/Quiz');
    const Question = require('../models/Question');
    const Material = require('../models/Material');
    const CodeAssignment = require('../models/CodeAssignment');
    const TestCase = require('../models/TestCase');

    // 1. Create Announcements
    console.log('\n--- Creating Announcements ---');
    const announcements = await Announcement.insertMany([
      {
        courseId: courseId,
        authorId: instructorId,
        authorName: instructorName,
        title: 'Welcome to Mobile App Development!',
        content: 'Welcome to this exciting course on Mobile App Development! We will cover Flutter, Dart, and cross-platform development techniques. Please review the syllabus and get your development environment ready.',
        createdAt: new Date('2026-01-15')
      },
      {
        courseId: courseId,
        authorId: instructorId,
        authorName: instructorName,
        title: 'Flutter Setup Instructions',
        content: 'Please install Flutter SDK and set up Android Studio or VS Code with Flutter extensions before our next class. Links to installation guides are in the Materials section.',
        createdAt: new Date('2026-01-18')
      },
      {
        courseId: courseId,
        authorId: instructorId,
        authorName: instructorName,
        title: 'Assignment 1 Released',
        content: 'Your first assignment on Dart basics has been released. Due date is February 5th. Please check the Classwork tab for details.',
        createdAt: new Date('2026-01-22')
      }
    ]);
    console.log(`Created ${announcements.length} announcements`);

    // 2. Create Assignments
    console.log('\n--- Creating Assignments ---');
    const assignments = await Assignment.insertMany([
      {
        courseId: courseId,
        createdBy: instructorId,
        createdByName: instructorName,
        title: 'Dart Programming Basics',
        description: `Complete the following Dart programming exercises:
1. Create a function to calculate factorial
2. Implement a class for a simple calculator
3. Write a program using Lists and Maps

Submit a single .dart file with all solutions.`,
        type: 'file',
        startDate: new Date('2026-01-22'),
        deadline: new Date('2026-02-05'),
        points: 100,
        allowedFileTypes: ['.dart', '.zip'],
        createdAt: new Date('2026-01-22')
      },
      {
        courseId: courseId,
        createdBy: instructorId,
        createdByName: instructorName,
        title: 'First Flutter App - Hello World',
        description: `Create your first Flutter application:
1. Display a centered text "Hello World"
2. Add a button that changes the text when pressed
3. Style the app with a custom theme

Submit the entire project folder as a ZIP file.`,
        type: 'file',
        startDate: new Date('2026-01-25'),
        deadline: new Date('2026-02-12'),
        points: 100,
        allowedFileTypes: ['.zip'],
        createdAt: new Date('2026-01-25')
      },
      {
        courseId: courseId,
        createdBy: instructorId,
        createdByName: instructorName,
        title: 'Widget Layout Challenge',
        description: `Build a profile card UI using Flutter widgets:
- Use Column, Row, and Container widgets
- Include an avatar, name, and bio section
- Make it responsive for different screen sizes

Include screenshots showing your app on different devices.`,
        type: 'file',
        startDate: new Date('2026-01-28'),
        deadline: new Date('2026-02-20'),
        points: 100,
        allowedFileTypes: ['.zip', '.png', '.jpg'],
        createdAt: new Date('2026-01-28')
      }
    ]);
    console.log(`Created ${assignments.length} assignments`);

    // 3. Create Code Assignments
    console.log('\n--- Creating Code Assignments ---');
    
    // First create the code assignment
    const codeAssignment = new CodeAssignment({
      courseId: courseId,
      createdBy: instructorId,
      title: 'Add Two Numbers',
      description: `Write a Python function called \`add_numbers\` that takes two integers as parameters and returns their sum.

Your function should:
- Accept two integer parameters: a and b
- Return the sum of a and b
- Handle both positive and negative numbers

Example:
add_numbers(3, 5) should return 8
add_numbers(-2, 7) should return 5`,
      language: 'python',
      languageId: 71, // Judge0 Python language ID
      starterCode: `def add_numbers(a, b):
    # Write your code here
    pass

# Test your function
if __name__ == "__main__":
    result = add_numbers(3, 5)
    print(f"Result: {result}")`,
      solutionCode: `def add_numbers(a, b):
    return a + b

# Test the function
if __name__ == "__main__":
    result = add_numbers(3, 5)
    print(f"Result: {result}")`,
      points: 100,
      difficulty: 'easy',
      dueDate: new Date('2026-02-10'),
      createdAt: new Date('2026-01-29')
    });
    
    const savedCodeAssignment = await codeAssignment.save();
    console.log('Created code assignment:', savedCodeAssignment.title);

    // Create test cases for the code assignment
    const testCases = await TestCase.insertMany([
      {
        assignmentId: savedCodeAssignment._id,
        name: 'Basic Addition',
        input: '3,5',
        expectedOutput: '8',
        weight: 25,
        isHidden: false
      },
      {
        assignmentId: savedCodeAssignment._id,
        name: 'Negative Numbers',
        input: '-2,7',
        expectedOutput: '5',
        weight: 25,
        isHidden: true
      },
      {
        assignmentId: savedCodeAssignment._id,
        name: 'Zero Addition',
        input: '0,10',
        expectedOutput: '10',
        weight: 25,
        isHidden: true
      },
      {
        assignmentId: savedCodeAssignment._id,
        name: 'Both Negative',
        input: '-3,-7',
        expectedOutput: '-10',
        weight: 25,
        isHidden: true
      }
    ]);
    console.log(`Created ${testCases.length} test cases`);

    // 4. Create Materials
    console.log('\n--- Creating Materials ---');
    const materials = await Material.insertMany([
      {
        courseId: courseId,
        createdBy: instructorId,
        title: 'Course Syllabus',
        description: 'Complete syllabus for Mobile App Development course including schedule, grading criteria, and learning objectives.',
        links: ['https://flutter.dev/docs'],
        createdAt: new Date('2026-01-15')
      },
      {
        courseId: courseId,
        createdBy: instructorId,
        title: 'Flutter Installation Guide',
        description: 'Step-by-step guide to install Flutter SDK on Windows, macOS, and Linux.',
        links: ['https://docs.flutter.dev/get-started/install'],
        createdAt: new Date('2026-01-18')
      },
      {
        courseId: courseId,
        createdBy: instructorId,
        title: 'Dart Language Tour',
        description: 'Official Dart language documentation covering all syntax and features.',
        links: ['https://dart.dev/language'],
        createdAt: new Date('2026-01-18')
      },
      {
        courseId: courseId,
        createdBy: instructorId,
        title: 'Lecture 1 - Introduction to Mobile Development',
        description: 'Slides covering the landscape of mobile app development, native vs cross-platform approaches.',
        links: ['https://flutter.dev'],
        createdAt: new Date('2026-01-20')
      },
      {
        courseId: courseId,
        createdBy: instructorId,
        title: 'Lecture 2 - Dart Fundamentals',
        description: 'Comprehensive slides on Dart programming language basics including variables, functions, classes, and async programming.',
        links: ['https://dart.dev'],
        createdAt: new Date('2026-01-22')
      }
    ]);
    console.log(`Created ${materials.length} materials`);

    // 4. Create Questions for Quiz
    console.log('\n--- Creating Quiz Questions ---');
    const questions = await Question.insertMany([
      {
        courseId: courseId,
        createdBy: instructorId,
        questionText: 'What is the main programming language used in Flutter development?',
        choices: [
          { text: 'Java', isCorrect: false },
          { text: 'Kotlin', isCorrect: false },
          { text: 'Dart', isCorrect: true },
          { text: 'Swift', isCorrect: false }
        ],
        difficulty: 'easy',
        category: 'Flutter Basics',
        createdAt: new Date('2026-01-20')
      },
      {
        courseId: courseId,
        createdBy: instructorId,
        questionText: 'Which widget is used to create a scrollable list in Flutter?',
        choices: [
          { text: 'Column', isCorrect: false },
          { text: 'Row', isCorrect: false },
          { text: 'ListView', isCorrect: true },
          { text: 'Container', isCorrect: false }
        ],
        difficulty: 'easy',
        category: 'Widgets',
        createdAt: new Date('2026-01-20')
      },
      {
        courseId: courseId,
        createdBy: instructorId,
        questionText: 'What is the purpose of the "pubspec.yaml" file in a Flutter project?',
        choices: [
          { text: 'Define UI layouts', isCorrect: false },
          { text: 'Configure app dependencies and metadata', isCorrect: true },
          { text: 'Store user data', isCorrect: false },
          { text: 'Define API routes', isCorrect: false }
        ],
        difficulty: 'easy',
        category: 'Project Structure',
        createdAt: new Date('2026-01-20')
      },
      {
        courseId: courseId,
        createdBy: instructorId,
        questionText: 'Which of the following is a stateful widget lifecycle method?',
        choices: [
          { text: 'build()', isCorrect: false },
          { text: 'initState()', isCorrect: true },
          { text: 'render()', isCorrect: false },
          { text: 'onCreate()', isCorrect: false }
        ],
        difficulty: 'medium',
        category: 'State Management',
        createdAt: new Date('2026-01-20')
      },
      {
        courseId: courseId,
        createdBy: instructorId,
        questionText: 'What is the difference between StatelessWidget and StatefulWidget?',
        choices: [
          { text: 'StatelessWidget can change over time, StatefulWidget cannot', isCorrect: false },
          { text: 'StatefulWidget can change its state during runtime, StatelessWidget cannot', isCorrect: true },
          { text: 'There is no difference', isCorrect: false },
          { text: 'StatelessWidget is faster than StatefulWidget', isCorrect: false }
        ],
        difficulty: 'medium',
        category: 'State Management',
        createdAt: new Date('2026-01-20')
      },
      {
        courseId: courseId,
        createdBy: instructorId,
        questionText: 'Which command is used to create a new Flutter project?',
        choices: [
          { text: 'flutter init', isCorrect: false },
          { text: 'flutter new', isCorrect: false },
          { text: 'flutter create', isCorrect: true },
          { text: 'flutter start', isCorrect: false }
        ],
        difficulty: 'easy',
        category: 'Flutter CLI',
        createdAt: new Date('2026-01-20')
      },
      {
        courseId: courseId,
        createdBy: instructorId,
        questionText: 'What does the "hot reload" feature in Flutter do?',
        choices: [
          { text: 'Restarts the entire app', isCorrect: false },
          { text: 'Injects updated source code into the running app without losing state', isCorrect: true },
          { text: 'Clears the app cache', isCorrect: false },
          { text: 'Compiles the app for production', isCorrect: false }
        ],
        difficulty: 'medium',
        category: 'Development',
        createdAt: new Date('2026-01-20')
      },
      {
        courseId: courseId,
        createdBy: instructorId,
        questionText: 'Which widget is commonly used to handle user input in Flutter?',
        choices: [
          { text: 'Text', isCorrect: false },
          { text: 'TextField', isCorrect: true },
          { text: 'Label', isCorrect: false },
          { text: 'Input', isCorrect: false }
        ],
        difficulty: 'easy',
        category: 'Widgets',
        createdAt: new Date('2026-01-20')
      },
      {
        courseId: courseId,
        createdBy: instructorId,
        questionText: 'What is the purpose of the BuildContext in Flutter?',
        choices: [
          { text: 'To store application data', isCorrect: false },
          { text: 'To handle the widget location in the widget tree', isCorrect: true },
          { text: 'To manage network requests', isCorrect: false },
          { text: 'To define app themes', isCorrect: false }
        ],
        difficulty: 'hard',
        category: 'Flutter Architecture',
        createdAt: new Date('2026-01-20')
      },
      {
        courseId: courseId,
        createdBy: instructorId,
        questionText: 'Which package manager does Flutter use for dependencies?',
        choices: [
          { text: 'npm', isCorrect: false },
          { text: 'pip', isCorrect: false },
          { text: 'pub', isCorrect: true },
          { text: 'gradle', isCorrect: false }
        ],
        difficulty: 'easy',
        category: 'Flutter Basics',
        createdAt: new Date('2026-01-20')
      }
    ]);
    console.log(`Created ${questions.length} questions`);

    // 5. Create Quizzes
    console.log('\n--- Creating Quizzes ---');
    const quizzes = await Quiz.insertMany([
      {
        courseId: courseId,
        createdBy: instructorId,
        title: 'Flutter Fundamentals Quiz',
        description: 'Test your understanding of Flutter basics, widgets, and development concepts.',
        selectedQuestions: questions.slice(0, 5).map(q => q._id),
        duration: 15,
        maxAttempts: 2,
        shuffleQuestions: true,
        showResultsImmediately: true,
        questionStructure: { easy: 3, medium: 2, hard: 0 },
        openDate: new Date('2026-01-25'),
        closeDate: new Date('2026-02-25'),
        status: 'active',
        isActive: true,
        totalPoints: 50,
        createdAt: new Date('2026-01-20')
      },
      {
        courseId: courseId,
        createdBy: instructorId,
        title: 'Dart & Flutter Development Quiz',
        description: 'Comprehensive quiz covering Dart programming and Flutter development practices.',
        selectedQuestions: questions.slice(5, 10).map(q => q._id),
        duration: 20,
        maxAttempts: 2,
        shuffleQuestions: true,
        showResultsImmediately: true,
        questionStructure: { easy: 2, medium: 2, hard: 1 },
        openDate: new Date('2026-02-01'),
        closeDate: new Date('2026-03-01'),
        status: 'active',
        isActive: true,
        totalPoints: 50,
        createdAt: new Date('2026-01-25')
      }
    ]);
    console.log(`Created ${quizzes.length} quizzes`);

    console.log('\n========================================');
    console.log('Sample data created successfully!');
    console.log('========================================');
    console.log('Summary:');
    console.log(`- Announcements: ${announcements.length}`);
    console.log(`- Assignments: ${assignments.length}`);
    console.log(`- Code Assignments: 1`);
    console.log(`- Test Cases: ${testCases.length}`);
    console.log(`- Materials: ${materials.length}`);
    console.log(`- Questions: ${questions.length}`);
    console.log(`- Quizzes: ${quizzes.length}`);

    process.exit(0);
  } catch (error) {
    console.error('Error seeding data:', error);
    process.exit(1);
  }
}

seedData();

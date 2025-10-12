// server.js - Main Express Server
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
const authRoutes = require('./routes/auth');
const courseRoutes = require('./routes/courses');
const userRoutes = require('./routes/users');
const semesterRoutes = require('./routes/semesters');
const studentRoutes = require('./routes/students');
const notificationRoutes = require('./routes/notifications');
const announcementRoutes = require('./routes/announcements');
const assignmentRoutes = require('./routes/assignments');
const classworkRoutes = require('./routes/classwork');
const messageRoutes = require('./routes/messages');
const groupRoutes = require('./routes/groups');
const quizRoutes = require('./routes/quizzes');
const questionRoutes = require('./routes/questions');
const quizAttemptRoutes = require('./routes/quiz-attempts');
const materialRoutes = require('./routes/materials');
const forumRoutes = require('./routes/forum');
const { router: fileRoutes, initializeGridFS } = require('./routes/files');

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/courses', courseRoutes);
app.use('/api/semesters', semesterRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/announcements', announcementRoutes);
app.use('/api/assignments', assignmentRoutes);
app.use('/api/classwork', classworkRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/quizzes', quizRoutes);
app.use('/api/questions', questionRoutes);
app.use('/api/quiz-attempts', quizAttemptRoutes);
app.use('/api/materials', materialRoutes);
app.use('/api/forum', forumRoutes);
app.use('/api/files', fileRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

// MongoDB connection
mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('Connected to MongoDB');
    
    // Initialize GridFS for file storage
    const { GridFSBucket } = require('mongodb');
    const db = mongoose.connection.db;
    const gfsBucket = new GridFSBucket(db, { bucketName: 'uploads' });
    initializeGridFS(gfsBucket);
    console.log('GridFS initialized');
    
    // Start scheduled tasks
    startScheduledTasks();
    
    const PORT = process.env.PORT || 5000;
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  })
  .catch((error) => {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  });

// Scheduled tasks
function startScheduledTasks() {
  const Quiz = require('./models/Quiz');
  const QuizAttempt = require('./models/QuizAttempt');
  
  // Auto-close expired quizzes every 5 minutes
  setInterval(async () => {
    try {
      const now = new Date();
      
      // Find quizzes that should be closed
      const expiredQuizzes = await Quiz.find({
        closeDate: { $lte: now },
        status: { $in: ['active', 'draft'] },
        isActive: true
      });

      if (expiredQuizzes.length > 0) {
        // Auto-submit any in-progress attempts for expired quizzes
        for (const quiz of expiredQuizzes) {
          await QuizAttempt.updateMany(
            { quizId: quiz._id, status: 'in_progress' },
            { 
              status: 'auto_submitted',
              endTime: now,
              submissionTime: now
            }
          );
        }

        // Update quiz status
        await Quiz.updateMany(
          { _id: { $in: expiredQuizzes.map(q => q._id) } },
          { 
            status: 'closed',
            isActive: false
          }
        );

        console.log(`🔒 Auto-closed ${expiredQuizzes.length} expired quizzes`);
      }
    } catch (error) {
      console.error('❌ Error in scheduled quiz cleanup:', error);
    }
  }, 5 * 60 * 1000); // Every 5 minutes
  
  console.log('📅 Scheduled tasks started - checking for expired quizzes every 5 minutes');
}

module.exports = app;
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
    
    const PORT = process.env.PORT || 5000;
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  })
  .catch((error) => {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  });

module.exports = app;
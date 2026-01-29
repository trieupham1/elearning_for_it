const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const multer = require('multer');
const { GridFSBucket } = require('mongodb');
const cloudinary = require('cloudinary').v2;
const { auth, instructorOnly } = require('../middleware/auth');
const Video = require('../models/Video');
const VideoProgress = require('../models/VideoProgress');
const Playlist = require('../models/Playlist');

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Initialize GridFS with 'uploads' bucket (for backward compatibility)
let gfsBucket;
mongoose.connection.once('open', () => {
  gfsBucket = new GridFSBucket(mongoose.connection.db, {
    bucketName: 'uploads'
  });
  console.log('✅ Video routes: GridFS initialized with "uploads" bucket');
});

// Configure multer for memory storage
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 100 * 1024 * 1024 // 100MB max (Cloudinary free tier limit)
  },
  fileFilter: (req, file, cb) => {
    // Accept video files - check both mimetype and file extension
    const allowedMimeTypes = [
      'video/mp4', 'video/mpeg', 'video/quicktime', 'video/x-msvideo',
      'video/x-matroska', 'video/webm', 'video/ogg', 'video/3gpp',
      'application/octet-stream' // Some devices send this for videos
    ];
    const allowedExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.ogg', '.3gp'];
    
    const fileExtension = '.' + file.originalname.split('.').pop().toLowerCase();
    const isValidMime = file.mimetype.startsWith('video/') || allowedMimeTypes.includes(file.mimetype);
    const isValidExtension = allowedExtensions.includes(fileExtension);
    
    console.log(`📹 File upload check: ${file.originalname}, MIME: ${file.mimetype}, Ext: ${fileExtension}`);
    
    if (isValidMime || isValidExtension) {
      cb(null, true);
    } else {
      console.error(`❌ Rejected file: ${file.originalname}, MIME: ${file.mimetype}`);
      cb(new Error('Only video files are allowed!'), false);
    }
  }
});

// @route   POST /api/videos/upload
// @desc    Upload a video to Cloudinary
// @access  Private (Instructor only)
router.post('/upload', auth, instructorOnly, upload.single('video'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No video file uploaded' });
    }

    const { title, description, courseId, tags, duration } = req.body;

    if (!title || !courseId) {
      return res.status(400).json({ message: 'Title and courseId are required' });
    }

    console.log(`📹 Uploading video to Cloudinary: ${title} (${(req.file.size / 1024 / 1024).toFixed(2)} MB)`);

    // Upload to Cloudinary
    const uploadPromise = new Promise((resolve, reject) => {
      const uploadStream = cloudinary.uploader.upload_stream(
        {
          resource_type: 'video',
          folder: `elearning/videos/${courseId}`,
          public_id: `video_${Date.now()}`,
          eager: [
            { streaming_profile: 'full_hd', format: 'm3u8' } // HLS streaming
          ],
          eager_async: true
        },
        (error, result) => {
          if (error) {
            console.error('Cloudinary upload error:', error);
            reject(error);
          } else {
            resolve(result);
          }
        }
      );
      uploadStream.end(req.file.buffer);
    });

    const cloudinaryResult = await uploadPromise;
    console.log('✅ Video uploaded to Cloudinary:', cloudinaryResult.secure_url);

    // Create video document
    const video = new Video({
      title,
      description,
      courseId,
      uploadedBy: req.user.userId,
      cloudinaryUrl: cloudinaryResult.secure_url,
      cloudinaryPublicId: cloudinaryResult.public_id,
      filename: req.file.originalname,
      mimeType: req.file.mimetype,
      size: req.file.size,
      duration: cloudinaryResult.duration || duration || 0,
      tags: tags ? JSON.parse(tags) : [],
      isPublished: false,
      storageType: 'cloudinary'
    });

    await video.save();

    res.status(201).json({
      message: 'Video uploaded successfully',
      video: {
        id: video._id,
        title: video.title,
        streamUrl: cloudinaryResult.secure_url,
        duration: video.duration
      }
    });

  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ message: error.message || 'Error uploading video' });
  }
});

// @route   GET /api/videos/:id/stream
// @desc    Stream a video (supports both Cloudinary and GridFS)
// @access  Public (no auth for better compatibility with video players)
router.get('/:id/stream', async (req, res) => {
  console.log(`\n🎬 ========== VIDEO STREAM REQUEST ==========`);
  console.log(`📍 Video ID: ${req.params.id}`);
  
  try {
    const video = await Video.findById(req.params.id);
    
    if (!video) {
      console.error(`❌ Video not found in database: ${req.params.id}`);
      return res.status(404).json({ message: 'Video not found' });
    }

    console.log(`✅ Video found: ${video.title}`);
    console.log(`📦 Storage type: ${video.storageType || 'gridfs'}`);

    // Increment view count (async, don't wait)
    video.incrementViewCount().catch(err => console.error('Error incrementing view count:', err));

    // If Cloudinary video, redirect to Cloudinary URL
    if (video.storageType === 'cloudinary' && video.cloudinaryUrl) {
      console.log(`☁️ Redirecting to Cloudinary: ${video.cloudinaryUrl}`);
      return res.redirect(video.cloudinaryUrl);
    }

    // Otherwise, stream from GridFS (backward compatibility)
    if (!gfsBucket) {
      console.error('❌ GridFS bucket not initialized!');
      return res.status(500).json({ message: 'GridFS not initialized' });
    }

    console.log(`📁 Streaming from GridFS, File ID: ${video.fileId}`);

    // Get file from GridFS
    const files = await gfsBucket.find({ _id: video.fileId }).toArray();
    
    if (files.length === 0) {
      console.error(`❌ Video file not found in GridFS: ${video.fileId}`);
      return res.status(404).json({ message: 'Video file not found in storage' });
    }

    const file = files[0];
    const videoSize = file.length;
    const contentType = 'video/mp4';
    
    console.log(`✅ File found in GridFS: ${file.filename} (${(videoSize / 1024 / 1024).toFixed(2)} MB)`);

    // Set CORS headers for video streaming
    res.set({
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Range, Content-Type',
      'Access-Control-Expose-Headers': 'Content-Length, Content-Range, Accept-Ranges',
    });

    // Handle range requests (required for video seeking)
    const range = req.headers.range;
    
    if (range) {
      console.log(`📍 Range request: ${range}`);
      
      const parts = range.replace(/bytes=/, '').split('-');
      const start = parseInt(parts[0], 10);
      const end = parts[1] ? parseInt(parts[1], 10) : videoSize - 1;
      const chunkSize = (end - start) + 1;

      console.log(`📤 Sending bytes ${start}-${end}/${videoSize} (${chunkSize} bytes)`);

      // Send 206 Partial Content
      res.writeHead(206, {
        'Content-Range': `bytes ${start}-${end}/${videoSize}`,
        'Accept-Ranges': 'bytes',
        'Content-Length': chunkSize,
        'Content-Type': contentType,
        'Cache-Control': 'public, max-age=0',
      });

      const downloadStream = gfsBucket.openDownloadStream(video.fileId, {
        start: start,
        end: end + 1
      });

      downloadStream.on('error', (error) => {
        console.error('❌ Stream error:', error);
      });

      downloadStream.on('end', () => {
        console.log('✅ Stream ended successfully');
      });

      downloadStream.pipe(res);
      
    } else {
      // No range, send entire file
      console.log(`📤 Sending full video (${videoSize} bytes)`);
      
      res.writeHead(200, {
        'Content-Length': videoSize,
        'Content-Type': contentType,
        'Accept-Ranges': 'bytes',
        'Cache-Control': 'public, max-age=0',
      });

      const downloadStream = gfsBucket.openDownloadStream(video.fileId);

      downloadStream.on('error', (error) => {
        console.error('❌ Stream error:', error);
      });

      downloadStream.on('end', () => {
        console.log('✅ Stream ended successfully');
      });

      downloadStream.pipe(res);
    }

  } catch (error) {
    console.error('❌ Stream video error:', error);
    if (!res.headersSent) {
      res.status(500).json({ message: error.message });
    }
  }
  
  console.log(`========================================\n`);
});

// @route   POST /api/videos/:id/track-progress
// @desc    Track video watch progress
// @access  Private
router.post('/:id/track-progress', auth, async (req, res) => {
  try {
    const { position } = req.body; // Position in seconds

    if (position === undefined) {
      return res.status(400).json({ message: 'Position is required' });
    }

    const video = await Video.findById(req.params.id);
    if (!video) {
      return res.status(404).json({ message: 'Video not found' });
    }

    console.log(`📹 Video found:`, {
      id: video._id,
      title: video.title,
      duration: video.duration,
      hasDuration: !!video.duration
    });

    // Find or create progress record
    let progress = await VideoProgress.findOne({
      videoId: req.params.id,
      userId: req.user.userId
    });

    if (!progress) {
      progress = new VideoProgress({
        videoId: req.params.id,
        userId: req.user.userId
      });
    }

    // Update progress
    await progress.updateProgress(position, video.duration);

    console.log(`📊 Progress tracked for user ${req.user.userId}:`, {
      videoId: video._id,
      position,
      duration: video.duration,
      completionPercentage: progress.completionPercentage,
      completed: progress.completed
    });

    res.json({
      message: 'Progress updated',
      progress: {
        lastWatchedPosition: progress.lastWatchedPosition,
        completionPercentage: progress.completionPercentage,
        completed: progress.completed
      }
    });

  } catch (error) {
    console.error('Track progress error:', error);
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/videos/:id/progress
// @desc    Get user's progress for a video
// @access  Private
router.get('/:id/progress', auth, async (req, res) => {
  try {
    const progress = await VideoProgress.findOne({
      videoId: req.params.id,
      userId: req.user.userId
    });

    if (!progress) {
      return res.json({
        lastWatchedPosition: 0,
        completionPercentage: 0,
        completed: false
      });
    }

    res.json({
      lastWatchedPosition: progress.lastWatchedPosition,
      completionPercentage: progress.completionPercentage,
      completed: progress.completed
    });

  } catch (error) {
    console.error('Get progress error:', error);
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/videos/course/:courseId
// @desc    Get all videos for a course
// @access  Private
router.get('/course/:courseId', auth, async (req, res) => {
  try {
    const videos = await Video.find({ 
      courseId: req.params.courseId,
      isPublished: true 
    })
    .populate('uploadedBy', 'fullName email')
    .sort({ createdAt: -1 });

    // Get progress for each video (for students)
    const videosWithProgress = await Promise.all(videos.map(async (video) => {
      const progress = await VideoProgress.findOne({
        videoId: video._id,
        userId: req.user.userId
      });

      return {
        ...video.toObject(),
        progress: progress ? {
          lastWatchedPosition: progress.lastWatchedPosition,
          completionPercentage: progress.completionPercentage,
          completed: progress.completed
        } : null
      };
    }));

    res.json(videosWithProgress);

  } catch (error) {
    console.error('Get course videos error:', error);
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/videos/:id
// @desc    Get video details
// @access  Private
router.get('/:id', auth, async (req, res) => {
  try {
    const video = await Video.findById(req.params.id)
      .populate('uploadedBy', 'fullName email');

    if (!video) {
      return res.status(404).json({ message: 'Video not found' });
    }

    // Get user's progress
    const progress = await VideoProgress.findOne({
      videoId: req.params.id,
      userId: req.user.userId
    });

    // Build response with appropriate stream URL
    const videoData = video.toObject();
    if (video.storageType === 'cloudinary' && video.cloudinaryUrl) {
      videoData.streamUrl = video.cloudinaryUrl;
    } else {
      videoData.streamUrl = `/api/videos/${video._id}/stream`;
    }

    res.json({
      ...videoData,
      progress: progress ? {
        lastWatchedPosition: progress.lastWatchedPosition,
        completionPercentage: progress.completionPercentage,
        completed: progress.completed
      } : null
    });

  } catch (error) {
    console.error('Get video error:', error);
    res.status(500).json({ message: error.message });
  }
});

// @route   PUT /api/videos/:id
// @desc    Update video details
// @access  Private (Instructor only)
router.put('/:id', auth, instructorOnly, async (req, res) => {
  try {
    const { title, description, tags, duration, isPublished } = req.body;

    const video = await Video.findById(req.params.id);
    if (!video) {
      return res.status(404).json({ message: 'Video not found' });
    }

    // Check if user is the uploader
    if (video.uploadedBy.toString() !== req.user.userId) {
      return res.status(403).json({ message: 'Not authorized to update this video' });
    }

    // Update fields
    if (title) video.title = title;
    if (description !== undefined) video.description = description;
    if (tags) video.tags = tags;
    if (duration) video.duration = duration;
    if (isPublished !== undefined) video.isPublished = isPublished;

    await video.save();

    res.json({
      message: 'Video updated successfully',
      video
    });

  } catch (error) {
    console.error('Update video error:', error);
    res.status(500).json({ message: error.message });
  }
});

// @route   DELETE /api/videos/:id
// @desc    Delete a video
// @access  Private (Instructor only)
router.delete('/:id', auth, instructorOnly, async (req, res) => {
  try {
    const video = await Video.findById(req.params.id);
    if (!video) {
      return res.status(404).json({ message: 'Video not found' });
    }

    // Check if user is the uploader
    if (video.uploadedBy.toString() !== req.user.userId) {
      return res.status(403).json({ message: 'Not authorized to delete this video' });
    }

    // Delete file from GridFS
    await gfsBucket.delete(video.fileId);

    // Delete progress records
    await VideoProgress.deleteMany({ videoId: video._id });

    // Delete video document
    await video.deleteOne();

    res.json({ message: 'Video deleted successfully' });

  } catch (error) {
    console.error('Delete video error:', error);
    res.status(500).json({ message: error.message });
  }
});

// ============== PLAYLIST ROUTES ==============

// @route   POST /api/videos/playlists
// @desc    Create a playlist
// @access  Private (Instructor only)
router.post('/playlists', auth, instructorOnly, async (req, res) => {
  try {
    const { title, description, courseId, videos } = req.body;

    if (!title || !courseId) {
      return res.status(400).json({ message: 'Title and courseId are required' });
    }

    const playlist = new Playlist({
      title,
      description,
      courseId,
      createdBy: req.user.userId,
      videos: videos || []
    });

    await playlist.save();

    res.status(201).json({
      message: 'Playlist created successfully',
      playlist
    });

  } catch (error) {
    console.error('Create playlist error:', error);
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/videos/playlists/course/:courseId
// @desc    Get all playlists for a course
// @access  Private
router.get('/playlists/course/:courseId', auth, async (req, res) => {
  try {
    const playlists = await Playlist.find({ 
      courseId: req.params.courseId,
      isPublished: true 
    })
    .populate('videos.videoId')
    .populate('createdBy', 'fullName email');

    res.json(playlists);

  } catch (error) {
    console.error('Get playlists error:', error);
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/videos/:id/analytics
// @desc    Get video watch analytics (who watched, completion percentage)
// @access  Private (Instructor only)
router.get('/:id/analytics', auth, instructorOnly, async (req, res) => {
  try {
    const video = await Video.findById(req.params.id).populate('courseId');
    
    if (!video) {
      return res.status(404).json({ message: 'Video not found' });
    }

    // Verify instructor owns this course
    if (video.courseId.instructor.toString() !== req.user.userId) {
      return res.status(403).json({ message: 'Not authorized to view analytics' });
    }

    // Get all students enrolled in the course (populate without field selection to include virtuals)
    const Course = require('../models/Course');
    const course = await Course.findById(video.courseId._id).populate('students');

    // Get video progress for all students (populate without field selection to include virtuals)
    const progressRecords = await VideoProgress.find({ videoId: video._id })
      .populate('userId');

    console.log(`📊 Analytics for video ${video._id}:`, {
      totalStudents: course.students.length,
      progressRecordsFound: progressRecords.length,
      studentIds: course.students.map(s => s._id.toString()),
      progressUserIds: progressRecords.map(p => p.userId?._id.toString())
    });

    // Create a map of student progress
    const progressMap = new Map();
    progressRecords.forEach(progress => {
      if (progress.userId) {
        progressMap.set(progress.userId._id.toString(), {
          studentId: progress.userId._id,
          studentName: progress.userId.fullName,
          email: progress.userId.email,
          profilePicture: progress.userId.profilePicture,
          completionPercentage: progress.completionPercentage,
          lastWatchedPosition: progress.lastWatchedPosition,
          completed: progress.completionPercentage >= 75, // 75% threshold
          lastUpdated: progress.updatedAt
        });
      }
    });

    // Count students who have watched (any progress)
    const studentsWithProgress = course.students.filter(student => 
      progressMap.has(student._id.toString())
    ).length;

    // Build analytics data
    const analytics = {
      videoId: video._id,
      videoTitle: video.title,
      totalStudents: course.students.length,
      studentsWatched: studentsWithProgress,
      studentsCompleted: progressRecords.filter(p => p.completionPercentage >= 75).length,
      completionRate: course.students.length > 0 
        ? Math.round((progressRecords.filter(p => p.completionPercentage >= 75).length / course.students.length) * 100)
        : 0,
      students: course.students.map(student => {
        const studentId = student._id.toString();
        const progress = progressMap.get(studentId);
        
        return {
          studentId: student._id,
          studentName: student.fullName,
          email: student.email,
          profilePicture: student.profilePicture,
          watched: !!progress,
          completionPercentage: progress ? progress.completionPercentage : 0,
          completed: progress ? progress.completed : false,
          lastWatchedPosition: progress ? progress.lastWatchedPosition : 0,
          lastUpdated: progress ? progress.lastUpdated : null
        };
      }).sort((a, b) => {
        // Sort: completed first, then by completion percentage
        if (a.completed !== b.completed) return b.completed - a.completed;
        return b.completionPercentage - a.completionPercentage;
      })
    };

    res.json(analytics);

  } catch (error) {
    console.error('Get video analytics error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

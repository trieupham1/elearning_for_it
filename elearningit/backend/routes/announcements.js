const express = require('express');
const Announcement = require('../models/Announcement');
const Group = require('../models/Group');
const Notification = require('../models/Notification');
const { authMiddleware, instructorOnly } = require('../middleware/auth');

const router = express.Router();

// Get announcements by course
router.get('/', authMiddleware, async (req, res) => {
  try {
    const { courseId } = req.query;
    
    let query = { courseId };
    
    if (req.user.role === 'student') {
      // Get student's groups
      const groups = await Group.find({ 
        courseId, 
        studentIds: req.user.userId 
      });
      const groupIds = groups.map(g => g._id);
      query.$or = [
        { groupIds: { $in: groupIds } },
        { groupIds: { $size: 0 } } // All students announcements
      ];
    }
    
    const announcements = await Announcement.find(query)
      .populate('authorId', 'fullName avatar')
      .populate('groupIds', 'name')
      .sort({ createdAt: -1 });
    
    res.json(announcements);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Get single announcement
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const announcement = await Announcement.findById(req.params.id)
      .populate('authorId', 'fullName avatar')
      .populate('groupIds', 'name');
    
    if (!announcement) {
      return res.status(404).json({ message: 'Announcement not found' });
    }
    
    res.json(announcement);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// Create announcement
router.post('/', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const announcement = new Announcement({
      ...req.body,
      authorId: req.user.userId
    });
    await announcement.save();
    
    // Send notifications to students
    // TODO: Implement notification system
    
    res.status(201).json(announcement);
  } catch (error) {
    res.status(400).json({ message: 'Error creating announcement', error: error.message });
  }
});

// Update announcement
router.put('/:id', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const announcement = await Announcement.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );
    
    if (!announcement) {
      return res.status(404).json({ message: 'Announcement not found' });
    }
    
    res.json(announcement);
  } catch (error) {
    res.status(400).json({ message: 'Error updating announcement', error: error.message });
  }
});

// Track announcement view
router.post('/:id/view', authMiddleware, async (req, res) => {
  try {
    const announcement = await Announcement.findById(req.params.id);
    
    if (!announcement) {
      return res.status(404).json({ message: 'Announcement not found' });
    }
    
    const alreadyViewed = announcement.viewedBy.some(
      v => v.userId.toString() === req.user.userId
    );
    
    if (!alreadyViewed) {
      announcement.viewedBy.push({
        userId: req.user.userId,
        viewedAt: new Date()
      });
      await announcement.save();
    }
    
    res.json({ message: 'View tracked' });
  } catch (error) {
    res.status(400).json({ message: 'Error tracking view', error: error.message });
  }
});

// Delete announcement
router.delete('/:id', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const announcement = await Announcement.findByIdAndDelete(req.params.id);
    
    if (!announcement) {
      return res.status(404).json({ message: 'Announcement not found' });
    }
    
    res.json({ message: 'Announcement deleted successfully' });
  } catch (error) {
    res.status(400).json({ message: 'Error deleting announcement', error: error.message });
  }
});

module.exports = router;
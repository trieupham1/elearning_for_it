// utils/notificationHelper.js
const Notification = require('../models/Notification');

/**
 * Helper functions to create notifications for various events
 */

// Notify students when new material is uploaded
async function notifyNewMaterial(courseId, courseName, materialTitle, studentIds) {
  const notifications = studentIds.map(studentId => ({
    userId: studentId,
    type: 'material',
    title: 'New Material Available',
    message: `New material "${materialTitle}" uploaded in ${courseName}`,
    data: {
      courseId,
      courseName,
      materialTitle
    }
  }));

  return await Notification.createBulkNotifications(notifications);
}

// Notify students when new announcement is posted
async function notifyNewAnnouncement(courseId, courseName, announcementTitle, studentIds) {
  const notifications = studentIds.map(studentId => ({
    userId: studentId,
    type: 'announcement',
    title: 'New Announcement',
    message: `New announcement in ${courseName}: ${announcementTitle}`,
    data: {
      courseId,
      courseName,
      announcementTitle
    }
  }));

  return await Notification.createBulkNotifications(notifications);
}

// Notify students when new assignment is created
async function notifyNewAssignment(courseId, courseName, assignmentTitle, dueDate, studentIds) {
  const notifications = studentIds.map(studentId => ({
    userId: studentId,
    type: 'assignment',
    title: 'New Assignment',
    message: `New assignment "${assignmentTitle}" in ${courseName}. Due: ${dueDate}`,
    data: {
      courseId,
      courseName,
      assignmentTitle,
      dueDate
    }
  }));

  return await Notification.createBulkNotifications(notifications);
}

// Notify students when new quiz is available
async function notifyNewQuiz(courseId, courseName, quizTitle, studentIds) {
  const notifications = studentIds.map(studentId => ({
    userId: studentId,
    type: 'quiz',
    title: 'New Quiz Available',
    message: `New quiz "${quizTitle}" is now available in ${courseName}`,
    data: {
      courseId,
      courseName,
      quizTitle
    }
  }));

  return await Notification.createBulkNotifications(notifications);
}

// Notify instructor when student submits assignment
async function notifyAssignmentSubmission(instructorId, courseName, assignmentTitle, studentName, submissionId) {
  return await Notification.createNotification({
    userId: instructorId,
    type: 'submission',
    title: 'New Assignment Submission',
    message: `${studentName} submitted "${assignmentTitle}" in ${courseName}`,
    data: {
      courseName,
      assignmentTitle,
      studentName,
      submissionId
    }
  });
}

// Notify instructor when student completes quiz
async function notifyQuizAttempt(instructorId, courseName, quizTitle, studentName, score, attemptId) {
  return await Notification.createNotification({
    userId: instructorId,
    type: 'quiz_attempt',
    title: 'Quiz Completed',
    message: `${studentName} completed "${quizTitle}" in ${courseName}. Score: ${score}`,
    data: {
      courseName,
      quizTitle,
      studentName,
      score,
      attemptId
    }
  });
}

// Notify user when they receive a new comment
async function notifyNewComment(userId, commenterName, topicTitle, commentText, courseId) {
  return await Notification.createNotification({
    userId,
    type: 'comment',
    title: 'New Comment',
    message: `${commenterName} commented on "${topicTitle}": ${commentText.substring(0, 50)}...`,
    data: {
      commenterName,
      topicTitle,
      courseId
    }
  });
}

// Notify user when they receive a private message
async function notifyPrivateMessage(recipientId, senderName, messagePreview) {
  return await Notification.createNotification({
    userId: recipientId,
    type: 'message',
    title: 'New Message',
    message: `${senderName}: ${messagePreview.substring(0, 100)}...`,
    data: {
      senderName
    }
  });
}

// Notify instructor when student requests to join course via code
async function notifyJoinRequest(instructorId, studentName, studentId, courseName, courseId) {
  return await Notification.createNotification({
    userId: instructorId,
    type: 'message',
    title: 'Course Join Request',
    message: `${studentName} is requesting to join ${courseName}`,
    data: {
      studentName,
      studentId,
      courseName,
      courseId,
      isJoinRequest: true
    }
  });
}

// Notify student when instructor approves join request
async function notifyJoinApproved(studentId, courseName, courseId) {
  return await Notification.createNotification({
    userId: studentId,
    type: 'message',
    title: 'Join Request Approved',
    message: `Your request to join ${courseName} has been approved!`,
    data: {
      courseName,
      courseId
    }
  });
}

module.exports = {
  notifyNewMaterial,
  notifyNewAnnouncement,
  notifyNewAssignment,
  notifyNewQuiz,
  notifyAssignmentSubmission,
  notifyQuizAttempt,
  notifyNewComment,
  notifyPrivateMessage,
  notifyJoinRequest,
  notifyJoinApproved
};

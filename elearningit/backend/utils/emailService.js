// ====================
// utils/emailService.js
// ====================
const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    this.transporter = nodemailer.createTransport({
      service: process.env.EMAIL_SERVICE || 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASSWORD
      }
    });
  }

  async sendEmail(to, subject, html) {
    try {
      const mailOptions = {
        from: process.env.EMAIL_FROM,
        to,
        subject,
        html
      };

      await this.transporter.sendMail(mailOptions);
      console.log(`Email sent to ${to}`);
      return true;
    } catch (error) {
      console.error('Email send error:', error);
      return false;
    }
  }

  async sendNewAnnouncementEmail(user, announcement, courseTitle) {
    const subject = `New Announcement: ${announcement.title}`;
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #1976D2; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background-color: #f5f5f5; }
          .button { display: inline-block; padding: 10px 20px; background-color: #1976D2; 
                    color: white; text-decoration: none; border-radius: 5px; margin-top: 15px; }
          .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>📢 New Announcement</h1>
          </div>
          <div class="content">
            <p>Hello ${user.fullName},</p>
            <p>A new announcement has been posted in <strong>${courseTitle}</strong>:</p>
            <h2>${announcement.title}</h2>
            <div>${announcement.content.substring(0, 200)}...</div>
            <a href="${process.env.FRONTEND_URL}/courses/${announcement.courseId}/announcements/${announcement._id}" 
               class="button">View Announcement</a>
          </div>
          <div class="footer">
            <p>Faculty of Information Technology - E-Learning System</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.sendEmail(user.email, subject, html);
  }

  async sendAssignmentDeadlineEmail(user, assignment, courseTitle, daysRemaining) {
    const subject = `Reminder: ${assignment.title} - Due in ${daysRemaining} days`;
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #FF9800; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background-color: #f5f5f5; }
          .deadline { background-color: #fff3cd; border-left: 4px solid #ff9800; 
                      padding: 15px; margin: 15px 0; }
          .button { display: inline-block; padding: 10px 20px; background-color: #FF9800; 
                    color: white; text-decoration: none; border-radius: 5px; margin-top: 15px; }
          .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>⏰ Assignment Deadline Reminder</h1>
          </div>
          <div class="content">
            <p>Hello ${user.fullName},</p>
            <p>This is a reminder about an upcoming assignment deadline in <strong>${courseTitle}</strong>:</p>
            <h2>${assignment.title}</h2>
            <div class="deadline">
              <strong>⚠️ Due in ${daysRemaining} days</strong><br>
              Deadline: ${new Date(assignment.deadline).toLocaleString()}
            </div>
            <p>${assignment.description}</p>
            <a href="${process.env.FRONTEND_URL}/courses/${assignment.courseId}/assignments/${assignment._id}" 
               class="button">View Assignment</a>
          </div>
          <div class="footer">
            <p>Faculty of Information Technology - E-Learning System</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.sendEmail(user.email, subject, html);
  }

  async sendQuizAvailableEmail(user, quiz, courseTitle) {
    const subject = `New Quiz Available: ${quiz.title}`;
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background-color: #f5f5f5; }
          .quiz-info { background-color: #e8f5e9; padding: 15px; margin: 15px 0; 
                       border-radius: 5px; }
          .button { display: inline-block; padding: 10px 20px; background-color: #4CAF50; 
                    color: white; text-decoration: none; border-radius: 5px; margin-top: 15px; }
          .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>📝 New Quiz Available</h1>
          </div>
          <div class="content">
            <p>Hello ${user.fullName},</p>
            <p>A new quiz is now available in <strong>${courseTitle}</strong>:</p>
            <h2>${quiz.title}</h2>
            <div class="quiz-info">
              <strong>Quiz Details:</strong><br>
              Duration: ${quiz.duration} minutes<br>
              Attempts allowed: ${quiz.maxAttempts}<br>
              Opens: ${new Date(quiz.openDate).toLocaleString()}<br>
              Closes: ${new Date(quiz.closeDate).toLocaleString()}
            </div>
            <p>${quiz.description}</p>
            <a href="${process.env.FRONTEND_URL}/courses/${quiz.courseId}/quizzes/${quiz._id}" 
               class="button">Take Quiz</a>
          </div>
          <div class="footer">
            <p>Faculty of Information Technology - E-Learning System</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.sendEmail(user.email, subject, html);
  }

  async sendSubmissionConfirmationEmail(user, assignment, submission, courseTitle) {
    const subject = `Submission Confirmed: ${assignment.title}`;
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #2196F3; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background-color: #f5f5f5; }
          .confirmation { background-color: #e3f2fd; padding: 15px; margin: 15px 0; 
                          border-radius: 5px; border-left: 4px solid #2196F3; }
          .button { display: inline-block; padding: 10px 20px; background-color: #2196F3; 
                    color: white; text-decoration: none; border-radius: 5px; margin-top: 15px; }
          .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>✅ Submission Confirmed</h1>
          </div>
          <div class="content">
            <p>Hello ${user.fullName},</p>
            <p>Your submission for <strong>${assignment.title}</strong> in ${courseTitle} has been received.</p>
            <div class="confirmation">
              <strong>Submission Details:</strong><br>
              Attempt: ${submission.attemptNumber} of ${assignment.maxAttempts}<br>
              Submitted: ${new Date(submission.submittedAt).toLocaleString()}<br>
              Status: ${submission.isLate ? '⚠️ Late Submission' : '✓ On Time'}<br>
              Files submitted: ${submission.files.length}
            </div>
            ${submission.isLate ? '<p style="color: #ff9800;">⚠️ Note: This was a late submission.</p>' : ''}
            <a href="${process.env.FRONTEND_URL}/courses/${assignment.courseId}/assignments/${assignment._id}" 
               class="button">View Submission</a>
          </div>
          <div class="footer">
            <p>Faculty of Information Technology - E-Learning System</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.sendEmail(user.email, subject, html);
  }

  async sendGradeFeedbackEmail(user, assignment, submission, courseTitle) {
    const subject = `Assignment Graded: ${assignment.title}`;
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #9C27B0; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background-color: #f5f5f5; }
          .grade { background-color: #f3e5f5; padding: 20px; margin: 15px 0; 
                   border-radius: 5px; text-align: center; }
          .grade-score { font-size: 48px; font-weight: bold; color: #9C27B0; }
          .feedback { background-color: white; padding: 15px; margin: 15px 0; 
                      border-radius: 5px; border-left: 4px solid #9C27B0; }
          .button { display: inline-block; padding: 10px 20px; background-color: #9C27B0; 
                    color: white; text-decoration: none; border-radius: 5px; margin-top: 15px; }
          .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>📊 Assignment Graded</h1>
          </div>
          <div class="content">
            <p>Hello ${user.fullName},</p>
            <p>Your assignment <strong>${assignment.title}</strong> in ${courseTitle} has been graded.</p>
            <div class="grade">
              <p style="margin: 0; color: #666;">Your Grade</p>
              <div class="grade-score">${submission.grade}</div>
            </div>
            ${submission.feedback ? `
              <div class="feedback">
                <strong>Instructor Feedback:</strong><br>
                ${submission.feedback}
              </div>
            ` : ''}
            <a href="${process.env.FRONTEND_URL}/courses/${assignment.courseId}/assignments/${assignment._id}" 
               class="button">View Details</a>
          </div>
          <div class="footer">
            <p>Faculty of Information Technology - E-Learning System</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.sendEmail(user.email, subject, html);
  }
}

module.exports = new EmailService();
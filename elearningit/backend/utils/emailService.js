// ====================
// utils/emailService.js
// ====================
const nodemailer = require('nodemailer');
const { Resend } = require('resend');
const brevo = require('@getbrevo/brevo');

// Helper function to extract ObjectId string from either a string or populated object
function getIdString(idOrObject) {
  if (!idOrObject) return '';
  if (typeof idOrObject === 'string') return idOrObject;
  if (idOrObject._id) return idOrObject._id.toString();
  if (idOrObject.toString) return idOrObject.toString();
  return '';
}

class EmailService {
  constructor() {
    // Check if email is configured
    this.isConfigured = !!(
      (process.env.EMAIL_SERVICE && process.env.EMAIL_USER && process.env.EMAIL_PASSWORD) ||
      process.env.RESEND_API_KEY ||
      process.env.SENDGRID_API_KEY ||
      process.env.BREVO_API_KEY ||
      process.env.BREVO_SMTP_KEY
    );

    if (!this.isConfigured) {
      console.warn('⚠️ Email service not configured. Set EMAIL credentials, RESEND_API_KEY, BREVO_API_KEY, or SENDGRID_API_KEY in .env file');
      console.warn('⚠️ Email notifications will be skipped until configuration is complete');
      return;
    }

    try {
      // Option 1: Brevo HTTP API (works on Render free tier - recommended)
      // Can use BREVO_API_KEY (preferred) or fallback to BREVO_SMTP_KEY
      const brevoApiKey = process.env.BREVO_API_KEY || process.env.BREVO_SMTP_KEY;
      if (brevoApiKey && (process.env.BREVO_API_KEY || process.env.USE_BREVO_HTTP === 'true')) {
        // Use the Brevo HTTP API directly with fetch
        this.brevoApiKey = brevoApiKey;
        this.useBrevoAPI = true;
        console.log('✅ Email service initialized with Brevo HTTP API');
      }
      // Option 2: Resend HTTP API (requires verified domain)
      else if (process.env.RESEND_API_KEY) {
        this.resend = new Resend(process.env.RESEND_API_KEY);
        this.useResendAPI = true;
        console.log('✅ Email service initialized with Resend HTTP API');
      }
      // Option 3: Brevo SMTP (may not work on Render free tier)
      else if (process.env.BREVO_SMTP_KEY) {
        this.transporter = nodemailer.createTransport({
          host: 'smtp-relay.brevo.com',
          port: 587,
          secure: false,
          auth: {
            user: process.env.BREVO_SMTP_USER || process.env.EMAIL_USER,
            pass: process.env.BREVO_SMTP_KEY
          }
        });
        console.log('✅ Email service initialized with Brevo SMTP');
      }
      // Option 4: SendGrid (free 100 emails/day)
      else if (process.env.SENDGRID_API_KEY) {
        this.transporter = nodemailer.createTransport({
          host: 'smtp.sendgrid.net',
          port: 587,
          auth: {
            user: 'apikey',
            pass: process.env.SENDGRID_API_KEY
          }
        });
        console.log('✅ Email service initialized with SendGrid');
      }
      // Option 5: Gmail with App Password
      else {
        this.transporter = nodemailer.createTransport({
          service: process.env.EMAIL_SERVICE || 'gmail',
          auth: {
            user: process.env.EMAIL_USER,
            pass: process.env.EMAIL_PASSWORD
          }
        });
        console.log('✅ Email service initialized with', process.env.EMAIL_SERVICE || 'gmail');
      }
    } catch (error) {
      console.error('❌ Failed to initialize email service:', error.message);
      this.isConfigured = false;
    }
  }

  async sendEmail(to, subject, html) {
    if (!this.isConfigured) {
      console.log(`📧 Email would be sent to ${to}: ${subject} (Email not configured)`);
      return false;
    }

    try {
      const fromEmail = process.env.EMAIL_FROM || process.env.EMAIL_USER || 'noreply@example.com';
      const fromName = 'E-Learning System';
      
      // Option 1: Use Brevo HTTP API (works on Render free tier - bypasses SMTP port blocking)
      if (this.useBrevoAPI && this.brevoApiKey) {
        const response = await fetch('https://api.brevo.com/v3/smtp/email', {
          method: 'POST',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'api-key': this.brevoApiKey
          },
          body: JSON.stringify({
            sender: { name: fromName, email: fromEmail },
            to: [{ email: to }],
            subject: subject,
            htmlContent: html
          })
        });
        
        if (!response.ok) {
          const errorData = await response.json();
          throw new Error(errorData.message || `HTTP ${response.status}`);
        }
        
        console.log(`✅ Email sent via Brevo API to ${to}: ${subject}`);
        return true;
      }
      
      // Option 2: Use Resend HTTP API
      if (this.useResendAPI && this.resend) {
        const { data, error } = await this.resend.emails.send({
          from: `${fromName} <${fromEmail}>`,
          to: [to],
          subject,
          html
        });
        
        if (error) {
          console.error(`❌ Resend API error to ${to}:`, error.message);
          return false;
        }
        
        console.log(`✅ Email sent to ${to}: ${subject}`);
        return true;
      }
      
      // Option 3: Use nodemailer for SMTP (Brevo SMTP, SendGrid, Gmail)
      const mailOptions = {
        from: `${fromName} <${fromEmail}>`,
        to,
        subject,
        html
      };

      await this.transporter.sendMail(mailOptions);
      console.log(`✅ Email sent to ${to}: ${subject}`);
      return true;
    } catch (error) {
      console.error(`❌ Email send error to ${to}:`, error.message);
      return false;
    }
  }

  async sendNewAnnouncementEmail(user, announcement, courseTitle) {
    const courseId = getIdString(announcement.courseId);
    const announcementId = getIdString(announcement._id);
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
            <p>A new announcement has been posted in <strong>${courseTitle || 'your course'}</strong>:</p>
            <h2>${announcement.title}</h2>
            <div>${announcement.content ? announcement.content.substring(0, 200) + '...' : ''}</div>
            <a href="${process.env.FRONTEND_URL}/#/courses/${courseId}/announcements/${announcementId}" 
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

  async sendNewAssignmentEmail(user, assignment, courseTitle) {
    const subject = `New Assignment: ${assignment.title}`;
    const deadlineDate = new Date(assignment.deadline);
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #2196F3; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background-color: #f5f5f5; }
          .assignment-info { background-color: #e3f2fd; padding: 15px; margin: 15px 0; 
                             border-radius: 5px; border-left: 4px solid #2196F3; }
          .button { display: inline-block; padding: 10px 20px; background-color: #2196F3; 
                    color: white; text-decoration: none; border-radius: 5px; margin-top: 15px; }
          .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>📝 New Assignment Posted</h1>
          </div>
          <div class="content">
            <p>A new assignment has been posted in <strong>${courseTitle}</strong>:</p>
            <h2>${assignment.title}</h2>
            <div class="assignment-info">
              <strong>Assignment Details:</strong><br>
              ${assignment.description ? assignment.description.substring(0, 200) + '...' : 'No description provided'}<br><br>
              <strong>📅 Deadline:</strong> ${deadlineDate.toLocaleString()}<br>
              ${assignment.maxScore ? `<strong>📊 Max Score:</strong> ${assignment.maxScore} points<br>` : ''}
            </div>
            <a href="${process.env.FRONTEND_URL}/#/courses/${getIdString(assignment.courseId)}/assignments/${getIdString(assignment._id)}" 
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
            <p>This is a reminder about an upcoming assignment deadline in <strong>${courseTitle || 'your course'}</strong>:</p>
            <h2>${assignment.title}</h2>
            <div class="deadline">
              <strong>⚠️ Due in ${daysRemaining} days</strong><br>
              Deadline: ${new Date(assignment.deadline).toLocaleString()}
            </div>
            <p>${assignment.description || ''}</p>
            <a href="${process.env.FRONTEND_URL}/#/courses/${getIdString(assignment.courseId)}/assignments/${getIdString(assignment._id)}" 
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
            <p>A new quiz is now available in <strong>${courseTitle}</strong>:</p>
            <h2>${quiz.title}</h2>
            <div class="quiz-info">
              <strong>Quiz Details:</strong><br>
              Duration: ${quiz.duration} minutes<br>
              Attempts allowed: ${quiz.maxAttempts}<br>
              Opens: ${new Date(quiz.openDate).toLocaleString()}<br>
              Closes: ${new Date(quiz.closeDate).toLocaleString()}
            </div>
            <p>${quiz.description || ''}</p>
            <a href="${process.env.FRONTEND_URL}/#/courses/${getIdString(quiz.courseId)}/quizzes/${getIdString(quiz._id)}" 
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
            <p>Your submission for <strong>${assignment.title}</strong> in ${courseTitle || 'your course'} has been received.</p>
            <div class="confirmation">
              <strong>Submission Details:</strong><br>
              Attempt: ${submission.attemptNumber} of ${assignment.maxAttempts}<br>
              Submitted: ${new Date(submission.submittedAt).toLocaleString()}<br>
              Status: ${submission.isLate ? '⚠️ Late Submission' : '✓ On Time'}<br>
              Files submitted: ${submission.files ? submission.files.length : 0}
            </div>
            ${submission.isLate ? '<p style="color: #ff9800;">⚠️ Note: This was a late submission.</p>' : ''}
            <a href="${process.env.FRONTEND_URL}/#/courses/${getIdString(assignment.courseId)}/assignments/${getIdString(assignment._id)}" 
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
            <p>Your assignment <strong>${assignment.title}</strong> in ${courseTitle || 'your course'} has been graded.</p>
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
            <a href="${process.env.FRONTEND_URL}/#/courses/${getIdString(assignment.courseId)}/assignments/${getIdString(assignment._id)}" 
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

  async sendPasswordResetEmail(user, resetCode) {
    const subject = 'Password Reset Verification Code - E-Learning System';
    
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #FF5722; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background-color: #f5f5f5; }
          .warning { background-color: #fff3cd; border-left: 4px solid #ff9800; 
                     padding: 15px; margin: 15px 0; }
          .code-box { background-color: #e3f2fd; border: 2px solid #2196f3; 
                      padding: 20px; margin: 20px 0; text-align: center; border-radius: 10px; }
          .verification-code { font-size: 32px; font-weight: bold; color: #1976d2; 
                               letter-spacing: 8px; font-family: monospace; }
          .footer { padding: 20px; text-align: center; font-size: 12px; color: #666; }
          .security-note { background-color: #e8f5e9; padding: 15px; margin: 15px 0; 
                           border-left: 4px solid #4caf50; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🔐 Password Reset Code</h1>
          </div>
          <div class="content">
            <p>We received a request to reset your password for your E-Learning System account.</p>
            
            <div class="warning">
              <strong>⚠️ Important:</strong> If you did not request this password reset, please ignore this email. Your account is still secure.
            </div>
            
            <p>Use the following verification code to reset your password:</p>
            
            <div class="code-box">
              <p style="margin: 0; color: #666; font-size: 14px;">Your Verification Code:</p>
              <div class="verification-code">${resetCode}</div>
              <p style="margin: 10px 0 0 0; color: #666; font-size: 12px;">Enter this code in the password reset form</p>
            </div>
            
            <div class="security-note">
              <strong>🔒 Security Information:</strong><br>
              • This code will expire in 15 minutes for security reasons<br>
              • You can only use this code once<br>
              • If the code expires, you can request a new password reset<br>
              • Never share this code with anyone
            </div>
            
            <p><strong>How to use this code:</strong></p>
            <ol>
              <li>Go back to the password reset page in your browser</li>
              <li>Enter your email address</li>
              <li>Enter the verification code: <strong>${resetCode}</strong></li>
              <li>Set your new password</li>
            </ol>
            
            <p>If you're having trouble, please contact your instructor or system administrator.</p>
          </div>
          <div class="footer">
            <p>Faculty of Information Technology - E-Learning System</p>
            <p>This is an automated message, please do not reply to this email.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.sendEmail(user.email, subject, html);
  }
}

module.exports = new EmailService();
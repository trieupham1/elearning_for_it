// Test email configuration
require('dotenv').config();
const emailService = require('./utils/emailService'); // Import the instance directly

async function testEmail() {
  
  // Replace with your test email
  const testEmail = 'trieup920@gmail.com'; // Testing with sender's own email
  
  try {
    console.log('Testing email configuration...');
    console.log('');
    console.log('📧 Email Service Configuration:');
    if (process.env.RESEND_API_KEY) {
      console.log('   Using: Resend');
      console.log('   API Key: ' + process.env.RESEND_API_KEY.substring(0, 10) + '...');
    } else if (process.env.SENDGRID_API_KEY) {
      console.log('   Using: SendGrid');
    } else {
      console.log('   Using: Gmail/SMTP');
      console.log('   EMAIL_USER:', process.env.EMAIL_USER);
      console.log('   EMAIL_SERVICE:', process.env.EMAIL_SERVICE);
    }
    console.log('   EMAIL_FROM:', process.env.EMAIL_FROM);
    console.log('');
    
    const result = await emailService.sendEmail(
      testEmail,
      'Test Email from E-Learning System',
      `
        <h2>🎉 Test Email Successful!</h2>
        <p>If you receive this email, your email configuration is working correctly!</p>
        <p><strong>Service Used:</strong> ${process.env.RESEND_API_KEY ? 'Resend' : process.env.SENDGRID_API_KEY ? 'SendGrid' : 'Gmail/SMTP'}</p>
        <p><strong>Sent at:</strong> ${new Date().toLocaleString()}</p>
      `
    );
    
    if (result) {
      console.log('✅ Email sent successfully to', testEmail);
    } else {
      console.log('❌ Email failed to send');
    }
  } catch (error) {
    console.error('❌ Email test failed:', error.message);
  }
}

testEmail();
// ============================================
// SEED SPECIFIC STUDENT ACCOUNT - Tran Manh Khang
// ============================================

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const dotenv = require('dotenv');

// Load environment variables from parent directory
dotenv.config({ path: '../.env' });

// Import User model
const User = require('../models/User');

const SALT_ROUNDS = 10;

async function seedAdminAccount() {
  try {
    // Check if MONGODB_URI is available
    if (!process.env.MONGODB_URI) {
      console.error('❌ MONGODB_URI environment variable not found');
      console.error('Please make sure you have a .env file in the backend directory with MONGODB_URI');
      process.exit(1);
    }

    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✓ Connected to MongoDB Atlas');

    // Check if user already exists
    const existingUser = await User.findOne({ 
      $or: [
        { email: 'adminHR@example.com' },
        { username: 'admin' }
      ]
    });

    if (existingUser) {
      console.log('⚠️ User already exists with this email or username');
      console.log('Existing user:', {
        username: existingUser.username,
        email: existingUser.email,
        fullName: `${existingUser.firstName} ${existingUser.lastName}`
      });
      
      // Ask if want to update
      console.log('\nWould you like to update the existing user? (Delete and recreate)');
      // For this script, we'll just update the existing one
      await User.deleteOne({ _id: existingUser._id });
      console.log('✓ Deleted existing user');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash('admin123', SALT_ROUNDS);

    // Create your student account
    const khangStudent = await User.create({
      username: 'NguyenVanAn',
      password: hashedPassword,
      role: 'admin',
      firstName: 'NguyenVan',
      lastName: 'An',
      email: 'adminHR@example.com',
      profilePicture: 'https://ui-avatars.com/api/?name=NguyenVan+An&size=200',
      phoneNumber: '+84123456789',
      department: 'Faculty of Information Technology',
      bio: 'Hiring Manager Admin Account',
      isActive: true
    });
  } catch (error) {
    console.error('❌ Error creating admin account:', error);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log('\nDatabase connection closed');
    process.exit(0);
  }
}

// Run the function
seedAdminAccount();
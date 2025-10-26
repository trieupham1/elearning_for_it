// ============================================
// E-LEARNING DATABASE IMPORT SCRIPT
// Import data from exported JSON files
// ============================================

const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config({ path: '../.env' });

// Import all models
const User = require('../models/User');
const Semester = require('../models/Semester');
const Course = require('../models/Course');
const Group = require('../models/Group');
const Announcement = require('../models/Announcement');
const Assignment = require('../models/Assignment');
const Submission = require('../models/Submission');
const Question = require('../models/Question');
const Quiz = require('../models/Quiz');
const QuizAttempt = require('../models/QuizAttempt');
const Material = require('../models/Material');
const ForumTopic = require('../models/ForumTopic');
const ForumReply = require('../models/ForumReply');
const Message = require('../models/Message');
const Notification = require('../models/Notification');
const Comment = require('../models/Comment');

// Import configuration
const IMPORT_CONFIG = {
  clearExistingData: false, // Set to true to clear collections before import
  validateData: true,
  continueOnError: true,
  importPath: './exports',
  useCompleteFile: true // Use complete_database_export.json or individual files
};

async function importDatabase() {
  try {
    console.log('🚀 Starting database import...\n');

    // Check if MONGODB_URI is available
    if (!process.env.MONGODB_URI) {
      console.error('❌ MONGODB_URI environment variable not found');
      console.error('Please make sure you have a .env file in the backend directory with MONGODB_URI');
      process.exit(1);
    }

    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✓ Connected to MongoDB Atlas');

    const importDir = path.join(__dirname, IMPORT_CONFIG.importPath);
    
    if (!fs.existsSync(importDir)) {
      console.error(`❌ Import directory not found: ${importDir}`);
      console.error('Please run the export script first or check the import path');
      process.exit(1);
    }

    // Define collections with their models (order matters for relationships)
    const collections = [
      { name: 'users', model: User },
      { name: 'semesters', model: Semester },
      { name: 'courses', model: Course },
      { name: 'groups', model: Group },
      { name: 'announcements', model: Announcement },
      { name: 'assignments', model: Assignment },
      { name: 'materials', model: Material },
      { name: 'questions', model: Question },
      { name: 'quizzes', model: Quiz },
      { name: 'submissions', model: Submission },
      { name: 'quizAttempts', model: QuizAttempt },
      { name: 'forumTopics', model: ForumTopic },
      { name: 'forumReplies', model: ForumReply },
      { name: 'messages', model: Message },
      { name: 'notifications', model: Notification },
      { name: 'comments', model: Comment }
    ];

    let importData = {};
    const stats = {};

    // Load import data
    if (IMPORT_CONFIG.useCompleteFile) {
      const completeFilePath = path.join(importDir, 'complete_database_export.json');
      
      if (fs.existsSync(completeFilePath)) {
        console.log('📂 Loading complete database export file...');
        const completeData = JSON.parse(fs.readFileSync(completeFilePath, 'utf8'));
        
        console.log(`✓ Loaded export from: ${completeData.metadata.exportDate}`);
        console.log(`✓ Database: ${completeData.metadata.databaseName}`);
        
        importData = completeData.collections;
      } else {
        console.error('❌ Complete export file not found, falling back to individual files');
        IMPORT_CONFIG.useCompleteFile = false;
      }
    }

    // Load individual files if not using complete file
    if (!IMPORT_CONFIG.useCompleteFile) {
      console.log('📂 Loading individual collection files...');
      
      for (const collection of collections) {
        const fileName = `${collection.name}.json`;
        const filePath = path.join(importDir, fileName);
        
        if (fs.existsSync(filePath)) {
          const fileData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
          importData[collection.name] = fileData;
          console.log(`✓ Loaded ${collection.name} from ${fileName}`);
        } else {
          console.log(`⚠️ File not found: ${fileName}`);
        }
      }
    }

    // Import each collection
    for (const collection of collections) {
      try {
        const collectionData = importData[collection.name];
        
        if (!collectionData || !collectionData.data) {
          console.log(`⚠️ No data found for ${collection.name}, skipping...`);
          stats[collection.name] = { imported: 0, errors: 1, message: 'No data found' };
          continue;
        }

        console.log(`\n📊 Importing ${collection.name}...`);
        console.log(`  Records to import: ${collectionData.data.length}`);

        // Clear existing data if configured
        if (IMPORT_CONFIG.clearExistingData) {
          const deleteResult = await collection.model.deleteMany({});
          console.log(`  🗑️ Cleared ${deleteResult.deletedCount} existing records`);
        }

        let imported = 0;
        let errors = 0;
        const errorDetails = [];

        // Import records
        for (const record of collectionData.data) {
          try {
            // Validate data if configured
            if (IMPORT_CONFIG.validateData) {
              // Basic validation - ensure required fields exist
              if (!record._id) {
                throw new Error('Missing _id field');
              }
            }

            // Create or update record
            await collection.model.findOneAndUpdate(
              { _id: record._id },
              record,
              { upsert: true, new: true }
            );
            
            imported++;
          } catch (error) {
            errors++;
            errorDetails.push({
              record: record._id || 'unknown',
              error: error.message
            });

            if (!IMPORT_CONFIG.continueOnError) {
              throw error;
            }
          }
        }

        stats[collection.name] = {
          imported,
          errors,
          total: collectionData.data.length,
          errorDetails: errorDetails.slice(0, 5) // Keep first 5 error details
        };

        if (errors === 0) {
          console.log(`  ✅ Successfully imported ${imported} ${collection.name} records`);
        } else {
          console.log(`  ⚠️ Imported ${imported}/${collectionData.data.length} ${collection.name} records (${errors} errors)`);
          if (errorDetails.length > 0) {
            console.log(`    First error: ${errorDetails[0].error}`);
          }
        }

      } catch (error) {
        console.error(`❌ Error importing ${collection.name}:`, error.message);
        stats[collection.name] = { 
          imported: 0, 
          errors: 1, 
          message: error.message 
        };

        if (!IMPORT_CONFIG.continueOnError) {
          throw error;
        }
      }
    }

    // Generate import summary
    console.log('\n========================================');
    console.log('✅ DATABASE IMPORT COMPLETED!');
    console.log('========================================\n');

    console.log('📈 Import Statistics:');
    console.log('====================');

    let totalImported = 0;
    let totalErrors = 0;

    Object.entries(stats).forEach(([collection, stat]) => {
      totalImported += stat.imported || 0;
      totalErrors += stat.errors || 0;

      if (stat.message) {
        console.log(`${collection}: ${stat.message}`);
      } else {
        const status = stat.errors === 0 ? '✅' : '⚠️';
        console.log(`${status} ${collection}: ${stat.imported}/${stat.total} imported (${stat.errors} errors)`);
      }
    });

    console.log('\n📊 Summary:');
    console.log(`Total records imported: ${totalImported}`);
    console.log(`Total errors: ${totalErrors}`);

    if (totalErrors > 0) {
      console.log('\n⚠️ Some records failed to import. Check the detailed output above.');
      console.log('Common issues:');
      console.log('- Duplicate key errors (records already exist)');
      console.log('- Schema validation failures');
      console.log('- Reference integrity issues');
    }

    // Save import log
    const importLog = {
      importDate: new Date().toISOString(),
      config: IMPORT_CONFIG,
      statistics: stats,
      summary: {
        totalImported,
        totalErrors,
        collections: Object.keys(stats).length
      }
    };

    const logPath = path.join(importDir, 'import_log.json');
    fs.writeFileSync(logPath, JSON.stringify(importLog, null, 2));
    console.log(`\n📄 Import log saved to: ${logPath}`);

  } catch (error) {
    console.error('❌ Database import failed:', error);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔐 Database connection closed');
    process.exit(0);
  }
}

// Run the import
if (require.main === module) {
  console.log('⚠️ WARNING: This will import data into your database!');
  console.log('Current configuration:');
  console.log(`- Clear existing data: ${IMPORT_CONFIG.clearExistingData}`);
  console.log(`- Continue on error: ${IMPORT_CONFIG.continueOnError}`);
  console.log(`- Import path: ${IMPORT_CONFIG.importPath}`);
  console.log('\nPress Ctrl+C to cancel, or wait 5 seconds to continue...\n');

  setTimeout(() => {
    importDatabase();
  }, 5000);
}

module.exports = { importDatabase };
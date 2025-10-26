// ============================================
// E-LEARNING DATABASE EXPORT SCRIPT
// Export all collections with relationships and categories
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

// Export configuration
const EXPORT_CONFIG = {
  includePasswords: false, // Set to true if you want to export hashed passwords
  includeTimestamps: true,
  prettifyJson: true,
  separateFiles: true, // Export each collection to separate file
  exportPath: './exports'
};

async function exportDatabase() {
  try {
    console.log('🚀 Starting database export...\n');

    // Check if MONGODB_URI is available
    if (!process.env.MONGODB_URI) {
      console.error('❌ MONGODB_URI environment variable not found');
      console.error('Please make sure you have a .env file in the backend directory with MONGODB_URI');
      process.exit(1);
    }

    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✓ Connected to MongoDB Atlas');

    // Create export directory
    const exportDir = path.join(__dirname, EXPORT_CONFIG.exportPath);
    if (!fs.existsSync(exportDir)) {
      fs.mkdirSync(exportDir, { recursive: true });
      console.log(`✓ Created export directory: ${exportDir}`);
    }

    // Export data with statistics
    const exportData = {};
    const stats = {};

    // Define collections to export with their models
    const collections = [
      { name: 'users', model: User, category: 'Authentication' },
      { name: 'semesters', model: Semester, category: 'Academic Structure' },
      { name: 'courses', model: Course, category: 'Academic Structure' },
      { name: 'groups', model: Group, category: 'Academic Structure' },
      { name: 'announcements', model: Announcement, category: 'Course Content' },
      { name: 'assignments', model: Assignment, category: 'Course Content' },
      { name: 'submissions', model: Submission, category: 'Student Work' },
      { name: 'materials', model: Material, category: 'Course Resources' },
      { name: 'questions', model: Question, category: 'Assessment' },
      { name: 'quizzes', model: Quiz, category: 'Assessment' },
      { name: 'quizAttempts', model: QuizAttempt, category: 'Student Work' },
      { name: 'forumTopics', model: ForumTopic, category: 'Communication' },
      { name: 'forumReplies', model: ForumReply, category: 'Communication' },
      { name: 'messages', model: Message, category: 'Communication' },
      { name: 'notifications', model: Notification, category: 'System' },
      { name: 'comments', model: Comment, category: 'Interaction' }
    ];

    // Export each collection
    for (const collection of collections) {
      try {
        console.log(`📊 Exporting ${collection.name}...`);
        
        let data;
        if (collection.name === 'users' && !EXPORT_CONFIG.includePasswords) {
          // Export users without passwords
          data = await collection.model.find({}).select('-password').lean();
        } else {
          data = await collection.model.find({}).lean();
        }

        // Add metadata
        const collectionData = {
          metadata: {
            collection: collection.name,
            category: collection.category,
            exportDate: new Date().toISOString(),
            count: data.length,
            includesPasswords: collection.name === 'users' ? EXPORT_CONFIG.includePasswords : false
          },
          data: data
        };

        exportData[collection.name] = collectionData;
        stats[collection.name] = {
          category: collection.category,
          count: data.length
        };

        // Export to separate file if configured
        if (EXPORT_CONFIG.separateFiles) {
          const fileName = `${collection.name}.json`;
          const filePath = path.join(exportDir, fileName);
          
          fs.writeFileSync(
            filePath, 
            JSON.stringify(collectionData, null, EXPORT_CONFIG.prettifyJson ? 2 : 0)
          );
          
          console.log(`  ✓ Exported ${data.length} ${collection.name} records to ${fileName}`);
        }

      } catch (error) {
        console.error(`❌ Error exporting ${collection.name}:`, error.message);
        stats[collection.name] = { category: collection.category, count: 0, error: error.message };
      }
    }

    // Create complete export file
    const completeExport = {
      metadata: {
        exportDate: new Date().toISOString(),
        databaseName: process.env.MONGODB_URI.split('/').pop()?.split('?')[0] || 'unknown',
        totalCollections: collections.length,
        exportConfig: EXPORT_CONFIG,
        statistics: stats
      },
      collections: exportData
    };

    const completeFilePath = path.join(exportDir, 'complete_database_export.json');
    fs.writeFileSync(
      completeFilePath, 
      JSON.stringify(completeExport, null, EXPORT_CONFIG.prettifyJson ? 2 : 0)
    );

    // Generate export summary
    const summary = generateExportSummary(stats);
    const summaryPath = path.join(exportDir, 'export_summary.txt');
    fs.writeFileSync(summaryPath, summary);

    console.log('\n========================================');
    console.log('✅ DATABASE EXPORT COMPLETED SUCCESSFULLY!');
    console.log('========================================\n');

    // Display statistics by category
    console.log('📈 Export Statistics by Category:');
    console.log('==================================');
    
    const categorizedStats = {};
    Object.entries(stats).forEach(([collection, info]) => {
      if (!categorizedStats[info.category]) {
        categorizedStats[info.category] = [];
      }
      categorizedStats[info.category].push({
        collection,
        count: info.count,
        error: info.error
      });
    });

    Object.entries(categorizedStats).forEach(([category, collections]) => {
      console.log(`\n📂 ${category}:`);
      collections.forEach(col => {
        if (col.error) {
          console.log(`  ❌ ${col.collection}: ERROR - ${col.error}`);
        } else {
          console.log(`  ✓ ${col.collection}: ${col.count} records`);
        }
      });
    });

    console.log('\n📁 Export Files Created:');
    console.log('========================');
    console.log(`📄 Complete export: ${completeFilePath}`);
    console.log(`📄 Summary: ${summaryPath}`);
    
    if (EXPORT_CONFIG.separateFiles) {
      console.log('\n📁 Individual Collection Files:');
      collections.forEach(col => {
        const fileName = `${col.name}.json`;
        console.log(`  📄 ${exportDir}/${fileName}`);
      });
    }

    console.log('\n🎯 Export completed successfully!');
    console.log(`Total records exported: ${Object.values(stats).reduce((sum, stat) => sum + (stat.count || 0), 0)}`);

  } catch (error) {
    console.error('❌ Database export failed:', error);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔐 Database connection closed');
    process.exit(0);
  }
}

function generateExportSummary(stats) {
  const now = new Date().toISOString();
  const totalRecords = Object.values(stats).reduce((sum, stat) => sum + (stat.count || 0), 0);
  
  let summary = `E-LEARNING DATABASE EXPORT SUMMARY
==========================================
Export Date: ${now}
Total Collections: ${Object.keys(stats).length}
Total Records: ${totalRecords}

COLLECTION BREAKDOWN:
====================

`;

  // Group by category
  const categorized = {};
  Object.entries(stats).forEach(([collection, info]) => {
    if (!categorized[info.category]) {
      categorized[info.category] = [];
    }
    categorized[info.category].push({ collection, ...info });
  });

  Object.entries(categorized).forEach(([category, collections]) => {
    summary += `${category.toUpperCase()}:\n`;
    summary += '-'.repeat(category.length + 1) + '\n';
    
    collections.forEach(col => {
      if (col.error) {
        summary += `❌ ${col.collection}: ERROR - ${col.error}\n`;
      } else {
        summary += `✓ ${col.collection}: ${col.count} records\n`;
      }
    });
    summary += '\n';
  });

  summary += `EXPORT CONFIGURATION:
====================
Include Passwords: ${EXPORT_CONFIG.includePasswords}
Include Timestamps: ${EXPORT_CONFIG.includeTimestamps}
Prettify JSON: ${EXPORT_CONFIG.prettifyJson}
Separate Files: ${EXPORT_CONFIG.separateFiles}
Export Path: ${EXPORT_CONFIG.exportPath}

USAGE NOTES:
============
- Password fields are ${EXPORT_CONFIG.includePasswords ? 'INCLUDED' : 'EXCLUDED'} in user exports
- All ObjectIds are preserved for maintaining relationships
- Timestamps show original creation/modification dates
- Use this export for backup, migration, or development seeding

END OF SUMMARY
==============
`;

  return summary;
}

// Run the export
if (require.main === module) {
  exportDatabase();
}

module.exports = { exportDatabase };
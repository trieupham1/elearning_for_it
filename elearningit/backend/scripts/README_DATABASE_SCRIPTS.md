# Database Export/Import Scripts

This directory contains scripts for exporting and importing the complete e-learning database, including all categories and relationships.

## 📁 Available Scripts

### 1. Export Database (`export-database.js`)
Exports all collections from the MongoDB database to JSON files.

**Features:**
- Exports all 16 collections with categorization
- Preserves relationships (ObjectIds)
- Excludes passwords by default (configurable)
- Creates both individual files and complete export
- Generates detailed statistics and summary

**Usage:**
```bash
# Run export script
npm run export:db

# Or directly with node
node scripts/export-database.js
```

### 2. Import Database (`import-database.js`)
Imports data from exported JSON files back into MongoDB.

**Features:**
- Imports from complete export file or individual files
- Preserves original ObjectIds and relationships
- Configurable data clearing and validation
- Error handling with detailed logging
- Creates import log for auditing

**Usage:**
```bash
# Run import script (with 5-second warning)
npm run import:db

# Or directly with node
node scripts/import-database.js
```

### 3. Seed Scripts
- `seed.js` - Complete database seeding with sample data
- `seed-khang.js` - Create specific student account

## 📊 Exported Collections by Category

### 🔐 Authentication
- **users** - All user accounts (students, instructors, admins)

### 🏫 Academic Structure
- **semesters** - Academic semesters/terms
- **courses** - Course definitions and details
- **groups** - Course groups and sections

### 📚 Course Content
- **announcements** - Course announcements
- **assignments** - Assignment definitions

### 📖 Course Resources
- **materials** - Course materials and files

### 📝 Assessment
- **questions** - Quiz/test questions
- **quizzes** - Quiz definitions

### 👨‍🎓 Student Work
- **submissions** - Assignment submissions
- **quizAttempts** - Quiz attempt records

### 💬 Communication
- **forumTopics** - Discussion forum topics
- **forumReplies** - Forum replies
- **messages** - Direct messages

### 🔔 System
- **notifications** - System notifications

### 🤝 Interaction
- **comments** - Comments on various content

## ⚙️ Configuration Options

### Export Configuration (`EXPORT_CONFIG`)
```javascript
{
  includePasswords: false,    // Include hashed passwords in export
  includeTimestamps: true,    // Include createdAt/updatedAt
  prettifyJson: true,         // Format JSON with indentation
  separateFiles: true,        // Create individual collection files
  exportPath: './exports'     // Export directory path
}
```

### Import Configuration (`IMPORT_CONFIG`)
```javascript
{
  clearExistingData: false,   // Clear collections before import
  validateData: true,         // Validate data before import
  continueOnError: true,      // Continue if individual records fail
  importPath: './exports',    // Import directory path
  useCompleteFile: true       // Use complete export or individual files
}
```

## 📁 Export File Structure

After running the export script, you'll find:

```
backend/scripts/exports/
├── complete_database_export.json   # Complete database in one file
├── export_summary.txt              # Human-readable summary
├── import_log.json                 # Import history (after imports)
├── users.json                      # Individual collection files
├── courses.json
├── assignments.json
├── ... (one file per collection)
```

## 🚀 Common Use Cases

### 1. **Database Backup**
```bash
# Create complete backup
npm run export:db

# This creates timestamped exports with all data and relationships
```

### 2. **Environment Migration**
```bash
# Export from production/staging
npm run export:db

# Copy exports folder to new environment
# Import to new database
npm run import:db
```

### 3. **Development Setup**
```bash
# Get data from existing system
npm run export:db

# Set up new development environment
npm run import:db
```

### 4. **Data Analysis**
```bash
# Export current state
npm run export:db

# Analyze JSON files with external tools
# Individual collection files in exports/ folder
```

## ⚠️ Important Notes

### Security
- **Passwords are excluded by default** from user exports
- Set `includePasswords: true` only if needed for complete restoration
- Always secure your export files - they contain sensitive data

### Data Integrity
- **ObjectIds are preserved** to maintain relationships
- Import order matters for referential integrity
- Use `clearExistingData: false` to avoid duplicate key errors

### Performance
- Large databases may take time to export/import
- Consider running during low-traffic periods
- Monitor disk space for export files

## 🔧 Troubleshooting

### Common Issues

1. **"No data found" errors**
   - Ensure export was completed successfully
   - Check export directory exists and contains files

2. **Duplicate key errors during import**
   - Set `clearExistingData: true` to clear before import
   - Or use `continueOnError: true` to skip duplicates

3. **Connection errors**
   - Verify `MONGODB_URI` in `.env` file
   - Ensure database is accessible

4. **Schema validation errors**
   - Check if database schema has changed
   - Set `validateData: false` to bypass validation

### Getting Help

Check the detailed console output during export/import for specific error messages and statistics.

## 📈 Export Statistics Example

```
📈 Export Statistics by Category:
==================================

📂 Authentication:
  ✓ users: 25 records

📂 Academic Structure:
  ✓ semesters: 4 records
  ✓ courses: 12 records
  ✓ groups: 8 records

📂 Course Content:
  ✓ announcements: 45 records
  ✓ assignments: 23 records

... (and so on)

Total records exported: 487
```

This comprehensive export/import system ensures you can safely backup, migrate, and restore your complete e-learning database with all relationships intact!
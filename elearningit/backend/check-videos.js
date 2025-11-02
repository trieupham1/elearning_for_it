// Check videos in MongoDB Atlas
const mongoose = require('mongoose');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI;

mongoose.connect(MONGODB_URI)
  .then(async () => {
    console.log('✅ Connected to MongoDB Atlas');
    
    const db = mongoose.connection.db;
    
    // List all collections
    const collections = await db.listCollections().toArray();
    console.log('\n📋 All collections:');
    collections.forEach(c => console.log('  -', c.name));
    
    // Check videos collection
    console.log('\n🎬 Checking videos collection...');
    const videos = await db.collection('videos').find({}).sort({createdAt: -1}).limit(10).toArray();
    console.log(`Found ${videos.length} videos`);
    
    if (videos.length > 0) {
      videos.forEach((v, i) => {
        console.log(`\n${i + 1}. Video:`);
        console.log('   ID:', v._id);
        console.log('   Title:', v.title);
        console.log('   FileID:', v.fileId);
        console.log('   CourseID:', v.courseId);
        console.log('   Created:', v.createdAt);
      });
    } else {
      console.log('❌ No videos found in database!');
    }
    
    // Check GridFS collections
    console.log('\n📦 Checking GridFS buckets...');
    const gridFSCollections = collections.filter(c => c.name.includes('.files'));
    
    for (const coll of gridFSCollections) {
      const count = await db.collection(coll.name).countDocuments();
      console.log(`\n${coll.name}: ${count} files`);
      
      if (count > 0) {
        const files = await db.collection(coll.name).find({}).sort({uploadDate: -1}).limit(5).toArray();
        files.forEach((f, i) => {
          console.log(`  ${i + 1}. ${f.filename} (${f._id}) - ${(f.length / 1024 / 1024).toFixed(2)} MB`);
        });
      }
    }
    
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ Error:', err);
    process.exit(1);
  });

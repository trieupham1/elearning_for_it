const mongoose = require('mongoose');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI;

async function inspectDatabase() {
  try {
    console.log('Connecting to:', MONGODB_URI.replace(/:[^:]*@/, ':****@'));
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    const db = mongoose.connection.db;
    
    // List all collections
    const collections = await db.listCollections().toArray();
    console.log('📚 Available collections:');
    collections.forEach(c => console.log('  -', c.name));
    console.log();
    
    // Check videos collection
    const videosCount = await db.collection('videos').countDocuments();
    console.log(`📹 Videos collection: ${videosCount} documents`);
    if (videosCount > 0) {
      const videos = await db.collection('videos').find({}).limit(5).toArray();
      console.log('Sample videos:', JSON.stringify(videos, null, 2));
    }
    console.log();
    
    // Try to find our specific video ID in any collection
    const videoId = '6906620fe2524328ca9b203d';
    console.log(`🔍 Searching for ID ${videoId} in all collections...`);
    
    for (const coll of collections) {
      const found = await db.collection(coll.name).findOne({
        _id: new mongoose.Types.ObjectId(videoId)
      });
      
      if (found) {
        console.log(`\n✅ FOUND in '${coll.name}' collection!`);
        console.log(JSON.stringify(found, null, 2));
      }
    }

    await mongoose.disconnect();
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

inspectDatabase();

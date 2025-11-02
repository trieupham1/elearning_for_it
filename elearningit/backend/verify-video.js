const mongoose = require('mongoose');

const MONGODB_URI = 'mongodb+srv://ggcl_elearning:elearning123@cluster0.0uni9.mongodb.net/elearning';

async function verifyVideoDuration() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const videoId = '6906620fe2524328ca9b203d';
    const db = mongoose.connection.db;
    
    const video = await db.collection('videos').findOne({ 
      _id: new mongoose.Types.ObjectId(videoId) 
    });
    
    if (video) {
      console.log('✅ Video found:');
      console.log('  ID:', video._id.toString());
      console.log('  Title:', video.title);
      console.log('  Duration:', video.duration, 'seconds');
      console.log('  Has Duration:', !!video.duration);
    } else {
      console.log('❌ Video not found');
    }

    await mongoose.disconnect();
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

verifyVideoDuration();

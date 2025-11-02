const mongoose = require('mongoose');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI;

async function fixVideoDuration() {
  try {
    console.log('Connecting to:', MONGODB_URI.replace(/:[^:]*@/, ':****@'));
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    const videoId = '6906620fe2524328ca9b203d';
    const duration = 13; // Video is 13 seconds long

    const db = mongoose.connection.db;
    
    const result = await db.collection('videos').findOneAndUpdate(
      { _id: new mongoose.Types.ObjectId(videoId) },
      { $set: { duration: duration } },
      { returnDocument: 'after' }
    );
    
    console.log('Raw result:', result);
    
    if (result && result.value) {
      console.log('\n✅ Video duration updated successfully!');
      console.log('  Video ID:', result.value._id.toString());
      console.log('  Title:', result.value.title);
      console.log('  Duration:', result.value.duration, 'seconds');
      console.log('  Updated At:', result.value.updatedAt);
    } else if (result && result.ok) {
      console.log('\n✅ Update command completed');
      // Verify by reading back
      const video = await db.collection('videos').findOne({ _id: new mongoose.Types.ObjectId(videoId) });
      console.log('  Video ID:', video._id.toString());
      console.log('  Title:', video.title);
      console.log('  Duration:', video.duration, 'seconds');
    } else {
      console.log('❌ Video not found');
    }

    await mongoose.disconnect();
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

fixVideoDuration();

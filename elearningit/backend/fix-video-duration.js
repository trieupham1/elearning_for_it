const mongoose = require('mongoose');

const MONGODB_URI = 'mongodb+srv://ggcl_elearning:elearning123@cluster0.0uni9.mongodb.net/elearning';

async function fixVideoDuration() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const videoId = '6906620fe2524328ca9b203d';
    const duration = 13; // Video is 13 seconds long

    // Update using the database directly
    const db = mongoose.connection.db;
    
    // First, find what collection the video is in
    const collections = ['videos', 'classwork', 'materials'];
    let updated = false;
    
    for (const collName of collections) {
      const result = await db.collection(collName).findOneAndUpdate(
        { _id: new mongoose.Types.ObjectId(videoId) },
        { $set: { duration: duration } },
        { returnDocument: 'after' }
      );
      
      if (result) {
        console.log(`✅ Found and updated in '${collName}' collection!`);
        console.log('  Video ID:', videoId);
        console.log('  Title:', result.title);
        console.log('  Duration:', result.duration, 'seconds');
        updated = true;
        break;
      }
    }
    
    if (!updated) {
      // Try with the Video model
      const Video = mongoose.model('Video', new mongoose.Schema({
        title: String,
        duration: Number
      }, { collection: 'videos', strict: false }));
      
      const doc = await Video.findByIdAndUpdate(
        videoId,
        { duration: duration },
        { new: true, upsert: false }
      );
      
      if (doc) {
        console.log('✅ Updated via Video model!');
        console.log('  Duration:', doc.duration);
        updated = true;
      }
    }
    
    if (!updated) {
      console.log('❌ Could not find video in any collection');
      console.log('Listing all collections...');
      const colls = await db.listCollections().toArray();
      console.log('Available collections:', colls.map(c => c.name));
    }

    await mongoose.disconnect();
    process.exit(updated ? 0 : 1);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

fixVideoDuration();

const mongoose = require('mongoose');

const MONGODB_URI = 'mongodb+srv://ggcl_elearning:elearning123@cluster0.0uni9.mongodb.net/elearning';

async function updateVideoDuration() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const videoId = '6906620fe2524328ca9b203d';
    const duration = 13; // seconds

    // Try updating directly using the collection
    const db = mongoose.connection.db;
    const result = await db.collection('videos').findOneAndUpdate(
      { _id: new mongoose.Types.ObjectId(videoId) },
      { $set: { duration } },
      { returnDocument: 'after' }
    );

    console.log('Update result:', result);

    if (!result || !result._id) {
      console.log('❌ Video not found in videos collection');
      console.log('Checking classwork collection...');
      
      // Check classwork collection
      const classworkItem = await db.collection('classwork').findOne({ _id: new mongoose.Types.ObjectId(videoId) });
      
      if (classworkItem) {
        console.log('✅ Found as classwork item!', classworkItem);
        
        // Update the duration in classwork
        const updateResult = await db.collection('classwork').findOneAndUpdate(
          { _id: new mongoose.Types.ObjectId(videoId) },
          { $set: { duration } },
          { returnDocument: 'after' }
        );
        
        console.log('✅ Classwork item updated:', updateResult);
        process.exit(0);
      }
      
      console.log('❌ Not found in classwork either');
      console.log('Searching for videos collection...');
      const count = await db.collection('videos').countDocuments();
      console.log('Total videos in collection:', count);
      
      if (count > 0) {
        const allVideos = await db.collection('videos').find({}).limit(5).toArray();
        console.log('Sample videos:', allVideos);
      }
      process.exit(1);
    }

    console.log('✅ Video duration updated successfully:');
    console.log('  Video ID:', result._id.toString());
    console.log('  Title:', result.title);
    console.log('  Duration:', result.duration, 'seconds');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }
}

updateVideoDuration();

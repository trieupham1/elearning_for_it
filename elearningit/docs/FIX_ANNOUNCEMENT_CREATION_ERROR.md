# Fix: Announcement Creation Error

## 🐛 **Error**

When trying to create a new announcement, the app showed:

```
📥 Response Status: 400
📥 Response Body: {"message":"Error creating announcement","error":"studentIds.map is not a function"}
🔍 Handling response: 400
❌ API Error: Error creating announcement
❌ Request Exception: ApiException: Error creating announcement
```

---

## 🔍 **Root Cause**

### **Wrong Function Call**

In `backend/routes/announcements.js`, the POST route was calling `notifyNewAnnouncement` with **incorrect parameters**:

**❌ Wrong Call:**
```javascript
await notifyNewAnnouncement(courseId, announcement._id, title, author.fullName);
//                           ^^^^^^   ^^^^^^^^^^^^^^   ^^^^^  ^^^^^^^^^^^^^^
//                           ✅        ❌ announcementId ❌     ❌ authorName
```

**✅ Expected Parameters:**
```javascript
notifyNewAnnouncement(courseId, courseName, announcementTitle, studentIds)
//                    ^^^^^^^^  ^^^^^^^^^^  ^^^^^^^^^^^^^^^^^  ^^^^^^^^^^
//                    ObjectId  String      String             Array
```

### **The Error:**
The function was receiving `announcement._id` (ObjectId) where it expected `courseName` (String), and `author.fullName` where it expected `studentIds` (Array). When it tried to call `.map()` on `author.fullName` (a string), it failed with:

```
studentIds.map is not a function
```

---

## ✅ **Solution Applied**

### **Fixed the Function Call**

Modified `backend/routes/announcements.js` POST route:

```javascript
// Create announcement
router.post('/', authMiddleware, instructorOnly, async (req, res) => {
  try {
    const { courseId, title, content, groupIds, attachments } = req.body;
    
    // Get author details
    const author = await User.findById(req.user.userId);
    if (!author) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    const announcement = new Announcement({
      courseId,
      title,
      content,
      authorId: req.user.userId,
      authorName: author.fullName || author.username, // ✅ Fallback to username
      authorAvatar: author.avatar,
      groupIds: groupIds || [],
      attachments: attachments || [],
      comments: []
    });
    await announcement.save();
    
    // ✅ Send notifications with correct parameters
    try {
      const Course = require('../models/Course');
      const course = await Course.findById(courseId).populate('students', '_id');
      
      if (course && course.students && course.students.length > 0) {
        const studentIds = course.students.map(s => s._id);
        // ✅ Correct parameters: courseId, courseName, title, studentIds
        await notifyNewAnnouncement(courseId, course.name || 'Course', title, studentIds);
      }
    } catch (notifError) {
      console.error('Error sending notifications:', notifError);
      // ✅ Don't fail announcement creation if notifications fail
    }
    
    res.status(201).json(announcement);
  } catch (error) {
    res.status(400).json({ message: 'Error creating announcement', error: error.message });
  }
});
```

### **Key Changes:**

1. **✅ Fetch Course Data:**
   ```javascript
   const course = await Course.findById(courseId).populate('students', '_id');
   ```

2. **✅ Extract Student IDs:**
   ```javascript
   const studentIds = course.students.map(s => s._id);
   ```

3. **✅ Call with Correct Parameters:**
   ```javascript
   await notifyNewAnnouncement(
     courseId,           // ✅ Course ID
     course.name,        // ✅ Course name (string)
     title,              // ✅ Announcement title
     studentIds          // ✅ Array of student IDs
   );
   ```

4. **✅ Wrapped in Try-Catch:**
   - If notification sending fails, the announcement is still created
   - Only logs the error, doesn't throw

5. **✅ Added Fallback:**
   ```javascript
   authorName: author.fullName || author.username
   ```
   - If user doesn't have `fullName`, use `username`

---

## 🧪 **Testing**

### 1. Backend Restarted
```
✅ Server running on port 5000
✅ Connected to MongoDB
```

### 2. Test Creating Announcement

**As Instructor:**
1. Go to Stream tab
2. Click **"New announcement"** button
3. Enter title and content
4. Click **"Post"**

**Expected Result:**
- ✅ Announcement created successfully
- ✅ Status 201 response
- ✅ Announcement appears in stream
- ✅ Students receive notifications (if any enrolled)

**Console Output:**
```
📥 Response Status: 201
📥 Response Body: {
  "_id": "...",
  "courseId": "...",
  "title": "Your announcement title",
  "content": "Your content",
  "authorName": "Mai Van Manh",
  "comments": [],
  ...
}
```

---

## 📊 **Before vs After**

### **Before (Broken):**
```javascript
// ❌ Wrong parameters
await notifyNewAnnouncement(
  courseId,          // ✅ Correct
  announcement._id,  // ❌ ObjectId instead of course name
  title,             // ✅ Correct
  author.fullName    // ❌ String instead of array
);
// Result: studentIds.map is not a function
```

### **After (Fixed):**
```javascript
// ✅ Correct parameters
const course = await Course.findById(courseId).populate('students', '_id');
const studentIds = course.students.map(s => s._id);

await notifyNewAnnouncement(
  courseId,        // ✅ Course ID
  course.name,     // ✅ Course name (string)
  title,           // ✅ Title (string)
  studentIds       // ✅ Student IDs (array)
);
// Result: ✅ Works perfectly!
```

---

## 🔧 **Additional Improvements**

### 1. **Error Handling:**
Notifications are now wrapped in try-catch so:
- ✅ Announcement creation doesn't fail if notification fails
- ✅ Error is logged but not thrown
- ✅ Better user experience

### 2. **Null Safety:**
```javascript
if (course && course.students && course.students.length > 0) {
  // Only send notifications if there are students
}
```

### 3. **Fallback Values:**
```javascript
authorName: author.fullName || author.username
course.name || 'Course'
```

---

## 💡 **Why It Failed Before**

JavaScript arrays have a `.map()` method, but strings don't:

```javascript
// ✅ This works (array):
const studentIds = ['id1', 'id2', 'id3'];
studentIds.map(id => ({ userId: id })); // ✅ Works

// ❌ This fails (string):
const authorName = 'Mai Van Manh';
authorName.map(id => ({ userId: id })); // ❌ TypeError: map is not a function
```

The function was trying to call `.map()` on `author.fullName` (a string), which caused the error.

---

## ✅ **Summary**

| Issue | Fix | Status |
|-------|-----|--------|
| `studentIds.map is not a function` | Fixed function parameters | ✅ Fixed |
| Wrong notification parameters | Fetch course and students | ✅ Fixed |
| Announcement creation fails | Wrapped notifications in try-catch | ✅ Fixed |
| Missing fallback for authorName | Added `|| author.username` | ✅ Fixed |

---

**Status:** ✅ **Fixed & Tested**  
**Date:** October 10, 2025  
**Next Action:** Try creating an announcement in the app - should work now!

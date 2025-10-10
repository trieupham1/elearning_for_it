# Quick Start Guide - Testing Your Integrated App

## 🚀 Start Everything in 3 Steps

### Step 1: Start Backend Server
```powershell
cd backend
node server.js
```
✅ You should see:
```
Server running on port 5000
Connected to MongoDB
```

### Step 2: Start Flutter App
```powershell
cd ..
flutter run
```

### Step 3: Test Features
1. **Login** with an existing account
2. **Navigate to a course** from the dashboard
3. **Test each tab:**

---

## 🧪 Quick Feature Tests

### Stream Tab (Announcements)
1. Click **Stream** tab
2. See announcements load from backend ✅
3. **(Instructor only)** Click **"New announcement"** button
4. Fill title and content → Click **Post**
5. See announcement appear → Backend saved ✅
6. Click to expand → Add a comment
7. Comment appears → Backend saved ✅

### Classwork Tab
1. Click **Classwork** tab
2. See assignments/quizzes/materials load ✅
3. Type in **search box** → Results filter instantly ✅
4. Click **"Assignments"** chip → Only assignments show ✅
5. Click **"Quizzes"** chip → Only quizzes show ✅
6. Click **"All"** chip → Everything shows ✅

### People Tab
1. Click **People** tab
2. See **Teachers** section with instructors ✅
3. See **Classmates** section with students ✅
4. Click **message icon** next to an instructor
5. Chat screen opens ✅

### Chat Screen
1. Type a message
2. Click send button
3. Message appears in chat ✅
4. Backend saved message + sent notification ✅

---

## 🔍 What's Happening Behind the Scenes

### When you open Stream Tab:
```
1. StreamTab → AnnouncementService.getAnnouncements(courseId)
2. HTTP GET /api/announcements?courseId=<id>
3. Backend queries MongoDB
4. Returns JSON array of announcements
5. UI displays announcements
```

### When you create an announcement:
```
1. Click "New announcement" → Dialog appears
2. Fill form → Click Post
3. AnnouncementService.createAnnouncement(...)
4. HTTP POST /api/announcements
5. Backend saves to MongoDB
6. Backend triggers notifications to all students
7. UI reloads announcements
```

### When you search classwork:
```
1. Type in search box: "javascript"
2. ClassworkService.getClasswork(courseId, search: "javascript")
3. HTTP GET /api/classwork/course/:id?search=javascript
4. Backend searches titles and descriptions
5. Returns filtered results
6. UI displays matching items
```

### When you filter classwork:
```
1. Click "Assignments" chip
2. ClassworkService.getClasswork(courseId, filter: "assignments")
3. HTTP GET /api/classwork/course/:id?filter=assignments
4. Backend returns only assignments
5. UI displays assignments only
```

### When you send a message:
```
1. Type message → Click send
2. MessageService.sendMessage(receiverId, content)
3. HTTP POST /api/messages
4. Backend checks permissions (student → instructor only)
5. Backend saves message to MongoDB
6. Backend sends notification to receiver
7. UI reloads conversation
```

---

## ✅ Expected Behavior

### All Tabs:
- ✅ Show **loading indicator** while fetching data
- ✅ Show **"No data yet"** message if empty
- ✅ Show **error message** if API fails
- ✅ **Pull-to-refresh** reloads from backend

### Permissions:
- ✅ **Students** see "New announcement" button grayed out or hidden
- ✅ **Instructors** see "New announcement" button active
- ✅ **Students** can only message instructors (enforced by backend)
- ✅ **Instructors** can message anyone

### Notifications:
- ✅ New announcement → All students notified
- ✅ New comment → Announcement author notified
- ✅ New message → Receiver notified
- ✅ New assignment/quiz/material → All students notified

---

## 🚨 Common Issues & Fixes

### "No data showing"
**Check:**
1. Is backend running? → `cd backend && node server.js`
2. Is MongoDB connected? → Check backend terminal
3. Does the course have data? → Check MongoDB database
4. Are you logged in? → Try logging out and back in

### "401 Unauthorized"
**Fix:**
1. Log out and log back in
2. Check `lib/config/api_config.dart` has correct base URL
3. Token might be expired

### "Connection refused"
**Fix:**
1. Backend not running → Start with `node server.js`
2. Wrong URL → Check if using `localhost` vs `10.0.2.2` (Android emulator)
3. Port blocked → Make sure port 5000 is not in use

### Search/Filter not working
**Fix:**
1. Check backend terminal for errors
2. Make sure `/api/classwork` routes are registered
3. Try clearing search box and typing again

---

## 📱 Features by User Role

### Student Can:
- ✅ View announcements
- ✅ Add comments to announcements
- ✅ View all classwork
- ✅ Search and filter classwork
- ✅ View teachers and classmates
- ✅ Message **instructors only**
- ✅ View notifications

### Instructor Can:
- ✅ Everything students can do, PLUS:
- ✅ Create announcements
- ✅ Create assignments/quizzes/materials
- ✅ Message **anyone** (students and other instructors)
- ✅ View submission notifications
- ✅ View quiz attempt notifications

---

## 🎯 Key Files Reference

### Service Files (Make API calls):
- `lib/services/announcement_service.dart`
- `lib/services/classwork_service.dart`
- `lib/services/people_service.dart`
- `lib/services/message_service.dart`

### Screen Files (UI):
- `lib/screens/course_tabs/stream_tab.dart`
- `lib/screens/course_tabs/classwork_tab.dart`
- `lib/screens/course_tabs/people_tab.dart`
- `lib/screens/chat_screen.dart`

### Backend Routes:
- `backend/routes/announcements.js`
- `backend/routes/classwork.js`
- `backend/routes/courses.js` (people endpoint)
- `backend/routes/messages.js`

### Backend Models:
- `backend/models/Announcement.js`
- `backend/models/Assignment.js`
- `backend/models/Quiz.js`
- `backend/models/Material.js`
- `backend/models/Message.js`

---

## 💡 Pro Tips

1. **Check Console Logs**: Flutter console shows API calls and errors
2. **Check Backend Logs**: Backend terminal shows incoming requests
3. **Use Pull-to-Refresh**: Swipe down on any tab to reload data
4. **Test Permissions**: Login as both student and instructor to test
5. **Check Notifications**: Bell icon shows unread count

---

## 🎉 You're All Set!

Everything is integrated and ready to test. If you see data in the tabs, **congratulations!** Your full-stack integration is working perfectly! 🚀

**Need Help?** Check:
- `docs/BACKEND_API_INTEGRATION.md` - Full API documentation
- `docs/FRONTEND_BACKEND_INTEGRATION_COMPLETE.md` - Complete integration guide
- Backend terminal for error messages
- Flutter console for debug logs

Happy testing! 🎊

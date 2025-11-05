# Video Call Testing - Quick Reference Card

## 🎯 3-Minute Setup

### 1. Get PC IP (CMD)
```cmd
ipconfig
```
Look for: `IPv4 Address. . . : 192.168.x.x`

---

### 2. Update Flutter Config
File: `elearningit\lib\config\api_config.dart`

```dart
static String getBaseUrl() {
  const String pcIp = 'http://192.168.1.100:5000'; // YOUR IP HERE!
  
  if (kIsWeb) return _localBase;
  
  try {
    if (Platform.isAndroid) {
      return pcIp; // Changed from _androidEmulatorBase
    }
    return _localBase;
  } catch (e) {
    return _localBase;
  }
}
```

---

### 3. Update Backend Server
File: `elearningit\backend\server.js` (line ~103)

```javascript
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
```

---

### 4. Start & Test
```cmd
# Terminal 1: Start backend
cd elearningit\backend && npm run dev

# Terminal 2: Run on Android
cd elearningit && flutter run

# Terminal 3 (optional): Run on PC/Web
flutter run -d chrome
```

---

## ✅ Quick Verification

| Step | What | Where | Expected |
|------|------|-------|----------|
| 1 | Backend health | PC browser: `localhost:5000/api/health` | `{"status":"ok"}` |
| 2 | Network test | Android browser: `http://192.168.x.x:5000/api/health` | `{"status":"ok"}` |
| 3 | Socket.IO | Backend console | `🔌 Socket connected` |
| 4 | User register | Backend console | `✅ User registered` |
| 5 | Call works | Both devices | Video & audio ✅ |

---

## 🐛 Quick Troubleshooting

| Problem | Quick Fix |
|---------|-----------|
| "Cannot connect" | ✅ Same WiFi? ✅ Correct IP? ✅ Rebuilt app? |
| No video | Grant camera permission in Android settings |
| No audio | Grant microphone permission |
| Socket fails | Restart backend, clear app data |
| Still failing | Check `QUICK_START_VIDEO_CALL.md` |

---

## 📞 Test Sequence

```
1. PC: Login as User A
2. Android: Login as User B
3. PC: Click video call icon on User B
4. Android: Should see incoming call
5. Android: Click "Accept"
6. Both: Should see each other ✅
```

---

## 🔗 Full Documentation

- 📘 `QUICK_START_VIDEO_CALL.md` - Step-by-step guide
- 📗 `docs/VIDEO_CALL_TESTING_GUIDE.md` - Detailed testing
- 📙 `docs/VIDEO_CALL_TESTING_CHECKLIST.md` - Complete checklist
- 📕 `docs/VIDEO_CALL_ARCHITECTURE.md` - Architecture diagrams

---

## 💡 Remember

- ✅ Both devices on SAME WiFi
- ✅ Backend binds to `0.0.0.0`
- ✅ Flutter config has YOUR PC's IP
- ✅ Rebuild app after config changes
- ✅ Permissions granted (camera/mic)

---

**That's it! You should be testing calls in 5 minutes! 🚀**

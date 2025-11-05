# 📞 QUICK START - Testing Video Calls RIGHT NOW

## ⚡ 3-Minute Setup

### 1️⃣ Rebuild Your App (REQUIRED!)
```bash
# Stop current app if running (Ctrl+C)
# Then rebuild:
cd elearningit
flutter run
```

**Why rebuild?** We added Android permissions to manifest - hot restart won't apply them!

---

### 2️⃣ Grant Permissions (When Prompted)
When app first runs, Android will ask:
- ✅ **Allow Camera**
- ✅ **Allow Microphone**  
- ✅ **Allow Notifications** (Android 13+)

---

### 3️⃣ Test Your Setup

#### On Android Device:
1. Login to your account (e.g., `maivanmanh`)
2. Keep app open

#### On PC Web Browser:
1. Open `http://172.31.98.89:5000` (your backend URL)
2. Login with **different account**
3. Find your Android user and click **"Call"** button

#### What Should Happen:
📳 **Android device vibrates and shows notification**  
📱 **Incoming call screen appears** (if app is open)  
🔊 **You can answer or reject the call**

---

## 🐛 If Notification Doesn't Appear

### Quick Fix 1: Initialize WebRTC Socket
The notification needs WebRTC socket to be connected. Add this code:

**File: `lib/screens/student_home_screen.dart`** (or wherever user lands after login)

```dart
import '../../services/webrtc_service.dart';
import '../../utils/token_manager.dart';

class StudentHomeScreen extends StatefulWidget {
  // ... existing code ...
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final WebRTCService _webrtcService = WebRTCService();

  @override
  void initState() {
    super.initState();
    _initializeWebRTC(); // ⬅️ ADD THIS
  }

  // ⬅️ ADD THIS METHOD
  Future<void> _initializeWebRTC() async {
    final userId = await TokenManager().getUserId();
    if (userId != null) {
      print('🔌 Initializing WebRTC for user: $userId');
      await _webrtcService.initializeSocket(userId);
      print('✅ WebRTC socket initialized');
    }
  }

  // ... rest of existing code ...
}
```

### Quick Fix 2: Check Backend is Running
```bash
curl http://172.31.98.89:5000/api/health
```

Should return: `{"status":"ok"}`

### Quick Fix 3: Check Android Logs
Look for these logs in Flutter console:
```
🔌 Socket connected for WebRTC
📞 Incoming call: {...}
✅ Incoming call notification shown
```

---

## ✅ What We Fixed Today

1. **Network Connection** ✅
   - Fixed IP address from `192.168.1.224` → `172.31.98.89`
   - Your Android device can now reach backend server

2. **Android Permissions** ✅
   - Added all required permissions to AndroidManifest.xml
   - Camera, microphone, notifications, wake lock, etc.

3. **Notification System** ✅
   - Installed `flutter_local_notifications` package
   - Created `CallNotificationService` to show incoming calls
   - Updated `WebRTCService` to emit incoming call events

4. **Incoming Call UI** ✅
   - `IncomingCallScreen` already exists
   - Shows Answer/Reject buttons
   - Integrates with WebRTC service

---

## 📋 Testing Checklist

- [ ] Rebuilt app with `flutter run` (not just hot restart!)
- [ ] Granted camera/microphone permissions
- [ ] Logged in on Android device
- [ ] Backend running and accessible
- [ ] Tried making call from PC web browser
- [ ] Notification appeared on Android? ✅
- [ ] Could answer call? ✅
- [ ] Video/audio working? ✅

---

## 🆘 Still Not Working?

### Check These Logs:

**Android (Flutter Console):**
```
✅ Login successful
🔄 Testing connection to http://172.31.98.89:5000...
✅ Connection test successful!
🔌 Socket connected for WebRTC
```

**If you see `❌ Connection test failed` or `❌ Socket disconnected`:**
- Backend might be down
- Run: `cd backend && npm run dev`

---

## 🎯 Summary

| Component | Status |
|-----------|--------|
| Network connectivity | ✅ Fixed (IP: 172.31.98.89) |
| Android permissions | ✅ Added to manifest |
| Notification package | ✅ Installed |
| WebRTC service | ✅ Updated with stream |
| Incoming call screen | ✅ Exists |
| **Socket initialization** | ⚠️ **YOU NEED TO ADD** |

---

## 📞 Next Steps

1. **Rebuild app now**: `flutter run`
2. **Add WebRTC initialization** (see Quick Fix 1 above)
3. **Test call from PC to Android**
4. **Verify notification appears**

---

**Once you add the WebRTC initialization after login, incoming calls will work perfectly! 🚀**

Need help? Check these docs:
- `INCOMING_CALL_FIX_COMPLETE.md` - Full implementation details
- `FINAL_CALL_IMPLEMENTATION.md` - Complete technical reference
- `NETWORK_CONNECTIVITY_FIX.md` - Network troubleshooting

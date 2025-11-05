# Quick Start: Testing Video Calls Between PC and Android

## 🎯 Quick Overview
You have a working video call system using WebRTC and Socket.IO. To test between your PC and Android device, follow these steps:

---

## ⚠️ CRITICAL: Do This First!

### Step 1: Find Your PC's IP Address

Open **Command Prompt (CMD)** and run:
```cmd
ipconfig
```

Look for **"IPv4 Address"** under your active WiFi adapter. It will look like:
```
IPv4 Address. . . . . . . . . . . : 192.168.1.100
```

**Write down this IP address!** You'll need it in the next step.

---

### Step 2: Update Flutter API Configuration

Open this file in VS Code:
```
elearningit\lib\config\api_config.dart
```

**Find this section (around line 30):**
```dart
static String getBaseUrl() {
  if (kIsWeb) {
    return _localBase;
  }

  try {
    if (Platform.isAndroid) {
      return _androidEmulatorBase;  // <-- CHANGE THIS LINE
    }
    return _localBase;
  } catch (e) {
    return _localBase;
  }
}
```

**Change to this (add your IP at the top and modify the return line):**
```dart
static String getBaseUrl() {
  // ⚠️ REPLACE WITH YOUR PC'S ACTUAL IP ADDRESS
  const String pcIp = 'http://192.168.1.100:5000'; // <-- PUT YOUR IP HERE!
  
  if (kIsWeb) {
    return _localBase;
  }

  try {
    if (Platform.isAndroid) {
      return pcIp;  // <-- Changed to use PC's IP
    }
    return _localBase;
  } catch (e) {
    return _localBase;
  }
}
```

**Save the file!** ✅

---

### Step 3: Make Backend Accessible to Android

Open this file:
```
elearningit\backend\server.js
```

**Find this line (around line 103):**
```javascript
const server = app.listen(PORT, () => {
```

**Change it to:**
```javascript
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Access from Android: http://<YOUR_PC_IP>:${PORT}`);
});
```

This allows the backend to accept connections from other devices on your network.

**Save the file!** ✅

---

## 🚀 Start Testing

### Step 4: Start Backend Server

Open **Command Prompt** in VS Code (Terminal → New Terminal):

```cmd
cd elearningit\backend
npm run dev
```

**Expected output:**
```
Server running on port 5000
✓ Socket.IO server initialized
✓ WebRTC signaling server initialized
```

**Keep this terminal running!**

---

### Step 5: Test Backend Connectivity

**On your PC** - Open browser and go to:
```
http://localhost:5000/api/health
```

**On your Android device** - Open browser (Chrome/Firefox) and go to:
```
http://192.168.1.100:5000/api/health
```
(Replace `192.168.1.100` with YOUR PC's IP)

Both should show a success response (like `{"status":"ok"}`).

❌ **If Android shows "Cannot connect":**
- Make sure both devices are on the **SAME WiFi network**
- Check Windows Firewall (temporarily disable to test)
- Verify you used the correct IP address

---

### Step 6: Build and Run Flutter App

#### For Android Device:

1. **Connect your Android device via USB**
2. **Enable USB Debugging** on Android (Settings → Developer Options)
3. **Run these commands:**

```cmd
cd elearningit
flutter clean
flutter pub get
flutter run
```

Select your Android device when prompted.

⏱️ This will take 2-5 minutes for first build.

#### For PC (Web):

Open a **second terminal** and run:
```cmd
cd elearningit
flutter run -d chrome
```

---

### Step 7: Test Video Call! 🎥

#### Login as Different Users:

1. **PC (Chrome):** Login as `instructor@example.com` / password
2. **Android:** Login as `student@example.com` / password

*(Use your actual test accounts)*

#### Initiate Call:

**From PC:**
1. Navigate to Messages/Chat
2. Find the student user
3. Click the **video camera icon** 📹

**On Android:**
You should:
- See incoming call notification
- Hear ringtone
- See caller's name
- Have "Accept" and "Reject" buttons

**Accept the call!**

#### Expected Result: ✅

- Both users see each other's video
- Audio works in both directions
- You can see call duration timer
- Connection status shows "Connected"

---

## 🎮 Test All Features

While in the call, test:

| Feature | Button | Expected Result |
|---------|--------|----------------|
| **Mute/Unmute** | 🎤 Microphone icon | Other user can't hear you |
| **Video On/Off** | 📹 Camera icon | Other user sees black screen |
| **Switch Camera** | 🔄 (Android only) | Switches front/back camera |
| **Speaker** | 🔊 (Android only) | Toggles speaker mode |
| **End Call** | ☎️ Red button | Call ends for both users |

---

## 🐛 Common Issues & Quick Fixes

### Issue: "Cannot connect to server" on Android

**Fix:**
1. Verify both devices on same WiFi
2. Double-check IP address in `api_config.dart`
3. Rebuild app: `flutter clean && flutter pub get && flutter run`

### Issue: "Socket connection failed"

**Check backend console** - should show:
```
🔌 Socket connected: <socket_id>
✅ User <userId> registered with socket <socket_id>
```

**If not:**
- Restart backend server
- Clear app data on Android
- Check CORS settings (should allow "*")

### Issue: "No video or audio"

**Fix:**
1. **Android:** Settings → Apps → Your App → Permissions → Allow Camera & Microphone
2. **PC (Web):** Allow camera/microphone when browser prompts
3. Check if another app is using camera

### Issue: Call connects but no video

**Check Flutter console** for these logs:
```dart
📹 Local stream obtained
📹 Remote stream obtained
🧊 ICE Connection State: connected
```

**If missing:**
- Check WebRTC permissions
- Verify STUN servers are accessible
- Check network inspector for WebRTC errors

---

## 📝 Testing Checklist

Before reporting success, verify:

- [ ] Call from PC → Android works
- [ ] Call from Android → PC works
- [ ] Video visible on both sides
- [ ] Audio clear on both sides
- [ ] Mute/unmute works
- [ ] Video on/off works
- [ ] End call works from either side
- [ ] Rejected call works
- [ ] Missed call (no answer) works
- [ ] Multiple calls in a row work

---

## 🔍 Debug Commands

**View Flutter logs:**
```cmd
flutter logs
```

**Check connected devices:**
```cmd
flutter devices
```

**Restart app on Android:**
```cmd
flutter run --hot
```

**View backend logs:**
Just watch the terminal where `npm run dev` is running

---

## 📚 Additional Resources

Created for you:
- 📄 `docs/VIDEO_CALL_TESTING_GUIDE.md` - Detailed guide with troubleshooting
- ✅ `docs/VIDEO_CALL_TESTING_CHECKLIST.md` - Complete testing checklist
- 🔧 `lib/config/api_config_testing.dart` - Template configuration file
- ⚡ `setup_video_call_test.bat` - Automated setup script

---

## 🎯 Expected Flow

```
1. User A (PC) clicks video call button
   ↓
2. Backend receives "call_initiated" via Socket.IO
   ↓
3. Backend sends "incoming_call" to User B (Android)
   ↓
4. User B sees incoming call screen
   ↓
5. User B clicks "Accept"
   ↓
6. Backend sends "call_answered" to User A
   ↓
7. WebRTC peer connection established
   ↓
8. ICE candidates exchanged
   ↓
9. Video/audio streams connected
   ↓
10. Both users see and hear each other ✅
```

---

## 🆘 Still Having Issues?

1. **Check this first:** Are both devices on same WiFi? (Most common issue!)
2. **Verify backend:** Can you access health endpoint from Android browser?
3. **Check logs:** What errors appear in backend console and Flutter console?
4. **Test Socket.IO:** Use online tool to test Socket.IO connection
5. **Firewall:** Temporarily disable Windows Firewall to test

---

## 💡 Pro Tips

1. **Use `flutter run` (not `flutter build`)** - Faster iteration during testing
2. **Keep backend terminal visible** - Watch for connection logs
3. **Use `flutter logs` in separate terminal** - See real-time Flutter logs
4. **Test on same WiFi as your router** - Not guest networks (often isolated)
5. **Use 5GHz WiFi if available** - Better for video streaming

---

**Good luck testing! 🚀**

If everything is configured correctly, you should have working video calls within 10-15 minutes!

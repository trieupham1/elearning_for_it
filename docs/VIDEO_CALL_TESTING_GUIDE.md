# Video/Audio Call Testing Guide - PC & Android Device

This guide will help you test the video/audio call functionality between your PC (web browser or desktop app) and your Android device.

## Prerequisites

### 1. Network Setup
Both devices must be on the **same local network** (same WiFi):
- PC: Connected to your WiFi network
- Android Device: Connected to the same WiFi network

### 2. Find Your PC's Local IP Address

**On Windows (CMD):**
```cmd
ipconfig
```
Look for "IPv4 Address" under your active network adapter (e.g., `192.168.1.100`)

**Common local IP ranges:**
- `192.168.x.x`
- `10.0.x.x`
- `172.16.x.x` to `172.31.x.x`

### 3. Backend Configuration

Make sure your backend server binds to `0.0.0.0` (all network interfaces) instead of `localhost`.

**Update `elearningit/backend/server.js`:**
```javascript
const PORT = process.env.PORT || 5000;
const HOST = '0.0.0.0'; // Important: bind to all interfaces

// ... (existing code)

const server = app.listen(PORT, HOST, () => {
  console.log(`Server running on http://0.0.0.0:${PORT}`);
  console.log(`Local IP: http://<YOUR_LOCAL_IP>:${PORT}`);
});
```

### 4. Flutter Configuration for Android

**Update `elearningit/lib/config/api_config.dart`:**

Replace the `getBaseUrl()` method with:
```dart
static String getBaseUrl() {
  // For testing with real Android device on same network
  // Replace with your PC's actual local IP address
  const String _pcLocalIp = 'http://192.168.1.100:5000'; // CHANGE THIS!
  
  if (kIsWeb) {
    return _localBase; // localhost:5000 for web
  }

  try {
    if (Platform.isAndroid) {
      // For Android Emulator, use 10.0.2.2
      // For Real Android Device, use PC's local IP
      // Uncomment the appropriate line:
      
      // return _androidEmulatorBase; // For emulator testing
      return _pcLocalIp; // For real device testing
    }
    return _localBase; // For iOS or other platforms
  } catch (e) {
    return _localBase;
  }
}
```

## Testing Steps

### Step 1: Start the Backend Server

```cmd
cd elearningit\backend
npm install
npm run dev
```

Verify the server is running and note the port (default: 5000).

**Check that Socket.IO is working:**
You should see in the console:
```
✓ Socket.IO server initialized
✓ WebRTC signaling server initialized
```

### Step 2: Test Backend Accessibility

**From PC (in browser):**
```
http://localhost:5000/api/health
```

**From Android device (in browser):**
```
http://192.168.1.100:5000/api/health
```
(Replace `192.168.1.100` with your PC's actual IP)

Both should return a successful response.

### Step 3: Build and Run on Android

**Option A: Debug Mode (Recommended for testing)**
```cmd
cd elearningit
flutter pub get
flutter run
```
Select your Android device when prompted.

**Option B: Release Build**
```cmd
flutter build apk
flutter install
```

### Step 4: Run on PC

**Option A: Web (Chrome/Edge)**
```cmd
cd elearningit
flutter run -d chrome
```

**Option B: Windows Desktop**
```cmd
flutter run -d windows
```

### Step 5: Test the Call Feature

#### Create Two Test Accounts

1. **Device 1 (PC):** Login as User A (e.g., instructor@example.com)
2. **Device 2 (Android):** Login as User B (e.g., student@example.com)

#### Initiate a Video Call

1. On **PC** (User A):
   - Navigate to a chat or messaging screen
   - Find User B in the user list
   - Click the video call icon
   - You should see "Calling..." screen

2. On **Android** (User B):
   - You should receive an incoming call notification
   - You should hear the ringtone
   - Accept the call

3. **Expected Result:**
   - Both users should see each other's video
   - Audio should work in both directions
   - Connection status should show "Connected"

#### Test Call Features

Test the following during the call:

- ✅ **Mute/Unmute Audio:** Click the microphone icon
- ✅ **Enable/Disable Video:** Click the camera icon
- ✅ **Switch Camera (Android):** Click the camera switch icon
- ✅ **Speaker On/Off (Android):** Toggle speaker mode
- ✅ **End Call:** Click the red phone icon
- ✅ **Screen Sharing** (if implemented): Click the screen share icon

### Step 6: Test Different Scenarios

#### Test 1: Incoming Call While App is in Background
1. Put the app in background on Android
2. Initiate a call from PC
3. Verify that notification appears on Android

#### Test 2: Reject a Call
1. Initiate a call from PC
2. Reject it on Android
3. Verify that PC shows "Call rejected"

#### Test 3: Call Ended by Other User
1. Accept a call on both devices
2. End the call from one device
3. Verify that the other device receives "Call ended"

#### Test 4: Poor Network Conditions
1. Move Android device away from WiFi router
2. Observe connection quality indicators
3. Test if ICE candidates reconnect

## Common Issues & Solutions

### Issue 1: "Connection Failed" or "Cannot Connect"

**Possible Causes:**
- PC and Android are not on the same network
- Firewall blocking port 5000
- Backend not bound to 0.0.0.0

**Solutions:**
```cmd
# Check if port is accessible
# On Android, use a browser:
http://<PC_IP>:5000/api/health

# On PC, check Windows Firewall:
# Allow port 5000 for Node.js
```

### Issue 2: "Socket Connection Failed"

**Check Socket.IO Connection:**
```javascript
// In backend console, you should see:
🔌 Socket connected: <socket_id>
✅ User <userId> registered with socket <socket_id>
```

**If not appearing:**
- Check CORS settings in `backend/server.js`
- Verify Socket.IO client is using correct URL
- Check network inspector for WebSocket connection errors

### Issue 3: "No Video/Audio"

**Permissions:**
- Android: Grant Camera and Microphone permissions in app settings
- Web: Allow camera/microphone access in browser prompt

**Check Flutter WebRTC:**
```dart
// In WebRTCService, check console logs:
print('📹 Local stream obtained: $_localStream');
print('📹 Remote stream obtained: $_remoteStream');
```

### Issue 4: "ICE Connection Failed"

**STUN/TURN Server Issues:**
- Using public STUN servers (Google) should work for local network
- If still failing, check WebRTC debug logs

**Enable WebRTC Logging:**
```dart
// In webrtc_service.dart
_peerConnection!.onIceConnectionState = (state) {
  print('🧊 ICE Connection State: $state');
};
```

### Issue 5: Android Shows "10.0.2.2" Error

This means you're still using the emulator configuration on a real device.

**Fix:** Update `api_config.dart` to use your PC's local IP as shown in Step 4.

## Debugging Tips

### 1. Enable Verbose Logging

**Backend:**
```javascript
// In webrtcSignaling.js, add:
console.log('📊 Call initiated data:', data);
console.log('👥 Active user sockets:', Array.from(userSockets.keys()));
```

**Frontend:**
```dart
// In webrtc_service.dart, add:
print('🔍 Socket connected: ${_socket?.connected}');
print('🔍 Current user ID: $_currentUserId');
print('🔍 Other user ID: $_otherUserId');
```

### 2. Monitor Network Traffic

**Chrome DevTools (Web):**
- Open DevTools → Network → WS (WebSocket)
- Monitor Socket.IO messages

**Android:**
- Use `flutter logs` command
- Check Logcat for Flutter prints

### 3. Test Backend Independently

Use a tool like [Socket.IO Client Tool](https://amritb.github.io/socketio-client-tool/):
1. Connect to `http://<PC_IP>:5000`
2. Emit `register` event with a test user ID
3. Test `call_initiated` events

## Advanced Testing

### Load Testing
Test multiple simultaneous calls:
1. Use 3+ devices (PCs, Android devices, emulators)
2. Initiate multiple calls simultaneously
3. Monitor server CPU and memory usage

### Network Simulation
Test on poor networks:
```cmd
# Use Android Developer Options
# Enable "Network speed" throttling
# Test with "Slow 3G" or "Fast 3G"
```

### Production Deployment
When deploying to production:
1. Use HTTPS for backend (required for WebRTC on web)
2. Configure TURN servers (for NAT traversal)
3. Update `api_config.dart` with production URLs

## Quick Reference Commands

```cmd
# Start backend
cd elearningit\backend && npm run dev

# Run on Android (debug)
cd elearningit && flutter run

# Run on Web
flutter run -d chrome

# Run on Windows
flutter run -d windows

# Check Flutter devices
flutter devices

# Clean build
flutter clean && flutter pub get

# Check logs
flutter logs
```

## Contact & Support

If issues persist:
1. Check backend console for errors
2. Check Flutter console for errors
3. Review Socket.IO connection logs
4. Verify WebRTC peer connection states

---

**Remember:** For testing on the same local network, the most important steps are:
1. ✅ Find your PC's local IP address
2. ✅ Update `api_config.dart` with that IP
3. ✅ Ensure backend binds to `0.0.0.0`
4. ✅ Both devices on same WiFi network
5. ✅ Rebuild and reinstall the Flutter app on Android

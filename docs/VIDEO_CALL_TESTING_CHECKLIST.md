# Video Call Testing Checklist

Use this checklist to ensure everything is configured correctly for testing video calls between your PC and Android device.

## Pre-Testing Setup

### Network Configuration
- [ ] PC and Android device are connected to the **SAME WiFi network**
- [ ] Found PC's local IP address using `ipconfig` command
- [ ] IP address is in format: `192.168.x.x` or `10.0.x.x`

### Backend Configuration
- [ ] Backend server binds to `0.0.0.0` (not just `localhost`)
- [ ] Port 5000 is not blocked by Windows Firewall
- [ ] Backend dependencies installed (`npm install`)
- [ ] Backend starts without errors (`npm run dev`)

### Frontend Configuration
- [ ] Updated `lib/config/api_config.dart` with PC's local IP
- [ ] Used format: `http://192.168.x.x:5000` (replace x.x with your IP)
- [ ] Commented out emulator configuration (10.0.2.2)
- [ ] Ran `flutter pub get` after changes
- [ ] Rebuilt the app completely (`flutter clean` then `flutter run`)

### Device Setup
- [ ] Android device has USB debugging enabled
- [ ] Android device detected by Flutter (`flutter devices`)
- [ ] Camera permission granted on Android device
- [ ] Microphone permission granted on Android device
- [ ] PC browser (Chrome/Edge) has camera/microphone permissions

## Testing Checklist

### Basic Connectivity
- [ ] Backend server running and accessible from PC: `http://localhost:5000/api/health`
- [ ] Backend server accessible from Android browser: `http://192.168.x.x:5000/api/health`
- [ ] Socket.IO connection established (check backend console logs)

### User Setup
- [ ] Two test accounts created (e.g., instructor and student)
- [ ] PC logged in as User A
- [ ] Android device logged in as User B
- [ ] Both users can see each other in user list or chat

### Video Call Tests

#### Test 1: Basic Video Call (PC → Android)
- [ ] Initiated video call from PC
- [ ] Incoming call notification received on Android
- [ ] Ringtone plays on Android
- [ ] Accepted call on Android
- [ ] Video appears on both devices
- [ ] Audio works both directions
- [ ] Connection status shows "Connected"
- [ ] Call duration timer working

#### Test 2: Basic Video Call (Android → PC)
- [ ] Initiated video call from Android
- [ ] Incoming call notification received on PC
- [ ] Accepted call on PC
- [ ] Video appears on both devices
- [ ] Audio works both directions

#### Test 3: Call Controls
- [ ] Mute/unmute microphone works on both devices
- [ ] Enable/disable video works on both devices
- [ ] Switch camera (front/back) works on Android
- [ ] Speaker toggle works on Android
- [ ] End call works from both devices
- [ ] Call ends properly for both users

#### Test 4: Call Rejection
- [ ] Initiated call from one device
- [ ] Rejected call on other device
- [ ] Rejection notification received
- [ ] Both apps return to normal state

#### Test 5: Missed Call
- [ ] Initiated call from one device
- [ ] Did not answer on other device
- [ ] Call times out after ~30 seconds
- [ ] Missed call recorded

#### Test 6: Background/Foreground
- [ ] App in background on Android
- [ ] Incoming call notification appears
- [ ] Tapping notification opens app
- [ ] Call screen appears correctly
- [ ] Can accept call from notification

#### Test 7: Network Quality
- [ ] Call maintains quality with good WiFi
- [ ] Call adapts when device moves far from router
- [ ] ICE reconnection works
- [ ] Quality indicators update appropriately

### Audio-Only Call Tests
- [ ] Audio call initiated successfully
- [ ] Audio call accepted successfully
- [ ] Audio quality is clear
- [ ] All controls (mute, speaker, end) work

## Troubleshooting Checklist

If calls fail, check:

### Connection Issues
- [ ] Both devices can ping each other
- [ ] Windows Firewall not blocking port 5000
- [ ] Antivirus not blocking connections
- [ ] Router not isolating devices (AP isolation disabled)

### Socket.IO Issues
- [ ] Backend logs show: `🔌 Socket connected`
- [ ] Backend logs show: `✅ User registered with socket`
- [ ] Frontend logs show socket connection
- [ ] No CORS errors in browser console

### WebRTC Issues
- [ ] STUN servers accessible (Google STUN)
- [ ] ICE candidates being exchanged (check logs)
- [ ] Peer connection state is "connected"
- [ ] Local and remote streams are set

### Permission Issues
- [ ] Android app has camera permission
- [ ] Android app has microphone permission
- [ ] Android app has notification permission
- [ ] Browser has camera/microphone access
- [ ] No "Permission denied" errors in logs

### Media Issues
- [ ] Camera is not being used by another app
- [ ] Microphone is not being used by another app
- [ ] Device has working camera and microphone
- [ ] Video renderer is initialized

## Performance Checklist

- [ ] Call connects within 3-5 seconds
- [ ] Video latency is acceptable (< 500ms)
- [ ] Audio sync with video
- [ ] No audio echo or feedback
- [ ] CPU usage reasonable on both devices
- [ ] Battery drain acceptable on Android
- [ ] Memory usage stable (no leaks)

## Documentation Checklist

- [ ] Read `docs/VIDEO_CALL_TESTING_GUIDE.md`
- [ ] Understand Socket.IO signaling flow
- [ ] Understand WebRTC peer connection flow
- [ ] Know how to check logs on both platforms
- [ ] Know how to use browser DevTools for WebRTC debugging

## Post-Testing

- [ ] Document any issues found
- [ ] Note call quality metrics
- [ ] Test with multiple users if possible
- [ ] Verify call history is saved correctly
- [ ] Check database for call records

---

## Quick Command Reference

```bash
# Find PC IP (Windows CMD)
ipconfig

# Start backend
cd elearningit\backend && npm run dev

# Run on Android
cd elearningit && flutter run

# Run on Web
flutter run -d chrome

# Check devices
flutter devices

# View logs
flutter logs

# Rebuild completely
flutter clean && flutter pub get && flutter run
```

---

## Success Criteria

Video calling feature is working correctly if:
- ✅ Calls can be initiated from both devices
- ✅ Calls can be accepted/rejected
- ✅ Video and audio work bidirectionally
- ✅ All call controls function properly
- ✅ Connection is stable for at least 2 minutes
- ✅ Multiple consecutive calls work without issues
- ✅ App handles call end gracefully
- ✅ No memory leaks or crashes during calls

---

**Date Tested:** _______________
**Tester:** _______________
**Result:** [ ] Pass  [ ] Fail
**Notes:** 

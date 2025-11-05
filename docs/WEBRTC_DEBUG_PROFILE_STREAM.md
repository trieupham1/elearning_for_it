# WebRTC Debug and Fixes - Profile Avatar & Stream Issues

## Changes Made

### 1. Profile Picture URL Construction
**Problem:** Profile pictures not loading because they might be relative paths from backend.

**Fix Added:**
- Added `_profileImageUrl` getter in `IncomingCallScreen` that constructs full URLs
- Handles both relative paths (`/api/files/...`) and absolute URLs (`http://...`)
- Added error handling for NetworkImage with `onBackgroundImageError`

```dart
String? get _profileImageUrl {
  if (widget.caller.profilePicture == null || 
      widget.caller.profilePicture!.isEmpty) {
    return null;
  }
  
  final pic = widget.caller.profilePicture!;
  // If it's already a full URL, return it
  if (pic.startsWith('http://') || pic.startsWith('https://')) {
    return pic;
  }
  // Otherwise, construct full URL
  return '${ApiConfig.baseUrl}${pic.startsWith('/') ? '' : '/'}$pic';
}
```

### 2. Enhanced Logging
**Added comprehensive logs to trace data flow:**

**In `student_home_screen.dart`:**
```dart
print('📋 IncomingCall data:');
print('   - callerId: ${incomingCall.callerId}');
print('   - callerName: ${incomingCall.callerName}');
print('   - callerUsername: ${incomingCall.callerUsername}');
print('   - callerAvatar: ${incomingCall.callerAvatar}');
print('   - callType: ${incomingCall.callType}');
print('   - offer: ${incomingCall.offer != null}');
```

**In `incoming_call_screen.dart`:**
```dart
print('🔍 IncomingCallScreen - Caller Info:');
print('   ID: ${widget.caller.id}');
print('   Name: ${widget.caller.fullName}');
print('   Username: ${widget.caller.username}');
print('   Profile Picture Raw: ${widget.caller.profilePicture}');
print('   Profile Picture URL: $_profileImageUrl');
print('   Offer available: ${widget.offer != null}');
```

### 3. Added `onAddStream` Callback
**Problem:** Remote video stream might not be received on some devices.

**Fix:** Added compatibility callback alongside `onTrack`:

```dart
// Handle onAddStream for compatibility (some WebRTC versions use this)
_peerConnection!.onAddStream = (stream) {
  print('📹 Received remote stream via onAddStream');
  _remoteStream = stream;
  _remoteStreamController.add(_remoteStream!);
};
```

## Files Modified

1. ✅ `lib/screens/call/incoming_call_screen.dart`
   - Added `_profileImageUrl` getter for proper URL construction
   - Enhanced initState() with detailed logging
   - Added error handler for NetworkImage
   - Imported ApiConfig for base URL

2. ✅ `lib/screens/student_home_screen.dart`
   - Added detailed logging of IncomingCall data
   - Logs now show all caller information received from Socket.IO

3. ✅ `lib/screens/instructor_home_screen.dart`
   - Same logging fixes as student home screen

4. ✅ `lib/services/webrtc_service.dart`
   - Added `onAddStream` callback for compatibility
   - Enhanced logging in both `onTrack` and `onAddStream`

## Debugging Steps

### Step 1: Check What's Being Received
After making a call, check the logs:

```
📋 IncomingCall data:
   - callerId: 673d1234567890abcdef
   - callerName: John Doe
   - callerUsername: johndoe
   - callerAvatar: /api/files/673d1234567890abcdef  ← Check this
   - callType: video
   - offer: true
```

### Step 2: Check IncomingCallScreen
When incoming call screen appears:

```
🔍 IncomingCallScreen - Caller Info:
   ID: 673d1234567890abcdef
   Name: John Doe
   Username: johndoe
   Profile Picture Raw: /api/files/673d1234567890abcdef
   Profile Picture URL: http://172.31.98.89:5000/api/files/673d1234567890abcdef  ← Full URL
   Offer available: true
```

### Step 3: Check answerCall Execution
When you click Accept:

```
📞 Accepting call: 673d1234567890abcdef
📞 Calling answerCall with offer: true
📞 answerCall START - callId: 673d1234567890abcdef
📞 Creating peer connection...
📞 Initializing local media...
📞 Setting remote description (offer)...
✅ Remote description set
📞 Creating answer...
✅ Answer created and set as local description
📞 Sending answer via socket...
✅ answerCall COMPLETE - answer sent
```

### Step 4: Check Stream Reception
After connection established:

```
📹 Received remote track
📹 Setting remote stream from track event
OR
📹 Received remote stream via onAddStream
```

## Common Issues and Solutions

### Issue 1: Profile Picture Shows Initials Instead of Avatar

**Possible Causes:**
1. User hasn't set a profile picture (field is `null` or empty)
2. Profile picture path is incorrect
3. Image URL is not accessible from Android device

**Debug:**
- Check logs for "Profile Picture Raw" and "Profile Picture URL"
- If Raw is `null` → User has no avatar set
- If URL doesn't start with `http://172.31.98.89:5000` → URL construction failed
- Try accessing the URL in a browser from the Android device

### Issue 2: Connection Shows "Connected" But No Video

**Possible Causes:**
1. Remote stream not being received
2. Permissions issue (camera/mic not granted)
3. Stream not being added to peer connection tracks

**Debug:**
- Check for "📹 Received remote track" or "📹 Received remote stream" in logs
- If missing → Stream not being sent properly from caller side
- Check caller's logs for "📹 Local stream initialized"
- Verify both devices granted camera/microphone permissions

### Issue 3: answerCall Not Being Called

**This was the CRITICAL bug we fixed earlier!**

**Debug:**
- Look for "📞 Calling answerCall with offer: true" in logs
- If missing → answerCall() is not being called
- If present but no "📞 answerCall START" → Function crashed before executing
- Check for any error messages

## Testing Checklist

After rebuilding, test in this order:

- [ ] Make a call from PC to Android
- [ ] Check Android logs for "📋 IncomingCall data"
- [ ] Verify callerAvatar value in logs
- [ ] Accept the call
- [ ] Check for "📞 answerCall START" logs
- [ ] Verify "✅ answerCall COMPLETE" appears
- [ ] Check for "📹 Received remote track/stream" logs
- [ ] Verify video appears on both sides
- [ ] Check if profile picture loads correctly
- [ ] Test call from Android to PC (reverse direction)

## Next Steps

1. **If profile picture still doesn't load:**
   - Check the actual `profilePicture` value in MongoDB
   - Verify the file exists at that path
   - Test the URL directly in a browser
   - Check backend file serving endpoint

2. **If video still doesn't show:**
   - Check if `onAddStream` or `onTrack` is being triggered
   - Verify local stream is being added to peer connection
   - Check ICE candidate exchange is happening
   - Look for any WebRTC errors in logs

3. **If offer is null:**
   - Check backend webrtcSignaling.js
   - Verify offer is being passed in call_initiated event
   - Check Socket.IO event data structure

## Files to Monitor

**Backend Logs:**
```bash
cd backend
npm run dev
# Watch for:
# - "📞 Call initiated:"
# - "✅ Call accepted:"
```

**Android Logs:**
```bash
# In VS Code, open Debug Console while running app
# Or use: adb logcat | grep -E "📞|📹|🔍|📋"
```

---

**Summary:** We've added comprehensive debugging, fixed profile picture URL construction, and added stream handling compatibility. The connection is working (showing "Connected"), so now we need to verify the streams are being properly exchanged.

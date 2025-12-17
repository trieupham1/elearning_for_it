# Video Call Issues - Final Fixes

## Date: 2024
## Issues Resolved:
1. **Username Display Issue**: Users showing as "User ID" instead of actual names on first join
2. **Camera Not Visible After Screen Share**: Camera not showing to other users after stopping screen share

---

## Issue 1: Username Display Fix

### Problem
When users first joined a video call, they appeared as "User 181630024" instead of their actual name like "Nguyen Van B". Names only appeared correctly after rejoining the call.

### Root Cause
The backend Socket.IO handler for `share_agora_uid` was only using socket properties (`socket.userName` and `socket.userProfile`) instead of the data sent in the event payload. This created a race condition where the socket properties might not be set yet when the `share_agora_uid` event was emitted.

### Solution
Updated [backend/utils/webrtcSignaling.js](../backend/utils/webrtcSignaling.js) to use `userName` and `userProfile` from the event data payload first, falling back to socket properties if needed:

```javascript
// Before:
const mappingData = {
  userId,
  agoraUid,
  userName: socket.userName,
  userProfile: socket.userProfile,
};

// After:
if (userName) socket.userName = userName;
if (userProfile) socket.userProfile = userProfile;

const mappingData = {
  userId,
  agoraUid,
  userName: userName || socket.userName || `User ${userId}`,
  userProfile: userProfile || socket.userProfile,
};
```

**Files Changed:**
- `elearningit/backend/utils/webrtcSignaling.js` (lines 74-98)

---

## Issue 2: Camera Not Visible After Screen Share

### Problem
When a user stopped screen sharing, their camera did not become visible to other participants even though the camera was republished locally.

### Root Cause
Two issues:
1. The camera track was being republished on the sharer's side, but other clients weren't being explicitly notified to refresh their video views
2. No explicit signal was sent to indicate "camera is back on" - only the implicit Agora `user-published` event which might not trigger a UI refresh

### Solution

#### Backend Changes
Added a new Socket.IO event handler `camera_republished` in [backend/utils/webrtcSignaling.js](../backend/utils/webrtcSignaling.js):

```javascript
// Camera republished after screen share (notify others that camera is back on)
socket.on('camera_republished', (data) => {
  const { channelName, agoraUid, userId } = data;
  // Broadcast to others in the channel (not including sender)
  socket.to(channelName).emit('camera_republished', {
    agoraUid,
    userId,
  });
  console.log(`📹 User with Agora UID ${agoraUid} republished camera in ${channelName}`);
});
```

**Files Changed:**
- `elearningit/backend/utils/webrtcSignaling.js` (lines 134-143)

#### Frontend Changes

**1. Emit camera_republished event after screen share stops:**

Updated [lib/screens/video_call/web_course_video_call_screen.dart](../lib/screens/video_call/web_course_video_call_screen.dart) to emit the event when screen sharing stops:

```dart
// Listen for screen share state changes (e.g., browser stop button)
_webService!.screenShareState.listen((isSharing) async {
  final myUid = _webService!.localUid;
  if (mounted && myUid != null) {
    // ... existing code ...
    
    // If we stopped sharing and camera is on, notify that camera is republished
    if (!isSharing && _isVideoEnabled) {
      debugPrint('📹 Screen share stopped, notifying about camera republish');
      // Wait a bit for the camera to be republished
      await Future.delayed(const Duration(milliseconds: 800));
      _socket?.emit('camera_republished', {
        'channelName': _channelName,
        'agoraUid': myUid,
        'userId': widget.currentUser.id,
      });
    }
  }
});
```

**2. Listen for camera_republished event and refresh video view:**

Added listener to handle incoming `camera_republished` events:

```dart
// Listen for camera republished after screen share
_socket?.on('camera_republished', (data) {
  final rawAgoraUid = data['agoraUid'];
  if (mounted && rawAgoraUid != null) {
    final agoraUid = rawAgoraUid is int ? rawAgoraUid : int.tryParse(rawAgoraUid.toString());
    if (agoraUid != null) {
      debugPrint('📹 Camera republished for UID $agoraUid - triggering UI refresh');
      // Force a rebuild to show the camera video
      setState(() {
        // Update user status to reflect camera is on
        if (_userStatuses.containsKey(agoraUid)) {
          _userStatuses[agoraUid]!['isCameraOff'] = false;
        }
      });
      
      // Re-register the video view to ensure it plays
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _remoteUsers.contains(agoraUid)) {
          _registerRemoteVideoView(agoraUid);
        }
      });
    }
  }
});
```

**Files Changed:**
- `elearningit/lib/screens/video_call/web_course_video_call_screen.dart` (lines 186-211, 424-453)

---

## Testing Instructions

### Test Username Display
1. Open two browsers (e.g., Chrome and Firefox or two Chrome windows in different profiles)
2. Log in with different accounts in each browser
3. Join the same course video call from both browsers
4. **Expected**: User names should display correctly immediately upon join (e.g., "Nguyen Van B" not "User 181630024")

### Test Camera After Screen Share
1. Open two browsers with different accounts
2. Join the same course video call
3. In Browser A, start screen sharing
4. Verify Browser B can see the screen share
5. In Browser A, stop screen sharing
6. **Expected**: Browser B should immediately see Browser A's camera video again
7. The camera feed should be visible without any refresh or rejoin

---

## Technical Details

### Event Flow for Username
1. User joins call → `join_group_call` event emitted
2. Agora SDK joins channel → generates local UID
3. `share_agora_uid` event emitted **with userName and userProfile in payload**
4. Backend receives event → extracts userName/userProfile from data → broadcasts to all participants
5. All participants receive `agora_uid_mapped` with correct user info
6. UI updates to show real names immediately

### Event Flow for Camera Republish
1. User stops screen share → Agora service unpublishes screen track
2. Agora service republishes camera track
3. After 800ms delay, `camera_republished` event emitted via Socket.IO
4. Backend broadcasts event to other participants
5. Other participants receive event → update user status → re-register video view
6. Camera video displays correctly

---

## Additional Notes

- **Delay Timing**: The 800ms delay before emitting `camera_republished` ensures the Agora camera track is fully republished before notifying others
- **Fallback Logic**: The username fix includes fallback logic: `userName || socket.userName || User ${userId}` to handle edge cases
- **Video View Registration**: The `_registerRemoteVideoView()` method ensures the Agora video track is properly attached to the HTML element

---

## Files Modified Summary

### Backend
1. `elearningit/backend/utils/webrtcSignaling.js`
   - Updated `share_agora_uid` handler (lines 74-98)
   - Added `camera_republished` handler (lines 134-143)

### Frontend
1. `elearningit/lib/screens/video_call/web_course_video_call_screen.dart`
   - Updated screen share state listener to emit `camera_republished` (lines 186-211)
   - Added `camera_republished` event listener (lines 424-453)

---

## Rollback Instructions

If issues arise, revert changes by:
1. Backend: Restore `backend/utils/webrtcSignaling.js` to use only socket properties
2. Frontend: Remove the `camera_republished` emit and listener code
3. Restart the Node.js server
4. Hot reload or restart the Flutter app

---

## Status
✅ **COMPLETED** - Both issues addressed with backend and frontend changes
🧪 **READY FOR TESTING** - Awaiting user verification

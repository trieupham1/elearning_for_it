# Video Call Architecture & Flow Diagrams

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Your Local Network                          │
│                        (Same WiFi Required)                         │
│                                                                     │
│  ┌──────────────────┐                    ┌──────────────────┐    │
│  │   PC (User A)    │                    │ Android (User B) │    │
│  │                  │                    │                  │    │
│  │  ┌────────────┐  │                    │  ┌────────────┐  │    │
│  │  │  Flutter   │  │                    │  │  Flutter   │  │    │
│  │  │   Web/     │  │                    │  │   Android  │  │    │
│  │  │  Desktop   │  │                    │  │    App     │  │    │
│  │  └─────┬──────┘  │                    │  └──────┬─────┘  │    │
│  │        │         │                    │         │        │    │
│  │        │ HTTP    │                    │         │ HTTP   │    │
│  │        │ WS      │                    │         │ WS     │    │
│  └────────┼─────────┘                    └─────────┼────────┘    │
│           │                                        │             │
│           │                                        │             │
│           └────────────────┬───────────────────────┘             │
│                            │                                     │
│                            ▼                                     │
│                  ┌──────────────────┐                           │
│                  │  Backend Server  │                           │
│                  │  (Node.js)       │                           │
│                  │                  │                           │
│                  │  Port: 5000      │                           │
│                  │  Host: 0.0.0.0   │                           │
│                  │                  │                           │
│                  │  ┌────────────┐  │                           │
│                  │  │ Socket.IO  │  │ ◄── WebRTC Signaling     │
│                  │  │  Server    │  │                           │
│                  │  └────────────┘  │                           │
│                  │                  │                           │
│                  │  ┌────────────┐  │                           │
│                  │  │  MongoDB   │  │ ◄── Call Records         │
│                  │  │            │  │                           │
│                  │  └────────────┘  │                           │
│                  └──────────────────┘                           │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘

                          Internet
                             │
                             ▼
                  ┌──────────────────┐
                  │  Google STUN     │ ◄── ICE/NAT Traversal
                  │  Servers         │
                  └──────────────────┘
```

---

## Video Call Initiation Flow

```
PC (Caller)                Backend Server              Android (Callee)
    │                            │                            │
    │ 1. Click "Video Call"      │                            │
    ├───────────────────────────►│                            │
    │   POST /api/calls/initiate │                            │
    │   {calleeId, type: video}  │                            │
    │                            │                            │
    │ 2. Call record created     │                            │
    │◄───────────────────────────┤                            │
    │   {callId, status:ringing} │                            │
    │                            │                            │
    │ 3. Connect to Socket.IO    │                            │
    ├───────────────────────────►│                            │
    │   emit('register', userId) │                            │
    │                            │                            │
    │ 4. Create peer connection  │                            │
    │   & generate offer SDP     │                            │
    │                            │                            │
    │ 5. Send offer via socket   │                            │
    ├───────────────────────────►│                            │
    │ emit('call_initiated', {   │                            │
    │   calleeId, offer          │                            │
    │ })                         │                            │
    │                            │ 6. Forward to callee       │
    │                            ├───────────────────────────►│
    │                            │ emit('incoming_call', {    │
    │                            │   callerId, offer          │
    │                            │ })                         │
    │                            │                            │
    │                            │   7. Show incoming call UI │
    │                            │   8. User clicks "Accept"  │
    │                            │                            │
    │                            │ 9. Create peer connection  │
    │                            │    & generate answer SDP   │
    │                            │                            │
    │                            │ 10. Send answer via socket │
    │                            │◄───────────────────────────┤
    │                            │ emit('call_accepted', {    │
    │                            │   callerId, answer         │
    │                            │ })                         │
    │ 11. Receive answer         │                            │
    │◄───────────────────────────┤                            │
    │ emit('call_answered', {    │                            │
    │   answer                   │                            │
    │ })                         │                            │
    │                            │                            │
    │ 12. Set remote description │                            │
    │                            │ 13. Set remote description │
    │                            │                            │
    │◄────────────────────────── ICE Candidates ─────────────►│
    │                     (Exchanged via Socket.IO)           │
    │                                                          │
    │◄══════════════════ WebRTC Connection ═══════════════════►│
    │            (Direct peer-to-peer video/audio)            │
    │                                                          │
```

---

## ICE Candidate Exchange

```
PC                          Backend                    Android
│                              │                           │
│  Generate ICE candidate      │                           │
├─────────────────────────────►│                           │
│  emit('ice_candidate')       │                           │
│                              ├──────────────────────────►│
│                              │  forward to peer          │
│                              │                           │
│                              │  Generate ICE candidate   │
│                              │◄──────────────────────────┤
│                              │  emit('ice_candidate')    │
│◄─────────────────────────────┤                           │
│  forward to peer             │                           │
│                              │                           │
│  Add candidate to peer conn  │  Add candidate to peer conn
│                              │                           │
│◄════════════════════════════════════════════════════════►│
│              Try all candidate pairs                     │
│              Find best route (usually direct)            │
│                                                          │
│◄════════════════════════════════════════════════════════►│
│           CONNECTED - Start media stream                 │
│                                                          │
```

---

## Media Stream Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    PC (User A)                              │
│                                                             │
│  1. getUserMedia({video: true, audio: true})               │
│     ↓                                                       │
│  2. Local MediaStream                                      │
│     - Video track (camera)                                 │
│     - Audio track (microphone)                             │
│     ↓                                                       │
│  3. Display in local video element                         │
│     ↓                                                       │
│  4. Add tracks to RTCPeerConnection                        │
│     ↓                                                       │
│  ═══════════════════════════════════════════════════════   │
│  ║              WebRTC Data Channel                   ║   │
│  ║  (Encrypted, peer-to-peer, bypasses backend)      ║   │
│  ═══════════════════════════════════════════════════════   │
│     ↓                                                       │
└─────┼───────────────────────────────────────────────────────┘
      │
      │  Transmitted over Internet
      │  (May go through STUN/TURN servers for NAT traversal)
      │
      ↓
┌─────┴───────────────────────────────────────────────────────┐
│                   Android (User B)                          │
│                                                             │
│  5. Receive remote MediaStream via peer connection         │
│     ↓                                                       │
│  6. Remote MediaStream                                     │
│     - Video track (from User A's camera)                   │
│     - Audio track (from User A's microphone)               │
│     ↓                                                       │
│  7. Display in remote video element                        │
│                                                             │
│  AND SIMULTANEOUSLY:                                        │
│                                                             │
│  8. getUserMedia({video: true, audio: true})               │
│     ↓                                                       │
│  9. Local MediaStream (User B's camera/mic)                │
│     ↓                                                       │
│  10. Send back to User A via same WebRTC connection        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Call Controls Flow

```
User Action: Click Mute Button
│
├─► WebRTCService.toggleMute()
│   │
│   ├─► localStream.getAudioTracks()[0].enabled = false
│   │
│   ├─► Update local UI (show muted icon)
│   │
│   └─► Automatically stops audio transmission
│       (Other user can't hear you)
│
│
User Action: Click Video Off Button
│
├─► WebRTCService.toggleVideo()
│   │
│   ├─► localStream.getVideoTracks()[0].enabled = false
│   │
│   ├─► Update local UI (show video off icon)
│   │
│   └─► Automatically stops video transmission
│       (Other user sees black screen)
│
│
User Action: Click End Call Button
│
├─► CallService.endCall(callId)
│   │
│   ├─► HTTP POST /api/calls/:callId/end
│   │   │
│   │   └─► Backend updates call status to "ended"
│   │
│   ├─► Socket.IO emit('call_ended', {otherUserId})
│   │   │
│   │   └─► Backend forwards to other user's socket
│   │       │
│   │       └─► Other user receives 'call_ended' event
│   │           │
│   │           └─► Closes connection and shows "Call Ended"
│   │
│   └─► WebRTCService.dispose()
│       │
│       ├─► Close peer connection
│       ├─► Stop all media tracks
│       ├─► Disconnect socket
│       └─► Navigate back to previous screen
```

---

## Network Configuration Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                       WiFi Router                           │
│                    (192.168.1.1)                            │
│                                                             │
│  DHCP assigns IPs to devices:                              │
│  - PC: 192.168.1.100                                       │
│  - Android: 192.168.1.150                                  │
│                                                             │
└──────────────┬────────────────────────┬─────────────────────┘
               │                        │
               │                        │
    ┌──────────▼──────────┐  ┌──────────▼──────────┐
    │   PC                │  │   Android Device    │
    │   IP: 192.168.1.100 │  │   IP: 192.168.1.150 │
    │                     │  │                     │
    │   Backend Server    │  │   Flutter App       │
    │   Port: 5000        │  │                     │
    │   Bound to: 0.0.0.0 │  │   Connects to:      │
    │   (All interfaces)  │  │   192.168.1.100:5000│
    └─────────────────────┘  └─────────────────────┘

When Android connects:
- HTTP: http://192.168.1.100:5000/api/...
- WebSocket: ws://192.168.1.100:5000/socket.io/?...
- WebRTC: Peer-to-peer (may use STUN for NAT traversal)
```

---

## File Structure

```
elearningit/
│
├── lib/
│   ├── config/
│   │   └── api_config.dart ◄────────── UPDATE THIS! (Set PC IP)
│   │
│   ├── models/
│   │   ├── call.dart ◄───────────────── Call data model
│   │   └── user.dart
│   │
│   ├── services/
│   │   ├── call_service.dart ◄────────── HTTP API calls
│   │   ├── webrtc_service.dart ◄──────── WebRTC logic
│   │   └── api_service.dart
│   │
│   └── screens/
│       └── call/
│           └── video_call_screen.dart ◄─ Call UI
│
└── backend/
    ├── server.js ◄─────────────────────── UPDATE THIS! (Bind to 0.0.0.0)
    │
    ├── models/
    │   └── Call.js ◄────────────────────── Call database model
    │
    ├── routes/
    │   └── calls.js ◄───────────────────── Call REST API
    │
    └── utils/
        └── webrtcSignaling.js ◄─────────── Socket.IO signaling
```

---

## Socket.IO Events Reference

### Client → Server

| Event | Data | Description |
|-------|------|-------------|
| `register` | `userId` | Register socket with user ID |
| `call_initiated` | `{calleeId, offer, callId}` | Start a call |
| `call_accepted` | `{callerId, answer, callId}` | Accept incoming call |
| `call_rejected` | `{callerId, callId}` | Reject incoming call |
| `call_ended` | `{otherUserId, callId}` | End active call |
| `ice_candidate` | `{otherUserId, candidate}` | Send ICE candidate |
| `quality_update` | `{callId, quality}` | Update call quality |

### Server → Client

| Event | Data | Description |
|-------|------|-------------|
| `incoming_call` | `{callerId, callerName, offer}` | Receive call request |
| `call_answered` | `{calleeId, answer}` | Call was accepted |
| `call_rejected` | `{calleeId}` | Call was rejected |
| `call_ended` | `{userId}` | Call ended by other user |
| `ice_candidate` | `{candidate}` | Receive ICE candidate |
| `call_failed` | `{reason}` | Call failed (e.g., user offline) |
| `call_error` | `{message}` | Error occurred |

---

## WebRTC Connection States

```
┌─────────────┐
│     NEW     │ ◄── Initial state
└──────┬──────┘
       │ setLocalDescription(offer)
       ▼
┌─────────────┐
│  CONNECTING │ ◄── ICE gathering started
└──────┬──────┘
       │ ICE candidates exchanged
       ▼
┌─────────────┐
│  CONNECTED  │ ◄── Call is active! ✅
└──────┬──────┘
       │
       ├─── Network issues ───┐
       │                      │
       ▼                      ▼
┌─────────────┐      ┌─────────────┐
│DISCONNECTED │      │   FAILED    │
└──────┬──────┘      └──────┬──────┘
       │                    │
       │ Reconnect          │ Close
       │ attempts           │
       ▼                    ▼
┌─────────────┐      ┌─────────────┐
│  CONNECTED  │      │   CLOSED    │
└─────────────┘      └─────────────┘
```

---

## Testing Scenarios Diagram

```
Scenario 1: Successful Call
PC: Initiate ──► Android: Ring ──► Android: Accept ──► Connected ✅

Scenario 2: Rejected Call
PC: Initiate ──► Android: Ring ──► Android: Reject ──► Call Ended ❌

Scenario 3: Missed Call
PC: Initiate ──► Android: Ring ──► Android: No answer ──► Timeout ⏱️

Scenario 4: Network Issues
Connected ──► Poor WiFi ──► Reconnecting ──► Connected ✅

Scenario 5: User Ends Call
Connected ──► User A: End ──► Both: Call Ended ✅
```

---

## Debugging Checklist Flow

```
Call Not Working?
│
├─► Network Issue?
│   ├─► Same WiFi? ──► NO ──► Connect both to same WiFi
│   └─► Can ping PC? ──► NO ──► Check firewall
│
├─► Backend Issue?
│   ├─► Server running? ──► NO ──► Start with npm run dev
│   ├─► Socket.IO working? ──► NO ──► Check CORS settings
│   └─► Port 5000 accessible? ──► NO ──► Check firewall
│
├─► Frontend Issue?
│   ├─► Correct IP in config? ──► NO ──► Update api_config.dart
│   ├─► App rebuilt? ──► NO ──► flutter clean && flutter run
│   └─► Permissions granted? ──► NO ──► Enable camera/mic
│
└─► WebRTC Issue?
    ├─► Local stream? ──► NO ──► Check getUserMedia
    ├─► Remote stream? ──► NO ──► Check peer connection
    ├─► ICE connected? ──► NO ──► Check STUN servers
    └─► Check browser console for WebRTC errors
```

---

This diagram-based documentation should help you visualize how everything connects and flows! 🎯

# Android Emulator Connection Issue - QUICK FIX

## Problem
```
❌ Connection test failed: SocketException: No route to host (errno = 113)
address = 10.0.2.2, port = 5000
```

The Android emulator cannot connect to your backend server at `10.0.2.2:5000`.

---

## ✅ Solution 1: Restart Backend with Correct Binding (RECOMMENDED)

Your backend is already configured correctly, but let's verify it's actually listening:

### Step 1: Stop Current Backend
Press `Ctrl+C` in the terminal running Node.js

### Step 2: Restart Backend
```bash
cd elearningit/backend
node server.js
```

**Expected output:**
```
Connected to MongoDB
Server running on port 5000
✓ WebRTC signaling server initialized
```

### Step 3: Verify Backend is Accessible
Open **CMD** on your PC and run:
```cmd
netstat -an | findstr ":5000"
```

You should see:
```
TCP    0.0.0.0:5000           0.0.0.0:0              LISTENING
```

If you see `127.0.0.1:5000` instead of `0.0.0.0:5000`, the backend is not bound correctly.

---

## ✅ Solution 2: Check Windows Firewall

The firewall might be blocking the connection from the emulator.

### Option A: Temporarily Disable Firewall (for testing)
1. Open **Windows Security**
2. Click **Firewall & network protection**
3. Click your active network (Private network)
4. Turn **Windows Defender Firewall** to **Off**
5. Try connecting from the app again
6. **Remember to turn it back ON after testing!**

### Option B: Add Firewall Rule (recommended)
```powershell
# Run PowerShell as Administrator
New-NetFirewallRule -DisplayName "Node.js Backend" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

---

## ✅ Solution 3: Verify Emulator Network Settings

### Check Emulator Configuration:
1. With emulator running, open **CMD**
2. Run:
```cmd
adb shell ping 10.0.2.2
```

**Expected output:**
```
PING 10.0.2.2: 56 data bytes
64 bytes from 10.0.2.2: icmp_seq=0 ttl=64 time=0.234 ms
```

If ping fails, the emulator's network is not configured correctly.

### Fix: Restart Emulator with Network Reset
```bash
# Stop emulator
adb emu kill

# Start emulator again
flutter emulators --launch <emulator_id>
```

---

## ✅ Solution 4: Use Real Android Device Instead

If emulator networking is too problematic, use a real device:

### Step 1: Find Your PC's IP Address
```cmd
ipconfig
```
Look for **IPv4 Address** (e.g., `192.168.1.224`)

### Step 2: Update api_config.dart
You already have this IP in your code! I can see:
```dart
return 'http://192.168.1.224:5000';
```

But it's only used for non-Android platforms. Let me fix this:

```dart
static String getBaseUrl() {
  // For real Android device, use PC's local IP
  const String pcLocalIp = 'http://192.168.1.224:5000';
  
  if (kIsWeb) {
    return _localBase;
  }

  try {
    if (Platform.isAndroid) {
      // Uncomment one of these based on your testing scenario:
      
      // For Android EMULATOR:
      // return _androidEmulatorBase;
      
      // For REAL Android DEVICE:
      return pcLocalIp;
    }
    return pcLocalIp;
  } catch (e) {
    return _localBase;
  }
}
```

### Step 3: Connect Real Device
1. Connect phone via USB
2. Enable USB Debugging
3. Run: `flutter run`
4. Select your physical device

---

## 🎯 Quick Test Checklist

Run these tests in order:

### Test 1: Backend is Running
```bash
# On PC, open browser:
http://localhost:5000/api/health
```
✅ Should show: `{"status":"ok"}` or similar

### Test 2: Backend Accessible from Network
```bash
# On PC, open browser:
http://10.0.2.2:5000/api/health
```
❌ This will fail (10.0.2.2 is only for emulator)

Try instead:
```bash
# On PC, open browser:
http://192.168.1.224:5000/api/health
```
✅ Should work if firewall allows

### Test 3: Emulator Can Reach Host
```bash
adb shell ping 10.0.2.2
```
✅ Should get ping responses

### Test 4: Emulator Can Reach Backend
```bash
adb shell curl http://10.0.2.2:5000/api/health
```
✅ Should return health check response

---

## 🔍 Debug: Check What's Listening

Run this command to see what's listening on port 5000:

```cmd
netstat -ano | findstr ":5000"
```

**Good (listening on all interfaces):**
```
TCP    0.0.0.0:5000           0.0.0.0:0              LISTENING
```

**Bad (only listening on localhost):**
```
TCP    127.0.0.1:5000         0.0.0.0:0              LISTENING
```

If you see the "bad" version, your server.js is not binding to `0.0.0.0`.

---

## 💡 Recommended Quick Fix

Based on your logs, I recommend:

**Option 1: Use Real Android Device** (Easiest)
- I see you have the IP `192.168.1.224` configured
- Just switch the code to use real device instead of emulator
- Connect phone via USB
- Run `flutter run`

**Option 2: Fix Emulator Connection** (Current setup)
1. Stop backend (Ctrl+C)
2. Temporarily disable Windows Firewall
3. Restart backend: `cd elearningit/backend && node server.js`
4. Restart your Flutter app
5. Check if connection works

---

## 📝 After Fixing

Once connected, you should see in the Flutter logs:
```
I/flutter: ✅ Connection test successful
I/flutter: 🔐 Login successful for: phamquoctrieu
```

Instead of:
```
I/flutter: ❌ Connection test failed: No route to host
```

---

## 🆘 Still Not Working?

If none of the above works, there might be antivirus software blocking the connection. Try:
1. Temporarily disable antivirus
2. Add exception for Node.js in antivirus settings
3. Add exception for port 5000

---

**Next: After fixing connection, you can test video calls following QUICK_START_VIDEO_CALL.md**

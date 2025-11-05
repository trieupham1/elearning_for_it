# 🚨 IMMEDIATE FIX - Android Emulator "No Route to Host" Error

## Your Current Error:
```
❌ Connection test failed: SocketException: No route to host (errno = 113)
```

---

## 🎯 QUICKEST FIX (Choose One):

### Option A: Use Real Android Device (EASIEST - 2 minutes)

1. **Edit api_config.dart:**
   ```dart
   // Line 13: Change from true to false
   static const bool _useEmulator = false; // ⬅️ Changed to false
   ```

2. **Connect your phone:**
   - Connect phone via USB cable
   - Enable USB Debugging on phone
   - Make sure phone is on same WiFi as PC (192.168.1.x network)

3. **Run app:**
   ```bash
   flutter run
   # Select your physical device when prompted
   ```

✅ **Should work immediately!** Your PC IP (192.168.1.224) is already configured.

---

### Option B: Fix Emulator Connection (5 minutes)

#### Step 1: Check if Backend is Accessible

Open **Command Prompt** and run:
```cmd
netstat -an | findstr ":5000"
```

**Look for this line:**
```
TCP    0.0.0.0:5000           0.0.0.0:0              LISTENING
```

✅ If you see `0.0.0.0:5000` → Backend is configured correctly
❌ If you see `127.0.0.1:5000` → Backend needs restart

#### Step 2: Fix Windows Firewall

**Quick Test (Temporary):**
1. Press `Win + R`
2. Type: `firewall.cpl`
3. Click "Turn Windows Defender Firewall on or off"
4. Select "Turn off" for Private networks
5. Try your app again

**Permanent Fix:**
Run this in **PowerShell as Administrator:**
```powershell
New-NetFirewallRule -DisplayName "Node.js Port 5000" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

#### Step 3: Restart Everything

1. **Stop backend** (Ctrl+C in Node terminal)
2. **Restart backend:**
   ```bash
   cd elearningit/backend
   node server.js
   ```
3. **Restart emulator:**
   ```bash
   # Stop app
   flutter run
   ```

---

## 🧪 Test Connection

After applying fix, open your app and check logs:

**BEFORE (Not Working):**
```
I/flutter: ❌ Connection test failed: No route to host
```

**AFTER (Working):**
```
I/flutter: ✅ Connection test successful  
I/flutter: 🔐 Login successful for: phamquoctrieu
```

---

## 📱 Current Configuration Summary

Based on your code, here's your current setup:

| Setting | Value |
|---------|-------|
| **PC IP Address** | 192.168.1.224 |
| **Backend Port** | 5000 |
| **Backend URL** | http://192.168.1.224:5000 |
| **Emulator URL** | http://10.0.2.2:5000 |
| **Current Mode** | Emulator (`_useEmulator = true`) |

To switch between emulator and real device, just change:
```dart
// File: lib/config/api_config.dart, Line 13
static const bool _useEmulator = true;  // Emulator
static const bool _useEmulator = false; // Real device
```

---

## 🎬 Recommended Action NOW:

**I recommend Option A (Real Device)** because:
- ✅ Faster to set up
- ✅ Better for testing (especially video calls)
- ✅ No firewall issues
- ✅ More realistic testing environment

**Steps:**
1. Change `_useEmulator` to `false` in api_config.dart
2. Save the file
3. Connect your phone via USB
4. Run: `flutter run`
5. Select your physical device
6. Try logging in

**That's it! 🎉**

---

## 🔍 Verify Backend is Running

Your backend looks healthy from the logs:
```
✅ Connected to MongoDB
✅ WebRTC signaling server initialized
✅ Server running on port 5000
```

The issue is purely network connectivity between emulator and host.

---

## ⚡ After Connection Works

Once you can log in successfully, you'll be ready to test video calls!

See these guides:
- `QUICK_START_VIDEO_CALL.md` - Video call testing
- `VIDEO_CALL_TESTING_CHECKLIST.md` - Complete testing checklist

---

**Need help? Check `ANDROID_EMULATOR_CONNECTION_FIX.md` for detailed troubleshooting!**

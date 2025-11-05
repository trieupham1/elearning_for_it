# ⚡ QUICK FIX: Real Device Not Using Correct Server URL

## ❌ Problem You Just Had:

Running on **real Android device**, but app still connects to emulator URL:
```
I/flutter: 🔄 Testing connection to http://10.0.2.2:5000
```

This is WRONG for real devices! ❌

---

## ✅ Solution Applied:

Changed `api_config.dart` line 16:
```dart
// BEFORE (Wrong):
static const bool _useEmulator = true;

// AFTER (Correct):
static const bool _useEmulator = false;
```

---

## 🔄 IMPORTANT: Must Restart App!

**Option 1: Hot Restart** (Fastest - try this first)
- Press `R` in the terminal where Flutter is running
- Or use VS Code's hot restart button (🔄)

**Option 2: Full Restart** (If hot restart doesn't work)
```bash
# Stop app (Ctrl+C in terminal)
# Then run:
flutter run
```

**Option 3: Reinstall** (If still not working)
```bash
flutter clean
flutter run
```

---

## ✅ After Restart, You Should See:

```
I/flutter: 🔄 Testing connection to http://192.168.1.224:5000
                                          ^^^^^^^^^^^^^^^^
                                          Your PC's actual IP!
I/flutter: ✅ Connection test successful
I/flutter: 🔐 Login successful for: maivanmanh
```

**NOT:**
```
I/flutter: 🔄 Testing connection to http://10.0.2.2:5000
                                          ^^^^^^^^^^
                                          Emulator IP (wrong!)
```

---

## 🔍 Quick Checklist:

- [x] Changed `_useEmulator` to `false` ✅
- [ ] Restarted the Flutter app ⬅️ **DO THIS NOW!**
- [ ] Verified logs show correct IP (192.168.1.224)
- [ ] Login successful

---

## 💡 Remember for Future:

### When to use `_useEmulator = true`:
- Testing with Android Emulator
- App connects to: `http://10.0.2.2:5000`

### When to use `_useEmulator = false`:
- Testing with Real Android Device
- Testing with iOS Device  
- App connects to: `http://192.168.1.224:5000` (your PC's IP)

---

## 🚨 If Still Not Working After Restart:

1. **Check your PC's IP hasn't changed:**
   ```cmd
   ipconfig
   ```
   Look for IPv4 Address, update `_pcLocalIp` if different

2. **Check device is on same WiFi:**
   - Device WiFi should be same network as PC
   - Both should have 192.168.1.x addresses

3. **Check backend is running:**
   ```
   http://192.168.1.224:5000/api/health
   ```
   Should work in browser on PC

---

**Now restart your app and try logging in again! 🚀**

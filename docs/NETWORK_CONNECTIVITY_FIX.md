# Network Connectivity Fix - Android Device Can't Reach PC Server

## 🔍 Problem
Your Android device can connect to WiFi but **can't reach your PC's backend server** at `192.168.1.224:5000`.

## ✅ Quick Fixes (Try in Order)

### 1️⃣ **Check Windows Firewall** (Most Common Issue)

**Option A: Temporarily Disable Firewall (Testing Only)**
```powershell
# Run as Administrator in PowerShell
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
```

**Option B: Add Firewall Rule (Recommended)**
```powershell
# Run as Administrator in PowerShell
New-NetFirewallRule -DisplayName "Node.js Server Port 5000" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

**Option C: GUI Method**
1. Open **Windows Defender Firewall** → Advanced Settings
2. Click **Inbound Rules** → **New Rule**
3. Select **Port** → Next
4. Enter **5000** → Next
5. Select **Allow the connection** → Next
6. Check all profiles (Domain, Private, Public) → Next
7. Name: "Node.js Server Port 5000" → Finish

---

### 2️⃣ **Verify Backend is Accessible from PC First**

Open browser on your **PC** and test:
```
http://192.168.1.224:5000/api/health
```

Should see: `{"status":"ok"}`

---

### 3️⃣ **Test from Android Device Browser**

1. Open **Chrome/Browser** on your Android device
2. Navigate to: `http://192.168.1.224:5000/api/health`
3. **Expected**: `{"status":"ok"}`
4. **If fails**: Network connectivity issue (see troubleshooting below)

---

### 4️⃣ **Verify Both Devices on Same Network**

**On PC (PowerShell):**
```powershell
ipconfig
```
Look for: `IPv4 Address. . . . . . . . . . . : 192.168.1.224`

**On Android:**
1. Settings → WiFi → Your network → Advanced
2. Check IP address (should be `192.168.1.xxx`)
3. **Both must be on same subnet** (192.168.1.x)

---

### 5️⃣ **Check Backend is Running and Listening**

**On PC (PowerShell):**
```powershell
netstat -an | findstr "5000"
```

Should see:
```
TCP    0.0.0.0:5000           0.0.0.0:0              LISTENING
```

If not listening:
```bash
cd backend
npm run dev
```

---

## 🔧 Advanced Troubleshooting

### Test Network Connectivity from Android

**Method 1: Ping Test (if available)**
- Download "Network Utilities" or "PingTools" app
- Ping: `192.168.1.224`
- **Expected**: Replies received
- **If fails**: PC firewall blocking ICMP or network isolation

**Method 2: Port Scanner App**
- Download "Fing" or "Network Analyzer" app
- Scan for `192.168.1.224:5000`
- **Expected**: Port 5000 shown as OPEN
- **If closed**: Firewall blocking or server not listening

---

### Check Router AP Isolation

Some routers have **AP Isolation** (Client Isolation) enabled, which prevents devices from communicating with each other.

**To Disable:**
1. Access your router admin panel (usually `192.168.1.1` or `192.168.0.1`)
2. Look for: **Wireless Settings** → **AP Isolation** / **Client Isolation**
3. **Disable** this feature
4. Save and restart router

---

### Windows Firewall - Detailed Check

**Check if port 5000 is blocked:**
```powershell
# Run as Administrator
Get-NetFirewallPortFilter | Where-Object {$_.LocalPort -eq 5000} | Get-NetFirewallRule | Format-Table -Property DisplayName, Enabled, Direction, Action
```

**If no rules found or Action is "Block":**
```powershell
New-NetFirewallRule -DisplayName "Node.js Server Port 5000" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

---

## 🧪 Testing Steps (After Fix)

### 1. Test from PC Browser
```
http://192.168.1.224:5000/api/health
```

### 2. Test from Android Browser
```
http://192.168.1.224:5000/api/health
```

### 3. Test Flutter App Login
- Open Flutter app on Android
- Try login
- **Expected log**: `✅ Connection test successful!`

---

## 📱 Alternative: Use PC as USB Tethering Hotspot

If all else fails, you can use USB tethering:

**On Android:**
1. Settings → Network & Internet → Hotspot & Tethering
2. Enable **USB Tethering**
3. Connect Android to PC via USB cable
4. Your PC will get new IP (check with `ipconfig`)

**Update api_config.dart:**
```dart
static const String _pcLocalIp = 'http://192.168.42.129:5000'; // New USB tethering IP
```

---

## 🚀 Quick Test Command

After fixing firewall, test connectivity:

**From Android (using Terminal Emulator app or ADB):**
```bash
curl -v http://192.168.1.224:5000/api/health
```

**Expected output:**
```
< HTTP/1.1 200 OK
< Content-Type: application/json
...
{"status":"ok"}
```

---

## 📋 Summary Checklist

- [ ] Windows Firewall allows port 5000 (inbound)
- [ ] Backend server running and listening on 0.0.0.0:5000
- [ ] PC browser can access `http://192.168.1.224:5000/api/health`
- [ ] Android browser can access `http://192.168.1.224:5000/api/health`
- [ ] Both devices on same WiFi network (192.168.1.x)
- [ ] Router AP Isolation disabled
- [ ] Flutter app shows connection success

---

## 🎯 Most Likely Solution

**99% of the time it's Windows Firewall blocking the connection.**

**Quick fix:**
```powershell
# Run as Administrator
New-NetFirewallRule -DisplayName "Node.js Port 5000" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

Then test from Android browser: `http://192.168.1.224:5000/api/health`

---

**Once you see `{"status":"ok"}` in Android browser, your Flutter app will work! 🎉**

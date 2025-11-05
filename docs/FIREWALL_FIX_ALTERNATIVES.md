# Quick Firewall Fix Alternative Methods

## If PowerShell Admin Method Didn't Work

### Method 1: Manual Firewall Rule (GUI)

1. **Press Windows Key** and search: "Windows Defender Firewall"
2. Click **"Advanced settings"** (left sidebar)
3. Click **"Inbound Rules"** (left panel)
4. Click **"New Rule..."** (right panel)
5. Select **"Port"** → Click **Next**
6. Keep **TCP** selected
7. Enter **5000** in "Specific local ports" → Click **Next**
8. Select **"Allow the connection"** → Click **Next**
9. **Check all three boxes**: Domain, Private, Public → Click **Next**
10. Name: **"Node.js Server Port 5000"** → Click **Finish**

---

### Method 2: Temporarily Disable Firewall (Testing Only!)

⚠️ **Warning: Only for testing! Remember to re-enable!**

1. Press **Windows Key** + **R**
2. Type: `firewall.cpl` → Press **Enter**
3. Click **"Turn Windows Defender Firewall on or off"** (left sidebar)
4. Select **"Turn off Windows Defender Firewall"** for **Private network**
5. Click **OK**

**Test your Android connection** → Then **re-enable firewall!**

---

### Method 3: CMD Command (Run as Administrator)

```cmd
netsh advfirewall firewall add rule name="Node.js Port 5000" dir=in action=allow protocol=TCP localport=5000
```

---

### Method 4: Check Existing Firewall Rules

**See if rule was created:**
```powershell
Get-NetFirewallRule -DisplayName "*5000*" | Format-Table -Property DisplayName, Enabled, Direction, Action
```

**Or check all Node.js rules:**
```powershell
Get-NetFirewallRule -DisplayName "*Node*" | Format-Table -Property DisplayName, Enabled, Direction, Action
```

---

## 🧪 Test After Firewall Fix

### From PC Browser:
```
http://192.168.1.224:5000/api/health
```

### From Android Browser:
```
http://192.168.1.224:5000/api/health
```

### Both should show:
```json
{"status":"ok"}
```

---

## 🚀 Once Android Browser Works...

**Your Flutter app will immediately work too!**

Just try login again in the app. You should see:
```
✅ Connection test successful!
✅ Login successful for: maivanmanh
```

---

## 📱 Alternative: Use Different IP

If firewall still blocks, try getting your PC's IP from different network interface:

```powershell
ipconfig
```

Look for other `192.168.x.x` addresses under:
- Wireless LAN adapter Wi-Fi
- Ethernet adapter

Update `api_config.dart` with the new IP if needed.

---

## 🆘 Last Resort: USB Tethering

1. Connect Android to PC via USB cable
2. On Android: Settings → Hotspot & tethering → Enable **USB tethering**
3. On PC: Run `ipconfig` to find new IP (usually `192.168.42.xxx`)
4. Update `api_config.dart`:
   ```dart
   static const String _pcLocalIp = 'http://192.168.42.xxx:5000';
   ```
5. Restart Flutter app

---

**The firewall is 99% the cause. Once port 5000 is allowed, everything will work! 🎯**

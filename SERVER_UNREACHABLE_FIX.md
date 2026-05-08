# 🔧 Server Unreachable - Quick Fix Guide

## Problem
Your Flutter app shows "server unreachable" error because:
1. Backend server might not be running, OR
2. LAN IP address (192.168.1.7) has changed

---

## ✅ Solution 1: Start Backend Server

### **Check if Backend is Running:**

```bash
cd /Users/sumitgupta/omnicommerce\ copy/backend

# Check if server is already running
lsof -i :5000
```

If nothing shows up, start the server:

```bash
# Install dependencies first (if not done)
npm install

# Start the backend server
node server.js
```

You should see:
```
Server running on port 5000
MongoDB connected successfully
```

**Keep this terminal open!** Don't close it.

---

## ✅ Solution 2: Find Your Current LAN IP

Your IP (192.168.1.7) might have changed. Let's find the current one:

### **On macOS:**

```bash
# Get your LAN IP
ipconfig getifaddr en0
```

Or check System Preferences → Network → Wi-Fi → Status

It should look like: `192.168.1.XXX` or `10.0.0.XXX`

---

## ✅ Solution 3: Update Flutter App Configuration

Once you have your new IP, update the API endpoints file:

**File:** `flutter_pos_app/lib/core/constants/api_endpoints.dart`

```dart
// Line 21 - Update with YOUR current IP
static const String _lanBaseUrl = 'http://YOUR_CURRENT_IP:5000/api';
```

**Example:** If your IP is `192.168.1.105`:
```dart
static const String _lanBaseUrl = 'http://192.168.1.105:5000/api';
```

---

## ✅ Solution 4: Verify Network Connection

### **Both devices must be on SAME Wi-Fi network!**

Check on your Android phone:
- Settings → Wi-Fi
- Make sure you're connected to the SAME network as your laptop

### **Test Connection from Phone:**

1. Open browser on your phone
2. Go to: `http://YOUR_LAPTOP_IP:5000/api`
3. Should see: `{"message": "OmniCommerce API is running"}`

If you can't access it:
- Check laptop firewall settings
- Make sure both devices are on same network
- Try restarting your router

---

## 🚀 Complete Fix Workflow

Run these commands in order:

### **Step 1: Find Current IP**
```bash
# On your Mac terminal
ipconfig getifaddr en0
```

Note down the IP (e.g., 192.168.1.105)

### **Step 2: Update API Endpoints**

Edit this file:
`flutter_pos_app/lib/core/constants/api_endpoints.dart`

Change line 21:
```dart
static const String _lanBaseUrl = 'http://192.168.1.105:5000/api';
// Replace with YOUR actual IP
```

### **Step 3: Start Backend**

```bash
cd /Users/sumitgupta/omnicommerce\ copy/backend
npm install    # First time only
node server.js
```

Keep this terminal open!

### **Step 4: Restart Flutter App**

In a NEW terminal:
```bash
cd /Users/sumitgupta/omnicommerce\ copy/flutter_pos_app
flutter clean
flutter pub get
flutter run
```

---

## 🔍 Troubleshooting

### **Still can't connect?**

#### **Check if backend is actually running:**

Open browser on laptop and go to:
```
https://app-backend-je91.onrender.com/api
```

Should show API welcome message.

#### **Check firewall on Mac:**

System Preferences → Security & Privacy → Firewall
- Either turn off temporarily, OR
- Add Node.js to allowed apps

#### **Try localhost for emulator:**

If using Android emulator (not real device), change line 21 to:
```dart
static const String _lanBaseUrl = 'http://127.0.0.1:5000/api';
```

Because emulator can use localhost directly.

---

## 📱 For Real Device vs Emulator

### **Real Android Device (via USB/Wi-Fi):**
```dart
// Use your LAN IP
static const String _lanBaseUrl = 'http://192.168.1.XXX:5000/api';
```

### **Android Emulator (on laptop):**
```dart
// Use localhost
static const String _lanBaseUrl = 'http://127.0.0.1:5000/api';
```

The code already handles this automatically! Just make sure:
- Real device → Uses LAN IP (line 21)
- Emulator → Uses localhost (line 24)

---

## ✅ Quick Test Checklist

- [ ] Backend server running on port 5000
- [ ] Correct LAN IP in api_endpoints.dart
- [ ] Both devices on same Wi-Fi network
- [ ] Firewall allows incoming connections
- [ ] Can access `http://IP:5000/api` from phone browser

---

## 🎯 Most Common Issues

| Issue | Solution |
|-------|----------|
| Backend not started | Run `node server.js` in backend folder |
| Wrong IP address | Update line 21 with current IP |
| Different Wi-Fi networks | Connect both to same network |
| Firewall blocking | Allow Node.js in firewall settings |
| Using emulator with LAN IP | Change to localhost for emulator |

---

## 🚨 Emergency Fallback

If nothing works, you can temporarily disable API calls and use offline mode:

The app uses local mock data for inventory, so it will still work for testing most features without backend!

Just comment out API calls temporarily in your providers.

---

## Need More Help?

After trying the steps above, let me know:
1. What's your current LAN IP?
2. Is backend server running?
3. Are you using real device or emulator?
4. What error exactly do you see?

I'll help you debug further! 

---

*Generated on: April 3, 2026*  
*OmniCommerce POS - Server Connection Troubleshooting*

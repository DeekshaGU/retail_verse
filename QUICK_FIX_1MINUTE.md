# ⚡ 1-Minute Quick Fix - Server Unreachable Error

## 🎯 Problem: "Server unreachable. Please check your connection."

### ✅ QUICK FIX (Follow in exact order):

### 1️⃣ Start Backend (30 seconds)

**Terminal में run करें:**
```bash
cd backend
npm start
```

**Output ऐसा दिखना चाहिए:**
```
✅ Server running on port 5000
🌐 Network access: http://192.168.1.7:5000
```

📝 **Note this IP address!**

---

### 2️⃣ Update IP in Flutter App (20 seconds)

**File edit करें:**
```
flutter_pos_app/lib/core/constants/api_endpoints.dart
```

**Line 13 पर IP update करें:**
```dart
// Replace with YOUR laptop's IP from Step 1
static const String _lanBaseUrl = 'http://YOUR_IP:5000/api';
```

**Example:**
```dart
static const String _lanBaseUrl = 'http://192.168.1.100:5000/api';
```

---

### 3️⃣ Same Wi-Fi Check (10 seconds)

✅ **Laptop:** Connected to `HomeWiFi`  
✅ **Phone:** Connected to `HomeWiFi` (SAME network)

---

### 4️⃣ Test from Phone (30 seconds)

**Phone browser में जाएं:**
```
http://YOUR_IP:5000
```

✅ **अगर "POS Backend running" दिखे** → आगे बढ़ें  
❌ **अगर नहीं दिखे** → Same Wi-Fi check करें

---

### 5️⃣ Hot Restart Flutter App (10 seconds)

**Terminal में:**
```
Shift + R dabaएं
```

---

### 6️⃣ Test Login

**App में:**
- Email: `admin@example.com`
- Password: `admin123`
- Tap "Sign In"

✅ **Should work now!**

---

## 🔴 Still Not Working?

### Most Common Issues:

#### ❌ Backend not running
**Fix:**
```bash
cd backend && npm start
```

#### ❌ Different Wi-Fi networks
**Fix:** Both devices on SAME Wi-Fi

#### ❌ Wrong IP address
**Fix:** 
```bash
ipconfig getifaddr en0
# Update api_endpoints.dart with this IP
```

#### ❌ Firewall blocking
**Fix:** Temporarily disable firewall

---

## 📋 Full Details के लिए देखें:

- **[START_BACKEND_FIRST.md](START_BACKEND_FIRST.md)** - Complete English guide
- **[FIX_LOGIN_HINDI.md](FIX_LOGIN_HINDI.md)** - Hindi/English detailed guide

---

## ✅ Success Indicators

Backend terminal में:
```
POST /api/auth/login 200 - 45ms
```

Flutter console में:
```
✅ AuthService: Login successful
```

App में:
- ✅ Dashboard navigate होता है
- ✅ No errors
- ✅ Loading spinner दिखता है

---

**That's it! Login should work now.** 🚀

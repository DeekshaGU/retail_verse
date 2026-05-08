# 🚀 Complete Startup Guide - Backend + Flutter

## ⚠️ IMPORTANT: Follow These Steps in Order

### Step 1: Start the Backend Server FIRST

**Open Terminal 1:**
```bash
cd backend
npm start
```

**You should see:**
```
✅ Server running on port 5000
📡 Accessible at: http://localhost:5000
🌐 Network access: http://<YOUR_IP>:5000

Testing endpoints:
  - Health: http://localhost:5000/
  - Auth:   http://localhost:5000/api/auth/login
```

**Note your IP address** from the console output!

### Step 2: Verify Backend is Working

**Option A - Test in Browser:**
1. Open browser on your laptop
2. Go to: `http://localhost:5000`
3. You should see: `POS Backend running`

**Option B - Test Login API:**
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}'
```

**Expected Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {...}
}
```

### Step 3: Find Your IP Address

**On Mac:**
```bash
ipconfig getifaddr en0
```

**On Windows:**
```bash
ipconfig | findstr IPv4
```

**Example Output:** `192.168.1.7` (or similar)

### Step 4: Update Flutter App Configuration

**File:** `flutter_pos_app/lib/core/constants/api_endpoints.dart`

Find this line (around line 13):
```dart
static const String _lanBaseUrl = 'http://192.168.1.7:5000/api';
```

**Replace with YOUR IP from Step 3:**
```dart
static const String _lanBaseUrl = 'http://YOUR_ACTUAL_IP:5000/api';
```

**Example:** If your IP is `192.168.1.100`:
```dart
static const String _lanBaseUrl = 'http://192.168.1.100:5000/api';
```

### Step 5: Connect Both Devices to SAME Wi-Fi

✅ **Correct:**
- Laptop connected to Wi-Fi: `HomeWiFi`
- Android phone connected to Wi-Fi: `HomeWiFi` (SAME network)

❌ **Wrong:**
- Laptop on Ethernet cable
- Phone on cellular data
- Different Wi-Fi networks

### Step 6: Test Backend from Your Phone

**On your Android phone's browser:**
1. Open Chrome/Safari
2. Type: `http://YOUR_IP:5000` (use the same IP from Step 4)
3. You should see: `POS Backend running`

**If it loads** → ✅ Backend is accessible  
**If it doesn't load** → ❌ Check firewall or Wi-Fi connection

### Step 7: Run Flutter App

**Open Terminal 2 (keep Terminal 1 running):**
```bash
cd flutter_pos_app
flutter run
```

### Step 8: Test Login/Signup

**In the Flutter app:**

#### For Login:
1. Email: `admin@example.com`
2. Password: `admin123`
3. Tap "Sign In"

#### For Signup (if login doesn't work):
1. Tap "Create Account"
2. Fill in details
3. Tap "Create Account"
4. Then try login

### 🔍 Debug Checklist

#### If you see "Server unreachable":

**Check 1:** Is backend running?
```bash
# In Terminal 1, you should see recent request logs
# If not started, run: cd backend && npm start
```

**Check 2:** Same Wi-Fi?
- Laptop Wi-Fi name: _______________
- Phone Wi-Fi name: _______________
- Are they the SAME? YES / NO

**Check 3:** IP address correct?
```bash
# Run this and update api_endpoints.dart
ipconfig getifaddr en0
```

**Check 4:** Can phone reach backend?
- Open browser on phone
- Go to: `http://YOUR_IP:5000`
- Does it show "POS Backend running"? YES / NO

**Check 5:** Firewall blocking?
- **Mac:** System Preferences → Security → Firewall (temporarily disable)
- **Windows:** Defender Firewall → Allow an app → Node.js (enable)

### 🎯 Expected Console Output

#### Backend Terminal (Terminal 1):
```
✅ Server running on port 5000
📡 Accessible at: http://localhost:5000
🌐 Network access: http://192.168.1.7:5000

POST /api/auth/login 200 - 45ms
```

#### Flutter Console (Terminal 2):
```
🔵 AuthService [Login]
  URL: http://192.168.1.7:5000/api/auth/login
  Request Body: {"email":"admin@example.com","password":"admin123"}

🔵 AuthService [Login Response]
  Status Code: 200
  Response Body: {"token":"...","user":{...}}

✅ AuthService: Login successful
```

### 🆘 Emergency Fallback - Use Emulator

If real device testing is too complex, use Android Emulator:

**File:** `lib/core/constants/api_endpoints.dart`
```dart
// For emulator, it will automatically use localhost
// No need to change anything!
```

The code already handles this:
```dart
if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
  return _localBaseUrl; // Uses 127.0.0.1:5000
}
```

### ✅ Success Criteria

Both login and signup are working when:

1. ✅ Backend shows successful API calls in terminal
2. ✅ Flutter console shows "Login successful" or "Registration successful"
3. ✅ App navigates to dashboard after login
4. ✅ No "Server unreachable" errors
5. ✅ Keyboard doesn't show white card overlay

### 📝 Quick Reference Commands

**Start Backend:**
```bash
cd backend && npm start
```

**Check IP:**
```bash
ipconfig getifaddr en0
```

**Start Flutter:**
```bash
cd flutter_pos_app && flutter run
```

**Test Backend from Terminal:**
```bash
curl http://localhost:5000
```

---

## 🎯 FOLLOW THIS ORDER:

1. ✅ Start backend (Terminal 1)
2. ✅ Note IP address from backend logs
3. ✅ Update IP in `api_endpoints.dart`
4. ✅ Test backend from phone browser
5. ✅ Start Flutter app (Terminal 2)
6. ✅ Test login/signup

**Don't skip steps!** Each step depends on the previous one.

Good luck! 🚀

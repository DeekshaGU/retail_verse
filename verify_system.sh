#!/bin/bash

echo "🎯 OmniCommerce POS - Complete System Verification"
echo "===================================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo "Step 1: Checking Backend Server..."
echo "-----------------------------------"

# Check if backend is running
if lsof -Pi :5000 -sTCP:LISTEN -t >/dev/null ; then
    print_success "Backend server is running on port 5000"
else
    print_warning "Backend server is NOT running"
    echo ""
    echo "To start backend:"
    echo "  cd backend"
    echo "  npm start"
    echo ""
fi

echo ""
echo "Step 2: Checking Flutter Installation..."
echo "-----------------------------------------"

if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    print_success "Flutter is installed: $FLUTTER_VERSION"
    
    # Check for connected devices
    echo ""
    print_info "Checking for connected devices..."
    flutter devices
else
    print_error "Flutter is not installed or not in PATH"
fi

echo ""
echo "Step 3: Checking Node.js Installation..."
echo "-----------------------------------------"

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_success "Node.js is installed: $NODE_VERSION"
else
    print_error "Node.js is not installed"
fi

echo ""
echo "Step 4: Checking Project Structure..."
echo "--------------------------------------"

# Check backend files
if [ -f "backend/server.js" ]; then
    print_success "Backend server.js found"
else
    print_error "Backend server.js NOT found"
fi

if [ -f "backend/package.json" ]; then
    print_success "Backend package.json found"
else
    print_error "Backend package.json NOT found"
fi

# Check Flutter files
if [ -f "flutter_pos_app/lib/main.dart" ]; then
    print_success "Flutter main.dart found"
else
    print_error "Flutter main.dart NOT found"
fi

if [ -f "flutter_pos_app/pubspec.yaml" ]; then
    print_success "Flutter pubspec.yaml found"
else
    print_error "Flutter pubspec.yaml NOT found"
fi

echo ""
echo "Step 5: Checking API Configuration..."
echo "--------------------------------------"

# Extract IP from api_endpoints.dart
if [ -f "flutter_pos_app/lib/core/constants/api_endpoints.dart" ]; then
    API_IP=$(grep "_lanBaseUrl" flutter_pos_app/lib/core/constants/api_endpoints.dart | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
    if [ ! -z "$API_IP" ]; then
        print_success "API Base URL configured: http://$API_IP:5000/api"
        
        # Get actual local IP
        ACTUAL_IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I | awk '{print $1}')
        
        if [ "$API_IP" == "$ACTUAL_IP" ]; then
            print_success "IP address matches your current network!"
        else
            print_warning "IP address mismatch!"
            echo "  Configured IP: $API_IP"
            echo "  Current IP:    $ACTUAL_IP"
            echo ""
            print_info "If having connection issues, update api_endpoints.dart with:"
            echo "  static const String _lanBaseUrl = 'http://$ACTUAL_IP:5000/api';"
        fi
    else
        print_error "Could not find API IP configuration"
    fi
else
    print_error "api_endpoints.dart NOT found"
fi

echo ""
echo "Step 6: Testing Backend Health..."
echo "----------------------------------"

# Test if backend is accessible
if curl -s https://app-backend-je91.onrender.com/api > /dev/null 2>&1; then
    print_success "Backend is responding on localhost:5000"
    
    # Get response
    RESPONSE=$(curl -s https://app-backend-je91.onrender.com/api)
    if [[ "$RESPONSE" == *"POS Backend running"* ]]; then
        print_success "Backend health check passed: 'POS Backend running'"
    else
        print_warning "Backend responded but with unexpected message"
    fi
else
    print_error "Backend is NOT responding on localhost:5000"
fi

echo ""
echo "Step 7: Checking Android Internet Permission..."
echo "------------------------------------------------"

if [ -f "flutter_pos_app/android/app/src/main/AndroidManifest.xml" ]; then
    if grep -q "INTERNET" flutter_pos_app/android/app/src/main/AndroidManifest.xml; then
        print_success "Android INTERNET permission is enabled"
    else
        print_error "Android INTERNET permission is MISSING!"
    fi
    
    if grep -q "usesCleartextTraffic" flutter_pos_app/android/app/src/main/AndroidManifest.xml; then
        print_success "Android cleartext traffic is allowed (for HTTP)"
    else
        print_warning "Android cleartext traffic might be blocked"
    fi
else
    print_error "AndroidManifest.xml NOT found"
fi

echo ""
echo "Step 8: Quick UI/UX Checks..."
echo "------------------------------"

# Check for gradient in login screen
if [ -f "flutter_pos_app/lib/features/auth/presentation/screens/login_screen.dart" ]; then
    if grep -q "LinearGradient" flutter_pos_app/lib/features/auth/presentation/screens/login_screen.dart; then
        print_success "Login screen has gradient background ✨"
    else
        print_warning "Login screen gradient not found"
    fi
    
    # Check for keyboard handling
    if grep -q "resizeToAvoidBottomInset" flutter_pos_app/lib/features/auth/presentation/screens/login_screen.dart; then
        print_success "Keyboard overflow handling configured"
    else
        print_warning "Keyboard overflow handling might be missing"
    fi
else
    print_error "login_screen.dart NOT found"
fi

# Check signup screen
if [ -f "flutter_pos_app/lib/features/auth/presentation/screens/signup_screen.dart" ]; then
    if grep -q "LinearGradient" flutter_pos_app/lib/features/auth/presentation/screens/signup_screen.dart; then
        print_success "Signup screen has gradient background ✨"
    else
        print_warning "Signup screen gradient not found"
    fi
else
    print_error "signup_screen.dart NOT found"
fi

echo ""
echo "Step 9: Checking Error Handling..."
echo "-----------------------------------"

# Check auth service for error handling
if [ -f "flutter_pos_app/lib/data/remote/auth_service.dart" ]; then
    if grep -q "SocketException" flutter_pos_app/lib/data/remote/auth_service.dart; then
        print_success "Network error handling implemented"
    else
        print_warning "Network error handling might be incomplete"
    fi
    
    if grep -q "TimeoutException" flutter_pos_app/lib/data/remote/auth_service.dart; then
        print_success "Timeout error handling implemented"
    else
        print_warning "Timeout error handling might be missing"
    fi
else
    print_error "auth_service.dart NOT found"
fi

echo ""
echo "===================================================="
echo "📊 Verification Summary"
echo "===================================================="
echo ""

# Count successes and errors
SUCCESS_COUNT=$(echo "$OUTPUT" | grep -c "✅" || true)
ERROR_COUNT=$(echo "$OUTPUT" | grep -c "❌" || true)
WARNING_COUNT=$(echo "$OUTPUT" | grep -c "⚠️" || true)

print_success "Checks passed: $SUCCESS_COUNT"
if [ $ERROR_COUNT -gt 0 ]; then
    print_error "Checks failed: $ERROR_COUNT"
fi
if [ $WARNING_COUNT -gt 0 ]; then
    print_warning "Warnings: $WARNING_COUNT"
fi

echo ""
if [ $ERROR_COUNT -eq 0 ] && [ $WARNING_COUNT -eq 0 ]; then
    print_success "🎉 Everything looks good! Ready to run!"
    echo ""
    echo "Next steps:"
    echo "  1. Start backend: cd backend && npm start"
    echo "  2. Run Flutter: cd flutter_pos_app && flutter run"
    echo ""
elif [ $ERROR_COUNT -gt 0 ]; then
    print_error "Please fix the errors above before running the app."
    echo ""
else
    print_warning "Some warnings detected. App may still work, but check above."
    echo ""
fi

echo "===================================================="
echo ""

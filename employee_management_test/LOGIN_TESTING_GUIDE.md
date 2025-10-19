# 🧪 LOGIN SYSTEM - TESTING CHECKLIST

**Date**: October 19, 2025  
**Version**: 1.0  
**Status**: ✅ Ready for Testing

---

## 📋 PRE-REQUISITES

### ✅ Backend Status
- [x] Backend API running on http://localhost:5000
- [x] Swagger UI: http://localhost:5000/swagger
- [x] Database: FaceCheckinDB with Employees table
- [x] Test accounts provisioned (ADMIN/HR/Employee)

### ✅ Frontend Status
- [x] LoginScreen created (lib/screens/auth/login_screen.dart)
- [x] SplashScreen created (lib/screens/auth/splash_screen.dart)
- [x] AdminDashboard created (lib/screens/dashboard/admin_dashboard.dart)
- [x] HRDashboard created (lib/screens/dashboard/hr_dashboard.dart)
- [x] EmployeeDashboard created (lib/screens/dashboard/employee_dashboard.dart)
- [x] AuthService implemented (JWT validation)
- [x] SecureStorageService implemented (Token storage)
- [x] Routes configured (/splash, /login, /admin-dashboard, /hr-dashboard, /employee-dashboard)

---

## 🎯 TEST CASES

### TC1: Initial App Launch (Splash Screen)
**Steps**:
1. Launch app (flutter run -d edge)
2. Observe splash screen animation (1.5s)
3. Check session: No token → Navigate to Login

**Expected Result**:
- ✅ Splash screen shows: Logo + "Quản lý Nhân viên" + Loading indicator
- ✅ After 1.5s → Navigate to LoginScreen
- ✅ No errors in console

---

### TC2: Login with Email (Admin)
**Steps**:
1. On LoginScreen, enter:
   - **Email hoặc Mã NV**: `admin@test.com`
   - **Mật khẩu**: `ADMIN-2025-0001@2025`
2. Click **Đăng nhập**
3. Observe loading state (CircularProgressIndicator on button)

**Expected Result**:
- ✅ Loading indicator appears
- ✅ API call to POST http://10.0.2.2:5000/api/Employee/login (or localhost for web)
- ✅ Response: 200 OK with JWT token
- ✅ Token saved to SecureStorage
- ✅ Success message: "Xin chào, Test Admin! Quản trị viên"
- ✅ Navigate to `/admin-dashboard`
- ✅ AdminDashboard shows:
  - Welcome card with user name
  - Quick access grid (6 cards: Nhân viên, Bảng lương, Phòng ban, Khuôn mặt, Chấm công, Báo cáo)
  - User profile button (top-right)
  - System status card

**Debug Check**:
```dart
// Console should show:
// Login successful for: admin@test.com
// Role: Admin (Level 2)
// Dashboard route: /admin-dashboard
```

---

### TC3: Login with Employee Code (Admin)
**Steps**:
1. On LoginScreen, enter:
   - **Email hoặc Mã NV**: `ADMIN-2025-0001`
   - **Mật khẩu**: `ADMIN-2025-0001@2025`
2. Click **Đăng nhập**

**Expected Result**:
- ✅ Same as TC2 (Navigate to AdminDashboard)
- ✅ Backend accepts both Email and Employee Code

---

### TC4: Login with HR Account
**Steps**:
1. On LoginScreen, enter:
   - **Email hoặc Mã NV**: `hr@test.com`
   - **Mật khẩu**: `HR-2025-0001@2025`
2. Click **Đăng nhập**

**Expected Result**:
- ✅ Success message: "Xin chào, Test HR! Nhân sự"
- ✅ Navigate to `/hr-dashboard`
- ✅ HRDashboard shows:
  - Welcome card with HR icon
  - HR Tasks grid (4 cards: Nhân viên, Bảng lương, Chấm công, Báo cáo)
  - Permissions info card (green checkmarks + red X's)
  - User profile button

---

### TC5: Login with Employee Account
**Steps**:
1. On LoginScreen, enter:
   - **Email hoặc Mã NV**: `user@test.com`
   - **Mật khẩu**: `IT-2025-0001@2025`
2. Click **Đăng nhập**

**Expected Result**:
- ✅ Success message: "Xin chào, Test User!"
- ✅ Navigate to `/employee-dashboard`
- ✅ EmployeeDashboard shows:
  - Welcome card with employee code
  - Self-service menu (4 items: Phiếu lương, Lịch sử chấm công, Thông tin cá nhân, Chấm công)
  - Info card (blue)
  - User profile button

---

### TC6: Invalid Credentials
**Steps**:
1. On LoginScreen, enter:
   - **Email hoặc Mã NV**: `admin@test.com`
   - **Mật khẩu**: `wrong-password`
2. Click **Đăng nhập**

**Expected Result**:
- ✅ API returns: 400 Bad Request
- ✅ Error message displayed via SnackBar (RED):
  ```
  "Mã nhân viên/Email hoặc mật khẩu không đúng"
  ```
- ✅ Remain on LoginScreen (no navigation)

---

### TC7: Empty Fields Validation
**Steps**:
1. On LoginScreen, leave fields empty
2. Click **Đăng nhập**

**Expected Result**:
- ✅ Validation errors shown:
  - "Vui lòng nhập email hoặc mã nhân viên"
  - "Vui lòng nhập mật khẩu"
- ✅ No API call made
- ✅ Red border on TextFormFields

---

### TC8: Session Persistence (Critical)
**Steps**:
1. Login successfully (any account)
2. Navigate to dashboard
3. Close browser tab completely
4. Reopen app (flutter run -d edge)

**Expected Result**:
- ✅ SplashScreen checks session: `isLoggedIn() == true`
- ✅ Token validation: `isTokenValid() == true`
- ✅ **Auto-navigate to Dashboard** (no login required)
- ✅ Dashboard shows correct user data

**Debug Check**:
```dart
// Console should show:
// Splash: Token found
// Token valid until: 2025-10-19T20:00:00Z
// Auto-navigating to: /admin-dashboard
```

---

### TC9: Token Expiry (Edge Case)
**Steps**:
1. Login successfully
2. Wait 8 hours (or manually expire token in SecureStorage)
3. Reopen app

**Expected Result**:
- ✅ SplashScreen checks: `isTokenValid() == false`
- ✅ Navigate to `/login`
- ✅ Show message: "Phiên đăng nhập đã hết hạn"

---

### TC10: Logout Functionality
**Steps**:
1. Login successfully
2. On Dashboard, click **User Profile Button** (top-right)
3. Click **Đăng xuất**

**Expected Result**:
- ✅ Call `authService.logout()` → Clear SecureStorage
- ✅ Navigate to `/login` with `pushNamedAndRemoveUntil`
- ✅ No back button to dashboard
- ✅ Reopen app → SplashScreen → LoginScreen (no session)

---

### TC11: Password Visibility Toggle
**Steps**:
1. On LoginScreen, enter password
2. Click **eye icon** (visibility toggle)

**Expected Result**:
- ✅ Initial: Password obscured (●●●●●●●)
- ✅ After click: Password visible (ADMIN-2025-0001@2025)
- ✅ Icon changes: visibility_off ↔ visibility

---

### TC12: Quick Access Navigation (Admin Dashboard)
**Steps**:
1. Login as Admin
2. On AdminDashboard, click **Nhân viên** card

**Expected Result**:
- ✅ Navigate to `/employees` (EmployeeListScreen)
- ✅ AppBar shows "Nhân viên"
- ✅ List of employees displayed

**Repeat for**:
- Bảng lương → `/payroll`
- Phòng ban → `/departments`
- Khuôn mặt → `/face/register`
- Chấm công → `/face/checkin`
- Báo cáo → `/payroll/chart`

---

### TC13: API Base URL (Web vs Mobile)
**Check Configuration**:
```dart
// lib/config/api_config.dart

// For Web (Edge/Chrome):
static const String baseUrl = 'http://localhost:5000/api';

// For Android Emulator:
static const String baseUrl = 'http://10.0.2.2:5000/api';

// For iOS Simulator:
static const String baseUrl = 'http://localhost:5000/api';

// For Physical Device:
static const String baseUrl = 'http://192.168.1.x:5000/api'; // Replace with PC IP
```

**Expected Result**:
- ✅ Web (Edge): Uses `localhost:5000`
- ✅ API calls successful (no CORS errors)

---

## 🔍 DEBUG CHECKLIST

### Console Logs to Monitor
```
✅ Splash: Checking session...
✅ Token found: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
✅ Token valid: true
✅ User role: Admin
✅ Navigating to: /admin-dashboard
✅ Login API: POST http://localhost:5000/api/Employee/login
✅ Response: 200 OK
✅ Token saved to SecureStorage
```

### Network Tab (F12 DevTools)
```
POST /api/Employee/login
Status: 200 OK
Response Time: < 500ms

Request Headers:
  Content-Type: application/json

Request Body:
  {"identifier":"admin@test.com","password":"ADMIN-2025-0001@2025"}

Response Body:
  {
    "success": true,
    "token": "eyJ...",
    "employee": {...},
    "expiresAt": "2025-10-19T20:00:00Z"
  }
```

### SecureStorage Verification
```dart
// Add temporary debug code
final token = await SecureStorageService.readToken();
print('Stored Token: $token');

final userData = await SecureStorageService.readUserData();
print('User Data: $userData');
```

---

## ❌ KNOWN ISSUES & SOLUTIONS

### Issue 1: CORS Error (Web)
**Error**: `Access-Control-Allow-Origin header missing`

**Solution**:
1. Backend must enable CORS in `Program.cs`:
```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        builder => builder.AllowAnyOrigin()
                         .AllowAnyMethod()
                         .AllowAnyHeader());
});

app.UseCors("AllowAll");
```

### Issue 2: SecureStorage Not Working (Web)
**Error**: `flutter_secure_storage` uses localStorage on web (not encrypted)

**Solution**:
- ✅ Acceptable for development
- ⚠️ Production: Use server-side sessions or JWT in httpOnly cookies

### Issue 3: Token Not Persisting
**Error**: Token cleared on app restart

**Solution**:
1. Check `isLoggedIn()` implementation:
```dart
static Future<bool> isLoggedIn() async {
  final token = await readToken();
  return token != null && token.isNotEmpty;
}
```
2. Verify `initializeDateFormatting()` doesn't clear storage

### Issue 4: 401 Unauthorized on Protected Routes
**Error**: API returns 401 even after login

**Solution**:
1. Check JWT token in request headers:
```dart
final token = await SecureStorageService.readToken();
final headers = {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $token', // ✅ Include token
};
```

---

## 📊 TEST RESULTS TEMPLATE

| Test Case | Status | Notes |
|-----------|--------|-------|
| TC1: Splash Screen | ⬜ | |
| TC2: Login with Email | ⬜ | |
| TC3: Login with Code | ⬜ | |
| TC4: HR Login | ⬜ | |
| TC5: Employee Login | ⬜ | |
| TC6: Invalid Credentials | ⬜ | |
| TC7: Empty Fields | ⬜ | |
| TC8: Session Persistence | ⬜ | **CRITICAL** |
| TC9: Token Expiry | ⬜ | |
| TC10: Logout | ⬜ | |
| TC11: Password Toggle | ⬜ | |
| TC12: Navigation | ⬜ | |
| TC13: API Base URL | ⬜ | |

**Legend**:
- ⬜ Not Tested
- ✅ PASS
- ❌ FAIL
- ⚠️ Partial Pass

---

## 🚀 NEXT STEPS AFTER TESTING

### If All Tests Pass ✅
1. Mark todo "TEST Login System E2E" as completed
2. Move to: "Implement Advanced Features"
   - ApiInterceptor (auto refresh token)
   - ApiErrorHandler (global error handling)
   - LoadingService (global loading state)

### If Tests Fail ❌
1. Document specific error messages
2. Check console logs + network tab
3. Verify backend response format
4. Debug with breakpoints in:
   - `login_screen.dart` (line 85-145)
   - `auth_service.dart` (line 32-60)
   - `splash_screen.dart` (line 38-65)

---

**END OF TESTING GUIDE**

*Start testing when Flutter app launches on Edge browser!*
*Backend must be running on http://localhost:5000*

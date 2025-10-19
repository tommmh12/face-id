# 🚀 ADVANCED FEATURES - IMPLEMENTATION GUIDE

**Version**: 1.0  
**Date**: October 19, 2025  
**Status**: ✅ Implementation Complete

---

## 📋 TABLE OF CONTENTS

1. [Overview](#overview)
2. [ApiInterceptor - Auto Token Refresh](#apiinterceptor)
3. [ApiErrorHandler - Global Error Handling](#apierrorhandler)
4. [LoadingService - Global Loading State](#loadingservice)
5. [Integration Guide](#integration-guide)
6. [Testing](#testing)

---

## 1. OVERVIEW

### ✅ Features Implemented

| Feature | File | Lines | Status |
|---------|------|-------|--------|
| **ApiInterceptor** | `lib/services/api_interceptor.dart` | 230 | ✅ Complete |
| **ApiErrorHandler** | `lib/services/api_error_handler.dart` | 270 | ✅ Complete |
| **LoadingService** | `lib/services/loading_service.dart` | 200 | ✅ Complete |
| **Provider Setup** | `lib/main.dart` | - | ⏳ Pending |

### 🎯 Benefits

1. **ApiInterceptor**:
   - ✅ Auto-inject Bearer token to all requests
   - ✅ Auto-refresh token on 401 Unauthorized
   - ✅ Auto-retry failed requests with new token
   - ✅ Centralized timeout handling

2. **ApiErrorHandler**:
   - ✅ User-friendly error messages (Vietnamese)
   - ✅ Status code to icon/color mapping
   - ✅ Network/timeout error detection
   - ✅ Consistent SnackBar UI

3. **LoadingService**:
   - ✅ Global loading state (no prop drilling)
   - ✅ Prevent multiple simultaneous loads
   - ✅ Customizable loading message
   - ✅ Full-screen overlay with backdrop

---

## 2. APIINTERCEPTOR

### 📁 File: `lib/services/api_interceptor.dart`

### 🔧 Features

```dart
class ApiInterceptor {
  // Wrapper methods with auto token refresh
  static Future<http.Response> get(Uri url, {...});
  static Future<http.Response> post(Uri url, {...});
  static Future<http.Response> put(Uri url, {...});
  static Future<http.Response> delete(Uri url, {...});
}
```

### 🔄 Auto Token Refresh Flow

```
┌─────────────────────────────────────────────────────┐
│                 API Request Flow                    │
├─────────────────────────────────────────────────────┤
│                                                     │
│  1. Build Headers (Add Bearer Token)               │
│     ├── Read token from SecureStorage              │
│     └── Add "Authorization: Bearer <token>"        │
│                                                     │
│  2. Make HTTP Request                               │
│     ├── GET/POST/PUT/DELETE                        │
│     └── With timeout (30s default)                 │
│                                                     │
│  3. Check Response Status                           │
│     ├── 200-299 → ✅ SUCCESS (Return response)     │
│     ├── 401     → ⚠️ UNAUTHORIZED (Go to step 4)   │
│     └── Other   → ❌ ERROR (Return response)       │
│                                                     │
│  4. Token Refresh Logic (Only on 401)              │
│     ├── Call authService.refreshAccessToken()      │
│     ├── Success → ✅ Get new token                 │
│     └── Fail    → ❌ Return 401 (Force re-login)   │
│                                                     │
│  5. Retry Request (With new token)                 │
│     ├── Build headers with NEW token               │
│     ├── Retry same request                         │
│     └── Return response                            │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 📝 Usage Examples

#### Before (Without ApiInterceptor):
```dart
// ❌ Manual token management
final token = await SecureStorageService.readToken();
final response = await http.get(
  Uri.parse('${ApiConfig.baseUrl}/Employee'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token', // Manual injection
  },
);

if (response.statusCode == 401) {
  // ❌ Manual refresh logic
  // ... lots of boilerplate code
}
```

#### After (With ApiInterceptor):
```dart
// ✅ Automatic token injection + refresh
final response = await ApiInterceptor.get(
  Uri.parse('${ApiConfig.baseUrl}/Employee'),
);

// Token automatically added to headers
// 401 errors automatically handled
// Request automatically retried with new token
```

### 🔑 Key Methods

**1. GET Request**:
```dart
final response = await ApiInterceptor.get(
  Uri.parse('${ApiConfig.baseUrl}/Employee'),
  headers: {'Custom-Header': 'value'}, // Optional
  timeout: Duration(seconds: 30), // Optional
);
```

**2. POST Request**:
```dart
final response = await ApiInterceptor.post(
  Uri.parse('${ApiConfig.baseUrl}/Employee/login'),
  body: json.encode({
    'identifier': 'admin@test.com',
    'password': 'password123',
  }),
);
```

**3. Network Error Detection**:
```dart
try {
  final response = await ApiInterceptor.get(url);
} catch (e) {
  if (ApiInterceptor.isNetworkError(e)) {
    print('No internet connection');
  }
  if (ApiInterceptor.isTimeoutError(e)) {
    print('Request timeout');
  }
}
```

---

## 3. APIERRORHANDLER

### 📁 File: `lib/services/api_error_handler.dart`

### 🎨 Features

```dart
class ApiErrorHandler {
  // Handle HTTP error responses
  static void handleError(
    BuildContext context,
    http.Response response, {...}
  );
  
  // Handle network/timeout exceptions
  static void handleException(
    BuildContext context,
    Object error, {...}
  );
  
  // Show success message
  static void showSuccess(
    BuildContext context,
    String message, {...}
  );
}
```

### 📊 Status Code Mapping

| Status Code | Message (Vietnamese) | Icon | Color |
|-------------|----------------------|------|-------|
| **400** | "Yêu cầu không hợp lệ. Vui lòng kiểm tra lại thông tin." | ⚠️ `warning_amber` | 🟠 Orange |
| **401** | "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại." | 🔒 `lock_outline` | 🔴 Deep Orange |
| **403** | "Bạn không có quyền truy cập tài nguyên này." | 🚫 `block` | 🔴 Deep Orange |
| **404** | "Không tìm thấy dữ liệu yêu cầu." | 🔍 `search_off` | 🔵 Blue |
| **409** | "Dữ liệu đã tồn tại hoặc xung đột." | ❌ `error_outline` | 🟡 Amber |
| **422** | "Dữ liệu không hợp lệ. Vui lòng kiểm tra lại." | ⚠️ `warning_amber` | 🟠 Orange |
| **500** | "Lỗi máy chủ. Vui lòng thử lại sau." | ☁️ `cloud_off` | 🔴 Red |
| **502** | "Máy chủ không phản hồi. Vui lòng thử lại sau." | ☁️ `cloud_off` | 🔴 Red |
| **503** | "Dịch vụ tạm thời không khả dụng. Vui lòng thử lại sau." | ☁️ `cloud_off` | 🔴 Red |

### 📝 Usage Examples

#### 1. Handle HTTP Error Response:
```dart
final response = await http.get(url);

if (response.statusCode != 200) {
  ApiErrorHandler.handleError(context, response);
  return;
}

// Process successful response
```

#### 2. Handle Network Exception:
```dart
try {
  final response = await http.get(url);
} catch (e) {
  ApiErrorHandler.handleException(context, e);
  return;
}
```

#### 3. Custom Error Message:
```dart
ApiErrorHandler.handleError(
  context,
  response,
  customMessage: 'Không thể lưu dữ liệu. Vui lòng thử lại.',
);
```

#### 4. Show Success Message:
```dart
ApiErrorHandler.showSuccess(
  context,
  'Lưu thành công!',
  duration: Duration(seconds: 2),
);
```

### 🎨 SnackBar UI

```
┌────────────────────────────────────────────┐
│  🔒  Lỗi (401)                             │
│      Phiên đăng nhập đã hết hạn.          │
│      Vui lòng đăng nhập lại.              │
└────────────────────────────────────────────┘
      ↑ Deep Orange background
```

---

## 4. LOADINGSERVICE

### 📁 File: `lib/services/loading_service.dart`

### ⏳ Features

```dart
class LoadingService extends ChangeNotifier {
  bool get isLoading;
  String get loadingMessage;
  
  void show([String message]);
  void hide();
  Future<T> execute<T>(Future<T> Function() operation, {...});
}
```

### 🎨 Components

1. **LoadingService** (ChangeNotifier)
   - State management for loading
   
2. **GlobalLoadingOverlay** (Widget)
   - Full-screen loading overlay
   
3. **LoadingConsumer** (Widget)
   - Convenience widget for Consumer
   
4. **LoadingServiceExtension** (Extension)
   - Extension methods on BuildContext

### 📝 Usage Examples

#### Setup in main.dart (Step 1):
```dart
import 'package:provider/provider.dart';
import 'services/loading_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LoadingService(),
      child: const MyApp(),
    ),
  );
}
```

#### Setup Global Overlay (Step 2):
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            Consumer<LoadingService>(
              builder: (context, loading, _) {
                return loading.isLoading
                    ? const GlobalLoadingOverlay()
                    : const SizedBox.shrink();
              },
            ),
          ],
        );
      },
      // ... routes, theme, etc.
    );
  }
}
```

#### Usage in Login Screen:
```dart
// Method 1: Manual show/hide
context.read<LoadingService>().show('Đang đăng nhập...');
try {
  final response = await authService.login(...);
  context.read<LoadingService>().hide();
} catch (e) {
  context.read<LoadingService>().hide();
}

// Method 2: Auto show/hide with execute()
final loadingService = context.read<LoadingService>();
final response = await loadingService.execute(
  () => authService.login(...),
  message: 'Đang đăng nhập...',
);

// Method 3: Using extension methods
context.showLoading('Đang xử lý...');
try {
  await someAsyncOperation();
  context.hideLoading();
} catch (e) {
  context.hideLoading();
}
```

### 🎨 Loading Overlay UI

```
┌────────────────────────────────────────────┐
│                                            │
│   [Black backdrop with 50% opacity]       │
│                                            │
│         ┌──────────────────┐              │
│         │                  │              │
│         │  ⏳ Spinner      │              │
│         │                  │              │
│         │  Đang đăng nhập...│              │
│         │                  │              │
│         └──────────────────┘              │
│           ↑ White Card                    │
│                                            │
└────────────────────────────────────────────┘
```

---

## 5. INTEGRATION GUIDE

### 🚀 Step-by-Step Integration

#### **Step 1: Setup Provider in main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/loading_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LoadingService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Management',
      
      // ✅ Add global loading overlay
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            Consumer<LoadingService>(
              builder: (context, loading, _) {
                return loading.isLoading
                    ? const GlobalLoadingOverlay()
                    : const SizedBox.shrink();
              },
            ),
          ],
        );
      },
      
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        // ... other routes
      },
    );
  }
}
```

#### **Step 2: Update LoginScreen with All Features**

```dart
// lib/screens/auth/login_screen.dart

import 'package:provider/provider.dart';
import '../../services/api_interceptor.dart';
import '../../services/api_error_handler.dart';
import '../../services/loading_service.dart';
import '../../services/auth_service.dart';

Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;

  final loadingService = context.read<LoadingService>();
  final authService = AuthService();

  try {
    // ✅ Show loading
    loadingService.show('Đang đăng nhập...');

    // ✅ Call API with ApiInterceptor (auto token injection)
    final response = await authService.login(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
    );

    // ✅ Hide loading
    loadingService.hide();

    if (response.success) {
      // ✅ Show success message
      ApiErrorHandler.showSuccess(
        context,
        'Xin chào, ${response.fullName}!',
      );

      // Navigate to dashboard
      Navigator.pushNamedAndRemoveUntil(
        context,
        response.dashboardRoute,
        (route) => false,
      );
    }
  } catch (e) {
    // ✅ Hide loading
    loadingService.hide();

    // ✅ Show error
    ApiErrorHandler.handleException(context, e);
  }
}
```

#### **Step 3: Update API Calls to Use ApiInterceptor**

```dart
// Before:
final token = await SecureStorageService.readToken();
final response = await http.get(
  Uri.parse('${ApiConfig.baseUrl}/Employee'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
);

// After:
final response = await ApiInterceptor.get(
  Uri.parse('${ApiConfig.baseUrl}/Employee'),
);

// Automatically includes Bearer token
// Automatically refreshes on 401
```

---

## 6. TESTING

### ✅ Test Checklist

| Test Case | Status | Notes |
|-----------|--------|-------|
| **ApiInterceptor** | | |
| TC1: Token injection | ⬜ | Verify "Authorization" header |
| TC2: 401 → Refresh token | ⬜ | Simulate expired token |
| TC3: Retry after refresh | ⬜ | Verify request retried |
| TC4: Network error | ⬜ | Disconnect internet |
| TC5: Timeout error | ⬜ | Simulate slow API |
| **ApiErrorHandler** | | |
| TC6: 400 Bad Request | ⬜ | Orange SnackBar |
| TC7: 401 Unauthorized | ⬜ | Deep Orange SnackBar |
| TC8: 404 Not Found | ⬜ | Blue SnackBar |
| TC9: 500 Server Error | ⬜ | Red SnackBar |
| TC10: Network exception | ⬜ | "Không có kết nối mạng" |
| TC11: Success message | ⬜ | Green SnackBar |
| **LoadingService** | | |
| TC12: Show loading | ⬜ | Overlay appears |
| TC13: Hide loading | ⬜ | Overlay disappears |
| TC14: Execute method | ⬜ | Auto show/hide |
| TC15: Multiple loads | ⬜ | No stacking |

### 🧪 Test Scripts

#### Test ApiInterceptor Token Injection:
```dart
final response = await ApiInterceptor.get(
  Uri.parse('${ApiConfig.baseUrl}/Employee'),
);

// Check Network tab (F12):
// Request Headers should include:
// Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### Test ApiErrorHandler:
```dart
// Simulate 401 error
final response = http.Response('Unauthorized', 401);
ApiErrorHandler.handleError(context, response);

// Expected: Deep Orange SnackBar with lock icon
```

#### Test LoadingService:
```dart
context.showLoading('Testing...');
await Future.delayed(Duration(seconds: 2));
context.hideLoading();

// Expected: Loading overlay for 2 seconds
```

---

## 📊 SUMMARY

### ✅ Completed Implementation

1. **ApiInterceptor** (230 lines)
   - ✅ Auto token injection
   - ✅ Auto refresh on 401
   - ✅ Retry logic
   - ✅ Network/timeout detection

2. **ApiErrorHandler** (270 lines)
   - ✅ Status code mapping
   - ✅ Icon/color coding
   - ✅ User-friendly messages
   - ✅ SnackBar UI

3. **LoadingService** (200 lines)
   - ✅ ChangeNotifier
   - ✅ Global overlay
   - ✅ Extension methods
   - ✅ Provider integration

### ⏳ Next Steps

1. Setup Provider in `main.dart`
2. Update LoginScreen to use all features
3. Update all API calls to use ApiInterceptor
4. E2E testing with LOGIN_TESTING_GUIDE.md

---

**END OF ADVANCED FEATURES GUIDE**

*For support, see LOGIN_SYSTEM_GUIDE.md*  
*Last Updated: October 19, 2025*

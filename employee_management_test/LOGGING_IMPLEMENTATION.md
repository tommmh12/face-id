# 📝 Logging Implementation Guide

## ✅ Triển khai hệ thống logging toàn diện cho Flutter App

**Ngày:** $(Get-Date -Format "dd/MM/yyyy")  
**Mục tiêu:** Thêm logging nhất quán và chi tiết để dễ dàng debug lỗi trong production

---

## 📊 Tổng quan

### 🎯 Mục tiêu
- **Logging nhất quán** với emoji indicators cho dễ đọc
- **Categorization** rõ ràng (Camera, API, UI, Data, Security...)
- **Performance tracking** với đo thời gian thực thi
- **Error tracking** với stack traces đầy đủ
- **Security** - Tự động mask dữ liệu nhạy cảm (imageBase64)

### 🛠️ Giải pháp: AppLogger Utility Class

File: `lib/utils/app_logger.dart` (199 lines)

**Đặc điểm:**
- ✅ 15+ phương thức logging chuyên biệt
- ✅ Emoji indicators (📸🚀📥✅❌⚠️ℹ️💾🎨🔐📊🔍🎯)
- ✅ Optional tags cho filtering
- ✅ Stack trace auto-capture cho errors
- ✅ Performance timing với visual indicators (⚡🏃🐌)
- ✅ API logging với data masking
- ✅ Visual separators cho complex operations

---

## 📦 Files đã cập nhật

### 1️⃣ **lib/utils/app_logger.dart** (NEW)

**Các phương thức chính:**

#### General Logging
```dart
AppLogger.info('Message', tag: 'Optional');
AppLogger.success('Operation successful', tag: 'Task');
AppLogger.warning('Potential issue', tag: 'Validation');
AppLogger.error('Error occurred', error: e, stackTrace: stackTrace, tag: 'Critical');
```

#### API Logging
```dart
// Request - Automatically masks imageBase64
AppLogger.apiRequest('/api/face/register', method: 'POST', data: requestJson);

// Response
AppLogger.apiResponse('/api/face/register', 
  success: true, 
  message: 'Success', 
  data: 'FaceId: abc123'
);
```

#### Category-specific
```dart
AppLogger.camera('Camera initialized');
AppLogger.navigation('HomeScreen', 'DetailScreen', arguments: {'id': 123});
AppLogger.data('Loading employees: 50 items');
AppLogger.ui('Showing dialog');
AppLogger.security('Authentication token refreshed');
AppLogger.business('User confirmed purchase');
```

#### Performance Tracking
```dart
final stopwatch = Stopwatch()..start();
// ... do work ...
stopwatch.stop();
AppLogger.performance('Image compression', stopwatch.elapsed);
// Output: "📊 [PERFORMANCE] Image compression took 234ms ⚡"
```

#### Complex Operations
```dart
AppLogger.startOperation('Face Registration');
AppLogger.separator(title: 'STEP 1/4: Capture Image');
// ... step 1 ...
AppLogger.separator(title: 'STEP 2/4: Validate Face');
// ... step 2 ...
AppLogger.endOperation('Face Registration', success: true);
```

---

### 2️⃣ **lib/screens/face/face_register_screen.dart**

**Đã thay thế tất cả `debugPrint()` với AppLogger:**

| Phương thức | Before | After |
|-------------|--------|-------|
| `_initializeCamera()` | `debugPrint('📸 Initializing...')` | `AppLogger.camera('Initializing camera...')` |
| `_loadEmployees()` | `debugPrint('Loading employees...')` | `AppLogger.data('Loading employees...')` |
| `_registerFace()` | `debugPrint('🚀 [1/4] Capturing...')` | `AppLogger.startOperation()` + `AppLogger.separator()` |
| `dispose()` | `debugPrint('🔒 Disposing...')` | `AppLogger.info('Disposing...', tag: 'Lifecycle')` |

**Highlights:**

```dart
// Complex operation with steps
Future<void> _registerFace() async {
  AppLogger.startOperation(_isReRegister ? 'Face Re-Registration' : 'Face Registration');
  
  AppLogger.separator(title: 'STEP 1/4: Capture Image');
  // ... capture logic ...
  AppLogger.success('Image captured: ${base64Image.length} chars', tag: 'FaceRegister');
  
  AppLogger.separator(title: 'STEP 2/4: Validate Face');
  // ... validation logic ...
  AppLogger.success('Face validated successfully', tag: 'FaceRegister');
  
  AppLogger.separator(title: 'STEP 3/4: Prepare Request');
  // ... prepare request ...
  
  AppLogger.separator(title: 'STEP 4/4: Call API');
  AppLogger.apiRequest(endpoint, method: 'POST', data: request.toJson());
  // ... API call ...
  AppLogger.apiResponse(endpoint, success: response.success, message: response.message);
  
  AppLogger.endOperation('Face Registration', success: true);
}
```

---

### 3️⃣ **lib/utils/camera_helper.dart**

**Logging cho image compression:**

```dart
static Future<Uint8List> _compressImage(Uint8List imageBytes) async {
  final stopwatch = Stopwatch()..start();
  
  AppLogger.data(
    'Original image: ${image.width}x${image.height}, ${imageBytes.length} bytes',
    tag: 'CameraHelper',
  );
  
  // ... compression logic ...
  
  AppLogger.data('Resized to: ${image.width}x${image.height}', tag: 'CameraHelper');
  AppLogger.data('Compressed: ${compressedBytes.length} bytes', tag: 'CameraHelper');
  
  if (compressedBytes.length > maxSizeBytes) {
    AppLogger.warning('Compressed image > 2MB, re-compressing...', tag: 'CameraHelper');
    // ... re-compress ...
  }
  
  stopwatch.stop();
  AppLogger.performance('Image compression', stopwatch.elapsed);
  
  return compressedBytes;
}
```

---

### 4️⃣ **lib/services/face_api_service.dart**

**API request/response tracking:**

```dart
Future<ApiResponse<RegisterEmployeeFaceResponse>> register(RegisterEmployeeFaceRequest request) async {
  // Log request (imageBase64 will be masked automatically)
  AppLogger.apiRequest('$_endpoint/register', method: 'POST', data: request.toJson());
  
  final response = await handleRequest(
    () => CustomHttpClient.post(...),
    (json) => RegisterEmployeeFaceResponse.fromJson(json),
  );
  
  // Log response
  AppLogger.apiResponse(
    '$_endpoint/register',
    success: response.success,
    message: response.message,
    data: response.data != null ? 'FaceId: ${response.data!.faceId}' : null,
  );
  
  return response;
}
```

**Tất cả 4 endpoints đã có logging:**
- ✅ `/api/face/register`
- ✅ `/api/face/re-register`
- ✅ `/api/face/checkin`
- ✅ `/api/face/checkout`

---

## 🎨 Output Examples

### ✅ Successful Registration
```
═══════════════════════════════════════════════════════════
🎯 STARTING OPERATION: Face Registration
═══════════════════════════════════════════════════════════

────────────────────────────────────────────────────────────
📋 STEP 1/4: Capture Image
────────────────────────────────────────────────────────────
📸 [CAMERA] Initializing camera...
✅ [SUCCESS] [FaceRegister] Image captured: 145234 chars (141.8 KB encoded)

────────────────────────────────────────────────────────────
📋 STEP 2/4: Validate Face
────────────────────────────────────────────────────────────
💾 [DATA] [CameraHelper] Original image: 1920x1080, 524288 bytes (512.0 KB)
💾 [DATA] [CameraHelper] Resized to: 1080x607
💾 [DATA] [CameraHelper] Compressed: 89123 bytes (87.0 KB)
📊 [PERFORMANCE] Image compression took 234ms ⚡
✅ [SUCCESS] [FaceRegister] Face validated successfully

────────────────────────────────────────────────────────────
📋 STEP 3/4: Prepare Request
────────────────────────────────────────────────────────────
💾 [DATA] [FaceRegister] Request prepared (EmployeeId: emp001)

────────────────────────────────────────────────────────────
📋 STEP 4/4: Call API
────────────────────────────────────────────────────────────
🚀 [API REQUEST] POST /face/register
    Data: {employeeId: emp001, imageBase64: [MASKED - 141.8 KB]}
📥 [API RESPONSE] /face/register ✅ SUCCESS
    Message: Face registered successfully
    Data: FaceId: abc-123-def-456

📊 [PERFORMANCE] Face registration took 1.2s 🏃

═══════════════════════════════════════════════════════════
🎯 OPERATION COMPLETED: Face Registration ✅ SUCCESS
═══════════════════════════════════════════════════════════
```

### ❌ Error with Stack Trace
```
❌ [ERROR] [FaceRegister] Unexpected error during face registration
    Error: SocketException: Failed host lookup: 'api.studyplannerapp.io.vn'
    Stack Trace:
    #0      CameraHelper.captureImageAsBase64 (lib/utils/camera_helper.dart:45)
    #1      FaceRegisterScreen._registerFace (lib/screens/face/face_register_screen.dart:234)
    ...

═══════════════════════════════════════════════════════════
🎯 OPERATION COMPLETED: Face Registration ❌ FAILED
═══════════════════════════════════════════════════════════
```

---

## 📊 Logging Categories

| Category | Method | Emoji | Use Case |
|----------|--------|-------|----------|
| General | `info()` | ℹ️ | General information |
| Success | `success()` | ✅ | Successful operations |
| Warning | `warning()` | ⚠️ | Potential issues |
| Error | `error()` | ❌ | Errors with stack traces |
| API Request | `apiRequest()` | 🚀 | HTTP requests (auto-masks imageBase64) |
| API Response | `apiResponse()` | 📥 | HTTP responses with success flag |
| Navigation | `navigation()` | 🧭 | Screen transitions |
| Camera | `camera()` | 📸 | Camera operations |
| Data | `data()` | 💾 | Data loading/processing |
| UI | `ui()` | 🎨 | UI state changes |
| Security | `security()` | 🔐 | Authentication/authorization |
| Performance | `performance()` | 📊 | Timing with visual indicators |
| Business | `business()` | 🎯 | Business logic decisions |
| Debug | `debug()` | 🔍 | Development-only logs |

---

## 🔒 Security Features

### Auto-masking sensitive data

AppLogger automatically detects and masks `imageBase64` fields:

```dart
AppLogger.apiRequest('/api/face/register', 
  method: 'POST', 
  data: {
    'employeeId': 'emp001',
    'imageBase64': '/9j/4AAQSkZJRgABAQEAYABgAAD...' // 150KB
  }
);

// Output:
// 🚀 [API REQUEST] POST /api/face/register
//     Data: {employeeId: emp001, imageBase64: [MASKED - 146.5 KB]}
```

---

## 🚀 Next Steps

### Files chưa cập nhật (Optional):

1. **lib/screens/face/face_checkin_screen.dart**
   - Thêm logging cho `_performFaceRecognition()`
   - Track checkin success/failure

2. **lib/screens/employee/employee_detail_screen.dart**
   - Logging cho CRUD operations
   - Track employee updates

3. **lib/services/employee_api_service.dart**
   - API logging cho employee endpoints
   - Similar to FaceApiService

4. **lib/screens/employee/employee_list_screen.dart**
   - Data loading logs
   - Pagination tracking

---

## 📖 Usage Guidelines

### ✅ DO:
- Use appropriate log levels (info, success, warning, error)
- Add tags for better filtering: `tag: 'ScreenName'`
- Use `startOperation()` / `endOperation()` for complex flows
- Use `separator()` for multi-step processes
- Capture stack traces for all errors: `error: e, stackTrace: stackTrace`
- Use `performance()` for time-sensitive operations

### ❌ DON'T:
- Don't log sensitive data directly (passwords, tokens) - use `security()` with care
- Don't use `debugPrint()` anymore - use AppLogger instead
- Don't log inside tight loops (performance impact)
- Don't forget to add tags for important logs

---

## 🎓 Examples

### Basic Logging
```dart
AppLogger.info('Loading data...', tag: 'DataScreen');
AppLogger.success('Data loaded: 50 items', tag: 'DataScreen');
AppLogger.warning('Cache expired, fetching new data', tag: 'Cache');
AppLogger.error('Failed to load', error: e, stackTrace: stackTrace, tag: 'DataScreen');
```

### API Call
```dart
AppLogger.apiRequest('/api/employees', method: 'GET');
final response = await employeeService.getAll();
AppLogger.apiResponse('/api/employees', 
  success: response.success, 
  message: response.message,
  data: 'Count: ${response.data?.length ?? 0}'
);
```

### Navigation Tracking
```dart
AppLogger.navigation('EmployeeList', 'EmployeeDetail', arguments: {'id': employeeId});
Navigator.pushNamed(context, '/employee-detail', arguments: employeeId);
```

### Performance Measurement
```dart
final stopwatch = Stopwatch()..start();
await heavyOperation();
stopwatch.stop();
AppLogger.performance('Heavy operation', stopwatch.elapsed);
```

### Complex Operation
```dart
AppLogger.startOperation('Employee Registration');

AppLogger.separator(title: 'STEP 1/3: Validate Input');
// ... validation ...
AppLogger.success('Input validated', tag: 'Registration');

AppLogger.separator(title: 'STEP 2/3: Create Employee');
// ... create employee ...
AppLogger.success('Employee created: ${employee.id}', tag: 'Registration');

AppLogger.separator(title: 'STEP 3/3: Register Face');
// ... register face ...
AppLogger.success('Face registered: ${faceId}', tag: 'Registration');

AppLogger.endOperation('Employee Registration', success: true);
```

---

## ✅ Summary

**Files đã cập nhật:**
- ✅ `lib/utils/app_logger.dart` (NEW - 199 lines)
- ✅ `lib/screens/face/face_register_screen.dart` (15+ methods updated)
- ✅ `lib/utils/camera_helper.dart` (compression logging)
- ✅ `lib/services/face_api_service.dart` (4 endpoints: register, re-register, checkin, checkout)

**Benefits:**
- 🎯 **Consistent logging** across app
- 🔍 **Easy debugging** with emoji indicators
- 📊 **Performance tracking** built-in
- 🔒 **Security** - Auto-mask sensitive data
- 📝 **Better documentation** of code flow
- ⚡ **Production-ready** logging

**Testing:**
1. Run app: `flutter run`
2. Perform face registration
3. Check console output - sẽ thấy logs đẹp với emoji và structure rõ ràng
4. Trigger errors để xem stack traces

---

**🎉 Hoàn thành!** App giờ có hệ thống logging toàn diện, dễ debug và maintain.

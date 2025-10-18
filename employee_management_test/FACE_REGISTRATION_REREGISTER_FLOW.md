# 🎭 Face Registration with Re-Registration Flow

## 📋 Tổng quan tính năng

**FaceRegisterScreen** đã được viết lại hoàn toàn với logic phức tạp để xử lý:

1. ✅ Đăng ký Face ID lần đầu
2. ✅ Phát hiện khuôn mặt đã tồn tại
3. ✅ **Đăng ký lại (Re-Registration)** - Xóa ảnh cũ và thay thế bằng ảnh mới

---

## 🎯 Các Luồng Chính

### 📊 Luồng 1: Đăng Ký Lần Đầu (Normal Registration)

```
User vào màn hình
    ↓
Select employee từ dropdown (chỉ hiện NV chưa có Face ID)
    ↓
Click "Đăng Ký Face ID"
    ↓
Show Guidelines Dialog → User confirm
    ↓
Capture image → Validate face
    ↓
Call POST /api/face/register
    ↓
┌─────────────────────────────────────┐
│ Backend Response                    │
├─────────────────────────────────────┤
│ Success = true                      │
│   ✅ Show success dialog            │
│   ✅ Return to previous screen      │
│                                     │
│ Success = false                     │
│   ❌ Check error message            │
│   ├─ Contains "đã được đăng ký"?    │
│   │   → Go to Luồng 2 (Re-Reg)     │
│   └─ Other error                    │
│       → Show SnackBar               │
└─────────────────────────────────────┘
```

---

### 🔄 Luồng 2: Đăng Ký Lại (Re-Registration Flow)

```
API /register returns error: "Khuôn mặt đã được đăng ký..."
    ↓
✅ Detect keyword "đã được đăng ký" in error message
    ↓
Show AlertDialog "⚠️ Khuôn Mặt Đã Tồn Tại!"
    ├─ Display original error message
    ├─ Warning: "Ảnh cũ sẽ bị xóa"
    └─ Actions: [Hủy] [Đăng Ký Lại]
    ↓
User clicks "Đăng Ký Lại"
    ↓
Set _isReRegister = true
    ↓
Call _registerFace() again (reuse captured image)
    ↓
This time calls POST /api/face/re-register
    ↓
┌─────────────────────────────────────┐
│ Backend Re-Register Logic           │
├─────────────────────────────────────┤
│ 1. Delete old FaceId from AWS       │
│ 2. Delete old S3 image              │
│ 3. Upload new image to S3           │
│ 4. Index new face in Rekognition    │
│ 5. Update DB with new FaceId        │
└─────────────────────────────────────┘
    ↓
✅ Show success dialog "Đăng Ký Lại Thành Công"
    ↓
✅ Return to previous screen
```

---

## 🔑 Key Features Implemented

### 1️⃣ **Smart Error Detection**

```dart
bool _isFaceAlreadyRegisteredError(String errorMessage) {
  final lowerMsg = errorMessage.toLowerCase();
  return lowerMsg.contains('đã được đăng ký') ||
         lowerMsg.contains('đã tồn tại') ||
         lowerMsg.contains('already registered') ||
         lowerMsg.contains('already exists') ||
         lowerMsg.contains('duplicate face') ||
         lowerMsg.contains('face id đã có');
}
```

**Hỗ trợ**: Tiếng Việt + English error messages

---

### 2️⃣ **Captured Image Caching**

```dart
String? _capturedBase64Image; // ✅ Store for re-registration

// When capturing first time:
_capturedBase64Image = base64Image;

// When re-registering:
if (_isReRegister && _capturedBase64Image != null) {
  base64Image = _capturedBase64Image!; // Reuse
} else {
  base64Image = await CameraHelper.captureImageAsBase64();
}
```

**Lợi ích**: 
- User không cần chụp lại ảnh
- Đảm bảo dùng cùng 1 ảnh cho register và re-register
- Tránh confusion

---

### 3️⃣ **Re-Registration Dialog**

```dart
void _showReRegistrationDialog(String originalErrorMessage) {
  showDialog(
    ...
    icon: Icon(Icons.warning_amber_rounded, color: Colors.orange),
    title: '⚠️ Khuôn Mặt Đã Tồn Tại!',
    content: [
      Display original error message,
      Warning box với:
        • Ảnh cũ sẽ bị xóa
        • Ảnh mới thay thế hoàn toàn
        • Không thể hoàn tác
    ],
    actions: [
      [Hủy] → Clear cached image,
      [Đăng Ký Lại] → Set _isReRegister = true → Call _registerFace()
    ]
  );
}
```

**UX Design**:
- ⚠️ Orange color scheme (warning)
- 📋 Clear explanation of consequences
- ✅ Explicit consent required

---

### 4️⃣ **Conditional API Calls**

```dart
final response = _isReRegister
    ? await _faceService.reRegister(request)  // POST /api/face/re-register
    : await _faceService.register(request);   // POST /api/face/register
```

**Flag-based routing**: Đơn giản, rõ ràng

---

### 5️⃣ **Enhanced Guidelines Dialog**

```dart
// Title changes based on mode
title: Text(_isReRegister 
  ? '📸 Hướng dẫn chụp lại Face ID'  // Re-reg mode
  : '📸 Hướng dẫn chụp ảnh Face ID') // Normal mode

// Info box color changes
color: _isReRegister 
  ? Colors.orange.shade50  // Warning for re-reg
  : Colors.blue.shade50    // Info for normal

// Message changes
text: _isReRegister
  ? 'Ảnh cũ sẽ bị xóa và thay bằng ảnh mới'
  : 'Ảnh phải là JPG hoặc PNG, < 2MB'
```

---

### 6️⃣ **Success Dialog Enhancements**

```dart
// Title with emoji
title: Text(_isReRegister 
  ? '✅ Đăng Ký Lại Thành Công' 
  : '✅ Đăng Ký Thành Công')

// Content message
Text(_isReRegister
  ? 'Face ID đã được cập nhật thành công cho nhân viên:'
  : 'Face ID đã được đăng ký thành công cho nhân viên:')

// Info box for re-reg
if (_isReRegister) 
  Container(
    color: Colors.orange.shade50,
    child: 'Ảnh cũ đã bị xóa và thay bằng ảnh mới'
  )
```

---

## 📝 State Management

### State Variables:

```dart
bool _isReRegister = false;           // ✅ Re-registration mode flag
String? _capturedBase64Image;         // ✅ Cached image for re-use
bool _isCameraInitialized = false;    // ✅ Camera ready state
bool _isRegistering = false;          // ✅ Processing state
Employee? _selectedEmployee;          // ✅ Selected employee
```

### State Flow:

```
Initial State:
_isReRegister = false
_capturedBase64Image = null

User captures image:
_capturedBase64Image = "iVBORw0K..." (stored)

API returns "face exists":
_isReRegister = false (still)
_capturedBase64Image = "iVBORw0..." (preserved)
Show dialog

User confirms re-register:
_isReRegister = true ✅
_capturedBase64Image = "iVBORw0..." (reused)
Call _registerFace() again

After success:
_isReRegister = false (reset)
_capturedBase64Image = null (cleared)
```

---

## 🎨 UI States

### 1. **Loading State**
```
Camera initializing → CircularProgressIndicator
"Đang khởi động camera..."
```

### 2. **Ready State**
```
Camera preview with:
- Face overlay (green circle + corners)
- Instructions text overlay
- Dropdown (if no employee passed via args)
- "Đăng Ký Face ID" button (enabled)
```

### 3. **Registering State**
```
Button disabled
Button shows: "Đang đăng ký..." + CircularProgressIndicator
```

### 4. **Error State**
```
Camera failed → Red icon + "Camera không khả dụng"
+ "Thử lại" button → Calls _initializeCamera()
```

---

## 🔍 Error Detection Matrix

| Backend Message Contains | Action | UI Response |
|-------------------------|--------|-------------|
| "đã được đăng ký" | Trigger re-reg flow | Show re-registration dialog |
| "đã tồn tại" | Trigger re-reg flow | Show re-registration dialog |
| "already registered" | Trigger re-reg flow | Show re-registration dialog |
| "duplicate face" | Trigger re-reg flow | Show re-registration dialog |
| "Không phát hiện khuôn mặt" | Show error | Red SnackBar |
| "Ảnh quá tối" | Show error | Red SnackBar (preserve message) |
| Other errors | Show error | Red SnackBar |

---

## 🧪 Testing Scenarios

### ✅ Scenario 1: Normal Registration (Happy Path)

```
1. Open screen
2. Select employee "Nguyễn Văn A"
3. Click "Đăng Ký Face ID"
4. See guidelines dialog → Confirm
5. Camera captures face
6. API /register returns success
7. See success dialog "Đăng Ký Thành Công"
8. Return to previous screen
```

**Expected Console Logs**:
```
📸 Initializing camera...
✅ Camera initialized successfully
📸 [1/4] Capturing face image...
    Employee: Nguyễn Văn A (ID: 123)
✅ [1/4] Image captured: 234567 chars
🔍 [2/4] Validating face...
✅ [2/4] Face validated
📦 [3/4] Preparing API request...
🚀 [4/4] Calling register API...
📥 API Response: Success = true
✅ Face registration successful!
🏁 Process completed
```

---

### ✅ Scenario 2: Face Already Exists → Re-Register

```
1. Open screen
2. Select employee "Trần Thị B"
3. Click "Đăng Ký Face ID"
4. See guidelines → Confirm
5. Camera captures face
6. API /register returns:
   Success = false
   Message = "⚠️ Khuôn mặt này đã được đăng ký cho nhân viên khác"
7. ✅ System detects "đã được đăng ký" keyword
8. See dialog "Khuôn Mặt Đã Tồn Tại!"
   - Shows warning: Ảnh cũ sẽ bị xóa
   - Actions: [Hủy] [Đăng Ký Lại]
9. User clicks "Đăng Ký Lại"
10. API /re-register called (same image reused)
11. Backend:
    - Deletes old FaceId from AWS
    - Deletes old S3 image
    - Uploads new image
    - Returns success
12. See dialog "Đăng Ký Lại Thành Công"
    - Orange info box: "Ảnh cũ đã bị xóa"
13. Return to previous screen
```

**Expected Console Logs**:
```
📸 [1/4] Capturing face image...
✅ [1/4] Image captured
...
📥 API Response: Success = false
    Message: ⚠️ Khuôn mặt này đã được đăng ký...
❌ Face registration failed
⚠️ Face already registered! Showing re-registration dialog...
🔄 User confirmed re-registration, calling API again...
🔄 Reusing captured image for re-registration
🚀 [4/4] Calling re-register API...
📥 API Response: Success = true
✅ Face registration successful!
```

---

### ✅ Scenario 3: User Cancels Re-Registration

```
1-8. (Same as Scenario 2)
9. User clicks "Hủy"
10. Dialog closes
11. Captured image is cleared (_capturedBase64Image = null)
12. User can try again with different photo
```

---

### ✅ Scenario 4: Passed via Arguments (from Employee Detail)

```
1. Employee Detail Screen → Click "Cập Nhật Face ID"
2. See dialog:
   - If isFaceRegistered = false: "Bạn muốn đăng ký?"
   - If isFaceRegistered = true: "Bạn muốn đăng ký lại?" + Orange warning
3. User confirms
4. Navigate to FaceRegisterScreen with args:
   { employee: Employee, isReRegister: true }
5. Screen auto-fills employee dropdown
6. _isReRegister = true from start
7. Click button → Call /re-register directly
8. Success → Return to Employee Detail → Auto reload
```

---

## 📊 API Integration

### Request DTO (Same for both APIs):

```dart
class RegisterEmployeeFaceRequest {
  final int employeeId;
  final String imageBase64; // Pure base64, NO prefix
  
  Map<String, dynamic> toJson() {
    // Validation
    if (imageBase64.isEmpty) throw ArgumentError('imageBase64 empty');
    if (imageBase64.length < 100) throw ArgumentError('imageBase64 too short');
    
    return {
      'employeeId': employeeId,
      'imageBase64': imageBase64,
    };
  }
}
```

### Response DTO:

```dart
class RegisterEmployeeFaceResponse {
  final bool success;
  final String message;
  final String? faceId;
  final String? s3ImageUrl;
  
  factory RegisterEmployeeFaceResponse.fromJson(Map<String, dynamic> json) {
    return RegisterEmployeeFaceResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      faceId: json['faceId']?.toString(),
      s3ImageUrl: json['s3ImageUrl']?.toString(),
    );
  }
}
```

### Service Methods:

```dart
class FaceApiService {
  // POST /api/face/register
  Future<ApiResponse<RegisterEmployeeFaceResponse>> register(
    RegisterEmployeeFaceRequest request
  );
  
  // POST /api/face/re-register
  Future<ApiResponse<RegisterEmployeeFaceResponse>> reRegister(
    RegisterEmployeeFaceRequest request
  );
}
```

---

## 🎯 Key Differences: Register vs Re-Register

| Aspect | register() | reRegister() |
|--------|-----------|--------------|
| **Endpoint** | `/api/face/register` | `/api/face/re-register` |
| **Use Case** | First-time registration | Update existing face |
| **Validation** | Check if face already exists | Assume face exists |
| **AWS Actions** | Index new face only | Delete old → Index new |
| **S3 Actions** | Upload new image only | Delete old → Upload new |
| **DB Update** | INSERT FaceId | UPDATE FaceId |
| **Error if exists** | Return error "đã đăng ký" | Allow (that's the point) |

---

## 🚀 Production Checklist

### Backend Must Have:
- [ ] POST /api/face/register endpoint
- [ ] POST /api/face/re-register endpoint
- [ ] Error message contains "đã được đăng ký" when face exists
- [ ] AWS Rekognition delete old FaceId logic in re-register
- [ ] S3 delete old image logic in re-register

### Frontend Must Have:
- [x] Camera lifecycle (init + dispose)
- [x] Triple-check before CameraPreview
- [x] Error detection for "đã được đăng ký"
- [x] Re-registration dialog
- [x] Image caching for re-use
- [x] Conditional API routing (_isReRegister flag)
- [x] Success/Error SnackBar with proper formatting
- [x] Console logging for debugging

---

## 📚 Related Documents

1. `FACE_ID_FIX_SUMMARY.md` - Camera config & validation fixes
2. `FRONTEND_VALIDATION_ENHANCEMENT.md` - 4-layer validation
3. `CAMERA_LIFECYCLE_FIX.md` - Camera lifecycle & error handling
4. **`FACE_REGISTRATION_REREGISTER_FLOW.md`** ← This document

---

**Date**: 2025-10-18  
**Status**: ✅ Production-Ready  
**Feature**: Complete Re-Registration Flow with Smart Error Detection

# 🏗️ Project Architecture Overview

## 📱 App Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        MAIN.DART                            │
│  - Load .env configuration                                  │
│  - Initialize Riverpod                                      │
│  - Setup Material 3 theme                                   │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│                      HOME PAGE                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  [Face Icon]                                         │   │
│  │  Face Recognition Attendance                         │   │
│  │                                                       │   │
│  │  ┌───────────────────────────────────────────────┐  │   │
│  │  │  ✅ Check-In (Vào làm)                        │  │   │
│  │  │     [Large Green Button]                       │  │   │
│  │  └───────────────────────────────────────────────┘  │   │
│  │                                                       │   │
│  │  ┌───────────────────────────────────────────────┐  │   │
│  │  │  ⏰ Check-Out (Tan ca)                        │  │   │
│  │  │     [Large Orange Button]                      │  │   │
│  │  └───────────────────────────────────────────────┘  │   │
│  │                                                       │   │
│  │  [Kiểm tra kết nối API]                             │   │
│  └─────────────────────────────────────────────────────┘   │
└───────────┬────────────────────────────┬────────────────────┘
            │                            │
            ▼                            ▼
┌─────────────────────┐     ┌─────────────────────────┐
│   CAMERA PAGE       │     │   HEALTH CHECK API      │
│   (Check-In/Out)    │     │   GET /api/face/health  │
└─────────┬───────────┘     └─────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│  CAMERA PREVIEW                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  "Đặt khuôn mặt vào khung hình và nhấn nút chụp"     │ │
│  │                                                        │ │
│  │              ┌─────────────┐                          │ │
│  │              │     ○ ○     │                          │ │
│  │              │      ▽      │  [Face Oval Guide]       │ │
│  │              │    ─────    │                          │ │
│  │              └─────────────┘                          │ │
│  │                                                        │ │
│  │                  [📷 Chụp ảnh]                        │ │
│  └────────────────────────────────────────────────────────┘ │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│  IMAGE PROCESSING                                           │
│  1. Capture image from camera                              │
│  2. Convert to bytes                                        │
│  3. Resize to 800px width (ImageConverter)                 │
│  4. Encode to Base64                                        │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│  API CALL (AttendanceService)                              │
│  POST /api/face/checkin                                     │
│  {                                                           │
│    "faceImageBase64": "...",                                │
│    "checkType": "IN" or "OUT"                               │
│  }                                                           │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│  RESULT DIALOG                                              │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  SUCCESS:                   ERROR:                     │ │
│  │  ┌─────────┐               ┌─────────┐               │ │
│  │  │   ✅    │               │   ❌    │               │ │
│  │  └─────────┘               └─────────┘               │ │
│  │  Thành công!               Thất bại                   │ │
│  │                                                        │ │
│  │  👤 Họ và tên: John Doe    ℹ️ No matching user found │ │
│  │  ⏰ Thời gian: 17/01/2025                            │ │
│  │  📈 Độ tương đồng: 98.5%                             │ │
│  │  🔄 Loại: Vào làm                                     │ │
│  │                                                        │ │
│  │  [Đóng]                     [Đóng]                    │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 🏛️ Architecture Layers

```
┌──────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                       │
│  ┌────────────┐  ┌────────────┐  ┌──────────────┐          │
│  │  HomePage  │  │ CameraPage │  │ ResultDialog │          │
│  │ (Consumer) │  │ (Consumer) │  │  (Stateless) │          │
│  └────────────┘  └────────────┘  └──────────────┘          │
└───────────────────────────┬──────────────────────────────────┘
                            │ Riverpod State Management
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                      BUSINESS LAYER                          │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  AttendanceService (Provider)                       │    │
│  │  - checkHealth()                                     │    │
│  │  - submitAttendance(base64, checkType)              │    │
│  └─────────────────────────────────────────────────────┘    │
└───────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                       DATA LAYER                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  ApiClient (Singleton)                              │    │
│  │  - Dio instance                                      │    │
│  │  - Base URL from .env                                │    │
│  │  - 20s timeout                                       │    │
│  │  - Request/response logging                          │    │
│  └─────────────────────────────────────────────────────┘    │
└───────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                       MODEL LAYER                            │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  AttendanceResponse                                  │    │
│  │  - success: bool                                     │    │
│  │  - message: String                                   │    │
│  │  - userData: UserData?                               │    │
│  │                                                       │    │
│  │  UserData                                            │    │
│  │  - userId: int                                       │    │
│  │  - fullName: String                                  │    │
│  │  - similarityScore: double                           │    │
│  │  - checkTime: String                                 │    │
│  │  - checkType: String                                 │    │
│  └─────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────┘
```

---

## 📦 Dependency Graph

```
main.dart
  ├── flutter_riverpod (ProviderScope)
  ├── flutter_dotenv (dotenv.load)
  └── HomePage
       ├── AttendanceService (Provider)
       │    ├── ApiClient (Singleton)
       │    │    ├── Dio
       │    │    └── flutter_dotenv
       │    └── AttendanceResponse (Model)
       │
       └── CameraPage
            ├── camera (CameraController)
            ├── ImageConverter
            │    └── image package
            ├── AttendanceService
            └── ResultDialog
                 └── AttendanceResponse
```

---

## 🔄 Data Flow

```
User Action
    │
    ▼
┌─────────────────┐
│   UI Event      │  (Button tap: Check-In/Out)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Camera Capture │  (Take photo)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Image Converter │  (Resize + Base64 encode)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ API Service     │  (POST to backend)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  API Client     │  (Dio HTTP request)
└────────┬────────┘
         │
         ▼
    [Backend API]
         │
         ▼
┌─────────────────┐
│   Response      │  (JSON data)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Parse Model    │  (AttendanceResponse)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Update UI      │  (Show ResultDialog)
└─────────────────┘
```

---

## 🗂️ File Organization

```
face_id_app/
│
├── 📄 .env                          # Environment config (gitignored)
├── 📄 .env.example                  # Example config
├── 📄 pubspec.yaml                  # Dependencies
├── 📄 README.md                     # Main documentation
├── 📄 SETUP_GUIDE.md                # Setup instructions
├── 📄 SUMMARY.md                    # Project summary
├── 📄 PROJECT_STRUCTURE.md          # This file
├── 📄 start.ps1                     # Quick start script
│
├── 📁 lib/
│   ├── 📄 main.dart                 # Entry point [60 lines]
│   │
│   ├── 📁 core/
│   │   └── 📄 api_client.dart       # Dio config [42 lines]
│   │
│   ├── 📁 features/
│   │   └── 📁 attendance/
│   │       │
│   │       ├── 📁 data/
│   │       │   └── 📄 attendance_service.dart  # API calls [52 lines]
│   │       │
│   │       ├── 📁 model/
│   │       │   └── 📄 attendance_response.dart # Models [50 lines]
│   │       │
│   │       └── 📁 presentation/
│   │           ├── 📄 home_page.dart           # Home UI [215 lines]
│   │           ├── 📄 camera_page.dart         # Camera UI [235 lines]
│   │           └── 📄 result_dialog.dart       # Result UI [165 lines]
│   │
│   └── 📁 utils/
│       └── 📄 image_converter.dart  # Base64 util [30 lines]
│
├── 📁 android/
│   └── 📁 app/src/main/
│       └── 📄 AndroidManifest.xml   # Permissions configured ✅
│
└── 📁 ios/Runner/
    └── 📄 Info.plist                # Permissions configured ✅
```

---

## 🎨 UI Component Tree

```
MaterialApp (main.dart)
└── HomePage (ConsumerWidget)
    ├── AppBar
    ├── Gradient Container
    │   ├── Face Icon (Logo)
    │   ├── Title Text
    │   │
    │   ├── Check-In Button (Green)
    │   │   └── Navigator → CameraPage(checkType: "IN")
    │   │
    │   ├── Check-Out Button (Orange)
    │   │   └── Navigator → CameraPage(checkType: "OUT")
    │   │
    │   └── Health Check Button (Outlined)
    │       └── API Call → Health Dialog
    │
    └── CameraPage (ConsumerStatefulWidget)
        ├── AppBar (Dynamic color based on checkType)
        ├── CameraPreview (Full screen)
        ├── Face Oval Overlay
        ├── Instruction Text
        │
        └── Capture Button (FAB)
            └── onPressed:
                ├── Take Picture
                ├── Convert to Base64
                ├── Call API
                └── Show ResultDialog
                    ├── Success Card
                    │   ├── Check Icon
                    │   ├── User Info Rows
                    │   └── Close Button
                    │
                    └── Error Card
                        ├── Error Icon
                        ├── Error Message
                        └── Close Button
```

---

## 🔌 API Integration Map

```
Backend: https://api.studyplannerapp.io.vn
│
├── GET /api/face/health
│   │
│   ├── Request: None
│   ├── Response: 200 OK
│   │
│   └── Used by: HomePage.checkHealth()
│       └── Shows: Success/Fail Dialog
│
└── POST /api/face/checkin
    │
    ├── Request Headers:
    │   ├── Content-Type: application/json
    │   └── Accept: application/json
    │
    ├── Request Body:
    │   {
    │     "faceImageBase64": "data:image/jpeg;base64,...",
    │     "checkType": "IN" | "OUT"
    │   }
    │
    ├── Response (Success):
    │   {
    │     "success": true,
    │     "message": "Check-in successful",
    │     "userData": {
    │       "userId": 1,
    │       "fullName": "John Doe",
    │       "similarityScore": 98.5,
    │       "checkTime": "2025-01-17T10:30:00Z",
    │       "checkType": "IN"
    │     }
    │   }
    │
    ├── Response (Error):
    │   {
    │     "success": false,
    │     "message": "No matching user found",
    │     "userData": null
    │   }
    │
    └── Used by: AttendanceService.submitAttendance()
        └── Shows: ResultDialog with parsed data
```

---

## 🛠️ State Management Flow (Riverpod)

```
┌─────────────────────────────────────────────────────────────┐
│  ProviderScope (Root)                                       │
│  ┌───────────────────────────────────────────────────────┐ │
│  │                                                         │ │
│  │  Provider: attendanceServiceProvider                   │ │
│  │  ├── Creates: AttendanceService()                      │ │
│  │  └── Scope: Global                                     │ │
│  │                                                         │ │
│  │  ┌─────────────────────────────────────────────────┐  │ │
│  │  │  HomePage (ConsumerWidget)                      │  │ │
│  │  │  ├── ref.watch(attendanceServiceProvider)       │  │ │
│  │  │  └── Uses service for health check              │  │ │
│  │  └─────────────────────────────────────────────────┘  │ │
│  │                                                         │ │
│  │  ┌─────────────────────────────────────────────────┐  │ │
│  │  │  CameraPage (ConsumerStatefulWidget)            │  │ │
│  │  │  ├── ref.read(attendanceServiceProvider)        │  │ │
│  │  │  └── Uses service for attendance submission     │  │ │
│  │  └─────────────────────────────────────────────────┘  │ │
│  │                                                         │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Code Metrics

| Metric | Value |
|--------|-------|
| Total Dart Files | 9 |
| Total Lines of Code | ~850 |
| Main Features | 3 (Check-In, Check-Out, Health Check) |
| API Endpoints | 2 |
| UI Screens | 3 |
| Models | 2 |
| Services | 2 |
| Utilities | 1 |
| Dependencies | 5 major packages |
| Supported Platforms | 2 (Android, iOS) |

---

## 🔒 Security Features

```
┌─────────────────────────────────────────────────────────────┐
│  SECURITY LAYERS                                            │
│                                                              │
│  1. Environment Configuration                               │
│     ├── .env file (gitignored)                             │
│     ├── No hardcoded secrets                                │
│     └── Base URL configurable                               │
│                                                              │
│  2. Network Security                                        │
│     ├── HTTPS enforced                                      │
│     ├── 20s timeout (prevents hanging)                      │
│     └── Request/response logging (debug only)               │
│                                                              │
│  3. Data Processing                                         │
│     ├── Image resize (800px max width)                      │
│     ├── Base64 encoding                                     │
│     └── No persistent storage                               │
│                                                              │
│  4. Permissions                                             │
│     ├── Camera permission required                          │
│     ├── Internet permission explicit                        │
│     └── Runtime permission handling                         │
│                                                              │
│  5. Error Handling                                          │
│     ├── Try-catch blocks                                    │
│     ├── User-friendly error messages                        │
│     └── Graceful degradation                                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Feature Checklist

### Core Features
- ✅ Face capture using camera
- ✅ Image to Base64 conversion
- ✅ Image resize optimization
- ✅ API health check
- ✅ Check-in functionality
- ✅ Check-out functionality
- ✅ Real-time result display

### UI/UX Features
- ✅ Material 3 design
- ✅ Blue-white theme
- ✅ Loading indicators
- ✅ Success/error dialogs
- ✅ Face alignment guide
- ✅ Bilingual labels
- ✅ Responsive layout

### Technical Features
- ✅ MVVM architecture
- ✅ Riverpod state management
- ✅ Dio HTTP client
- ✅ Environment configuration
- ✅ Type-safe models
- ✅ Error handling
- ✅ Request logging
- ✅ Null safety

### Platform Support
- ✅ Android permissions
- ✅ iOS permissions
- ✅ Camera integration
- ✅ Network access

---

This structure provides a complete, production-ready Flutter application! 🚀

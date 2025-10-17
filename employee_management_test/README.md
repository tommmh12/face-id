# employee_management_test

# Employee Management & Face ID Flutter App

A comprehensive Flutter application for employee management with Face ID attendance tracking and automated payroll calculation.

## Features

### 🧑‍💼 Employee Management
- Create and manage employee profiles
- Department-based organization
- Employee status tracking
- Comprehensive employee information

### 🔐 Face Recognition Attendance
- Face registration using camera
- Real-time face recognition for check-in/check-out
- AWS Rekognition integration
- High confidence matching (85%+ threshold)
- Image storage in S3

### 💰 Payroll Management
- Automated payroll calculation
- Vietnamese tax compliance (PIT)
- Insurance deduction (BHXH, BHYT, BHTN)
- Overtime calculation
- Allowances and deductions
- 80% working hours rule
- Comprehensive payroll reports

## API Integration

This Flutter app is designed to work with the C# .NET API backend with the following controllers:

### Employee Controller (`/api/employee`)
- `GET /departments` - Get all departments
- `POST /` - Create new employee
- `GET /` - Get all employees
- `GET /{id}` - Get employee by ID
- `GET /department/{departmentId}` - Get employees by department
- `POST /register-face` - Register employee face
- `POST /verify-face` - Verify face for attendance

### Face API Controller (`/api/face`)
- `POST /register` - Register face with AWS Rekognition
- `POST /checkin` - Face recognition check-in
- `POST /checkout` - Face recognition check-out
- `GET /health` - Health check

### Payroll Controller (`/api/payroll`)
- `POST /periods` - Create payroll period
- `GET /periods` - Get all payroll periods
- `GET /periods/{id}` - Get payroll period by ID
- `POST /rules` - Create/update payroll rules
- `GET /rules/employee/{employeeId}` - Get employee payroll rules
- `GET /rules` - Get all payroll rules
- `POST /allowances` - Create allowances/deductions
- `GET /allowances/employee/{employeeId}` - Get employee allowances
- `POST /generate/{periodId}` - Generate payroll for period
- `GET /summary/{periodId}` - Get payroll summary
- `GET /records/period/{periodId}/employee/{employeeId}` - Get employee payroll

## Project Structure

```
lib/
├── config/
│   └── app_config.dart           # App configuration
├── models/
│   ├── department.dart           # Department model
│   ├── employee.dart             # Employee model
│   └── dto/
│       ├── employee_dtos.dart    # Employee DTOs
│       └── payroll_dtos.dart     # Payroll DTOs
├── services/
│   ├── api_service.dart          # Base API service
│   ├── employee_api_service.dart # Employee API service
│   ├── payroll_api_service.dart  # Payroll API service
│   └── face_api_service.dart     # Face API service
├── utils/
│   └── camera_helper.dart        # Camera utilities
├── screens/
│   ├── home_screen.dart          # Home dashboard
│   ├── employee/
│   │   ├── employee_list_screen.dart
│   │   └── employee_create_screen.dart
│   ├── face/
│   │   ├── face_register_screen.dart
│   │   └── face_checkin_screen.dart
│   └── payroll/
│       └── payroll_dashboard_screen.dart
└── main.dart                     # App entry point
```

## Setup Instructions

### 1. Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio or VS Code
- Physical device or emulator with camera

### 2. Installation
```bash
# Get dependencies
flutter pub get

# Configure API endpoint
# Edit lib/config/app_config.dart and update baseUrl
```

### 3. Configuration

#### API Configuration
Update `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://your-api-url:port/api';
```

#### Camera Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
```

Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for face recognition</string>
```

### 4. Running the App
```bash
# Run on connected device
flutter run

# Run in debug mode
flutter run --debug

# Build for release
flutter build apk # Android
flutter build ios # iOS
```

## Features Overview

### 🏠 Home Screen
- Dashboard with quick access to all features
- Quick check-in/check-out buttons
- Feature navigation cards

### 👥 Employee Management
- **Employee List**: View all employees with filtering by department
- **Create Employee**: Form to add new employees with validation
- **Face Registration**: Camera interface for registering employee faces
- Visual indicators for Face ID registration status

### 📷 Face Recognition
- **Face Registration**: 
  - Camera preview with face detection overlay
  - Real-time face validation
  - Direct integration with AWS Rekognition
- **Check-in/Check-out**:
  - Toggle between check-in and check-out modes
  - Real-time clock display
  - Face recognition with confidence scoring
  - Attendance logging

### 💰 Payroll Management
- **Dashboard**: Overview of payroll periods and summaries
- **Generate Payroll**: Automated calculation for all employees
- **Financial Summary**: 
  - Gross/Net salary totals
  - Insurance deductions
  - Tax calculations
  - Overtime payments

## Contributing

1. Follow Flutter coding standards
2. Add documentation for new features
3. Test on both Android and iOS
4. Ensure Vietnamese language support

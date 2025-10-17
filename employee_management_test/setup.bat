@echo off
REM Employee Management Flutter App Setup Script for Windows

echo 🚀 Setting up Employee Management Flutter App...
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed. Please install Flutter first.
    echo Visit: https://docs.flutter.dev/get-started/install
    pause
    exit /b 1
)

echo ✅ Flutter found
flutter --version | findstr /R "Flutter"

REM Check Flutter doctor
echo.
echo 🔍 Running Flutter doctor...
flutter doctor

REM Get dependencies
echo.
echo 📦 Getting Flutter dependencies...
flutter pub get

REM Configuration
echo.
echo ⚙️ Configuration Setup
echo Please update the API endpoint in the following file:
echo 📝 lib/config/app_config.dart
echo.
echo Change the baseUrl from:
echo   static const String baseUrl = 'https://your-api-url.com/api';
echo To your actual API URL, for example:
echo   static const String baseUrl = 'http://localhost:5000/api';
echo.

REM Platform setup
echo 📱 Platform Setup Instructions:
echo.
echo For Android:
echo ✅ Camera permissions are already added to AndroidManifest.xml
echo.
echo For iOS:
echo 📝 Add camera permission to ios/Runner/Info.plist:
echo ^<key^>NSCameraUsageDescription^</key^>
echo ^<string^>This app needs camera access for face recognition^</string^>
echo.

REM API Integration
echo 🔌 API Integration:
echo This app is designed to work with the C# .NET API backend.
echo Make sure your API server is running and accessible.
echo.
echo Key endpoints required:
echo • GET  /api/employee/departments
echo • POST /api/employee
echo • POST /api/face/register
echo • POST /api/face/checkin
echo • POST /api/face/checkout
echo • POST /api/payroll/generate/{periodId}
echo.

REM Features
echo 🎯 Features Available:
echo • 👥 Employee Management
echo • 📷 Face Registration ^& Recognition
echo • ⏰ Check-in/Check-out with Face ID
echo • 💰 Payroll Management ^& Calculation
echo • 📊 Payroll Reports ^& Summaries
echo.

REM Next steps
echo ▶️ Next Steps:
echo 1. Update API endpoint in lib/config/app_config.dart
echo 2. Ensure your C# API server is running
echo 3. Connect a physical device (camera required)
echo 4. Run: flutter run
echo.

echo 🎉 Setup complete! Happy coding!
pause
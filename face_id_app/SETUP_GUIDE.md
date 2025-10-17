# 🚀 Face Recognition Attendance - Setup Guide

## ✅ Installation Complete!

Your Flutter Face Recognition Attendance app has been successfully generated with all required files and dependencies.

## 📁 Project Structure

```
face_id_app/
├── .env                          # Environment configuration (BASE_URL)
├── .env.example                  # Example environment file
├── pubspec.yaml                  # Flutter dependencies
├── lib/
│   ├── main.dart                 # App entry point
│   ├── core/
│   │   └── api_client.dart       # Dio HTTP client
│   ├── features/
│   │   └── attendance/
│   │       ├── data/
│   │       │   └── attendance_service.dart
│   │       ├── model/
│   │       │   └── attendance_response.dart
│   │       └── presentation/
│   │           ├── home_page.dart
│   │           ├── camera_page.dart
│   │           └── result_dialog.dart
│   └── utils/
│       └── image_converter.dart
```

## 🔧 Configuration

### 1. Environment Variables

The `.env` file is already created with default configuration:

```env
BASE_URL=https://api.studyplannerapp.io.vn
API_TIMEOUT=20000
```

**To change the backend URL:**
- Edit `.env` file
- Update `BASE_URL` to your backend server

### 2. Camera Permissions

#### Android (`android/app/src/main/AndroidManifest.xml`)

Add before `<application>`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
<uses-feature android:name="android.hardware.camera.front" android:required="false"/>
```

#### iOS (`ios/Runner/Info.plist`)

Add these keys:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for face recognition attendance</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access</string>
```

## 🏃‍♂️ Running the App

### Method 1: VS Code
1. Connect your device or start emulator
2. Press `F5` or click "Run and Debug"
3. Select your device

### Method 2: Command Line

```powershell
# Check connected devices
flutter devices

# Run on connected device
flutter run

# Run in release mode
flutter run --release
```

## 🧪 Testing the App

### 1. Test API Connection
- Launch app
- Tap "Kiểm tra kết nối API" button
- Should show success if backend is running

### 2. Test Check-In
- Tap "Check-In (Vào làm)" button
- Position face in circle guide
- Tap camera button
- View result dialog

### 3. Test Check-Out
- Tap "Check-Out (Tan ca)" button
- Follow same process

## 🌐 API Integration

### Endpoints Used

**1. Health Check**
```
GET /api/face/health
```

**2. Check-in/Check-out**
```
POST /api/face/checkin
Content-Type: application/json

{
  "faceImageBase64": "<Base64 string>",
  "checkType": "IN" // or "OUT"
}
```

### Expected Response

**Success:**
```json
{
  "success": true,
  "message": "Check-in successful",
  "userData": {
    "userId": 1,
    "fullName": "John Doe",
    "similarityScore": 98.5,
    "checkTime": "2025-01-17T10:30:00Z",
    "checkType": "IN"
  }
}
```

**Error:**
```json
{
  "success": false,
  "message": "No matching user found",
  "userData": null
}
```

## 📦 Dependencies Installed

```yaml
flutter_riverpod: ^2.6.1    # State management
dio: ^5.4.0                 # HTTP client
camera: ^0.10.6             # Camera access
image: ^4.1.3               # Image processing
flutter_dotenv: ^5.2.1      # Environment variables
```

## 🔨 Build Commands

### Android APK
```powershell
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Google Play)
```powershell
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS
```powershell
flutter build ios --release
```

## 🐛 Troubleshooting

### Issue: Camera not opening
**Solution:**
- Check camera permissions in device settings
- Verify AndroidManifest.xml has camera permissions
- Restart the app

### Issue: API connection failed
**Solution:**
- Check `.env` file has correct BASE_URL
- Verify backend server is running
- Test with "Kiểm tra kết nối API" button
- Check device internet connection

### Issue: Build errors
**Solution:**
```powershell
flutter clean
flutter pub get
flutter run
```

### Issue: Dependencies conflict
**Solution:**
```powershell
flutter pub upgrade
```

## 📱 Platform Requirements

- **Android**: SDK 21+ (Android 5.0+)
- **iOS**: iOS 11.0+
- **Flutter**: 3.0.0+
- **Dart**: 3.0.0+

## 🔐 Security Notes

1. **Base64 Encoding**: Images are converted to Base64 before upload
2. **Image Compression**: Images are resized to 800px width to reduce payload
3. **HTTPS**: API communication uses HTTPS protocol
4. **Environment**: `.env` file is git-ignored (sensitive data protection)

## 📖 Usage Flow

1. **Launch App** → Home screen with 2 main buttons
2. **Tap Check-In/Check-Out** → Opens camera page
3. **Position Face** → Align face with circle guide
4. **Capture** → Tap camera button
5. **Processing** → Shows loading spinner
6. **Result** → Displays success/error dialog with user info
7. **Return** → Back to home screen

## 🎨 UI Features

- **Material 3 Design**: Modern, clean interface
- **Blue-White Theme**: Professional color scheme
- **Responsive Layout**: Works on all screen sizes
- **Vietnamese Labels**: Bilingual UI (English + Vietnamese)
- **Icon Indicators**: Visual feedback for actions
- **Loading States**: Clear processing indicators

## 🔄 Next Steps

1. ✅ Configure camera permissions (see above)
2. ✅ Update `.env` if needed
3. ✅ Connect device/emulator
4. ✅ Run `flutter run`
5. ✅ Test with your backend API

## 📞 Support

For issues or questions:
- Check this guide first
- Review README.md for detailed documentation
- Check Flutter logs: `flutter logs`
- Enable verbose logging in Dio (already enabled in `api_client.dart`)

## 🎯 Ready to Run!

Your app is now fully configured and ready to build. Simply run:

```powershell
flutter run
```

Good luck with your Face Recognition Attendance project! 🚀

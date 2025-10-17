# 🎯 Quick Reference Card

## ⚡ Quick Commands

```powershell
# Run the app
flutter run

# Run quick start script
.\start.ps1

# Clean & rebuild
flutter clean; flutter pub get; flutter run

# Build release APK
flutter build apk --release

# Check for issues
flutter doctor

# View logs
flutter logs
```

---

## 🔧 Configuration Files

| File | Purpose | Location |
|------|---------|----------|
| `.env` | API base URL | Root directory |
| `pubspec.yaml` | Dependencies | Root directory |
| `AndroidManifest.xml` | Android permissions | `android/app/src/main/` |
| `Info.plist` | iOS permissions | `ios/Runner/` |

---

## 🌐 API Endpoints

```
Base URL: https://api.studyplannerapp.io.vn

GET  /api/face/health        # Health check
POST /api/face/checkin       # Check-in/out
```

### Request Body
```json
{
  "faceImageBase64": "<Base64 string>",
  "checkType": "IN"  // or "OUT"
}
```

---

## 📱 Key Features

| Feature | Button | Action |
|---------|--------|--------|
| Check-In | Green "Vào làm" | Opens camera, sends "IN" |
| Check-Out | Orange "Tan ca" | Opens camera, sends "OUT" |
| Health Check | "Kiểm tra kết nối API" | Tests backend |

---

## 🗂️ Project Structure

```
lib/
├── main.dart                    # Entry point
├── core/
│   └── api_client.dart          # HTTP client
├── features/attendance/
│   ├── data/
│   │   └── attendance_service.dart
│   ├── model/
│   │   └── attendance_response.dart
│   └── presentation/
│       ├── home_page.dart
│       ├── camera_page.dart
│       └── result_dialog.dart
└── utils/
    └── image_converter.dart
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Camera not working | Check device permissions |
| API error | Verify `.env` BASE_URL |
| Build fails | Run `flutter clean` |
| Import errors | Run `flutter pub get` |

---

## 📦 Dependencies

```yaml
flutter_riverpod: ^2.6.1
dio: ^5.4.0
camera: ^0.10.6
image: ^4.1.3
flutter_dotenv: ^5.2.1
```

---

## 🔐 Environment Variables

```env
BASE_URL=https://api.studyplannerapp.io.vn
API_TIMEOUT=20000
```

Edit `.env` to change backend URL.

---

## 📖 Documentation Files

- `README.md` - Full documentation
- `SETUP_GUIDE.md` - Setup instructions
- `SUMMARY.md` - Project overview
- `PROJECT_STRUCTURE.md` - Architecture details
- `QUICK_REFERENCE.md` - This file

---

## 🚀 Getting Started (30 seconds)

1. Open terminal in project folder
2. Run: `flutter run`
3. Wait for app to launch
4. Tap "Kiểm tra kết nối API"
5. Done! ✅

---

## 💡 Pro Tips

- 🔥 **Hot Reload**: Press `r` in terminal
- 🔄 **Hot Restart**: Press `R` in terminal
- 🛑 **Stop App**: Press `q` in terminal
- 📊 **Performance**: Press `p` for performance overlay
- 🎨 **Debug Paint**: Press `P` for debug painting

---

## 📞 Need Help?

1. Check `SETUP_GUIDE.md`
2. Review `README.md`
3. Run `flutter doctor`
4. Check console logs

---

**App Version**: 1.0.0  
**Flutter SDK**: 3.0.0+  
**Last Updated**: October 17, 2025

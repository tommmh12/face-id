# Face Recognition Attendance App

A Flutter mobile application for employee attendance tracking using face recognition technology.

## Features

- ✅ **Check-In (Vào làm)** - Clock in using face recognition
- ⏰ **Check-Out (Tan ca)** - Clock out using face recognition  
- 🔍 **API Health Check** - Verify backend connectivity
- 📊 **Real-time Results** - Display name, time, and similarity score
- 🎨 **Material 3 Design** - Modern and clean UI

## Architecture

- **Pattern**: MVVM (Model-View-ViewModel)
- **State Management**: Riverpod
- **HTTP Client**: Dio
- **Camera**: camera package
- **Environment Config**: flutter_dotenv

## Project Structure

```
lib/
├── main.dart                              # App entry point
├── core/
│   └── api_client.dart                    # Dio HTTP client configuration
├── features/
│   └── attendance/
│       ├── data/
│       │   └── attendance_service.dart    # API service layer
│       ├── model/
│       │   └── attendance_response.dart   # Data models
│       └── presentation/
│           ├── home_page.dart             # Main screen
│           ├── camera_page.dart           # Camera capture screen
│           └── result_dialog.dart         # Result display dialog
└── utils/
    └── image_converter.dart               # Base64 conversion utility
```

## API Integration

**Base URL**: Configured via `.env` file

### Endpoints

1. **POST /api/face/checkin**
   - Submit face image for attendance
   - Request:
     ```json
     {
       "faceImageBase64": "<Base64 string>",
       "checkType": "IN" // or "OUT"
     }
     ```
   - Response:
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

2. **GET /api/face/health**
   - Check API server status

## Setup & Installation

### Prerequisites

- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / VS Code
- Android device or emulator (API 26+)

### Steps

1. **Clone the repository**
   ```bash
   cd c:\MyProject\face_id_app
   ```

2. **Configure environment**
   - Copy `.env.example` to `.env`
   - Update `BASE_URL` if needed:
     ```
     BASE_URL=https://api.studyplannerapp.io.vn
     API_TIMEOUT=20000
     ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Configuration

### Environment Variables (.env)

```env
BASE_URL=https://api.studyplannerapp.io.vn
API_TIMEOUT=20000
```

- `BASE_URL`: Backend API base URL
- `API_TIMEOUT`: Request timeout in milliseconds

## Usage

1. **Launch the app**
2. **Test API connection** - Tap "Kiểm tra kết nối API"
3. **Check-In** - Tap "Check-In (Vào làm)" button
4. **Capture face** - Position face in the circle guide and tap camera button
5. **View result** - See attendance confirmation with details
6. **Check-Out** - Similar process with "Check-Out (Tan ca)" button

## Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.4.9      # State management
  dio: ^5.4.0                   # HTTP client
  camera: ^0.10.5+5             # Camera access
  image: ^4.1.3                 # Image processing
  flutter_dotenv: ^5.1.0        # Environment variables
```

## Platform Support

- ✅ Android (8.0+)
- ✅ iOS (11.0+)

## Security Notes

- Face images are sent as Base64 encoded JPEG
- Images are resized to 800px width before upload
- HTTPS is enforced for API communication
- `.env` file is git-ignored for security

## Troubleshooting

### Camera not working
- Check camera permissions in device settings
- Ensure app has camera permission granted

### API connection failed
- Verify BASE_URL in `.env` file
- Check internet connection
- Test with "Kiểm tra kết nối API" button

### Build errors
- Run `flutter clean`
- Run `flutter pub get`
- Restart IDE

## License

MIT License

## Support

For issues or questions, please contact the development team.

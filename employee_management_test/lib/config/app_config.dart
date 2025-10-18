class AppConfig {
  // API Configuration
  static const String baseUrl = 'https://api.studyplannerapp.io.vn/api';
  
  // Update this URL to point to your actual C# API server
  // Examples:
  // - Development: 'http://localhost:5000/api' or 'https://localhost:7000/api'
  // - Production: 'https://your-domain.com/api'
  
  // AWS Rekognition Collection Configuration (from your C# code)
  static const String faceCollectionId = 'face-collection-hoang';
  static const double confidenceThreshold = 85.0;
  
  // S3 Folder Structure (from your C# code)
  static const String s3FacesFolder = 'faces/';
  static const String s3CheckinFolder = 'checkin/';
  static const String s3CheckoutFolder = 'checkout/';
  
  // App Configuration
  static const String appName = 'Employee Management & Face ID';
  static const String appVersion = '1.0.0';
  
  // Camera Settings
  static const Duration cameraPreviewTimeout = Duration(seconds: 30);
  static const int maxImageSizeKB = 1024; // 1MB
  
  // Localization
  static const String defaultLocale = 'vi_VN';
  
  // Development Mode
  static const bool isDevelopment = true;
  
  // Error Messages
  static const Map<String, String> errorMessages = {
    'network_error': 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.',
    'camera_error': 'Lỗi camera. Vui lòng kiểm tra quyền truy cập camera.',
    'face_not_detected': 'Không phát hiện khuôn mặt. Vui lòng thử lại.',
    'api_error': 'Lỗi hệ thống. Vui lòng thử lại sau.',
    'invalid_data': 'Dữ liệu không hợp lệ.',
  };
}

// Environment specific configurations
class DevConfig extends AppConfig {
  static const String baseUrl = 'http://localhost:5000/api';
  // or 'https://localhost:7000/api' if using HTTPS
}

class ProdConfig extends AppConfig {
  static const String baseUrl = 'https://your-production-domain.com/api';
}
/// Global App Configuration
/// ------------------------------------------------------------------
/// Dùng để cấu hình API, AWS, camera, localization, v.v.
/// Hỗ trợ tự động chọn môi trường Dev / Prod.
/// ------------------------------------------------------------------
class AppConfig {
  // ==========================================================
  // ⚙️ Environment Configuration
  // ==========================================================
  static const bool isDevelopment = true; 
  static const bool isStaging = false;    

  /// Tự động chọn base URL theo môi trường
  static String get baseUrl {
    if (isDevelopment) return DevConfig.baseUrl;
    if (isStaging) return StagingConfig.baseUrl;
    return ProdConfig.baseUrl;
  }

  // ==========================================================
  // 🌐 API Configuration
  // ==========================================================
  static const String apiVersion = 'v1'; // Optional
  static const Duration apiTimeout = Duration(seconds: 15);

  /// Full API endpoint (ví dụ: https://api.studyplannerapp.io.vn/api/v1)
  static String get apiBaseUrl => '$baseUrl/api/$apiVersion';

  // ==========================================================
  // 🤖 AWS Rekognition & S3 Configuration
  // ==========================================================
  static const String faceCollectionId = 'face-collection-hoang';
  static const double confidenceThreshold = 85.0;

  static const String s3FacesFolder = 'faces/';
  static const String s3CheckinFolder = 'checkin/';
  static const String s3CheckoutFolder = 'checkout/';

  // ==========================================================
  // 📱 App Information
  // ==========================================================
  static const String appName = 'Employee Management & Face ID';
  static const String appVersion = '1.0.0';
  static const String appAuthor = 'StudyPlanner Team';

  // ==========================================================
  // 📸 Camera Settings
  // ==========================================================
  static const Duration cameraPreviewTimeout = Duration(seconds: 30);
  static const int maxImageSizeKB = 1024; // 1MB

  // ==========================================================
  // 🌍 Localization
  // ==========================================================
  static const String defaultLocale = 'vi_VN';
  static const String fallbackLocale = 'en_US';

  // ==========================================================
  // ⚠️ Error Messages (hiển thị ra UI)
  // ==========================================================
  static const Map<String, String> errorMessages = {
    'network_error': 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.',
    'camera_error': 'Không thể truy cập camera. Vui lòng kiểm tra quyền.',
    'face_not_detected': 'Không phát hiện khuôn mặt. Vui lòng thử lại.',
    'api_error': 'Lỗi hệ thống. Vui lòng thử lại sau.',
    'invalid_data': 'Dữ liệu không hợp lệ.',
    'timeout': 'Yêu cầu quá thời gian cho phép.',
    'unauthorized': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
  };

  // ==========================================================
  // 🧩 Helper Methods
  // ==========================================================
  static void printCurrentEnvironment() {
    final env = isDevelopment
        ? 'Development'
        : (isStaging ? 'Staging' : 'Production');
    print('🔧 Running in $env mode → $baseUrl');
  }
}

// ==========================================================
// 🌍 Environment-specific Configurations
// ==========================================================

class DevConfig {
  static const String baseUrl = 'http://10.0.2.2:5000'; // dùng cho Android emulator
  // hoặc 'http://localhost:5000' nếu chạy Flutter Web / Windows
}

class StagingConfig {
  static const String baseUrl = 'https://staging.studyplannerapp.io.vn';
}

class ProdConfig {
  static const String baseUrl = 'https://api.studyplannerapp.io.vn';
}

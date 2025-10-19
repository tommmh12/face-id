/// 🌐 API Configuration
/// 
/// Central configuration for all API endpoints and settings
class ApiConfig {
  // ==================== BASE URL ====================
  
  /// Base URL for API (Change based on environment)
  /// 
  /// Development (Local):
  /// - Web (Chrome/Edge): 'http://localhost:5000/api'
  /// - Android Emulator: 'http://10.0.2.2:5000/api'
  /// - iOS Simulator: 'http://localhost:5000/api'
  /// - Physical Device: 'http://192.168.1.x:5000/api' (your computer's IP)
  /// 
  /// Production:
  /// - 'https://api.studyplannerapp.io.vn/api' (Current Production API)
  static const String baseUrl = 'https://api.studyplannerapp.io.vn/api';

  // ==================== ENDPOINTS ====================

  // Authentication
  static const String login = '/Employee/login';
  static const String logout = '/Employee/logout';
  static const String refreshToken = '/Employee/refresh-token';

  // Employee
  static const String employees = '/Employee';
  static String employeeById(int id) => '/Employee/$id';

  // Payroll
  static const String payrollPeriods = '/Payroll/periods';
  static const String payrollSummary = '/Payroll/summary';
  static const String payrollRecords = '/Payroll/records';
  static const String payrollGenerate = '/Payroll/generate';
  static const String payrollAudit = '/Payroll/audit';

  // Attendance
  static const String attendanceFaceId = '/Attendance/face-id';
  static const String attendanceRecords = '/Attendance/records';
  static const String attendanceSummary = '/Attendance/summary';

  // ==================== SETTINGS ====================

  /// Request timeout duration
  static const Duration timeout = Duration(seconds: 30);

  /// Max retry attempts for failed requests
  static const int maxRetries = 3;

  /// Enable request/response logging
  static const bool enableLogging = true;

  // ==================== HELPERS ====================

  /// Get full URL for endpoint
  static String getUrl(String endpoint) {
    return baseUrl + endpoint;
  }

  /// Check if base URL is localhost/emulator
  static bool get isLocalhost {
    return baseUrl.contains('localhost') || 
           baseUrl.contains('10.0.2.2') || 
           baseUrl.contains('127.0.0.1');
  }

  /// Get environment name
  static String get environment {
    if (isLocalhost) return 'Development';
    return 'Production';
  }
}

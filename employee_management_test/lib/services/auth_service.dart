import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../config/api_config.dart';
import '../utils/app_logger.dart';
import 'secure_storage_service.dart';

/// 🔐 Authentication Service
/// 
/// Handles user authentication and session management:
/// - Login with Email or Employee Code
/// - JWT Token management
/// - Token validation and refresh
/// - Logout
class AuthService {
  final String _baseUrl = '${ApiConfig.baseUrl}/Employee';

  // ==================== LOGIN ====================

  /// Login with Email or Employee Code
  /// 
  /// @param identifier - Email or Employee Code (e.g., "admin@company.com" or "EMP001")
  /// @param password - User password
  /// 
  /// @returns LoginResponse with user data and token
  /// @throws Exception if login fails
  Future<LoginResponse> login({
    required String identifier,
    required String password,
  }) async {
    AppLogger.startOperation('User Login');
    AppLogger.data('Identifier: $identifier', tag: 'Auth');

    try {
      // [1] Build Request Body
      final body = json.encode({
        'identifier': identifier, // Accepts Email OR Employee Code
        'password': password,
      });

      // [2] Call API
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Kết nối timeout. Vui lòng thử lại.');
        },
      );

      // [3] Handle Response
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // ✅ Login Success
        final token = responseData['token'] as String;
        final employeeData = responseData['employee'] as Map<String, dynamic>;

        // [3.1] Validate Token
        if (JwtDecoder.isExpired(token)) {
          throw Exception('Token đã hết hạn. Vui lòng đăng nhập lại.');
        }

        // [3.2] Extract User Data
        final employeeId = employeeData['id'] as int;
        final fullName = employeeData['fullName'] as String;
        final email = employeeData['email'] as String;
        final roleName = employeeData['roleName'] as String;
        final roleLevel = employeeData['roleLevel'] as int;

        // [3.3] Save Token & User Data Securely
        await SecureStorageService.saveToken(token);
        await SecureStorageService.saveUserData(
          employeeId: employeeId,
          employeeName: fullName,
          email: email,
          role: roleName,
          roleLevel: roleLevel,
        );

        AppLogger.success(
          'Login successful: $fullName ($roleName, Level $roleLevel)',
          tag: 'Auth',
        );
        AppLogger.endOperation('User Login', success: true);

        // [3.4] Return Login Response
        return LoginResponse(
          success: true,
          message: 'Đăng nhập thành công',
          token: token,
          employeeId: employeeId,
          fullName: fullName,
          email: email,
          roleName: roleName,
          roleLevel: roleLevel,
        );
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        // ❌ Bad Request or Unauthorized
        final message = responseData['message'] as String? ?? 'Đăng nhập thất bại';
        AppLogger.warning('Login failed: $message', tag: 'Auth');
        AppLogger.endOperation('User Login', success: false);
        
        throw Exception(message);
      } else {
        // ❌ Other Errors
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Login error', error: e, tag: 'Auth');
      AppLogger.endOperation('User Login', success: false);
      
      // Re-throw with user-friendly message
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('Không thể kết nối đến server.\nVui lòng kiểm tra kết nối mạng.');
      }
      
      rethrow;
    }
  }

  // ==================== TOKEN VALIDATION ====================

  /// Check if current token is valid
  /// 
  /// @returns true if token exists and not expired
  Future<bool> isTokenValid() async {
    try {
      final token = await SecureStorageService.readToken();
      
      if (token == null || token.isEmpty) {
        return false;
      }

      // Check if token is expired
      if (JwtDecoder.isExpired(token)) {
        AppLogger.warning('Token expired', tag: 'Auth');
        await logout(); // Auto logout
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.error('Token validation error', error: e, tag: 'Auth');
      return false;
    }
  }

  /// Get Token Expiry Date
  Future<DateTime?> getTokenExpiryDate() async {
    try {
      final token = await SecureStorageService.readToken();
      if (token == null) return null;

      final expiryDate = JwtDecoder.getExpirationDate(token);
      return expiryDate;
    } catch (e) {
      AppLogger.error('Failed to get token expiry', error: e, tag: 'Auth');
      return null;
    }
  }

  /// Decode Token and Get User Data
  Future<Map<String, dynamic>?> getTokenData() async {
    try {
      final token = await SecureStorageService.readToken();
      if (token == null) return null;

      final decodedToken = JwtDecoder.decode(token);
      return decodedToken;
    } catch (e) {
      AppLogger.error('Failed to decode token', error: e, tag: 'Auth');
      return null;
    }
  }

  // ==================== SESSION MANAGEMENT ====================

  /// Get Current User Data from Secure Storage
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return await SecureStorageService.readUserData();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await SecureStorageService.isLoggedIn() && await isTokenValid();
  }

  // ==================== LOGOUT ====================

  /// Logout User (Clear all session data)
  Future<void> logout() async {
    AppLogger.startOperation('User Logout');

    try {
      // TODO: Call backend logout API if needed
      // await http.post(Uri.parse('$_baseUrl/logout'));

      // Clear all secure storage
      await SecureStorageService.clearAll();

      AppLogger.success('Logout successful', tag: 'Auth');
      AppLogger.endOperation('User Logout', success: true);
    } catch (e) {
      AppLogger.error('Logout error', error: e, tag: 'Auth');
      AppLogger.endOperation('User Logout', success: false);
    }
  }

  // ==================== TOKEN REFRESH ====================

  /// Refresh Access Token (Call backend /refresh-token endpoint)
  /// 
  /// ⚠️ NOTE: Backend must implement POST /api/Employee/refresh-token
  /// with request body: { "refreshToken": "..." }
  /// 
  /// @returns true if refresh successful, false otherwise
  Future<bool> refreshAccessToken() async {
    AppLogger.startOperation('Token Refresh');

    try {
      final token = await SecureStorageService.readToken();
      
      if (token == null) {
        AppLogger.warning('No token to refresh', tag: 'Auth');
        return false;
      }

      // TODO: Implement refresh token endpoint on backend
      // For now, return false (will force re-login)
      AppLogger.warning(
        'Token refresh not implemented on backend yet',
        tag: 'Auth',
      );
      AppLogger.endOperation('Token Refresh', success: false);
      return false;

      // ✅ FUTURE IMPLEMENTATION:
      // final response = await http.post(
      //   Uri.parse('$_baseUrl/refresh-token'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({'refreshToken': token}),
      // );
      //
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   final newToken = data['token'] as String;
      //   await SecureStorageService.saveToken(newToken);
      //   return true;
      // }
      //
      // return false;

    } catch (e) {
      AppLogger.error('Token refresh failed', error: e, tag: 'Auth');
      AppLogger.endOperation('Token Refresh', success: false);
      return false;
    }
  }

  // ==================== ROLE-BASED NAVIGATION ====================

  /// Get Dashboard Route based on User Role
  /// 
  /// @returns Route name for navigation
  Future<String> getDashboardRoute() async {
    final userData = await getCurrentUser();
    
    if (userData == null) {
      return '/login';
    }

    final roleLevel = userData['roleLevel'] as int;

    // Route based on Role Level
    switch (roleLevel) {
      case 2: // Admin
        return '/admin-dashboard';
      case 1: // HR Manager
        return '/hr-dashboard';
      case 0: // Regular Employee
        return '/employee-dashboard';
      default:
        return '/login';
    }
  }

  /// Check if user has Admin privileges
  Future<bool> isAdmin() async {
    final userData = await getCurrentUser();
    return userData != null && userData['roleLevel'] == 2;
  }

  /// Check if user has HR privileges
  Future<bool> isHR() async {
    final userData = await getCurrentUser();
    return userData != null && userData['roleLevel'] >= 1;
  }
}

// ==================== LOGIN RESPONSE MODEL ====================

/// Login Response Model
class LoginResponse {
  final bool success;
  final String message;
  final String token;
  final int employeeId;
  final String fullName;
  final String email;
  final String roleName;
  final int roleLevel;

  LoginResponse({
    required this.success,
    required this.message,
    required this.token,
    required this.employeeId,
    required this.fullName,
    required this.email,
    required this.roleName,
    required this.roleLevel,
  });

  /// Get Dashboard Route based on Role Level
  String get dashboardRoute {
    switch (roleLevel) {
      case 2: // Admin
        return '/admin-dashboard';
      case 1: // HR Manager
        return '/hr-dashboard';
      case 0: // Employee
        return '/employee-dashboard';
      default:
        return '/login';
    }
  }

  /// Get Role Display Name
  String get roleDisplayName {
    switch (roleName.toLowerCase()) {
      case 'admin':
        return 'Quản trị viên';
      case 'hr':
      case 'hr manager':
        return 'Quản lý nhân sự';
      case 'employee':
      case 'user':
        return 'Nhân viên';
      default:
        return roleName;
    }
  }

  @override
  String toString() {
    return 'LoginResponse(success: $success, fullName: $fullName, role: $roleName, level: $roleLevel)';
  }
}

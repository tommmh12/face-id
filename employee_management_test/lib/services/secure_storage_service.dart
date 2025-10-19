import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_logger.dart';

/// 🔐 Secure Storage Service
/// 
/// Handles secure storage of sensitive data (JWT tokens, credentials)
/// using platform-specific secure storage:
/// - Android: KeyStore
/// - iOS: Keychain
/// - Windows: Credential Manager
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Storage Keys
  static const String _keyToken = 'jwt_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyEmployeeId = 'employee_id';
  static const String _keyEmployeeName = 'employee_name';
  static const String _keyEmployeeEmail = 'employee_email';
  static const String _keyRole = 'user_role';
  static const String _keyRoleLevel = 'role_level';

  // ==================== TOKEN MANAGEMENT ====================

  /// Save JWT Token
  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _keyToken, value: token);
      // ✅ Enhanced debugging
      print('💾 [STORAGE] Token saved: ${token.length} chars, starts with: ${token.substring(0, 20)}...');
      AppLogger.success('JWT Token saved securely to storage', tag: 'SecureStorage');
    } catch (e) {
      AppLogger.error('Failed to save token', error: e, tag: 'SecureStorage');
      rethrow;
    }
  }

  /// Read JWT Token
  static Future<String?> readToken() async {
    try {
      final token = await _storage.read(key: _keyToken);
      if (token != null) {
        // ✅ Enhanced debugging
        print('🔐 [STORAGE] Token retrieved: ${token.length} chars, starts with: ${token.substring(0, 20)}...');
        AppLogger.debug('JWT Token retrieved from secure storage', tag: 'SecureStorage');
      } else {
        print('⚠️ [STORAGE] No token found in secure storage');
        AppLogger.warning('No JWT token found in secure storage', tag: 'SecureStorage');
      }
      return token;
    } catch (e) {
      AppLogger.error('Failed to read token', error: e, tag: 'SecureStorage');
      return null;
    }
  }

  /// Delete JWT Token
  static Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _keyToken);
      AppLogger.info('JWT Token deleted', tag: 'SecureStorage');
    } catch (e) {
      AppLogger.error('Failed to delete token', error: e, tag: 'SecureStorage');
    }
  }

  // ==================== REFRESH TOKEN ====================

  /// Save Refresh Token (for future use)
  static Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
      AppLogger.debug('Refresh token saved', tag: 'SecureStorage');
    } catch (e) {
      AppLogger.error('Failed to save refresh token', error: e, tag: 'SecureStorage');
    }
  }

  /// Read Refresh Token
  static Future<String?> readRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken);
    } catch (e) {
      AppLogger.error('Failed to read refresh token', error: e, tag: 'SecureStorage');
      return null;
    }
  }

  // ==================== USER DATA ====================

  /// Save User Session Data
  static Future<void> saveUserData({
    required int employeeId,
    required String employeeName,
    required String email,
    required String role,
    required int roleLevel,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _keyEmployeeId, value: employeeId.toString()),
        _storage.write(key: _keyEmployeeName, value: employeeName),
        _storage.write(key: _keyEmployeeEmail, value: email),
        _storage.write(key: _keyRole, value: role),
        _storage.write(key: _keyRoleLevel, value: roleLevel.toString()),
      ]);
      AppLogger.success('User session data saved', tag: 'SecureStorage');
    } catch (e) {
      AppLogger.error('Failed to save user data', error: e, tag: 'SecureStorage');
    }
  }

  /// Read User Session Data
  static Future<Map<String, dynamic>?> readUserData() async {
    try {
      final results = await Future.wait([
        _storage.read(key: _keyEmployeeId),
        _storage.read(key: _keyEmployeeName),
        _storage.read(key: _keyEmployeeEmail),
        _storage.read(key: _keyRole),
        _storage.read(key: _keyRoleLevel),
      ]);

      if (results[0] == null) {
        return null; // No session data
      }

      return {
        'employeeId': int.parse(results[0]!),
        'employeeName': results[1],
        'email': results[2],
        'role': results[3],
        'roleLevel': int.parse(results[4] ?? '0'),
      };
    } catch (e) {
      AppLogger.error('Failed to read user data', error: e, tag: 'SecureStorage');
      return null;
    }
  }

  // ==================== LOGOUT ====================

  /// Clear All Session Data
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      AppLogger.success('All session data cleared (Logout)', tag: 'SecureStorage');
    } catch (e) {
      AppLogger.error('Failed to clear session data', error: e, tag: 'SecureStorage');
    }
  }

  // ==================== UTILITIES ====================

  /// Check if User is Logged In
  static Future<bool> isLoggedIn() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }

  /// Read specific key
  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      AppLogger.error('Failed to read key: $key', error: e, tag: 'SecureStorage');
      return null;
    }
  }

  /// Write specific key
  static Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      AppLogger.error('Failed to write key: $key', error: e, tag: 'SecureStorage');
    }
  }

  /// Delete specific key
  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      AppLogger.error('Failed to delete key: $key', error: e, tag: 'SecureStorage');
    }
  }
}

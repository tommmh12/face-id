import '../services/secure_storage_service.dart';

/// Helper class để lấy thông tin người dùng hiện tại
/// TODO: Implement proper user management system
class UserHelper {
  static const String _defaultUser = 'HR Admin';
  
  /// Lấy tên người dùng hiện tại từ auth service
  /// Hiện tại return default value, sau này có thể kết nối với auth service thực
  static Future<String> getCurrentUserName() async {
    try {
      // TODO: Implement real user name retrieval from auth service
      // For now, return default user
      final token = await SecureStorageService.readToken();
      if (token != null && token.isNotEmpty) {
        // TODO: Decode JWT token to get user info
        // For now, return default value
        return _defaultUser;
      }
      return _defaultUser;
    } catch (e) {
      return _defaultUser;
    }
  }
  
  /// Lấy ID người dùng hiện tại
  static Future<int> getCurrentUserId() async {
    try {
      // TODO: Implement real user ID retrieval from auth service
      // For now, return default ID
      return 1;
    } catch (e) {
      return 1;
    }
  }
  
  /// Kiểm tra người dùng hiện tại có quyền thực hiện thao tác không
  static Future<bool> hasPermission(String action) async {
    try {
      // TODO: Implement real permission checking
      // For now, return true (full access)
      return true;
    } catch (e) {
      return false;
    }
  }
}
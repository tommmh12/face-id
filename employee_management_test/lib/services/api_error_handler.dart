import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// 🚨 Global API Error Handler
/// 
/// Provides centralized error handling for all API responses:
/// - Status code to error message mapping
/// - Network error detection
/// - User-friendly error display (SnackBar)
/// - Icon and color coding by error type
/// 
/// Usage:
/// ```dart
/// final response = await http.get(...);
/// if (response.statusCode != 200) {
///   ApiErrorHandler.handleError(context, response);
///   return;
/// }
/// ```
class ApiErrorHandler {
  // Prevent instantiation
  ApiErrorHandler._();

  /// Handle API error response and show SnackBar
  /// 
  /// @param context - BuildContext for showing SnackBar
  /// @param response - HTTP response with error
  /// @param customMessage - Optional custom error message
  /// @param duration - SnackBar display duration (default 4 seconds)
  static void handleError(
    BuildContext context,
    http.Response response, {
    String? customMessage,
    Duration duration = const Duration(seconds: 4),
  }) {
    final statusCode = response.statusCode;
    final message = customMessage ?? _getDefaultErrorMessage(statusCode);
    final icon = _getErrorIcon(statusCode);
    final color = _getErrorColor(statusCode);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lỗi ($statusCode)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Handle network or exception errors
  /// 
  /// @param context - BuildContext for showing SnackBar
  /// @param error - Exception or error object
  /// @param duration - SnackBar display duration
  static void handleException(
    BuildContext context,
    Object error, {
    Duration duration = const Duration(seconds: 4),
  }) {
    String message;
    IconData icon;

    if (isNetworkError(error)) {
      message = 'Không có kết nối mạng. Vui lòng kiểm tra lại.';
      icon = Icons.wifi_off;
    } else if (isTimeoutError(error)) {
      message = 'Kết nối timeout. Vui lòng thử lại.';
      icon = Icons.timer_off;
    } else {
      message = 'Đã xảy ra lỗi: ${error.toString()}';
      icon = Icons.error_outline;
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show success message
  /// 
  /// @param context - BuildContext for showing SnackBar
  /// @param message - Success message
  /// @param duration - SnackBar display duration
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Get default error message based on status code
  static String _getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Yêu cầu không hợp lệ. Vui lòng kiểm tra lại thông tin.';
      case 401:
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      case 403:
        return 'Bạn không có quyền truy cập tài nguyên này.';
      case 404:
        return 'Không tìm thấy dữ liệu yêu cầu.';
      case 409:
        return 'Dữ liệu đã tồn tại hoặc xung đột.';
      case 422:
        return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
      case 500:
        return 'Lỗi máy chủ. Vui lòng thử lại sau.';
      case 502:
        return 'Máy chủ không phản hồi. Vui lòng thử lại sau.';
      case 503:
        return 'Dịch vụ tạm thời không khả dụng. Vui lòng thử lại sau.';
      default:
        if (statusCode >= 500) {
          return 'Lỗi máy chủ ($statusCode). Vui lòng thử lại sau.';
        } else if (statusCode >= 400) {
          return 'Yêu cầu thất bại ($statusCode). Vui lòng thử lại.';
        }
        return 'Đã xảy ra lỗi không xác định ($statusCode).';
    }
  }

  /// Get error icon based on status code
  static IconData _getErrorIcon(int statusCode) {
    switch (statusCode) {
      case 400:
      case 422:
        return Icons.warning_amber;
      case 401:
        return Icons.lock_outline;
      case 403:
        return Icons.block;
      case 404:
        return Icons.search_off;
      case 409:
        return Icons.error_outline;
      case 500:
      case 502:
      case 503:
        return Icons.cloud_off;
      default:
        return Icons.error_outline;
    }
  }

  /// Get error color based on status code
  static Color _getErrorColor(int statusCode) {
    switch (statusCode) {
      case 400:
      case 422:
        return Colors.orange[700]!; // Warning
      case 401:
      case 403:
        return Colors.deepOrange[700]!; // Access denied
      case 404:
        return Colors.blue[700]!; // Not found
      case 409:
        return Colors.amber[800]!; // Conflict
      case 500:
      case 502:
      case 503:
        return Colors.red[700]!; // Server error
      default:
        return Colors.red[600]!; // Generic error
    }
  }

  /// Check if error is network-related
  static bool isNetworkError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('no address associated with hostname');
  }

  /// Check if error is timeout-related
  static bool isTimeoutError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeoutexception') ||
        errorString.contains('operation timed out') ||
        errorString.contains('connection timeout');
  }
}

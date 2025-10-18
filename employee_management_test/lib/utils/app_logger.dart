import 'package:flutter/foundation.dart';

/// 🔍 App-wide logging utility with emoji indicators
/// Use this instead of debugPrint for consistent, colorful logging
class AppLogger {
  // Prevent instantiation
  AppLogger._();

  /// 📱 General info log
  static void info(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('ℹ️ $prefix$message');
  }

  /// ✅ Success log
  static void success(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('✅ $prefix$message');
  }

  /// ⚠️ Warning log
  static void warning(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('⚠️ $prefix$message');
  }

  /// ❌ Error log
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('❌ $prefix$message');
    if (error != null) {
      debugPrint('   Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('   Stack trace:\n$stackTrace');
    }
  }

  /// 🚀 API call start log
  static void apiRequest(String endpoint, {String method = 'POST', Map<String, dynamic>? data}) {
    debugPrint('🚀 API Request: $method $endpoint');
    if (data != null && data.isNotEmpty) {
      final keys = data.keys.where((k) => k != 'imageBase64').toList();
      if (keys.isNotEmpty) {
        debugPrint('   Params: ${keys.join(', ')}');
      }
      if (data.containsKey('imageBase64')) {
        final base64 = data['imageBase64'] as String?;
        if (base64 != null) {
          debugPrint('   Image: ${base64.length} chars (${(base64.length / 1024).toStringAsFixed(1)} KB)');
        }
      }
    }
  }

  /// 📥 API response log
  static void apiResponse(String endpoint, {required bool success, String? message, dynamic data}) {
    debugPrint('📥 API Response: $endpoint');
    debugPrint('   Success: $success');
    if (message != null && message.isNotEmpty) {
      debugPrint('   Message: $message');
    }
    if (data != null && data.toString().length < 200) {
      debugPrint('   Data: $data');
    }
  }

  /// 🔄 Navigation log
  static void navigation(String from, String to, {Map<String, dynamic>? arguments}) {
    debugPrint('🔄 Navigation: $from → $to');
    if (arguments != null && arguments.isNotEmpty) {
      final argSummary = arguments.keys.take(5).join(', ');
      debugPrint('   Arguments: $argSummary');
    }
  }

  /// 📸 Camera log
  static void camera(String message) {
    debugPrint('📸 Camera: $message');
  }

  /// 💾 Data/State log
  static void data(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('💾 $prefix$message');
  }

  /// 🎨 UI/Lifecycle log
  static void ui(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('🎨 $prefix$message');
  }

  /// 🔐 Security/Auth log (sensitive data should be masked)
  static void security(String message) {
    debugPrint('🔐 Security: $message');
  }

  /// 📊 Performance log
  static void performance(String operation, Duration duration) {
    final ms = duration.inMilliseconds;
    final emoji = ms < 100 ? '⚡' : ms < 500 ? '🏃' : '🐌';
    debugPrint('$emoji Performance: $operation took ${ms}ms');
  }

  /// 🔍 Debug verbose log (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('🔍 $prefix$message');
    }
  }

  /// 🎯 Business logic log
  static void business(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('🎯 $prefix$message');
  }

  /// ═══════════════════════════════════
  /// Separator for visual clarity
  static void separator({String? title}) {
    if (title != null) {
      debugPrint('\n═══════════════════════════════════');
      debugPrint('   $title');
      debugPrint('═══════════════════════════════════\n');
    } else {
      debugPrint('───────────────────────────────────');
    }
  }

  /// Start of a major operation
  static void startOperation(String operation) {
    separator(title: 'START: $operation');
  }

  /// End of a major operation
  static void endOperation(String operation, {bool success = true}) {
    final emoji = success ? '✅' : '❌';
    separator(title: '$emoji END: $operation');
  }
}

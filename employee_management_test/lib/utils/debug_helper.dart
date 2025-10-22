import 'dart:convert';

/// Helper utility for consistent debug logging across the app
/// Provides structured, color-coded debug output
class DebugHelper {
  static const bool _isDebugMode = true; // Set to false in production

  /// Log API request with formatted output
  static void logApiRequest(String endpoint, Map<String, dynamic> payload) {
    if (!_isDebugMode) return;
    
    print('\n┌─────────────────────────────────────────────────────────────────────────────');
    print('│ 🚀 API REQUEST');
    print('├─────────────────────────────────────────────────────────────────────────────');
    print('│ Endpoint: $endpoint');
    print('│ Payload:');
    print('│ ${_formatJson(payload)}');
    print('└─────────────────────────────────────────────────────────────────────────────\n');
  }

  /// Log API response with formatted output
  static void logApiResponse(String endpoint, int statusCode, String body) {
    if (!_isDebugMode) return;
    
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final icon = isSuccess ? '✅' : '❌';
    
    print('\n┌─────────────────────────────────────────────────────────────────────────────');
    print('│ $icon API RESPONSE');
    print('├─────────────────────────────────────────────────────────────────────────────');
    print('│ Endpoint: $endpoint');
    print('│ Status: $statusCode');
    print('│ Response Body:');
    print('│ ${_formatJsonString(body)}');
    print('└─────────────────────────────────────────────────────────────────────────────\n');
  }

  /// Log validation errors from .NET Core
  static void logValidationErrors(Map<String, dynamic> errors) {
    if (!_isDebugMode) return;
    
    print('\n┌─────────────────────────────────────────────────────────────────────────────');
    print('│ 🚨 VALIDATION ERRORS FROM SERVER');
    print('├─────────────────────────────────────────────────────────────────────────────');
    
    errors.forEach((field, messages) {
      print('│ Field: "$field"');
      if (messages is List) {
        for (var message in messages) {
          print('│   → $message');
        }
      } else {
        print('│   → $messages');
      }
      print('│');
    });
    
    print('└─────────────────────────────────────────────────────────────────────────────\n');
  }

  /// Format JSON map for pretty printing
  static String _formatJson(Map<String, dynamic> json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json).replaceAll('\n', '\n│ ');
    } catch (e) {
      return json.toString();
    }
  }

  /// Format JSON string for pretty printing
  static String _formatJsonString(String jsonString) {
    try {
      final jsonData = json.decode(jsonString);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonData).replaceAll('\n', '\n│ ');
    } catch (e) {
      return jsonString;
    }
  }

  /// Log general debug message
  static void log(String message, {String? tag}) {
    if (!_isDebugMode) return;
    
    final tagStr = tag != null ? '[$tag] ' : '';
    print('🔍 DEBUG: $tagStr$message');
  }

  /// Log error message
  static void logError(String message, {String? tag, dynamic error}) {
    if (!_isDebugMode) return;
    
    final tagStr = tag != null ? '[$tag] ' : '';
    print('💥 ERROR: $tagStr$message');
    if (error != null) {
      print('💥 Details: $error');
    }
  }

  /// Log success message
  static void logSuccess(String message, {String? tag}) {
    if (!_isDebugMode) return;
    
    final tagStr = tag != null ? '[$tag] ' : '';
    print('✅ SUCCESS: $tagStr$message');
  }
}
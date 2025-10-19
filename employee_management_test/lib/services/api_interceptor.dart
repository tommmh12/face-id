import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';
import 'auth_service.dart';

/// 🔄 API Interceptor - Auto Token Refresh & Retry
/// 
/// Provides wrapper methods for HTTP requests with:
/// - Automatic Bearer token injection
/// - Auto-refresh on 401 Unauthorized
/// - Retry request with new token
/// - Centralized timeout handling
/// 
/// Usage:
/// ```dart
/// // Instead of http.get()
/// final response = await ApiInterceptor.get(
///   Uri.parse('${ApiConfig.baseUrl}/Employee')
/// );
/// ```
class ApiInterceptor {
  // Prevent instantiation
  ApiInterceptor._();

  /// GET request with auto token refresh
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return _makeRequest(
      method: 'GET',
      url: url,
      headers: headers,
      timeout: timeout,
    );
  }

  /// POST request with auto token refresh
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return _makeRequest(
      method: 'POST',
      url: url,
      headers: headers,
      body: body,
      encoding: encoding,
      timeout: timeout,
    );
  }

  /// PUT request with auto token refresh
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return _makeRequest(
      method: 'PUT',
      url: url,
      headers: headers,
      body: body,
      encoding: encoding,
      timeout: timeout,
    );
  }

  /// DELETE request with auto token refresh
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return _makeRequest(
      method: 'DELETE',
      url: url,
      headers: headers,
      body: body,
      encoding: encoding,
      timeout: timeout,
    );
  }

  /// Internal method to make HTTP request with retry logic
  static Future<http.Response> _makeRequest({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    required Duration timeout,
  }) async {
    // Build headers with Bearer token
    final requestHeaders = await _buildHeaders(headers);

    try {
      // Make initial request
      http.Response response;
      
      switch (method) {
        case 'GET':
          response = await http
              .get(url, headers: requestHeaders)
              .timeout(timeout);
          break;
        case 'POST':
          response = await http
              .post(url, headers: requestHeaders, body: body, encoding: encoding)
              .timeout(timeout);
          break;
        case 'PUT':
          response = await http
              .put(url, headers: requestHeaders, body: body, encoding: encoding)
              .timeout(timeout);
          break;
        case 'DELETE':
          response = await http
              .delete(url, headers: requestHeaders, body: body, encoding: encoding)
              .timeout(timeout);
          break;
        default:
          throw UnsupportedError('HTTP method $method not supported');
      }

      // ✅ SUCCESS - Return response
      if (response.statusCode != 401) {
        return response;
      }

      // ⚠️ 401 UNAUTHORIZED - Try to refresh token
      print('🔄 ApiInterceptor: 401 Unauthorized detected, attempting token refresh...');
      
      final authService = AuthService();
      final refreshSuccess = await authService.refreshAccessToken();

      if (!refreshSuccess) {
        print('❌ ApiInterceptor: Token refresh failed, redirecting to login');
        return response; // Return 401 response (caller will handle logout)
      }

      // ✅ Token refreshed - Retry request with new token
      print('✅ ApiInterceptor: Token refreshed, retrying request...');
      final newHeaders = await _buildHeaders(headers);

      switch (method) {
        case 'GET':
          response = await http
              .get(url, headers: newHeaders)
              .timeout(timeout);
          break;
        case 'POST':
          response = await http
              .post(url, headers: newHeaders, body: body, encoding: encoding)
              .timeout(timeout);
          break;
        case 'PUT':
          response = await http
              .put(url, headers: newHeaders, body: body, encoding: encoding)
              .timeout(timeout);
          break;
        case 'DELETE':
          response = await http
              .delete(url, headers: newHeaders, body: body, encoding: encoding)
              .timeout(timeout);
          break;
        default:
          throw UnsupportedError('HTTP method $method not supported');
      }

      return response;

    } catch (e) {
      print('❌ ApiInterceptor: Request failed - $e');
      rethrow;
    }
  }

  /// Build request headers with Bearer token
  static Future<Map<String, String>> _buildHeaders(
    Map<String, String>? customHeaders,
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add custom headers
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    // Add Bearer token if available
    final token = await SecureStorageService.readToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Check if error is network-related
  static bool isNetworkError(Object error) {
    return error.toString().contains('SocketException') ||
        error.toString().contains('Failed host lookup') ||
        error.toString().contains('Network is unreachable');
  }

  /// Check if error is timeout-related
  static bool isTimeoutError(Object error) {
    return error.toString().contains('TimeoutException') ||
        error.toString().contains('Operation timed out');
  }
}

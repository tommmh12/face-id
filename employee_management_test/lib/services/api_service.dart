import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Cấu hình chung cho API
class ApiConfig {
  static final String baseUrl = AppConfig.baseUrl;

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders([String? token]) {
    final authHeaders = Map<String, String>.from(headers);
    if (token != null && token.isNotEmpty) {
      authHeaders['Authorization'] = 'Bearer $token';
    }
    return authHeaders;
  }
}

/// Exception tùy chỉnh cho API
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Response chuẩn hóa
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(T data, [int? statusCode]) {
    return ApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String message, [int? statusCode]) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

/// Service gốc cho các API khác kế thừa
class BaseApiService {
  final Duration _timeout = const Duration(seconds: 15);

  /// Xử lý request trả về object
  Future<ApiResponse<T>> handleRequest<T>(
    Future<http.Response> Function() requestFunction,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await requestFunction().timeout(_timeout);

      // Log status
      print('[API] → ${response.request?.url} (${response.statusCode})');

      if (response.body.isEmpty) {
        if (_isSuccess(response.statusCode)) {
          return ApiResponse.success(fromJson({}), response.statusCode);
        } else {
          return ApiResponse.error('Empty response body', response.statusCode);
        }
      }

      final Map<String, dynamic> jsonData = json.decode(response.body);

      if (_isSuccess(response.statusCode)) {
        return ApiResponse.success(fromJson(jsonData), response.statusCode);
      } else {
        final errorMessage =
            jsonData['message'] ?? jsonData['error'] ?? 'Unknown error occurred';
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } on SocketException {
      return ApiResponse.error('No Internet connection');
    } on HttpException {
      return ApiResponse.error('HTTP request failed');
    } on FormatException catch (e) {
      return ApiResponse.error('Invalid JSON response: ${e.message}');
    } on TimeoutException {
      return ApiResponse.error('Request timed out');
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Xử lý request trả về danh sách
  Future<ApiResponse<List<T>>> handleListRequest<T>(
    Future<http.Response> Function() requestFunction,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await requestFunction().timeout(_timeout);

      print('[API] → ${response.request?.url} (${response.statusCode})');

      if (response.body.isEmpty) {
        if (_isSuccess(response.statusCode)) {
          return ApiResponse.success(<T>[], response.statusCode);
        } else {
          return ApiResponse.error('Empty response body', response.statusCode);
        }
      }

      final dynamic jsonData = json.decode(response.body);

      if (_isSuccess(response.statusCode)) {
        if (jsonData is List) {
          final List<T> items = jsonData
              .map((item) => fromJson(item as Map<String, dynamic>))
              .toList();
          return ApiResponse.success(items, response.statusCode);
        } else {
          return ApiResponse.error('Expected array response but got object');
        }
      } else {
        final errorMessage = (jsonData is Map)
            ? (jsonData['message'] ??
                jsonData['error'] ??
                'Unknown error occurred')
            : 'Unknown error occurred';
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } on SocketException {
      return ApiResponse.error('No Internet connection');
    } on HttpException {
      return ApiResponse.error('HTTP request failed');
    } on FormatException catch (e) {
      return ApiResponse.error('Invalid JSON response: ${e.message}');
    } on TimeoutException {
      return ApiResponse.error('Request timed out');
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;
}

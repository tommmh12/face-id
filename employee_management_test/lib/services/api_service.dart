import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiConfig {
  static const String baseUrl = AppConfig.baseUrl;
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders([String? token]) {
    final authHeaders = Map<String, String>.from(headers);
    if (token != null) {
      authHeaders['Authorization'] = 'Bearer $token';
    }
    return authHeaders;
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

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

class BaseApiService {
  Future<ApiResponse<T>> handleRequest<T>(
    Future<http.Response> Function() requestFunction,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await requestFunction();
      
      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Handle empty success response
          return ApiResponse.success(fromJson({}), response.statusCode);
        } else {
          return ApiResponse.error('Empty response body', response.statusCode);
        }
      }

      final Map<String, dynamic> jsonData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(fromJson(jsonData), response.statusCode);
      } else {
        final errorMessage = jsonData['message'] ?? jsonData['error'] ?? 'Unknown error occurred';
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } on FormatException catch (e) {
      return ApiResponse.error('Invalid JSON response: ${e.toString()}');
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<T>>> handleListRequest<T>(
    Future<http.Response> Function() requestFunction,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await requestFunction();
      
      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return ApiResponse.success(<T>[], response.statusCode);
        } else {
          return ApiResponse.error('Empty response body', response.statusCode);
        }
      }

      final dynamic jsonData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (jsonData is List) {
          final List<T> items = jsonData.map((item) => fromJson(item as Map<String, dynamic>)).toList();
          return ApiResponse.success(items, response.statusCode);
        } else {
          return ApiResponse.error('Expected array response but got object');
        }
      } else {
        final errorMessage = (jsonData is Map) 
          ? (jsonData['message'] ?? jsonData['error'] ?? 'Unknown error occurred')
          : 'Unknown error occurred';
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } on FormatException catch (e) {
      return ApiResponse.error('Invalid JSON response: ${e.toString()}');
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }
}
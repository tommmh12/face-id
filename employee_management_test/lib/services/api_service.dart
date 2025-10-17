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
  final http.Client _client = http.Client();

  Future<ApiResponse<T>> handleRequest<T>(
    Future<http.Response> request,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await request;
      final Map<String, dynamic> jsonData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(fromJson(jsonData), response.statusCode);
      } else {
        final errorMessage = jsonData['message'] ?? 'Unknown error occurred';
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<T>>> handleListRequest<T>(
    Future<http.Response> request,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await request;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> jsonList = json.decode(response.body);
        final List<T> items = jsonList.map((json) => fromJson(json as Map<String, dynamic>)).toList();
        return ApiResponse.success(items, response.statusCode);
      } else {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final errorMessage = jsonData['message'] ?? 'Unknown error occurred';
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  void dispose() {
    _client.close();
  }
}
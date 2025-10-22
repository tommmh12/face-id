import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/debug_helper.dart';
import 'secure_storage_service.dart';

class ApiConfig {
  static const String baseUrl = AppConfig.baseUrl;
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders([String? token]) {
    final authHeaders = Map<String, String>.from(headers);
    // ✅ BẮT BUỘC: Kiểm tra cả null và isEmpty
    if (token != null && token.isNotEmpty) {
      // ✅ BẮT BUỘC: PHẢI CÓ DẤU CÁCH CHÍNH XÁC SAU "Bearer"
      authHeaders['Authorization'] = 'Bearer $token';
      print('🔐 [AUTH] Token added to headers: Bearer ${token.substring(0, 20)}...');
    } else {
      print('⚠️ [AUTH] No valid token provided - API call may fail');
    }
    return authHeaders;
  }

  /// ✅ Helper method: Automatically get authenticated headers
  static Future<Map<String, String>> getAuthenticatedHeaders() async {
    final token = await SecureStorageService.readToken();
    print('🔍 [AUTH] Retrieved token from storage: ${token != null ? "✅ Found" : "❌ Null"}');
    return getAuthHeaders(token);
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
  /// Parse HTTP response với guard clauses để ngăn crash
  Map<String, dynamic> _parseResponse(http.Response response) {
    // [1] Kiểm tra HTTP Status Code (4xx, 5xx)
    if (response.statusCode >= 400) {
      // Nếu là lỗi, chỉ cần parse body để lấy thông tin (nếu có)
      if (response.body.isNotEmpty) {
        try {
          final jsonData = json.decode(response.body);
          // Trả về JSON lỗi để handleRequest xử lý
          return jsonData is Map ? jsonData as Map<String, dynamic> : {
            'success': false, 
            'message': jsonData.toString(), 
            'statusCode': response.statusCode
          };
        } catch (e) {
          // Nếu JSON lỗi không hợp lệ, trả về một Map lỗi an toàn
          return {
            'success': false, 
            'message': 'Lỗi máy chủ không rõ', 
            'statusCode': response.statusCode
          };
        }
      } else {
        // Body trống + Status lỗi
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          'statusCode': response.statusCode
        };
      }
    }
    
    // [2] LỚP BẢO VỆ CRITICAL - Guard Clause cho Empty Body
    if (response.body.isEmpty) {
      // Nếu Status 200-299 nhưng body trống (Content-Length: 0)
      // Trả về JSON rỗng an toàn thay vì crash với FormatException
      return {
        'success': true,
        'message': 'Không có dữ liệu, nhưng kết nối thành công.',
        'data': [] // Mảng rỗng để tránh crash khi map to list
      };
    }

    // [3] Decode JSON (Chỉ khi body không trống)
    try {
      final jsonData = json.decode(response.body);
      // Nếu backend trả về string thay vì object
      if (jsonData is! Map && jsonData is! List) {
        return {
          'success': true,
          'message': 'Response received',
          'data': jsonData
        };
      }
      return jsonData is Map ? jsonData as Map<String, dynamic> : {'data': jsonData};
    } on FormatException catch (e) {
      // JSON malformed - body không phải JSON hợp lệ
      throw ApiException('Lỗi định dạng JSON từ Server: ${e.message}');
    } catch (e) {
      throw ApiException('Lỗi parse response: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> handleRequest<T>(
    Future<http.Response> Function() requestFunction,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await requestFunction();
      
      // 🔍 DEBUG: Log response details
      DebugHelper.logApiResponse('Response', response.statusCode, response.body);
      
      // Sử dụng _parseResponse với guard clauses - chỉ parse, không ném exception cho status code
      final Map<String, dynamic> jsonData = _parseResponse(response);

      // KIỂM TRA MÃ TRẠNG THÁI HTTP (Không dựa vào success field nữa)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success response (2xx)
        DebugHelper.logSuccess('Request thành công - Status ${response.statusCode}', tag: 'HTTP');
        
        // 🐛 FIX: Extract 'data' from response wrapper before passing to fromJson
        // Backend trả về: {"success": true, "message": "...", "data": {...}}
        // fromJson chỉ cần: {...} (data bên trong)
        final dataJson = jsonData['data'] as Map<String, dynamic>? ?? jsonData;
        print(">>> [handleRequest] Extracted data for fromJson: $dataJson");
        
        return ApiResponse.success(fromJson(dataJson), response.statusCode);
      } else {
        // Error response (4xx, 5xx) - Lấy thông báo lỗi từ JSON body
        DebugHelper.logError('Request thất bại - Status ${response.statusCode}', tag: 'HTTP');
        
        // Kiểm tra validation errors từ .NET Core
        if (jsonData['errors'] != null) {
          final errors = jsonData['errors'] as Map<String, dynamic>;
          DebugHelper.logValidationErrors(errors);
        }
        
        final errorMessage = jsonData['message'] ?? 
                           jsonData['title'] ?? 
                           jsonData['error'] ?? 
                           'Lỗi không xác định (HTTP ${response.statusCode})';
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } on ApiException catch (e) {
      // Bắt lỗi khi Body trống hoặc Malformed JSON (chỉ từ _parseResponse)
      DebugHelper.logError('ApiException: ${e.message}', tag: 'HTTP', error: e);
      return ApiResponse.error(e.message, e.statusCode);
    } on FormatException catch (e) {
      DebugHelper.logError('FormatException: ${e.message}', tag: 'HTTP', error: e);
      return ApiResponse.error('Lỗi định dạng JSON: ${e.message}');
    } catch (e) {
      DebugHelper.logError('Unexpected Exception: ${e.toString()}', tag: 'HTTP', error: e);
      return ApiResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<T>>> handleListRequest<T>(
    Future<http.Response> Function() requestFunction,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await requestFunction();
      
      // [1] LỚP BẢO VỆ - Kiểm tra empty body TRƯỚC khi decode
      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          // HTTP 200/204 với body trống → Trả về mảng rỗng thay vì crash
          return ApiResponse.success(<T>[], response.statusCode);
        } else {
          return ApiResponse.error(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}', 
            response.statusCode
          );
        }
      }

      // [2] Decode JSON (Chỉ khi body không trống)
      final dynamic jsonData = json.decode(response.body);

      // [3] KIỂM TRA MÃ TRẠNG THÁI HTTP
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success response (2xx) - Kiểm tra kiểu dữ liệu
        if (jsonData is List) {
          // Backend trả về array trực tiếp
          if (jsonData.isEmpty) {
            // Array rỗng → Empty state
            return ApiResponse.success(<T>[], response.statusCode);
          }
          final List<T> items = jsonData
              .map((item) => fromJson(item as Map<String, dynamic>))
              .toList();
          return ApiResponse.success(items, response.statusCode);
        } else if (jsonData is Map) {
          // Backend trả về wrapper object: {data: [...]}
          final data = jsonData['data'];
          if (data == null || (data is List && data.isEmpty)) {
            return ApiResponse.success(<T>[], response.statusCode);
          }
          if (data is List) {
            final List<T> items = data
                .map((item) => fromJson(item as Map<String, dynamic>))
                .toList();
            return ApiResponse.success(items, response.statusCode);
          }
          return ApiResponse.error('Expected array in data field but got ${data.runtimeType}');
        } else {
          return ApiResponse.error('Expected array response but got ${jsonData.runtimeType}');
        }
      } else {
        // Error response (4xx, 5xx) - Lấy thông báo lỗi từ JSON body
        final errorMessage = (jsonData is Map) 
          ? (jsonData['message'] ?? jsonData['error'] ?? 'Lỗi không xác định')
          : 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } on FormatException catch (e) {
      // JSON malformed - Không nên xảy ra nếu guard clause hoạt động
      return ApiResponse.error('Lỗi định dạng JSON từ Server: ${e.message}');
    } catch (e) {
      return ApiResponse.error('Lỗi kết nối: ${e.toString()}');
    }
  }
}
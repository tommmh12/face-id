import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

const String _defaultApiRoot = 'https://api.studyplannerapp.io.vn/api/';

String _resolveFaceApiBaseUrl() {
  const raw = String.fromEnvironment('FACE_API_BASE', defaultValue: _defaultApiRoot);
  final normalizedRoot = raw.endsWith('/') ? raw : '$raw/';
  if (normalizedRoot.toLowerCase().endsWith('face/')) {
    return normalizedRoot;
  }
  return '${normalizedRoot}face/';
}

class FaceService {
  FaceService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _resolveFaceApiBaseUrl(),
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                contentType: Headers.jsonContentType,
                responseType: ResponseType.json,
              ),
            );

  final Dio _dio;

  Future<FaceVerificationResult> verify(String endpoint, String base64Image) async {
    try {
      debugPrint('🔍 Đang gửi yêu cầu xác thực khuôn mặt...');
      
      final response = await _dio.post<Map<String, dynamic>>(
        endpoint,
        data: {'imageBase64': base64Image},
        options: Options(validateStatus: (_) => true),
      );
      
      final data = response.data ?? <String, dynamic>{};
      final statusCode = response.statusCode ?? 500;
      
      debugPrint('📡 API Response: Status ${statusCode}, Data: ${data}');
      
      return FaceVerificationResult.fromResponse(data, statusCode);
      
    } on DioException catch (e) {
      debugPrint('❌ Lỗi kết nối: ${e.message}');
      
      final dynamic data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return FaceVerificationResult.fromResponse(data, e.response?.statusCode ?? 500);
      }
      
      return FaceVerificationResult.error(_getErrorMessage(e.type));
    } catch (e) {
      debugPrint('💥 Lỗi không xác định: $e');
      return FaceVerificationResult.error('Đã xảy ra lỗi không xác định');
    }
  }

  String _getErrorMessage(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return 'Kết nối quá chậm. Vui lòng kiểm tra mạng và thử lại.';
      case DioExceptionType.sendTimeout:
        return 'Gửi dữ liệu quá chậm. Vui lòng thử lại.';
      case DioExceptionType.receiveTimeout:
        return 'Nhận dữ liệu quá chậm. Vui lòng thử lại.';
      case DioExceptionType.connectionError:
        return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.';
      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy.';
      default:
        return 'Lỗi kết nối. Vui lòng thử lại sau.';
    }
  }
}

class FaceVerificationResult {
  final bool success;
  final String message;
  final String? employeeName;
  final String? employeeId;
  final int statusCode;
  final DateTime timestamp;

  FaceVerificationResult._({
    required this.success,
    required this.message,
    this.employeeName,
    this.employeeId,
    required this.statusCode,
    required this.timestamp,
  });

  factory FaceVerificationResult.fromResponse(Map<String, dynamic> data, int statusCode) {
    final success = statusCode == 200 && (data['success'] == true || data['message']?.toString().contains('thành công') == true);
    
    return FaceVerificationResult._(
      success: success,
      message: data['message']?.toString() ?? 'Không có thông tin phản hồi',
      employeeName: data['employeeName']?.toString(),
      employeeId: data['employeeId']?.toString(),
      statusCode: statusCode,
      timestamp: DateTime.now(),
    );
  }

  factory FaceVerificationResult.error(String errorMessage) {
    return FaceVerificationResult._(
      success: false,
      message: errorMessage,
      statusCode: 500,
      timestamp: DateTime.now(),
    );
  }

  String get detailedMessage {
    if (success) {
      if (employeeName != null) {
        return 'Chấm công thành công!\nNhân viên: $employeeName';
      }
      return message;
    } else {
      return message;
    }
  }
}

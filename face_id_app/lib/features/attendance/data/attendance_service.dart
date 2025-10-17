import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../model/attendance_response.dart';

class AttendanceService {
  final Dio _dio = ApiClient().client;

  /// Check health status of the API
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/api/face/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Verify face for realtime check-in (always "IN")
  /// Uses /api/face/verify endpoint
  /// [imageBase64] - Base64 encoded face image
  Future<AttendanceResponse> verifyFace({
    required String imageBase64,
  }) async {
    try {
      final response = await _dio.post(
        '/api/face/verify',
        data: {
          'ImageBase64': imageBase64, // PascalCase for .NET API
        },
      );

      return AttendanceResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        // Server responded with error
        return AttendanceResponse.fromJson(
          e.response!.data as Map<String, dynamic>,
        );
      } else {
        // Network error
        return AttendanceResponse(
          success: false,
          status: 'error',
          message: 'Lỗi kết nối: ${e.message}',
          confidence: 0,
        );
      }
    } catch (e) {
      return AttendanceResponse(
        success: false,
        status: 'error',
        message: 'Lỗi không xác định: $e',
        confidence: 0,
      );
    }
  }

  /// Submit face check-in or check-out (manual)
  /// Uses /api/face/checkin endpoint (for manual selection)
  /// [faceImageBase64] - Base64 encoded face image
  /// [checkType] - "IN" for check-in, "OUT" for check-out
  Future<AttendanceResponse> submitAttendance({
    required String faceImageBase64,
    required String checkType,
  }) async {
    try {
      final response = await _dio.post(
        '/api/face/checkin',
        data: {
          'FaceImageBase64': faceImageBase64, // PascalCase for .NET API
          'CheckType': checkType, // PascalCase for .NET API
        },
      );

      return AttendanceResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) {
        // Server responded with error
        return AttendanceResponse.fromJson(
          e.response!.data as Map<String, dynamic>,
        );
      } else {
        // Network error
        return AttendanceResponse(
          success: false,
          status: 'error',
          message: 'Lỗi kết nối: ${e.message}',
          confidence: 0,
        );
      }
    } catch (e) {
      return AttendanceResponse(
        success: false,
        status: 'error',
        message: 'Lỗi không xác định: $e',
        confidence: 0,
      );
    }
  }
}

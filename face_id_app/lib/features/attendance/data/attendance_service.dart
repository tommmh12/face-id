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

  /// Submit face check-in or check-out
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
          'faceImageBase64': faceImageBase64,
          'checkType': checkType,
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
          message: 'Lỗi kết nối: ${e.message}',
          userData: null,
        );
      }
    } catch (e) {
      return AttendanceResponse(
        success: false,
        message: 'Lỗi không xác định: $e',
        userData: null,
      );
    }
  }
}

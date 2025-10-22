import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../models/dto/attendance_dtos.dart';
import '../models/dto/today_attendance_dto.dart';
import '../models/dto/manual_attendance_dtos.dart';
import '../config/api_config.dart';

/// Service for attendance management with Vietnam timezone (UTC+7)
/// Quản lý chấm công với múi giờ Việt Nam
class AttendanceApiService {
  static const _storage = FlutterSecureStorage();
  final String baseUrl = ApiConfig.baseUrl;

  /// Helper method to get authorization headers with JWT token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Helper method to handle HTTP requests with proper error handling
  Future<T> _handleRequest<T>(
    Future<http.Response> Function() request,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await request();
      final responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonData = json.decode(responseBody);
        return fromJson(jsonData);
      } else {
        // Handle error response
        try {
          final Map<String, dynamic> errorData = json.decode(responseBody);
          throw Exception(errorData['message'] ?? 'HTTP ${response.statusCode}');
        } catch (e) {
          throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
        }
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  /// Helper method to build query string from parameters
  String _buildQueryString(Map<String, dynamic> params) {
    if (params.isEmpty) return '';
    
    final queryParts = params.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}')
        .toList();
    
    return queryParts.isNotEmpty ? '?${queryParts.join('&')}' : '';
  }

  // ==================== ATTENDANCE HISTORY ====================

  /// Get attendance history with filters and pagination
  /// Lấy lịch sử chấm công với bộ filter và phân trang
  Future<AttendanceHistoryResponse> getAttendanceHistory(AttendanceHistoryRequest request) async {
    final queryString = _buildQueryString(request.toQueryParams());
    final url = '$baseUrl/api/attendance/history$queryString';
    final headers = await _getHeaders();

    return _handleRequest(
      () => http.get(Uri.parse(url), headers: headers),
      (json) => AttendanceHistoryResponse.fromJson(json),
    );
  }

  /// Get attendance history for a specific employee (Admin/HR only)
  /// Lấy lịch sử chấm công của một nhân viên cụ thể (chỉ Admin/HR)
  Future<AttendanceHistoryResponse> getEmployeeAttendanceHistory(
    int employeeId,
    AttendanceHistoryRequest request,
  ) async {
    final queryString = _buildQueryString(request.toQueryParams());
    final url = '$baseUrl/api/attendance/history/employee/$employeeId$queryString';
    final headers = await _getHeaders();

    return _handleRequest(
      () => http.get(Uri.parse(url), headers: headers),
      (json) => AttendanceHistoryResponse.fromJson(json),
    );
  }

  /// Get attendance history for a department (Admin/HR only)
  /// Lấy lịch sử chấm công theo phòng ban (chỉ Admin/HR)
  Future<AttendanceHistoryResponse> getDepartmentAttendanceHistory(
    int departmentId,
    AttendanceHistoryRequest request,
  ) async {
    final queryString = _buildQueryString(request.toQueryParams());
    final url = '$baseUrl/api/attendance/history/department/$departmentId$queryString';
    final headers = await _getHeaders();

    return _handleRequest(
      () => http.get(Uri.parse(url), headers: headers),
      (json) => AttendanceHistoryResponse.fromJson(json),
    );
  }

  // ==================== TODAY'S ATTENDANCE ====================

  /// Get my today's attendance
  /// Lấy thông tin chấm công hôm nay của tôi
  Future<TodayAttendanceResponse> getMyTodayAttendance() async {
    final url = '$baseUrl/api/attendance/today/me';
    final headers = await _getHeaders();

    return _handleRequest(
      () => http.get(Uri.parse(url), headers: headers),
      (json) => TodayAttendanceResponse.fromJson(json),
    );
  }

  /// Get today's attendance for a specific employee (Admin/HR only)
  /// Lấy thông tin chấm công hôm nay của một nhân viên (chỉ Admin/HR)
  Future<TodayAttendanceApiResponse> getEmployeeTodayAttendance(int employeeId) async {
    final url = '$baseUrl/api/attendance/today/employee/$employeeId';
    final headers = await _getHeaders();

    return _handleRequest(
      () => http.get(Uri.parse(url), headers: headers),
      (json) => TodayAttendanceApiResponse.fromJson(json),
    );
  }

  /// Get today's attendance for all employees in a department (Admin/HR only)
  /// Lấy thông tin chấm công hôm nay của toàn bộ phòng ban (chỉ Admin/HR)
  Future<Map<String, dynamic>> getDepartmentTodayAttendance(int departmentId) async {
    final url = '$baseUrl/api/attendance/today/department/$departmentId';
    final headers = await _getHeaders();

    return _handleRequest(
      () => http.get(Uri.parse(url), headers: headers),
      (json) {
        // Parse department today attendance response
        final data = (json['data'] as List<dynamic>?)
            ?.map((item) => DepartmentTodayAttendanceItem.fromJson(item))
            .toList() ?? [];

        return {
          'success': json['success'] ?? false,
          'message': json['message'] ?? '',
          'data': data,
          'departmentId': json['departmentId'],
          'totalEmployees': json['totalEmployees'] ?? 0,
          'checkedIn': json['checkedIn'] ?? 0,
          'completed': json['completed'] ?? 0,
          'timestamp': DateTime.parse(json['timestamp']),
        };
      },
    );
  }

  // ==================== ATTENDANCE STATISTICS ====================

  /// Get attendance statistics (Admin/HR only)
  /// Lấy thống kê chấm công (chỉ Admin/HR)
  Future<AttendanceStatsResponse> getAttendanceStatistics(AttendanceStatsRequest request) async {
    final queryString = _buildQueryString(request.toQueryParams());
    final url = '$baseUrl/api/attendance/statistics$queryString';
    final headers = await _getHeaders();

    return _handleRequest(
      () => http.get(Uri.parse(url), headers: headers),
      (json) => AttendanceStatsResponse.fromJson(json),
    );
  }

  /// Get attendance statistics for a specific employee (Admin/HR only)
  /// Lấy thống kê chấm công của một nhân viên (chỉ Admin/HR)
  Future<AttendanceStatsResponse> getEmployeeAttendanceStatistics(
    int employeeId,
    AttendanceStatsRequest request,
  ) async {
    final queryString = _buildQueryString(request.toQueryParams());
    final url = '$baseUrl/api/attendance/statistics/employee/$employeeId$queryString';
    final headers = await _getHeaders();

    return _handleRequest(
      () => http.get(Uri.parse(url), headers: headers),
      (json) => AttendanceStatsResponse.fromJson(json),
    );
  }

  /// Get attendance statistics for a department (Admin/HR only)
  /// Lấy thống kê chấm công theo phòng ban (chỉ Admin/HR)
  Future<AttendanceStatsResponse> getDepartmentAttendanceStatistics(
    int departmentId,
    AttendanceStatsRequest request,
  ) async {
    final queryString = _buildQueryString(request.toQueryParams());
    final url = '$baseUrl/api/attendance/statistics/department/$departmentId$queryString';
    final headers = await _getHeaders();

    return _handleRequest(
      () => http.get(Uri.parse(url), headers: headers),
      (json) => AttendanceStatsResponse.fromJson(json),
    );
  }

  // ==================== HEALTH CHECK ====================

  /// Health check for attendance service
  /// Kiểm tra tình trạng dịch vụ chấm công
  Future<Map<String, dynamic>> healthCheck() async {
    final url = '$baseUrl/api/attendance/health';
    final headers = await _getHeaders();

    return _handleRequest(
      () => http.get(Uri.parse(url), headers: headers),
      (json) => json,
    );
  }

  // ==================== UTILITY METHODS ====================

  /// Format duration to Vietnamese display string
  /// Định dạng thời lượng thành chuỗi hiển thị tiếng Việt
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}ph';
      } else {
        return '${hours}h';
      }
    } else {
      return '${minutes}ph';
    }
  }

  /// Format work hours to Vietnamese display
  /// Định dạng giờ làm việc thành chuỗi hiển thị tiếng Việt
  static String formatWorkHours(double? hours) {
    if (hours == null) return '0h';
    
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    
    if (h > 0) {
      if (m > 0) {
        return '${h}h ${m}ph';
      } else {
        return '${h}h';
      }
    } else {
      return '${m}ph';
    }
  }

  /// Get attendance rate display color
  /// Lấy màu hiển thị cho tỷ lệ chấm công
  static Color getAttendanceRateColor(double rate) {
    if (rate >= 95.0) {
      return const Color(0xFF4CAF50); // Excellent - Green
    } else if (rate >= 85.0) {
      return const Color(0xFF8BC34A); // Good - Light Green
    } else if (rate >= 75.0) {
      return const Color(0xFFFFEB3B); // Average - Yellow
    } else if (rate >= 60.0) {
      return const Color(0xFFFF9800); // Poor - Orange
    } else {
      return const Color(0xFFF44336); // Critical - Red
    }
  }

  /// Get attendance rate description in Vietnamese
  /// Lấy mô tả tỷ lệ chấm công bằng tiếng Việt
  static String getAttendanceRateDescription(double rate) {
    if (rate >= 95.0) {
      return 'Xuất sắc';
    } else if (rate >= 85.0) {
      return 'Tốt';
    } else if (rate >= 75.0) {
      return 'Trung bình';
    } else if (rate >= 60.0) {
      return 'Kém';
    } else {
      return 'Rất kém';
    }
  }

  // ==================== MANUAL BATCH ATTENDANCE ====================

  /// Process manual batch attendance (HR/Manager only)
  /// Xử lý chấm công thủ công hàng loạt (chỉ HR/Quản lý)
  Future<ManualBatchAttendanceResponse> processManualBatchAttendance(
    ManualBatchAttendanceRequest request,
  ) async {
    debugPrint('🚀 API Request: POST /attendance/manual-batch');
    debugPrint('   Date: ${request.date.toIso8601String()}');
    debugPrint('   Records: ${request.records.length}');
    debugPrint('   Reason: ${request.reason}');

    return await _handleRequest<ManualBatchAttendanceResponse>(
      () async {
        final uri = Uri.parse('$baseUrl/attendance/manual-batch');
        return await http.post(
          uri,
          headers: await _getHeaders(),
          body: json.encode(request.toJson()),
        );
      },
      (json) => ManualBatchAttendanceResponse.fromJson(json),
    );
  }

  /// Preview manual batch attendance (no execution, just validation)
  /// Xem trước chấm công thủ công hàng loạt (không thực thi, chỉ kiểm tra)
  Future<Map<String, dynamic>> previewManualBatchAttendance(
    ManualBatchAttendanceRequest request,
  ) async {
    debugPrint('👁️ API Request: POST /attendance/manual-batch/preview');
    debugPrint('   Date: ${request.date.toIso8601String()}');
    debugPrint('   Records: ${request.records.length}');

    return await _handleRequest<Map<String, dynamic>>(
      () async {
        final uri = Uri.parse('$baseUrl/attendance/manual-batch/preview');
        return await http.post(
          uri,
          headers: await _getHeaders(),
          body: json.encode(request.toJson()),
        );
      },
      (json) => json,
    );
  }

  /// Get today's attendance for department (needed for manual attendance merge logic)
  /// Lấy chấm công hôm nay của phòng ban (cần cho logic merge manual attendance)
  Future<List<TodayAttendanceApiResponse>> getTodayAttendanceForDepartment(
    int departmentId, {
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final dateParam = targetDate.toIso8601String().split('T')[0]; // YYYY-MM-DD format
    
    debugPrint('🚀 API Request: GET /attendance/today/department/$departmentId');
    debugPrint('   Date: $dateParam');

    return await _handleRequest<List<TodayAttendanceApiResponse>>(
      () async {
        final uri = Uri.parse('$baseUrl/attendance/today/department/$departmentId')
            .replace(queryParameters: {'date': dateParam});
        return await http.get(uri, headers: await _getHeaders());
      },
      (json) {
        // Handle both direct array and wrapped response
        List<dynamic> dataList = [];
        
        if (json.containsKey('data') && json['data'] is List) {
          dataList = json['data'] as List<dynamic>;
        } else {
          // Fallback: if json is directly a list, it's not expected but handle it
          debugPrint('Warning: Unexpected response format for department attendance: $json');
          dataList = []; // Return empty list to prevent crashes
        }
        
        return dataList
            .map((item) => TodayAttendanceApiResponse.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }
}


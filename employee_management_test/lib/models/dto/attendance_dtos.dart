import 'package:flutter/material.dart';

/// Attendance DTOs for Vietnam timezone (UTC+7)
/// Các DTO cho quản lý chấm công với múi giờ Việt Nam

// ==================== REQUEST DTOs ====================

/// Request DTO for attendance history with filters and pagination
class AttendanceHistoryRequest {
  final int? employeeId;
  final int? departmentId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? status; // "present", "late", "absent", "early_leave"
  final int? page;
  final int? pageSize;
  final String? searchTerm;
  final String? sortBy; // "date", "employee", "check_in", "check_out"
  final String? sortOrder; // "asc", "desc"

  const AttendanceHistoryRequest({
    this.employeeId,
    this.departmentId,
    this.fromDate,
    this.toDate,
    this.status,
    this.page = 1,
    this.pageSize = 20,
    this.searchTerm,
    this.sortBy = 'date',
    this.sortOrder = 'desc',
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (employeeId != null) params['employeeId'] = employeeId.toString();
    if (departmentId != null) params['departmentId'] = departmentId.toString();
    if (fromDate != null) params['fromDate'] = fromDate!.toIso8601String();
    if (toDate != null) params['toDate'] = toDate!.toIso8601String();
    if (status != null) params['status'] = status;
    if (page != null) params['page'] = page.toString();
    if (pageSize != null) params['pageSize'] = pageSize.toString();
    if (searchTerm != null && searchTerm!.isNotEmpty) params['searchTerm'] = searchTerm;
    if (sortBy != null) params['sortBy'] = sortBy;
    if (sortOrder != null) params['sortOrder'] = sortOrder;

    return params;
  }
}

/// Request DTO for attendance statistics
class AttendanceStatsRequest {
  final int? employeeId;
  final int? departmentId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? period; // "daily", "weekly", "monthly"

  const AttendanceStatsRequest({
    this.employeeId,
    this.departmentId,
    this.fromDate,
    this.toDate,
    this.period = 'monthly',
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (employeeId != null) params['employeeId'] = employeeId.toString();
    if (departmentId != null) params['departmentId'] = departmentId.toString();
    if (fromDate != null) params['fromDate'] = fromDate!.toIso8601String();
    if (toDate != null) params['toDate'] = toDate!.toIso8601String();
    if (period != null) params['period'] = period;

    return params;
  }
}

// ==================== RESPONSE DTOs ====================

/// Base response DTO for attendance operations
class AttendanceBaseResponse {
  final bool success;
  final String message;
  final DateTime timestamp;

  const AttendanceBaseResponse({
    required this.success,
    required this.message,
    required this.timestamp,
  });

  factory AttendanceBaseResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceBaseResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

/// Individual attendance record DTO
class AttendanceRecordResponse {
  final int id;
  final int employeeId;
  final String employeeCode;
  final String employeeName;
  final int? departmentId;
  final String? departmentName;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String status; // "present", "late", "absent", "early_leave", "working"
  final double? workHours;
  final double? lateMinutes;
  final double? earlyLeaveMinutes;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AttendanceRecordResponse({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    this.departmentId,
    this.departmentName,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.workHours,
    this.lateMinutes,
    this.earlyLeaveMinutes,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory AttendanceRecordResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordResponse(
      id: json['id'],
      employeeId: json['employeeId'],
      employeeCode: json['employeeCode'] ?? '',
      employeeName: json['employeeName'] ?? '',
      departmentId: json['departmentId'],
      departmentName: json['departmentName'],
      date: DateTime.parse(json['date']),
      checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      status: json['status'] ?? 'unknown',
      workHours: json['workHours']?.toDouble(),
      lateMinutes: json['lateMinutes']?.toDouble(),
      earlyLeaveMinutes: json['earlyLeaveMinutes']?.toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  /// Get status display text in Vietnamese
  String getStatusDisplayText() {
    switch (status.toLowerCase()) {
      case 'present':
        return 'Có mặt';
      case 'late':
        return 'Đi muộn';
      case 'absent':
        return 'Vắng mặt';
      case 'early_leave':
        return 'Về sớm';
      case 'working':
        return 'Đang làm việc';
      case 'completed':
        return 'Hoàn thành';
      default:
        return 'Không xác định';
    }
  }

  /// Get status color for UI display
  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'present':
      case 'completed':
        return const Color(0xFF4CAF50); // Green
      case 'late':
        return const Color(0xFFFF9800); // Orange
      case 'absent':
        return const Color(0xFFF44336); // Red
      case 'early_leave':
        return const Color(0xFFFF5722); // Deep Orange
      case 'working':
        return const Color(0xFF2196F3); // Blue
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}

/// Response DTO for attendance history with pagination
class AttendanceHistoryResponse extends AttendanceBaseResponse {
  final List<AttendanceRecordResponse> records;
  final int totalRecords;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  const AttendanceHistoryResponse({
    required super.success,
    required super.message,
    required super.timestamp,
    required this.records,
    required this.totalRecords,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  factory AttendanceHistoryResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      records: (json['data'] as List<dynamic>?)
          ?.map((record) => AttendanceRecordResponse.fromJson(record))
          .toList() ?? [],
      totalRecords: json['totalRecords'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['currentPage'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
    );
  }
}

/// Response DTO for today's attendance
class TodayAttendanceResponse extends AttendanceBaseResponse {
  final AttendanceRecordResponse? todayRecord;
  final bool hasCheckedIn;
  final bool hasCheckedOut;
  final String currentStatus;
  final Duration? workDuration;

  const TodayAttendanceResponse({
    required super.success,
    required super.message,
    required super.timestamp,
    this.todayRecord,
    required this.hasCheckedIn,
    required this.hasCheckedOut,
    required this.currentStatus,
    this.workDuration,
  });

  factory TodayAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return TodayAttendanceResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      todayRecord: json['data'] != null 
          ? AttendanceRecordResponse.fromJson(json['data'])
          : null,
      hasCheckedIn: json['hasCheckedIn'] ?? false,
      hasCheckedOut: json['hasCheckedOut'] ?? false,
      currentStatus: json['currentStatus'] ?? 'not_checked_in',
      workDuration: json['workDurationMinutes'] != null 
          ? Duration(minutes: json['workDurationMinutes'])
          : null,
    );
  }
}

/// Individual attendance statistics DTO
class AttendanceStatsData {
  final int totalDays;
  final int presentDays;
  final int lateDays;
  final int absentDays;
  final int earlyLeaveDays;
  final double attendanceRate;
  final double averageWorkHours;
  final double totalLateMinutes;
  final double totalEarlyLeaveMinutes;

  const AttendanceStatsData({
    required this.totalDays,
    required this.presentDays,
    required this.lateDays,
    required this.absentDays,
    required this.earlyLeaveDays,
    required this.attendanceRate,
    required this.averageWorkHours,
    required this.totalLateMinutes,
    required this.totalEarlyLeaveMinutes,
  });

  factory AttendanceStatsData.fromJson(Map<String, dynamic> json) {
    return AttendanceStatsData(
      totalDays: json['totalDays'] ?? 0,
      presentDays: json['presentDays'] ?? 0,
      lateDays: json['lateDays'] ?? 0,
      absentDays: json['absentDays'] ?? 0,
      earlyLeaveDays: json['earlyLeaveDays'] ?? 0,
      attendanceRate: (json['attendanceRate'] ?? 0.0).toDouble(),
      averageWorkHours: (json['averageWorkHours'] ?? 0.0).toDouble(),
      totalLateMinutes: (json['totalLateMinutes'] ?? 0.0).toDouble(),
      totalEarlyLeaveMinutes: (json['totalEarlyLeaveMinutes'] ?? 0.0).toDouble(),
    );
  }
}

/// Response DTO for attendance statistics
class AttendanceStatsResponse extends AttendanceBaseResponse {
  final AttendanceStatsData? stats;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String period;

  const AttendanceStatsResponse({
    required super.success,
    required super.message,
    required super.timestamp,
    this.stats,
    this.fromDate,
    this.toDate,
    required this.period,
  });

  factory AttendanceStatsResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceStatsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      stats: json['data'] != null 
          ? AttendanceStatsData.fromJson(json['data'])
          : null,
      fromDate: json['fromDate'] != null ? DateTime.parse(json['fromDate']) : null,
      toDate: json['toDate'] != null ? DateTime.parse(json['toDate']) : null,
      period: json['period'] ?? 'monthly',
    );
  }
}

/// Response DTO for department today attendance
class DepartmentTodayAttendanceItem {
  final int employeeId;
  final String employeeCode;
  final String employeeName;
  final String status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double? workHours;

  const DepartmentTodayAttendanceItem({
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.workHours,
  });

  factory DepartmentTodayAttendanceItem.fromJson(Map<String, dynamic> json) {
    return DepartmentTodayAttendanceItem(
      employeeId: json['employeeId'],
      employeeCode: json['employeeCode'] ?? '',
      employeeName: json['employeeName'] ?? '',
      status: json['status'] ?? 'not_checked_in',
      checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      workHours: json['workHours']?.toDouble(),
    );
  }
}


import 'package:flutter/material.dart';

/// Manual Batch Attendance DTOs for HR/Manager operations
/// DTOs cho chấm công thủ công hàng loạt (HR/Quản lý)

// ==================== REQUEST DTOs ====================

/// Single manual attendance record for batch processing
class ManualAttendanceRecord {
  final int employeeId;
  final String status; // "PRESENT", "ABSENT", "LATE", "HALF_DAY", "ON_LEAVE"
  final TimeOfDay? checkInTime; // Custom check-in time (for LATE status)
  final TimeOfDay? checkOutTime; // Custom check-out time (for HALF_DAY)
  final String? notes; // Notes/reason for manual entry
  final bool overrideExisting; // Override automatic attendance if exists

  const ManualAttendanceRecord({
    required this.employeeId,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.notes,
    this.overrideExisting = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'status': status,
      'checkInTime': checkInTime?.format24Hour(),
      'checkOutTime': checkOutTime?.format24Hour(),
      'notes': notes,
      'overrideExisting': overrideExisting,
    };
  }

  factory ManualAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return ManualAttendanceRecord(
      employeeId: json['employeeId'] as int,
      status: json['status'] as String,
      checkInTime: json['checkInTime'] != null 
          ? TimeOfDay.fromDateTime(DateTime.parse('1970-01-01 ${json['checkInTime']}'))
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? TimeOfDay.fromDateTime(DateTime.parse('1970-01-01 ${json['checkOutTime']}'))
          : null,
      notes: json['notes'] as String?,
      overrideExisting: json['overrideExisting'] as bool? ?? false,
    );
  }
}

/// Request for manual batch attendance processing
class ManualBatchAttendanceRequest {
  final DateTime date;
  final List<ManualAttendanceRecord> records;
  final String reason; // Reason for manual batch entry

  const ManualBatchAttendanceRequest({
    required this.date,
    required this.records,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'records': records.map((r) => r.toJson()).toList(),
      'reason': reason,
    };
  }

  factory ManualBatchAttendanceRequest.fromJson(Map<String, dynamic> json) {
    return ManualBatchAttendanceRequest(
      date: DateTime.parse(json['date'] as String),
      records: (json['records'] as List)
          .map((r) => ManualAttendanceRecord.fromJson(r as Map<String, dynamic>))
          .toList(),
      reason: json['reason'] as String,
    );
  }
}

// ==================== RESPONSE DTOs ====================

/// Response for manual batch attendance processing
class ManualBatchAttendanceResponse {
  final bool success;
  final String message;
  final DateTime processedDate;
  final int totalRecords;
  final int successfullyProcessed;
  final int skippedRecords;
  final int failedRecords;
  final int updatedRecords;
  final List<ManualAttendanceResult> results;
  final List<String> errors;
  final String processedBy;
  final DateTime processedAt;

  const ManualBatchAttendanceResponse({
    required this.success,
    required this.message,
    required this.processedDate,
    required this.totalRecords,
    required this.successfullyProcessed,
    required this.skippedRecords,
    required this.failedRecords,
    required this.updatedRecords,
    required this.results,
    required this.errors,
    required this.processedBy,
    required this.processedAt,
  });

  factory ManualBatchAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return ManualBatchAttendanceResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      processedDate: DateTime.parse(json['processedDate'] as String),
      totalRecords: json['totalRecords'] as int,
      successfullyProcessed: json['successfullyProcessed'] as int,
      skippedRecords: json['skippedRecords'] as int,
      failedRecords: json['failedRecords'] as int,
      updatedRecords: json['updatedRecords'] as int,
      results: (json['results'] as List)
          .map((r) => ManualAttendanceResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      errors: (json['errors'] as List).cast<String>(),
      processedBy: json['processedBy'] as String,
      processedAt: DateTime.parse(json['processedAt'] as String),
    );
  }

  /// Get summary message for UI display
  String get summaryMessage {
    if (totalRecords == 0) return 'Không có bản ghi nào được xử lý';
    
    final parts = <String>[];
    if (successfullyProcessed > 0) parts.add('$successfullyProcessed tạo mới');
    if (updatedRecords > 0) parts.add('$updatedRecords cập nhật');
    if (skippedRecords > 0) parts.add('$skippedRecords bỏ qua');
    if (failedRecords > 0) parts.add('$failedRecords lỗi');
    
    return 'Hoàn tất: ${parts.join(', ')}';
  }

  /// Check if has any issues
  bool get hasIssues => failedRecords > 0 || errors.isNotEmpty;

  /// Get success rate percentage
  double get successRate {
    if (totalRecords == 0) return 0.0;
    return ((successfullyProcessed + updatedRecords) / totalRecords) * 100;
  }
}

/// Result for individual manual attendance record
class ManualAttendanceResult {
  final int employeeId;
  final String employeeCode;
  final String employeeName;
  final String status; // "PRESENT", "ABSENT", etc.
  final String result; // "SUCCESS", "SKIPPED", "UPDATED", "FAILED"
  final String? message;
  final DateTime? checkInCreated;
  final DateTime? checkOutCreated;

  const ManualAttendanceResult({
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.status,
    required this.result,
    this.message,
    this.checkInCreated,
    this.checkOutCreated,
  });

  factory ManualAttendanceResult.fromJson(Map<String, dynamic> json) {
    return ManualAttendanceResult(
      employeeId: json['employeeId'] as int,
      employeeCode: json['employeeCode'] as String,
      employeeName: json['employeeName'] as String,
      status: json['status'] as String,
      result: json['result'] as String,
      message: json['message'] as String?,
      checkInCreated: json['checkInCreated'] != null 
          ? DateTime.parse(json['checkInCreated'] as String)
          : null,
      checkOutCreated: json['checkOutCreated'] != null
          ? DateTime.parse(json['checkOutCreated'] as String)
          : null,
    );
  }

  /// Get result color for UI display
  Color get resultColor {
    switch (result) {
      case 'SUCCESS':
        return Colors.green;
      case 'UPDATED':
        return Colors.blue;
      case 'SKIPPED':
        return Colors.orange;
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get result icon for UI display
  IconData get resultIcon {
    switch (result) {
      case 'SUCCESS':
        return Icons.check_circle;
      case 'UPDATED':
        return Icons.update;
      case 'SKIPPED':
        return Icons.skip_next;
      case 'FAILED':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  /// Get Vietnamese result text
  String get resultDisplayText {
    switch (result) {
      case 'SUCCESS':
        return 'Thành công';
      case 'UPDATED':
        return 'Đã cập nhật';
      case 'SKIPPED':
        return 'Bỏ qua';
      case 'FAILED':
        return 'Lỗi';
      default:
        return 'Không xác định';
    }
  }
}

// ==================== UI MODELS ====================

/// Model for RecyclerView items in Manual Attendance Screen
class EmployeeAttendanceModel {
  final int employeeId;
  final String employeeCode;
  final String employeeName;
  final String departmentName;
  final bool isEditable; // false if already checked-in automatically
  final String originalStatus; // "NOT_CHECKED", "PRESENT", "LATE", etc.
  
  // Editable fields (only when isEditable = true)
  String? selectedStatus; // User selected status
  TimeOfDay? customCheckInTime;
  TimeOfDay? customCheckOutTime;
  String? notes;
  bool overrideExisting;

  // Original attendance info (if exists)
  final DateTime? originalCheckIn;
  final DateTime? originalCheckOut;
  final String? originalCheckInDisplay;
  final String? originalCheckOutDisplay;
  final String? automaticAttendanceInfo; // Display info for auto attendance

  EmployeeAttendanceModel({
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.departmentName,
    required this.isEditable,
    required this.originalStatus,
    this.selectedStatus,
    this.customCheckInTime,
    this.customCheckOutTime,
    this.notes,
    this.overrideExisting = false,
    this.originalCheckIn,
    this.originalCheckOut,
    this.originalCheckInDisplay,
    this.originalCheckOutDisplay,
    this.automaticAttendanceInfo,
  });

  /// Check if this item has been modified by user
  bool get isDirty {
    if (!isEditable) return false;
    return selectedStatus != null && selectedStatus != originalStatus;
  }

  /// Get the current effective status
  String get effectiveStatus => selectedStatus ?? originalStatus;

  /// Check if should show custom time picker (for LATE status)
  bool get shouldShowTimePicker => effectiveStatus == 'LATE';

  /// Convert to ManualAttendanceRecord for API call
  ManualAttendanceRecord? toManualAttendanceRecord() {
    if (!isDirty) return null; // Don't send unchanged items
    
    return ManualAttendanceRecord(
      employeeId: employeeId,
      status: effectiveStatus,
      checkInTime: customCheckInTime,
      checkOutTime: customCheckOutTime,
      notes: notes,
      overrideExisting: overrideExisting,
    );
  }

  /// Create copy with updated fields
  EmployeeAttendanceModel copyWith({
    String? selectedStatus,
    TimeOfDay? customCheckInTime,
    TimeOfDay? customCheckOutTime,
    String? notes,
    bool? overrideExisting,
  }) {
    return EmployeeAttendanceModel(
      employeeId: employeeId,
      employeeCode: employeeCode,
      employeeName: employeeName,
      departmentName: departmentName,
      isEditable: isEditable,
      originalStatus: originalStatus,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      customCheckInTime: customCheckInTime ?? this.customCheckInTime,
      customCheckOutTime: customCheckOutTime ?? this.customCheckOutTime,
      notes: notes ?? this.notes,
      overrideExisting: overrideExisting ?? this.overrideExisting,
      originalCheckIn: originalCheckIn,
      originalCheckOut: originalCheckOut,
      originalCheckInDisplay: originalCheckInDisplay,
      originalCheckOutDisplay: originalCheckOutDisplay,
      automaticAttendanceInfo: automaticAttendanceInfo,
    );
  }

  @override
  String toString() {
    return 'EmployeeAttendanceModel(id: $employeeId, name: $employeeName, '
           'editable: $isEditable, original: $originalStatus, '
           'selected: $selectedStatus, dirty: $isDirty)';
  }
}

// ==================== ATTENDANCE STATUS CONSTANTS ====================

/// Available attendance statuses for manual entry
class AttendanceStatus {
  static const String present = 'PRESENT';
  static const String absent = 'ABSENT';
  static const String late = 'LATE';
  static const String halfDay = 'HALF_DAY';
  static const String onLeave = 'ON_LEAVE';
  static const String notChecked = 'NOT_CHECKED';

  /// Get all available statuses for dropdown
  static const List<String> allStatuses = [
    present,
    late,
    halfDay,
    absent,
    onLeave,
  ];

  /// Get Vietnamese display text for status
  static String getDisplayText(String status) {
    switch (status) {
      case present:
        return 'Có mặt đầy đủ';
      case absent:
        return 'Vắng mặt';
      case late:
        return 'Đi trễ';
      case halfDay:
        return 'Làm nửa ngày';
      case onLeave:
        return 'Nghỉ phép';
      case notChecked:
        return 'Chưa chấm công';
      default:
        return status;
    }
  }

  /// Get status color for UI
  static Color getStatusColor(String status) {
    switch (status) {
      case present:
        return Colors.green;
      case absent:
        return Colors.red;
      case late:
        return Colors.orange;
      case halfDay:
        return Colors.blue;
      case onLeave:
        return Colors.purple;
      case notChecked:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// Get status icon
  static IconData getStatusIcon(String status) {
    switch (status) {
      case present:
        return Icons.check_circle;
      case absent:
        return Icons.cancel;
      case late:
        return Icons.access_time;
      case halfDay:
        return Icons.schedule;
      case onLeave:
        return Icons.flight_takeoff;
      case notChecked:
        return Icons.help_outline;
      default:
        return Icons.help_outline;
    }
  }
}

// ==================== EXTENSIONS ====================

/// Extension to format TimeOfDay to 24-hour format
extension TimeOfDayExtension on TimeOfDay {
  String format24Hour() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Convert to TimeSpan format for API (HH:mm:ss)
  String toTimeSpan() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
  }
}
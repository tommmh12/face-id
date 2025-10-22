import 'package:flutter/material.dart';

/// Today Attendance DTOs cho API /api/Attendance/today/employee/{employeeId}
class TodayAttendanceApiResponse {
  final bool success;
  final String message;
  final int employeeId;
  final String employeeCode;
  final String employeeName;
  final DateTime date;
  final String dateDisplay;
  final CheckInOutRecord? checkIn;
  final CheckInOutRecord? checkOut;
  final String status;
  final String statusDisplay;
  final String? workingHours;
  final String? workingHoursDisplay;
  final DateTime timestamp;

  const TodayAttendanceApiResponse({
    required this.success,
    required this.message,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.date,
    required this.dateDisplay,
    this.checkIn,
    this.checkOut,
    required this.status,
    required this.statusDisplay,
    this.workingHours,
    this.workingHoursDisplay,
    required this.timestamp,
  });

  factory TodayAttendanceApiResponse.fromJson(Map<String, dynamic> json) {
    return TodayAttendanceApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      employeeId: json['employeeId'] ?? 0,
      employeeCode: json['employeeCode'] ?? '',
      employeeName: json['employeeName'] ?? '',
      date: DateTime.parse(json['date']),
      dateDisplay: json['dateDisplay'] ?? '',
      checkIn: json['checkIn'] != null 
          ? CheckInOutRecord.fromJson(json['checkIn'])
          : null,
      checkOut: json['checkOut'] != null 
          ? CheckInOutRecord.fromJson(json['checkOut'])
          : null,
      status: json['status'] ?? '',
      statusDisplay: json['statusDisplay'] ?? '',
      workingHours: json['workingHours'],
      workingHoursDisplay: json['workingHoursDisplay'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  /// Get status color for UI display
  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF4CAF50); // Green
      case 'working':
        return const Color(0xFF2196F3); // Blue
      case 'not_checked_in':
        return const Color(0xFF9E9E9E); // Grey
      case 'checked_in':
        return const Color(0xFFFF9800); // Orange
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Get working hours as Duration if available
  Duration? get workingDuration {
    if (workingHours == null) return null;
    
    try {
      // Parse format like "02:09:54.4191053"
      final parts = workingHours!.split(':');
      if (parts.length >= 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final secondsParts = parts[2].split('.');
        final seconds = int.tryParse(secondsParts[0]) ?? 0;
        
        return Duration(
          hours: hours,
          minutes: minutes,
          seconds: seconds,
        );
      }
    } catch (e) {
      // If parsing fails, return null
    }
    
    return null;
  }

  /// Check if employee has checked in today
  bool get hasCheckedIn => checkIn != null;

  /// Check if employee has checked out today  
  bool get hasCheckedOut => checkOut != null;
}

/// Check-in/Check-out record
class CheckInOutRecord {
  final int id;
  final int employeeId;
  final String employeeCode;
  final String employeeName;
  final String departmentName;
  final String checkType; // "IN" or "OUT"
  final DateTime checkTime;
  final double similarityScore;
  final String? checkImageUrl;
  final String checkTimeDisplay;
  final String checkTypeDisplay;

  const CheckInOutRecord({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.departmentName,
    required this.checkType,
    required this.checkTime,
    required this.similarityScore,
    this.checkImageUrl,
    required this.checkTimeDisplay,
    required this.checkTypeDisplay,
  });

  factory CheckInOutRecord.fromJson(Map<String, dynamic> json) {
    return CheckInOutRecord(
      id: json['id'] ?? 0,
      employeeId: json['employeeId'] ?? 0,
      employeeCode: json['employeeCode'] ?? '',
      employeeName: json['employeeName'] ?? '',
      departmentName: json['departmentName'] ?? '',
      checkType: json['checkType'] ?? '',
      checkTime: DateTime.parse(json['checkTime']),
      similarityScore: (json['similarityScore'] ?? 0.0).toDouble(),
      checkImageUrl: json['checkImageUrl'],
      checkTimeDisplay: json['checkTimeDisplay'] ?? '',
      checkTypeDisplay: json['checkTypeDisplay'] ?? '',
    );
  }

  /// Get icon for check type
  IconData get icon {
    switch (checkType.toUpperCase()) {
      case 'IN':
        return Icons.login;
      case 'OUT':
        return Icons.logout;
      default:
        return Icons.access_time;
    }
  }

  /// Get color for check type
  Color get color {
    switch (checkType.toUpperCase()) {
      case 'IN':
        return const Color(0xFF4CAF50); // Green
      case 'OUT':
        return const Color(0xFFFF5722); // Deep Orange
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}
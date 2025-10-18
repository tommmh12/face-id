// ==================== EMPLOYEE DTOs ====================

class CreateEmployeeRequest {
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final int departmentId;
  final String? position;
  final DateTime? dateOfBirth;

  CreateEmployeeRequest({
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.departmentId,
    this.position,
    this.dateOfBirth,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'departmentId': departmentId,
      'position': position,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
    };
  }
}

class CreateEmployeeResponse {
  final bool success;
  final String message;
  final String? employeeCode;
  final int? employeeId;

  CreateEmployeeResponse({
    required this.success,
    required this.message,
    this.employeeCode,
    this.employeeId,
  });

  factory CreateEmployeeResponse.fromJson(Map<String, dynamic> json) {
    return CreateEmployeeResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      employeeCode: json['employeeCode']?.toString(),
      employeeId: json['employeeId'],
    );
  }
}

// ==================== FACE RECOGNITION DTOs ====================

class RegisterEmployeeFaceRequest {
  final int employeeId;
  final String imageBase64;

  RegisterEmployeeFaceRequest({
    required this.employeeId,
    required this.imageBase64,
  });

  Map<String, dynamic> toJson() {
    // ✅ Validation logging
    if (imageBase64.isEmpty) {
      throw ArgumentError('❌ imageBase64 cannot be empty');
    }
    if (imageBase64.length < 100) {
      throw ArgumentError('❌ imageBase64 too short (${imageBase64.length} chars)');
    }
    
    return {
      'employeeId': employeeId,
      'imageBase64': imageBase64, // Pure base64, NO prefix
    };
  }
}

class RegisterEmployeeFaceResponse {
  final bool success;
  final String message;
  final String? faceId;
  final String? s3ImageUrl;

  RegisterEmployeeFaceResponse({
    required this.success,
    required this.message,
    this.faceId,
    this.s3ImageUrl,
  });

  factory RegisterEmployeeFaceResponse.fromJson(Map<String, dynamic> json) {
    return RegisterEmployeeFaceResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      faceId: json['faceId']?.toString(),
      s3ImageUrl: json['s3ImageUrl']?.toString(),
    );
  }
}

class VerifyFaceRequest {
  final String imageBase64;

  VerifyFaceRequest({
    required this.imageBase64,
  });

  Map<String, dynamic> toJson() {
    // ✅ Validation logging
    if (imageBase64.isEmpty) {
      throw ArgumentError('❌ imageBase64 cannot be empty');
    }
    if (imageBase64.length < 100) {
      throw ArgumentError('❌ imageBase64 too short (${imageBase64.length} chars)');
    }
    
    return {
      'imageBase64': imageBase64, // Pure base64, NO prefix
    };
  }
}

class VerifyEmployeeFaceResponse {
  final bool success;
  final String status;
  final String message;
  final double confidence;
  final EmployeeInfo? matchedEmployee;
  final AttendanceInfo? attendanceInfo;

  VerifyEmployeeFaceResponse({
    required this.success,
    required this.status,
    required this.message,
    required this.confidence,
    this.matchedEmployee,
    this.attendanceInfo,
  });

  factory VerifyEmployeeFaceResponse.fromJson(Map<String, dynamic> json) {
    return VerifyEmployeeFaceResponse(
      success: json['success'] ?? false,
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      matchedEmployee: json['matchedEmployee'] != null
          ? EmployeeInfo.fromJson(json['matchedEmployee'])
          : null,
      attendanceInfo: json['attendanceInfo'] != null
          ? AttendanceInfo.fromJson(json['attendanceInfo'])
          : null,
    );
  }
}

class EmployeeInfo {
  final int employeeId;
  final String employeeCode;
  final String fullName;
  final String? position;
  final String? department;

  EmployeeInfo({
    required this.employeeId,
    required this.employeeCode,
    required this.fullName,
    this.position,
    this.department,
  });

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeInfo(
      employeeId: json['employeeId'] ?? 0,
      employeeCode: json['employeeCode']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      position: json['position']?.toString(),
      department: json['department']?.toString(),
    );
  }
}

class AttendanceInfo {
  final int attendanceId;
  final String checkType;
  final DateTime checkTime;
  final String? s3ImageUrl;

  AttendanceInfo({
    required this.attendanceId,
    required this.checkType,
    required this.checkTime,
    this.s3ImageUrl,
  });

  factory AttendanceInfo.fromJson(Map<String, dynamic> json) {
    return AttendanceInfo(
      attendanceId: json['attendanceId'] ?? 0,
      checkType: json['checkType']?.toString() ?? '',
      checkTime: json['checkTime'] != null
          ? DateTime.tryParse(json['checkTime']) ?? DateTime.now()
          : DateTime.now(),
      s3ImageUrl: json['s3ImageUrl']?.toString(),
    );
  }
}
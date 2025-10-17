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
      success: json['success'],
      message: json['message'],
      employeeCode: json['employeeCode'],
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
    return {
      'employeeId': employeeId,
      'imageBase64': imageBase64,
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
      success: json['success'],
      message: json['message'],
      faceId: json['faceId'],
      s3ImageUrl: json['s3ImageUrl'],
    );
  }
}

class VerifyFaceRequest {
  final String imageBase64;

  VerifyFaceRequest({
    required this.imageBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      'imageBase64': imageBase64,
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
      success: json['success'],
      status: json['status'],
      message: json['message'],
      confidence: json['confidence']?.toDouble() ?? 0.0,
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
      employeeId: json['employeeId'],
      employeeCode: json['employeeCode'],
      fullName: json['fullName'],
      position: json['position'],
      department: json['department'],
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
      attendanceId: json['attendanceId'],
      checkType: json['checkType'],
      checkTime: DateTime.parse(json['checkTime']),
      s3ImageUrl: json['s3ImageUrl'],
    );
  }
}
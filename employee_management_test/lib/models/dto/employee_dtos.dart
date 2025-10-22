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

// ==================== NEW EMPLOYEE CRUD DTOs ====================

/// UPDATE EMPLOYEE
class UpdateEmployeeRequest {
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final int? departmentId;
  final String? position;
  final DateTime? dateOfBirth;
  final bool? isActive;
  String? updatedBy; // Set by controller from JWT claims

  UpdateEmployeeRequest({
    this.fullName,
    this.email,
    this.phoneNumber,
    this.departmentId,
    this.position,
    this.dateOfBirth,
    this.isActive,
    this.updatedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'departmentId': departmentId,
      'position': position,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'isActive': isActive,
      'updatedBy': updatedBy,
    };
  }
}

class UpdateEmployeeResponse {
  final bool success;
  final String message;
  final int? employeeId;
  final String? employeeCode;
  final String? updatedAt; // Vietnam timezone
  final String? updatedBy;
  final Map<String, dynamic>? changes;

  UpdateEmployeeResponse({
    required this.success,
    required this.message,
    this.employeeId,
    this.employeeCode,
    this.updatedAt,
    this.updatedBy,
    this.changes,
  });

  factory UpdateEmployeeResponse.fromJson(Map<String, dynamic> json) {
    return UpdateEmployeeResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      employeeId: json['employeeId'],
      employeeCode: json['employeeCode'],
      updatedAt: json['updatedAt'],
      updatedBy: json['updatedBy'],
      changes: json['changes'],
    );
  }
}

/// DELETE EMPLOYEE
class DeleteEmployeeResponse {
  final bool success;
  final String message;
  final int? employeeId;
  final String? employeeCode;
  final String? deletedAt; // Vietnam timezone
  final String? deletedBy;
  final String? reason;

  DeleteEmployeeResponse({
    required this.success,
    required this.message,
    this.employeeId,
    this.employeeCode,
    this.deletedAt,
    this.deletedBy,
    this.reason,
  });

  factory DeleteEmployeeResponse.fromJson(Map<String, dynamic> json) {
    return DeleteEmployeeResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      employeeId: json['employeeId'],
      employeeCode: json['employeeCode'],
      deletedAt: json['deletedAt'],
      deletedBy: json['deletedBy'],
      reason: json['reason'],
    );
  }
}

/// RESTORE EMPLOYEE
class RestoreEmployeeResponse {
  final bool success;
  final String message;
  final int? employeeId;
  final String? employeeCode;
  final String? restoredAt; // Vietnam timezone
  final String? restoredBy;
  final String? reason;

  RestoreEmployeeResponse({
    required this.success,
    required this.message,
    this.employeeId,
    this.employeeCode,
    this.restoredAt,
    this.restoredBy,
    this.reason,
  });

  factory RestoreEmployeeResponse.fromJson(Map<String, dynamic> json) {
    return RestoreEmployeeResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      employeeId: json['employeeId'],
      employeeCode: json['employeeCode'],
      restoredAt: json['restoredAt'],
      restoredBy: json['restoredBy'],
      reason: json['reason'],
    );
  }
}

// ==================== ROLE & STATUS MANAGEMENT ====================

/// CHANGE ROLE
class ChangeRoleRequest {
  final int newRoleId;
  final String? reason;
  String? updatedBy; // Set by controller from JWT claims

  ChangeRoleRequest({
    required this.newRoleId,
    this.reason,
    this.updatedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'newRoleId': newRoleId,
      'reason': reason,
      'updatedBy': updatedBy,
    };
  }
}

class ChangeRoleResponse {
  final bool success;
  final String message;
  final int? employeeId;
  final String? employeeCode;
  final int? oldRoleId;
  final String? oldRoleName;
  final int? newRoleId;
  final String? newRoleName;
  final String? changedAt; // Vietnam timezone
  final String? changedBy;
  final String? reason;

  ChangeRoleResponse({
    required this.success,
    required this.message,
    this.employeeId,
    this.employeeCode,
    this.oldRoleId,
    this.oldRoleName,
    this.newRoleId,
    this.newRoleName,
    this.changedAt,
    this.changedBy,
    this.reason,
  });

  factory ChangeRoleResponse.fromJson(Map<String, dynamic> json) {
    return ChangeRoleResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      employeeId: json['employeeId'],
      employeeCode: json['employeeCode'],
      oldRoleId: json['oldRoleId'],
      oldRoleName: json['oldRoleName'],
      newRoleId: json['newRoleId'],
      newRoleName: json['newRoleName'],
      changedAt: json['changedAt'],
      changedBy: json['changedBy'],
      reason: json['reason'],
    );
  }
}

/// CHANGE STATUS
class ChangeStatusRequest {
  final bool isActive;
  final String? reason;
  String? updatedBy; // Set by controller from JWT claims

  ChangeStatusRequest({
    required this.isActive,
    this.reason,
    this.updatedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'reason': reason,
      'updatedBy': updatedBy,
    };
  }
}

class ChangeStatusResponse {
  final bool success;
  final String message;
  final int? employeeId;
  final String? employeeCode;
  final bool? oldStatus;
  final bool? newStatus;
  final String? changedAt; // Vietnam timezone
  final String? changedBy;
  final String? reason;

  ChangeStatusResponse({
    required this.success,
    required this.message,
    this.employeeId,
    this.employeeCode,
    this.oldStatus,
    this.newStatus,
    this.changedAt,
    this.changedBy,
    this.reason,
  });

  factory ChangeStatusResponse.fromJson(Map<String, dynamic> json) {
    return ChangeStatusResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      employeeId: json['employeeId'],
      employeeCode: json['employeeCode'],
      oldStatus: json['oldStatus'],
      newStatus: json['newStatus'],
      changedAt: json['changedAt'],
      changedBy: json['changedBy'],
      reason: json['reason'],
    );
  }
}

/// UPDATE DEPARTMENT
class UpdateDepartmentRequest {
  final int newDepartmentId;
  final String? reason;
  String? updatedBy; // Set by controller from JWT claims

  UpdateDepartmentRequest({
    required this.newDepartmentId,
    this.reason,
    this.updatedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'newDepartmentId': newDepartmentId,
      'reason': reason,
      'updatedBy': updatedBy,
    };
  }
}

class UpdateDepartmentResponse {
  final bool success;
  final String message;
  final int? employeeId;
  final String? employeeCode;
  final int? oldDepartmentId;
  final String? oldDepartmentName;
  final int? newDepartmentId;
  final String? newDepartmentName;
  final String? updatedAt; // Vietnam timezone
  final String? updatedBy;
  final String? reason;

  UpdateDepartmentResponse({
    required this.success,
    required this.message,
    this.employeeId,
    this.employeeCode,
    this.oldDepartmentId,
    this.oldDepartmentName,
    this.newDepartmentId,
    this.newDepartmentName,
    this.updatedAt,
    this.updatedBy,
    this.reason,
  });

  factory UpdateDepartmentResponse.fromJson(Map<String, dynamic> json) {
    return UpdateDepartmentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      employeeId: json['employeeId'],
      employeeCode: json['employeeCode'],
      oldDepartmentId: json['oldDepartmentId'],
      oldDepartmentName: json['oldDepartmentName'],
      newDepartmentId: json['newDepartmentId'],
      newDepartmentName: json['newDepartmentName'],
      updatedAt: json['updatedAt'],
      updatedBy: json['updatedBy'],
      reason: json['reason'],
    );
  }
}

// ==================== ACCOUNT MANAGEMENT ====================

/// PROVISION ACCOUNT
class ProvisionAccountRequest {
  final String? reason;
  String? createdBy; // Set by controller from JWT claims

  ProvisionAccountRequest({
    this.reason,
    this.createdBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
      'createdBy': createdBy,
    };
  }
}

class ProvisionAccountResponse {
  final bool success;
  final String message;
  final int? employeeId;
  final String? employeeCode;
  final String? employeeName;
  final String? employeeEmail;
  final String? defaultPassword;
  final String? assignedRole;
  final String? departmentName;
  final String? provisionedAt; // Vietnam timezone
  final String? provisionedBy;
  final bool isUpdate; // true if updating existing account

  ProvisionAccountResponse({
    required this.success,
    required this.message,
    this.employeeId,
    this.employeeCode,
    this.employeeName,
    this.employeeEmail,
    this.defaultPassword,
    this.assignedRole,
    this.departmentName,
    this.provisionedAt,
    this.provisionedBy,
    this.isUpdate = false,
  });

  factory ProvisionAccountResponse.fromJson(Map<String, dynamic> json) {
    return ProvisionAccountResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      employeeId: json['employeeId'],
      employeeCode: json['employeeCode'],
      employeeName: json['employeeName'],
      employeeEmail: json['employeeEmail'],
      defaultPassword: json['defaultPassword'],
      assignedRole: json['assignedRole'],
      departmentName: json['departmentName'],
      provisionedAt: json['provisionedAt'],
      provisionedBy: json['provisionedBy'],
      isUpdate: json['isUpdate'] ?? false,
    );
  }
}

/// PROVISION ACCOUNT WITH EMAIL
class ProvisionAccountWithEmailResponse extends ProvisionAccountResponse {
  final bool? emailSent;

  ProvisionAccountWithEmailResponse({
    required bool success,
    required String message,
    int? employeeId,
    String? employeeCode,
    String? employeeName,
    String? employeeEmail,
    String? defaultPassword,
    String? assignedRole,
    String? departmentName,
    String? provisionedAt,
    String? provisionedBy,
    bool isUpdate = false,
    this.emailSent,
  }) : super(
          success: success,
          message: message,
          employeeId: employeeId,
          employeeCode: employeeCode,
          employeeName: employeeName,
          employeeEmail: employeeEmail,
          defaultPassword: defaultPassword,
          assignedRole: assignedRole,
          departmentName: departmentName,
          provisionedAt: provisionedAt,
          provisionedBy: provisionedBy,
          isUpdate: isUpdate,
        );

  factory ProvisionAccountWithEmailResponse.fromJson(Map<String, dynamic> json) {
    return ProvisionAccountWithEmailResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      employeeId: json['employeeId'],
      employeeCode: json['employeeCode'],
      employeeName: json['employeeName'],
      employeeEmail: json['employeeEmail'],
      defaultPassword: json['defaultPassword'],
      assignedRole: json['assignedRole'],
      departmentName: json['departmentName'],
      provisionedAt: json['provisionedAt'],
      provisionedBy: json['provisionedBy'],
      isUpdate: json['isUpdate'] ?? false,
      emailSent: json['emailSent'],
    );
  }
}

// ==================== PASSWORD MANAGEMENT ====================

/// CHANGE PASSWORD
class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}

class ChangePasswordResponse {
  final bool success;
  final String message;
  final int? employeeId;
  final String? employeeCode;
  final String? changedAt; // Vietnam timezone

  ChangePasswordResponse({
    required this.success,
    required this.message,
    this.employeeId,
    this.employeeCode,
    this.changedAt,
  });

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      employeeId: json['employeeId'],
      employeeCode: json['employeeCode'],
      changedAt: json['changedAt'],
    );
  }
}

/// RESET PASSWORD
class ResetPasswordRequest {
  final int employeeId;
  final String newPassword;
  final String? reason;
  String? updatedBy; // Set by controller from JWT claims

  ResetPasswordRequest({
    required this.employeeId,
    required this.newPassword,
    this.reason,
    this.updatedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'newPassword': newPassword,
      'reason': reason,
      'updatedBy': updatedBy,
    };
  }
}

class ResetPasswordResponse {
  final bool success;
  final String message;
  final int? employeeId;
  final String? employeeCode;
  final String? resetAt; // Vietnam timezone
  final String? resetBy;
  final String? reason;

  ResetPasswordResponse({
    required this.success,
    required this.message,
    this.employeeId,
    this.employeeCode,
    this.resetAt,
    this.resetBy,
    this.reason,
  });

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      employeeId: json['employeeId'],
      employeeCode: json['employeeCode'],
      resetAt: json['resetAt'],
      resetBy: json['resetBy'],
      reason: json['reason'],
    );
  }
}

// ==================== AUTHENTICATION ====================

/// LOGIN
class LoginRequest {
  final String identifier; // Email or Employee Code
  final String password;

  LoginRequest({
    required this.identifier,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'password': password,
    };
  }
}

class LoginResponse {
  final bool success;
  final String message;
  final String? token;
  final int? employeeId;
  final String? employeeCode;
  final String? fullName;
  final String? email;
  final String? roleName;
  final int? roleLevel;
  final String? departmentName;
  final String? loginAt; // Vietnam timezone

  LoginResponse({
    required this.success,
    required this.message,
    this.token,
    this.employeeId,
    this.employeeCode,
    this.fullName,
    this.email,
    this.roleName,
    this.roleLevel,
    this.departmentName,
    this.loginAt,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'],
      employeeId: json['employeeId'],
      employeeCode: json['employeeCode'],
      fullName: json['fullName'],
      email: json['email'],
      roleName: json['roleName'],
      roleLevel: json['roleLevel'],
      departmentName: json['departmentName'],
      loginAt: json['loginAt'],
    );
  }
}
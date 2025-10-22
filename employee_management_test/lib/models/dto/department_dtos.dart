

// ==================== DROPDOWN DEPARTMENT ====================

/// DTO cho dropdown phòng ban
class DropdownDepartment {
  final int id;
  final String code;
  final String name;
  final String displayName;

  DropdownDepartment({
    required this.id,
    required this.code,
    required this.name,
    required this.displayName,
  });

  factory DropdownDepartment.fromJson(Map<String, dynamic> json) {
    return DropdownDepartment(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'displayName': displayName,
    };
  }
}

// ==================== CREATE DEPARTMENT ====================

/// Request DTO cho việc tạo phòng ban mới
class CreateDepartmentRequest {
  final String code;
  final String name;
  final String? description;
  final String? location;
  final bool isActive;
  String? createdBy; // Will be set by controller from JWT claims

  CreateDepartmentRequest({
    required this.code,
    required this.name,
    this.description,
    this.location,
    this.isActive = true,
    this.createdBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'location': location,
      'isActive': isActive,
      'createdBy': createdBy,
    };
  }
}

/// Response DTO cho việc tạo phòng ban
class CreateDepartmentResponse {
  final bool success;
  final String message;
  final int? departmentId;
  final String? departmentCode;
  final String? departmentName;
  final String? createdAt; // Vietnam timezone
  final String? createdBy;

  CreateDepartmentResponse({
    required this.success,
    required this.message,
    this.departmentId,
    this.departmentCode,
    this.departmentName,
    this.createdAt,
    this.createdBy,
  });

  factory CreateDepartmentResponse.fromJson(Map<String, dynamic> json) {
    return CreateDepartmentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      departmentId: json['departmentId'],
      departmentCode: json['departmentCode'],
      departmentName: json['departmentName'],
      createdAt: json['createdAt'],
      createdBy: json['createdBy'],
    );
  }
}

// ==================== UPDATE DEPARTMENT ====================

/// Request DTO cho việc cập nhật thông tin phòng ban
class UpdateDepartmentInfoRequest {
  final String? name;
  final String? description;
  final String? location;
  final bool? isActive;
  String? updatedBy; // Will be set by controller from JWT claims

  UpdateDepartmentInfoRequest({
    this.name,
    this.description,
    this.location,
    this.isActive,
    this.updatedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'isActive': isActive,
      'updatedBy': updatedBy,
    };
  }
}

/// Response DTO cho việc cập nhật phòng ban
class UpdateDepartmentInfoResponse {
  final bool success;
  final String message;
  final int? departmentId;
  final String? departmentCode;
  final String? departmentName;
  final String? updatedAt; // Vietnam timezone
  final String? updatedBy;
  final Map<String, dynamic>? changes;

  UpdateDepartmentInfoResponse({
    required this.success,
    required this.message,
    this.departmentId,
    this.departmentCode,
    this.departmentName,
    this.updatedAt,
    this.updatedBy,
    this.changes,
  });

  factory UpdateDepartmentInfoResponse.fromJson(Map<String, dynamic> json) {
    return UpdateDepartmentInfoResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      departmentId: json['departmentId'],
      departmentCode: json['departmentCode'],
      departmentName: json['departmentName'],
      updatedAt: json['updatedAt'],
      updatedBy: json['updatedBy'],
      changes: json['changes'],
    );
  }
}

// ==================== DELETE DEPARTMENT ====================

/// Response DTO cho việc xóa phòng ban (soft delete)
class DeleteDepartmentResponse {
  final bool success;
  final String message;
  final int? departmentId;
  final String? departmentCode;
  final String? departmentName;
  final String? deletedAt; // Vietnam timezone
  final String? deletedBy;
  final String? reason;
  final int? affectedEmployees;

  DeleteDepartmentResponse({
    required this.success,
    required this.message,
    this.departmentId,
    this.departmentCode,
    this.departmentName,
    this.deletedAt,
    this.deletedBy,
    this.reason,
    this.affectedEmployees,
  });

  factory DeleteDepartmentResponse.fromJson(Map<String, dynamic> json) {
    return DeleteDepartmentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      departmentId: json['departmentId'],
      departmentCode: json['departmentCode'],
      departmentName: json['departmentName'],
      deletedAt: json['deletedAt'],
      deletedBy: json['deletedBy'],
      reason: json['reason'],
      affectedEmployees: json['affectedEmployees'],
    );
  }
}

// ==================== RESTORE DEPARTMENT ====================

/// Response DTO cho việc khôi phục phòng ban
class RestoreDepartmentResponse {
  final bool success;
  final String message;
  final int? departmentId;
  final String? departmentCode;
  final String? departmentName;
  final String? restoredAt; // Vietnam timezone
  final String? restoredBy;
  final String? reason;

  RestoreDepartmentResponse({
    required this.success,
    required this.message,
    this.departmentId,
    this.departmentCode,
    this.departmentName,
    this.restoredAt,
    this.restoredBy,
    this.reason,
  });

  factory RestoreDepartmentResponse.fromJson(Map<String, dynamic> json) {
    return RestoreDepartmentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      departmentId: json['departmentId'],
      departmentCode: json['departmentCode'],
      departmentName: json['departmentName'],
      restoredAt: json['restoredAt'],
      restoredBy: json['restoredBy'],
      reason: json['reason'],
    );
  }
}

// ==================== DEPARTMENT STATISTICS ====================

/// DTO cho thống kê phòng ban
class DepartmentStatistics {
  final int departmentId;
  final String departmentCode;
  final String departmentName;
  final int totalEmployees;
  final int activeEmployees;
  final int inactiveEmployees;
  final int employeesWithFace;
  final int employeesWithAccount;
  final String? lastUpdated; // Vietnam timezone
  final Map<String, int>? roleDistribution;
  final Map<String, int>? statusDistribution;

  DepartmentStatistics({
    required this.departmentId,
    required this.departmentCode,
    required this.departmentName,
    required this.totalEmployees,
    required this.activeEmployees,
    required this.inactiveEmployees,
    required this.employeesWithFace,
    required this.employeesWithAccount,
    this.lastUpdated,
    this.roleDistribution,
    this.statusDistribution,
  });

  factory DepartmentStatistics.fromJson(Map<String, dynamic> json) {
    return DepartmentStatistics(
      departmentId: json['departmentId'] ?? 0,
      departmentCode: json['departmentCode'] ?? '',
      departmentName: json['departmentName'] ?? '',
      totalEmployees: json['totalEmployees'] ?? 0,
      activeEmployees: json['activeEmployees'] ?? 0,
      inactiveEmployees: json['inactiveEmployees'] ?? 0,
      employeesWithFace: json['employeesWithFace'] ?? 0,
      employeesWithAccount: json['employeesWithAccount'] ?? 0,
      lastUpdated: json['lastUpdated'],
      roleDistribution: json['roleDistribution'] != null 
          ? Map<String, int>.from(json['roleDistribution'])
          : null,
      statusDistribution: json['statusDistribution'] != null 
          ? Map<String, int>.from(json['statusDistribution'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'departmentId': departmentId,
      'departmentCode': departmentCode,
      'departmentName': departmentName,
      'totalEmployees': totalEmployees,
      'activeEmployees': activeEmployees,
      'inactiveEmployees': inactiveEmployees,
      'employeesWithFace': employeesWithFace,
      'employeesWithAccount': employeesWithAccount,
      'lastUpdated': lastUpdated,
      'roleDistribution': roleDistribution,
      'statusDistribution': statusDistribution,
    };
  }

  /// Tính phần trăm nhân viên có khuôn mặt
  double get faceRegistrationPercentage {
    if (totalEmployees == 0) return 0.0;
    return (employeesWithFace / totalEmployees) * 100;
  }

  /// Tính phần trăm nhân viên có tài khoản
  double get accountProvisionPercentage {
    if (totalEmployees == 0) return 0.0;
    return (employeesWithAccount / totalEmployees) * 100;
  }

  /// Tính phần trăm nhân viên đang hoạt động
  double get activeEmployeePercentage {
    if (totalEmployees == 0) return 0.0;
    return (activeEmployees / totalEmployees) * 100;
  }
}
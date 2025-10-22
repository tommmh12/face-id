import 'package:flutter/material.dart';

// ==================== PAYROLL PERIOD DTOs ====================

class CreatePayrollPeriodRequest {
  final String periodName;
  final DateTime startDate;
  final DateTime endDate;

  CreatePayrollPeriodRequest({
    required this.periodName,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'periodName': periodName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}

class PayrollPeriodResponse {
  final int id;
  final String periodName;
  final DateTime startDate;
  final DateTime endDate;
  final bool isClosed;
  final DateTime? closedAt;
  final DateTime createdAt;

  PayrollPeriodResponse({
    required this.id,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.isClosed,
    this.closedAt,
    required this.createdAt,
  });

  factory PayrollPeriodResponse.fromJson(Map<String, dynamic> json) {
    return PayrollPeriodResponse(
      id: json['id'] ?? 0,
      periodName: json['periodName']?.toString() ?? '',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate']) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate']) ?? DateTime.now()
          : DateTime.now(),
      isClosed: json['isClosed'] ?? false,
      closedAt: json['closedAt'] != null ? DateTime.tryParse(json['closedAt']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

// ==================== PAYROLL RULE DTOs ====================

class CreatePayrollRuleRequest {
  final int employeeId;
  final double baseSalary;
  final int standardWorkingDays;
  final double socialInsuranceRate;
  final double healthInsuranceRate;
  final double unemploymentInsuranceRate;
  final double personalDeduction;
  final int numberOfDependents;
  final double dependentDeduction;

  CreatePayrollRuleRequest({
    required this.employeeId,
    required this.baseSalary,
    this.standardWorkingDays = 22,
    this.socialInsuranceRate = 8.0,
    this.healthInsuranceRate = 1.5,
    this.unemploymentInsuranceRate = 1.0,
    this.personalDeduction = 11000000,
    this.numberOfDependents = 0,
    this.dependentDeduction = 4400000,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'baseSalary': baseSalary,
      'standardWorkingDays': standardWorkingDays,
      'socialInsuranceRate': socialInsuranceRate,
      'healthInsuranceRate': healthInsuranceRate,
      'unemploymentInsuranceRate': unemploymentInsuranceRate,
      'personalDeduction': personalDeduction,
      'numberOfDependents': numberOfDependents,
      'dependentDeduction': dependentDeduction,
    };
  }
}

class PayrollRuleResponse {
  final int id;
  final int employeeId;
  final double baseSalary;
  final int standardWorkingDays;
  final double socialInsuranceRate;
  final double healthInsuranceRate;
  final double unemploymentInsuranceRate;
  final double personalDeduction;
  final int numberOfDependents;
  final double dependentDeduction;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  PayrollRuleResponse({
    required this.id,
    required this.employeeId,
    required this.baseSalary,
    required this.standardWorkingDays,
    required this.socialInsuranceRate,
    required this.healthInsuranceRate,
    required this.unemploymentInsuranceRate,
    required this.personalDeduction,
    required this.numberOfDependents,
    required this.dependentDeduction,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
  });

  factory PayrollRuleResponse.fromJson(Map<String, dynamic> json) {
    return PayrollRuleResponse(
      id: json['id'] ?? 0,
      employeeId: json['employeeId'] ?? 0,
      baseSalary: (json['baseSalary'] ?? 0).toDouble(),
      standardWorkingDays: json['standardWorkingDays'] ?? 22,
      socialInsuranceRate: (json['socialInsuranceRate'] ?? 0).toDouble(),
      healthInsuranceRate: (json['healthInsuranceRate'] ?? 0).toDouble(),
      unemploymentInsuranceRate: (json['unemploymentInsuranceRate'] ?? 0).toDouble(),
      personalDeduction: (json['personalDeduction'] ?? 0).toDouble(),
      numberOfDependents: json['numberOfDependents'] ?? 0,
      dependentDeduction: (json['dependentDeduction'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      isActive: json['isActive'] ?? true,
    );
  }
}

// ==================== PAYROLL RULE VERSION DTOs ====================

class CreatePayrollRuleVersionRequest {
  final int employeeId;
  final double baseSalary;
  final DateTime effectiveDate;
  final String reason;
  final int standardWorkingDays;
  final double socialInsuranceRate;
  final double healthInsuranceRate;
  final double unemploymentInsuranceRate;
  final double personalDeduction;
  final int numberOfDependents;
  final double dependentDeduction;
  String? createdBy; // Will be set by controller

  CreatePayrollRuleVersionRequest({
    required this.employeeId,
    required this.baseSalary,
    required this.effectiveDate,
    required this.reason,
    this.standardWorkingDays = 22,
    this.socialInsuranceRate = 8.0,
    this.healthInsuranceRate = 1.5,
    this.unemploymentInsuranceRate = 1.0,
    this.personalDeduction = 11000000,
    this.numberOfDependents = 0,
    this.dependentDeduction = 4400000,
    this.createdBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'baseSalary': baseSalary,
      'effectiveDate': effectiveDate.toIso8601String(),
      'reason': reason,
      'standardWorkingDays': standardWorkingDays,
      'socialInsuranceRate': socialInsuranceRate,
      'healthInsuranceRate': healthInsuranceRate,
      'unemploymentInsuranceRate': unemploymentInsuranceRate,
      'personalDeduction': personalDeduction,
      'numberOfDependents': numberOfDependents,
      'dependentDeduction': dependentDeduction,
      'createdBy': createdBy,
    };
  }
}

class PayrollRuleVersionResponse {
  final int id;
  final int employeeId;
  final int versionNumber;
  final double baseSalary;
  final int standardWorkingDays;
  final double socialInsuranceRate;
  final double healthInsuranceRate;
  final double unemploymentInsuranceRate;
  final double personalDeduction;
  final int numberOfDependents;
  final double dependentDeduction;
  final DateTime effectiveDate;
  final String reason;
  final String createdBy;
  final DateTime createdAt;
  final bool isActive;

  PayrollRuleVersionResponse({
    required this.id,
    required this.employeeId,
    required this.versionNumber,
    required this.baseSalary,
    required this.standardWorkingDays,
    required this.socialInsuranceRate,
    required this.healthInsuranceRate,
    required this.unemploymentInsuranceRate,
    required this.personalDeduction,
    required this.numberOfDependents,
    required this.dependentDeduction,
    required this.effectiveDate,
    required this.reason,
    required this.createdBy,
    required this.createdAt,
    required this.isActive,
  });

  factory PayrollRuleVersionResponse.fromJson(Map<String, dynamic> json) {
    return PayrollRuleVersionResponse(
      id: json['id'] ?? 0,
      employeeId: json['employeeId'] ?? 0,
      versionNumber: json['versionNumber'] ?? 1,
      baseSalary: (json['baseSalary'] ?? 0).toDouble(),
      standardWorkingDays: json['standardWorkingDays'] ?? 22,
      socialInsuranceRate: (json['socialInsuranceRate'] ?? 0).toDouble(),
      healthInsuranceRate: (json['healthInsuranceRate'] ?? 0).toDouble(),
      unemploymentInsuranceRate: (json['unemploymentInsuranceRate'] ?? 0).toDouble(),
      personalDeduction: (json['personalDeduction'] ?? 0).toDouble(),
      numberOfDependents: json['numberOfDependents'] ?? 0,
      dependentDeduction: (json['dependentDeduction'] ?? 0).toDouble(),
      effectiveDate: json['effectiveDate'] != null
          ? DateTime.tryParse(json['effectiveDate']) ?? DateTime.now()
          : DateTime.now(),
      reason: json['reason']?.toString() ?? 'Không có lý do',
      createdBy: json['createdBy']?.toString() ?? 'System',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }
}

// ==================== ALLOWANCE DTOs ====================

class CreateAllowanceRequest {
  final int employeeId;
  final String allowanceType;
  final double amount;
  final bool isDeduction;
  final bool isRecurring;
  final DateTime effectiveDate;
  final DateTime? expiryDate;

  CreateAllowanceRequest({
    required this.employeeId,
    required this.allowanceType,
    required this.amount,
    this.isDeduction = false,
    this.isRecurring = false,
    required this.effectiveDate,
    this.expiryDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'allowanceType': allowanceType,
      'amount': amount,
      'isDeduction': isDeduction,
      'isRecurring': isRecurring,
      'effectiveDate': effectiveDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }
}

class AllowanceResponse {
  final int id;
  final int employeeId;
  final String allowanceType;
  final double amount;
  final bool isDeduction;
  final bool isRecurring;
  final DateTime effectiveDate;
  final DateTime? expiryDate;
  final bool isActive;
  final DateTime createdAt;

  AllowanceResponse({
    required this.id,
    required this.employeeId,
    required this.allowanceType,
    required this.amount,
    required this.isDeduction,
    required this.isRecurring,
    required this.effectiveDate,
    this.expiryDate,
    required this.isActive,
    required this.createdAt,
  });

  factory AllowanceResponse.fromJson(Map<String, dynamic> json) {
    return AllowanceResponse(
      id: json['id'] ?? 0,
      employeeId: json['employeeId'] ?? 0,
      allowanceType: json['allowanceType']?.toString() ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      isDeduction: json['isDeduction'] ?? false,
      isRecurring: json['isRecurring'] ?? false,
      effectiveDate: json['effectiveDate'] != null
          ? DateTime.tryParse(json['effectiveDate']) ?? DateTime.now()
          : DateTime.now(),
      expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate']) : null,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

// ==================== PAYROLL GENERATION DTOs ====================

class GeneratePayrollResponse {
  final bool success;
  final String message;
  final int totalEmployees;
  final int successCount;
  final int failedCount;
  final List<String> errors;

  GeneratePayrollResponse({
    required this.success,
    required this.message,
    required this.totalEmployees,
    required this.successCount,
    required this.failedCount,
    required this.errors,
  });

  factory GeneratePayrollResponse.fromJson(Map<String, dynamic> json) {
    return GeneratePayrollResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      totalEmployees: json['totalEmployees'] ?? 0,
      successCount: json['successCount'] ?? 0,
      failedCount: json['failedCount'] ?? 0,
      errors: json['errors'] != null 
        ? List<String>.from(json['errors']) 
        : [],
    );
  }
}

/// 🔄 RECALCULATE PAYROLL RESPONSE (NEW - V2.1)
class RecalculatePayrollResponse {
  final bool success;
  final String message;
  final int totalEmployees;  
  final int recalculatedCount;
  final int failedCount;
  final List<String> errors;

  RecalculatePayrollResponse({
    required this.success,
    required this.message,
    required this.totalEmployees,
    required this.recalculatedCount,
    required this.failedCount,
    required this.errors,
  });

  factory RecalculatePayrollResponse.fromJson(Map<String, dynamic> json) {
    return RecalculatePayrollResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      totalEmployees: json['totalEmployees'] ?? 0,
      recalculatedCount: json['recalculatedCount'] ?? 0,
      failedCount: json['failedCount'] ?? 0,
      errors: json['errors'] != null 
        ? List<String>.from(json['errors']) 
        : [],
    );
  }
}

class PayrollSummaryResponse {
  final int periodId;
  final String periodName;
  final int totalEmployees;
  final double totalGrossSalary;
  final double totalNetSalary;
  final double totalInsuranceDeduction;
  final double totalPITDeduction;
  final double totalOvertimePay;

  PayrollSummaryResponse({
    required this.periodId,
    required this.periodName,
    required this.totalEmployees,
    required this.totalGrossSalary,
    required this.totalNetSalary,
    required this.totalInsuranceDeduction,
    required this.totalPITDeduction,
    required this.totalOvertimePay,
  });

  factory PayrollSummaryResponse.fromJson(Map<String, dynamic> json) {
    return PayrollSummaryResponse(
      periodId: json['periodId'],
      periodName: json['periodName'],
      totalEmployees: json['totalEmployees'],
      totalGrossSalary: json['totalGrossSalary']?.toDouble() ?? 0.0,
      totalNetSalary: json['totalNetSalary']?.toDouble() ?? 0.0,
      totalInsuranceDeduction: json['totalInsuranceDeduction']?.toDouble() ?? 0.0,
      totalPITDeduction: json['totalPITDeduction']?.toDouble() ?? 0.0,
      totalOvertimePay: json['totalOvertimePay']?.toDouble() ?? 0.0,
    );
  }
}

class PayrollRecordResponse {
  final int id;
  final int payrollPeriodId;
  final int employeeId;
  final String employeeName;
  final double totalWorkingDays;
  final double totalOTHours;
  final double totalOTPayment;
  final double baseSalaryActual;
  final double totalAllowances;
  final double bonus;
  final double adjustedGrossIncome;
  final double insuranceDeduction;
  final double pitDeduction;
  final double otherDeductions;
  final double netSalary;
  final DateTime calculatedAt;
  final String? notes;

  PayrollRecordResponse({
    required this.id,
    required this.payrollPeriodId,
    required this.employeeId,
    required this.employeeName,
    required this.totalWorkingDays,
    required this.totalOTHours,
    required this.totalOTPayment,
    required this.baseSalaryActual,
    required this.totalAllowances,
    required this.bonus,
    required this.adjustedGrossIncome,
    required this.insuranceDeduction,
    required this.pitDeduction,
    required this.otherDeductions,
    required this.netSalary,
    required this.calculatedAt,
    this.notes,
  });

  factory PayrollRecordResponse.fromJson(Map<String, dynamic> json) {
    return PayrollRecordResponse(
      id: json['id'] ?? 0,
      payrollPeriodId: json['payrollPeriodId'] ?? 0,
      employeeId: json['employeeId'] ?? 0,
      employeeName: json['employeeName']?.toString() ?? 'Chưa có tên',
      totalWorkingDays: (json['totalWorkingDays'] ?? 0).toDouble(),
      totalOTHours: (json['totalOTHours'] ?? 0).toDouble(),
      totalOTPayment: (json['totalOTPayment'] ?? 0).toDouble(),
      baseSalaryActual: (json['baseSalaryActual'] ?? 0).toDouble(),
      totalAllowances: (json['totalAllowances'] ?? 0).toDouble(),
      bonus: (json['bonus'] ?? 0).toDouble(),
      adjustedGrossIncome: (json['adjustedGrossIncome'] ?? 0).toDouble(),
      insuranceDeduction: (json['insuranceDeduction'] ?? 0).toDouble(),
      pitDeduction: (json['pitDeduction'] ?? 0).toDouble(),
      otherDeductions: (json['otherDeductions'] ?? 0).toDouble(),
      netSalary: (json['netSalary'] ?? 0).toDouble(),
      calculatedAt: json['calculatedAt'] != null
          ? DateTime.tryParse(json['calculatedAt']) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes']?.toString(),
    );
  }
}

// ==================== SALARY ADJUSTMENT DTOs ====================

class CreateSalaryAdjustmentRequest {
  final int employeeId;
  final String adjustmentType; // "BONUS", "PENALTY", "CORRECTION"
  final double amount;
  final DateTime effectiveDate;
  final String description;
  final String createdBy;

  CreateSalaryAdjustmentRequest({
    required this.employeeId,
    required this.adjustmentType,
    required this.amount,
    required this.effectiveDate,
    required this.description,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'adjustmentType': adjustmentType,
      'amount': amount,
      'effectiveDate': effectiveDate.toIso8601String(),
      'description': description,
      'createdBy': createdBy,
    };
  }
}

/// 🔄 UPDATED SALARY ADJUSTMENT RESPONSE (V2.1 - With Audit Fields)
class SalaryAdjustmentResponse {
  final int id;
  final int employeeId;
  final String? employeeCode;
  final String? employeeName;
  final String adjustmentType; // "BONUS", "PENALTY", "CORRECTION"
  final double amount;
  final DateTime effectiveDate;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final bool isProcessed; // 🔑 Kiểm soát có thể sửa hay không
  final String? lastUpdatedBy; // Audit field
  final DateTime? lastUpdatedAt; // Audit field

  SalaryAdjustmentResponse({
    required this.id,
    required this.employeeId,
    this.employeeCode,
    this.employeeName,
    required this.adjustmentType,
    required this.amount,
    required this.effectiveDate,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.isProcessed,
    this.lastUpdatedBy,
    this.lastUpdatedAt,
  });

  factory SalaryAdjustmentResponse.fromJson(Map<String, dynamic> json) {
    return SalaryAdjustmentResponse(
      id: json['id'] ?? 0,
      employeeId: json['employeeId'] ?? 0,
      employeeCode: json['employeeCode']?.toString(),
      employeeName: json['employeeName']?.toString(),
      adjustmentType: json['adjustmentType']?.toString() ?? 'UNKNOWN',
      amount: (json['amount'] ?? 0).toDouble(),
      effectiveDate: json['effectiveDate'] != null
          ? DateTime.tryParse(json['effectiveDate']) ?? DateTime.now()
          : DateTime.now(),
      description: json['description']?.toString() ?? 'Không có mô tả',
      createdBy: json['createdBy']?.toString() ?? 'System',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      isProcessed: json['isProcessed'] ?? false,
      lastUpdatedBy: json['lastUpdatedBy']?.toString(),
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? DateTime.tryParse(json['lastUpdatedAt'])
          : null,
    );
  }

  /// 🎨 Helper method để lấy màu theo loại adjustment
  Color getTypeColor() {
    switch (adjustmentType.toLowerCase()) {
      case 'bonus':
        return const Color(0xFF34C759); // Green for bonus
      case 'penalty':
        return const Color(0xFFFF3B30); // Red for penalty  
      case 'correction':
        return const Color(0xFFFF9500); // Orange for correction
      default:
        return const Color(0xFF007AFF); // Blue default
    }
  }

  /// 🏷️ Helper method để lấy label tiếng Việt
  String getTypeLabel() {
    switch (adjustmentType.toLowerCase()) {
      case 'bonus':
        return 'Thưởng';
      case 'penalty':
        return 'Phạt';
      case 'correction':
        return 'Điều chỉnh';
      default:
        return adjustmentType;
    }
  }

  /// 🔐 Helper method kiểm tra có thể chỉnh sửa không
  bool get canEdit => !isProcessed;
}

/// 🆕 UPDATE SALARY ADJUSTMENT DTO (NEW - V2.1)
class UpdateSalaryAdjustmentRequest {
  final String adjustmentType; // "BONUS", "PENALTY", "CORRECTION"
  final double amount;
  final DateTime effectiveDate;
  final String description;
  final String updatedBy;
  final String? updateReason; // Lý do cập nhật - quan trọng cho audit

  UpdateSalaryAdjustmentRequest({
    required this.adjustmentType,
    required this.amount,
    required this.effectiveDate,
    required this.description,
    required this.updatedBy,
    this.updateReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'adjustmentType': adjustmentType,
      'amount': amount,
      'effectiveDate': effectiveDate.toIso8601String(),
      'description': description,
      'updatedBy': updatedBy,
      'updateReason': updateReason,
    };
  }
}

// ==================== ATTENDANCE CORRECTION DTOs ====================

class CorrectAttendanceRequest {
  final int employeeId;
  final int periodId;
  final DateTime date;
  final int? workingDays;
  final double? overtimeHours;
  final String reason;
  final String correctedBy;

  CorrectAttendanceRequest({
    required this.employeeId,
    required this.periodId,
    required this.date,
    this.workingDays,
    this.overtimeHours,
    required this.reason,
    required this.correctedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'periodId': periodId,
      'date': date.toIso8601String(),
      'workingDays': workingDays,
      'overtimeHours': overtimeHours,
      'reason': reason,
      'correctedBy': correctedBy,
    };
  }
}

class AttendanceCorrectionResponse {
  final bool success;
  final String message;
  final int employeeId;
  final DateTime date;
  final int? oldWorkingDays;
  final int? newWorkingDays;
  final double? oldOvertimeHours;
  final double? newOvertimeHours;

  AttendanceCorrectionResponse({
    required this.success,
    required this.message,
    required this.employeeId,
    required this.date,
    this.oldWorkingDays,
    this.newWorkingDays,
    this.oldOvertimeHours,
    this.newOvertimeHours,
  });

  factory AttendanceCorrectionResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceCorrectionResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      employeeId: json['employeeId'] ?? 0,
      date: json['date'] != null
          ? DateTime.tryParse(json['date']) ?? DateTime.now()
          : DateTime.now(),
      oldWorkingDays: json['oldWorkingDays'],
      newWorkingDays: json['newWorkingDays'],
      oldOvertimeHours: json['oldOvertimeHours']?.toDouble(),
      newOvertimeHours: json['newOvertimeHours']?.toDouble(),
    );
  }
}

// ==================== PERIOD STATUS UPDATE DTOs ====================

class UpdatePeriodStatusRequest {
  final String status; // "Draft", "Processing", "Closed", "Reopened"
  final String? reason;
  final String? updatedBy;

  UpdatePeriodStatusRequest({
    required this.status,
    this.reason,
    this.updatedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'reason': reason,
      'updatedBy': updatedBy,
    };
  }
}
// ==================== PAYROLL RECORDS LIST RESPONSE ====================

/// Wrapper cho response của GET /api/payroll/records/period/{periodId}
/// Backend trả về: { success, message, periodId, periodName, isClosed, totalRecords, data: [...] }
/// ✅ FIXED: Backend đặt records trong key "data", không phải "records"
class PayrollRecordsListResponse {
  final int? periodId;
  final String? periodName;
  final bool? isClosed;
  final List<PayrollRecordResponse> records;
  final int totalRecords;

  PayrollRecordsListResponse({
    this.periodId,
    this.periodName,
    this.isClosed,
    required this.records,
    required this.totalRecords,
  });

  factory PayrollRecordsListResponse.fromJson(Map<String, dynamic> json) {
    // 🔍 Backend structure:
    // {
    //   "success": true,
    //   "message": "...",
    //   "periodId": 1,
    //   "periodName": "Kỳ lương tháng 8/2025",
    //   "isClosed": false,
    //   "totalRecords": 1,
    //   "data": [{ payroll record objects }]  ← Records ở đây!
    // }
    
    return PayrollRecordsListResponse(
      periodId: json['periodId'],
      periodName: json['periodName']?.toString(),
      isClosed: json['isClosed'],
      records: json['data'] != null && json['data'] is List  // ← Đổi từ 'records' sang 'data'
          ? (json['data'] as List)
              .map((item) => PayrollRecordResponse.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
      totalRecords: json['totalRecords'] ?? 0,
    );
  }
}

// ==================== AUDIT LOG DTOs (NEW - V3) ====================

class AuditLogResponse {
  final int id;
  final String action; // INSERT, UPDATE, DELETE
  final String entityType; // PayrollRecord, SalaryAdjustment, etc.
  final int entityId;
  final int? employeeId;
  final int userId;
  final String? userName;
  final DateTime timestamp;
  final String? fieldName;
  final String? oldValue;
  final String? newValue;
  final String? reason;

  AuditLogResponse({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.employeeId,
    required this.userId,
    this.userName,
    required this.timestamp,
    this.fieldName,
    this.oldValue,
    this.newValue,
    this.reason,
  });

  factory AuditLogResponse.fromJson(Map<String, dynamic> json) {
    return AuditLogResponse(
      id: json['id'] as int,
      action: json['action']?.toString() ?? '',
      entityType: json['entityType']?.toString() ?? '',
      entityId: json['entityId'] as int,
      employeeId: json['employeeId'] as int?,
      userId: json['userId'] as int,
      userName: json['userName']?.toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      fieldName: json['fieldName']?.toString(),
      oldValue: json['oldValue']?.toString(),
      newValue: json['newValue']?.toString(),
      reason: json['reason']?.toString(),
    );
  }
}

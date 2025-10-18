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
      success: json['success'],
      message: json['message'],
      totalEmployees: json['totalEmployees'],
      successCount: json['successCount'],
      failedCount: json['failedCount'],
      errors: List<String>.from(json['errors'] ?? []),
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
      employeeName: json['employeeName']?.toString() ?? '',
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
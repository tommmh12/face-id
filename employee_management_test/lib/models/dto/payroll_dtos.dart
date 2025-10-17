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
      id: json['id'],
      periodName: json['periodName'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isClosed: json['isClosed'],
      closedAt: json['closedAt'] != null ? DateTime.parse(json['closedAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
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
      id: json['id'],
      employeeId: json['employeeId'],
      baseSalary: json['baseSalary']?.toDouble() ?? 0.0,
      standardWorkingDays: json['standardWorkingDays'],
      socialInsuranceRate: json['socialInsuranceRate']?.toDouble() ?? 0.0,
      healthInsuranceRate: json['healthInsuranceRate']?.toDouble() ?? 0.0,
      unemploymentInsuranceRate: json['unemploymentInsuranceRate']?.toDouble() ?? 0.0,
      personalDeduction: json['personalDeduction']?.toDouble() ?? 0.0,
      numberOfDependents: json['numberOfDependents'],
      dependentDeduction: json['dependentDeduction']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isActive: json['isActive'],
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
      id: json['id'],
      employeeId: json['employeeId'],
      allowanceType: json['allowanceType'],
      amount: json['amount']?.toDouble() ?? 0.0,
      isDeduction: json['isDeduction'],
      isRecurring: json['isRecurring'],
      effectiveDate: DateTime.parse(json['effectiveDate']),
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
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
      id: json['id'],
      payrollPeriodId: json['payrollPeriodId'],
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      totalWorkingDays: json['totalWorkingDays']?.toDouble() ?? 0.0,
      totalOTHours: json['totalOTHours']?.toDouble() ?? 0.0,
      totalOTPayment: json['totalOTPayment']?.toDouble() ?? 0.0,
      baseSalaryActual: json['baseSalaryActual']?.toDouble() ?? 0.0,
      totalAllowances: json['totalAllowances']?.toDouble() ?? 0.0,
      bonus: json['bonus']?.toDouble() ?? 0.0,
      adjustedGrossIncome: json['adjustedGrossIncome']?.toDouble() ?? 0.0,
      insuranceDeduction: json['insuranceDeduction']?.toDouble() ?? 0.0,
      pitDeduction: json['pitDeduction']?.toDouble() ?? 0.0,
      otherDeductions: json['otherDeductions']?.toDouble() ?? 0.0,
      netSalary: json['netSalary']?.toDouble() ?? 0.0,
      calculatedAt: DateTime.parse(json['calculatedAt']),
      notes: json['notes'],
    );
  }
}
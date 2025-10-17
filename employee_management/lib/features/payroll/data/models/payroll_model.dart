class PayrollPeriod {
  final int id;
  final String periodName;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime? processedDate;
  final DateTime createdAt;

  PayrollPeriod({
    required this.id,
    required this.periodName,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.processedDate,
    required this.createdAt,
  });

  factory PayrollPeriod.fromJson(Map<String, dynamic> json) {
    return PayrollPeriod(
      id: json['id'] as int,
      periodName: json['periodName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: json['status'] as String,
      processedDate: json['processedDate'] != null
          ? DateTime.parse(json['processedDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class PayrollRule {
  final int id;
  final int employeeId;
  final String? employeeName;
  final double baseSalary;
  final double overtimeRate;
  final double insuranceRate;
  final double taxRate;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final DateTime createdAt;

  PayrollRule({
    required this.id,
    required this.employeeId,
    this.employeeName,
    required this.baseSalary,
    required this.overtimeRate,
    required this.insuranceRate,
    required this.taxRate,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.createdAt,
  });

  factory PayrollRule.fromJson(Map<String, dynamic> json) {
    return PayrollRule(
      id: json['id'] as int,
      employeeId: json['employeeId'] as int,
      employeeName: json['employeeName'] as String?,
      baseSalary: (json['baseSalary'] as num).toDouble(),
      overtimeRate: (json['overtimeRate'] as num).toDouble(),
      insuranceRate: (json['insuranceRate'] as num).toDouble(),
      taxRate: (json['taxRate'] as num).toDouble(),
      effectiveFrom: DateTime.parse(json['effectiveFrom'] as String),
      effectiveTo: json['effectiveTo'] != null
          ? DateTime.parse(json['effectiveTo'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class PayrollAllowance {
  final int id;
  final int employeeId;
  final String? employeeName;
  final String type;
  final double amount;
  final String description;
  final DateTime effectiveDate;
  final DateTime createdAt;

  PayrollAllowance({
    required this.id,
    required this.employeeId,
    this.employeeName,
    required this.type,
    required this.amount,
    required this.description,
    required this.effectiveDate,
    required this.createdAt,
  });

  factory PayrollAllowance.fromJson(Map<String, dynamic> json) {
    return PayrollAllowance(
      id: json['id'] as int,
      employeeId: json['employeeId'] as int,
      employeeName: json['employeeName'] as String?,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      effectiveDate: DateTime.parse(json['effectiveDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class PayrollRecord {
  final int id;
  final int periodId;
  final int employeeId;
  final String? employeeName;
  final double baseSalary;
  final double overtimePay;
  final double allowances;
  final double deductions;
  final double insuranceDeduction;
  final double taxDeduction;
  final double netSalary;
  final String status;
  final DateTime createdAt;

  PayrollRecord({
    required this.id,
    required this.periodId,
    required this.employeeId,
    this.employeeName,
    required this.baseSalary,
    required this.overtimePay,
    required this.allowances,
    required this.deductions,
    required this.insuranceDeduction,
    required this.taxDeduction,
    required this.netSalary,
    required this.status,
    required this.createdAt,
  });

  factory PayrollRecord.fromJson(Map<String, dynamic> json) {
    return PayrollRecord(
      id: json['id'] as int,
      periodId: json['periodId'] as int,
      employeeId: json['employeeId'] as int,
      employeeName: json['employeeName'] as String?,
      baseSalary: (json['baseSalary'] as num).toDouble(),
      overtimePay: (json['overtimePay'] as num).toDouble(),
      allowances: (json['allowances'] as num).toDouble(),
      deductions: (json['deductions'] as num).toDouble(),
      insuranceDeduction: (json['insuranceDeduction'] as num).toDouble(),
      taxDeduction: (json['taxDeduction'] as num).toDouble(),
      netSalary: (json['netSalary'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

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
      'PeriodName': periodName,                    // PascalCase
      'StartDate': startDate.toIso8601String(),    // PascalCase
      'EndDate': endDate.toIso8601String(),        // PascalCase
    };
  }
}

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
      'EmployeeId': employeeId,                                      // PascalCase
      'BaseSalary': baseSalary,                                      // PascalCase
      'StandardWorkingDays': standardWorkingDays,                    // PascalCase
      'SocialInsuranceRate': socialInsuranceRate,                    // PascalCase
      'HealthInsuranceRate': healthInsuranceRate,                    // PascalCase
      'UnemploymentInsuranceRate': unemploymentInsuranceRate,        // PascalCase
      'PersonalDeduction': personalDeduction,                        // PascalCase
      'NumberOfDependents': numberOfDependents,                      // PascalCase
      'DependentDeduction': dependentDeduction,                      // PascalCase
    };
  }
}

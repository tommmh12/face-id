/// 🕐 Working Hours & Working Days DTOs
/// For displaying monthly working hours and days statistics

/// 🕐 Working Hours Result for a single day
class WorkingHoursResult {
  final int employeeId;
  final DateTime date;
  final bool isPresent;
  final bool isLate;
  final bool isEarlyLeave;
  final double standardWorkingHours;
  final double overtimeHours;
  final double overtimePay;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? notes;

  WorkingHoursResult({
    required this.employeeId,
    required this.date,
    required this.isPresent,
    required this.isLate,
    required this.isEarlyLeave,
    required this.standardWorkingHours,
    required this.overtimeHours,
    required this.overtimePay,
    this.checkInTime,
    this.checkOutTime,
    this.notes,
  });

  factory WorkingHoursResult.fromJson(Map<String, dynamic> json) {
    return WorkingHoursResult(
      employeeId: json['employeeId'] as int,
      date: DateTime.parse(json['date'] as String),
      isPresent: json['isPresent'] as bool,
      isLate: json['isLate'] as bool,
      isEarlyLeave: json['isEarlyLeave'] as bool,
      standardWorkingHours: (json['standardWorkingHours'] as num).toDouble(),
      overtimeHours: (json['overtimeHours'] as num).toDouble(),
      overtimePay: (json['overtimePay'] as num).toDouble(),
      checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime'] as String) : null,
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime'] as String) : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'date': date.toIso8601String(),
      'isPresent': isPresent,
      'isLate': isLate,
      'isEarlyLeave': isEarlyLeave,
      'standardWorkingHours': standardWorkingHours,
      'overtimeHours': overtimeHours,
      'overtimePay': overtimePay,
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'notes': notes,
    };
  }
}

/// 📊 Working Days Calculation Result
class WorkingDaysCalculationResult {
  final int employeeId;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDaysInPeriod;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int earlyLeaveDays;
  final double fullWorkingDays;
  final double halfWorkingDays;
  final double totalWorkingDays;
  final double totalStandardHours;
  final double totalOvertimeHours;
  final double totalOvertimePay;
  final List<WorkingHoursResult> dailyBreakdown;
  final DateTime calculatedAt;
  final bool hasError;
  final String? errorMessage;

  WorkingDaysCalculationResult({
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    required this.totalDaysInPeriod,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.earlyLeaveDays,
    required this.fullWorkingDays,
    required this.halfWorkingDays,
    required this.totalWorkingDays,
    required this.totalStandardHours,
    required this.totalOvertimeHours,
    required this.totalOvertimePay,
    required this.dailyBreakdown,
    required this.calculatedAt,
    this.hasError = false,
    this.errorMessage,
  });

  factory WorkingDaysCalculationResult.fromJson(Map<String, dynamic> json) {
    return WorkingDaysCalculationResult(
      employeeId: json['employeeId'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalDaysInPeriod: json['totalDaysInPeriod'] as int,
      presentDays: json['presentDays'] as int,
      absentDays: json['absentDays'] as int,
      lateDays: json['lateDays'] as int,
      earlyLeaveDays: json['earlyLeaveDays'] as int,
      fullWorkingDays: (json['fullWorkingDays'] as num).toDouble(),
      halfWorkingDays: (json['halfWorkingDays'] as num).toDouble(),
      totalWorkingDays: (json['totalWorkingDays'] as num).toDouble(),
      totalStandardHours: (json['totalStandardHours'] as num).toDouble(),
      totalOvertimeHours: (json['totalOvertimeHours'] as num).toDouble(),
      totalOvertimePay: (json['totalOvertimePay'] as num).toDouble(),
      dailyBreakdown: (json['dailyBreakdown'] as List<dynamic>)
          .map((e) => WorkingHoursResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      hasError: json['hasError'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalDaysInPeriod': totalDaysInPeriod,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'lateDays': lateDays,
      'earlyLeaveDays': earlyLeaveDays,
      'fullWorkingDays': fullWorkingDays,
      'halfWorkingDays': halfWorkingDays,
      'totalWorkingDays': totalWorkingDays,
      'totalStandardHours': totalStandardHours,
      'totalOvertimeHours': totalOvertimeHours,
      'totalOvertimePay': totalOvertimePay,
      'dailyBreakdown': dailyBreakdown.map((e) => e.toJson()).toList(),
      'calculatedAt': calculatedAt.toIso8601String(),
      'hasError': hasError,
      'errorMessage': errorMessage,
    };
  }
}

/// 📊 Monthly Working Hours Summary
class MonthlyWorkingHoursSummary {
  final int employeeId;
  final String employeeName;
  final int year;
  final int month;
  final String monthName;
  final WorkingDaysCalculationResult workingDaysResult;
  final DateTime calculatedAt;

  MonthlyWorkingHoursSummary({
    required this.employeeId,
    required this.employeeName,
    required this.year,
    required this.month,
    required this.monthName,
    required this.workingDaysResult,
    required this.calculatedAt,
  });

  factory MonthlyWorkingHoursSummary.fromJson(Map<String, dynamic> json) {
    return MonthlyWorkingHoursSummary(
      employeeId: json['employeeId'] as int,
      employeeName: json['employeeName'] as String,
      year: json['year'] as int,
      month: json['month'] as int,
      monthName: json['monthName'] as String,
      workingDaysResult: WorkingDaysCalculationResult.fromJson(json['workingDaysResult'] as Map<String, dynamic>),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'year': year,
      'month': month,
      'monthName': monthName,
      'workingDaysResult': workingDaysResult.toJson(),
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  /// Helper to get formatted total hours
  String get formattedTotalHours => '${(workingDaysResult.totalStandardHours + workingDaysResult.totalOvertimeHours).toStringAsFixed(1)}h';
  
  /// Helper to get formatted working days
  String get formattedWorkingDays => '${workingDaysResult.totalWorkingDays.toStringAsFixed(1)} ngày';
  
  /// Helper to get attendance rate
  double get attendanceRate => workingDaysResult.totalDaysInPeriod > 0 
      ? (workingDaysResult.presentDays / workingDaysResult.totalDaysInPeriod) * 100 
      : 0.0;
      
  String get formattedAttendanceRate => '${attendanceRate.toStringAsFixed(1)}%';
}

/// 🔄 Batch Working Days Request
class BatchWorkingDaysRequest {
  final List<int> employeeIds;
  final DateTime startDate;
  final DateTime endDate;
  final bool includeDailyBreakdown;

  BatchWorkingDaysRequest({
    required this.employeeIds,
    required this.startDate,
    required this.endDate,
    this.includeDailyBreakdown = false,
  });

  factory BatchWorkingDaysRequest.fromJson(Map<String, dynamic> json) {
    return BatchWorkingDaysRequest(
      employeeIds: List<int>.from(json['employeeIds'] as List),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      includeDailyBreakdown: json['includeDailyBreakdown'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeIds': employeeIds,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'includeDailyBreakdown': includeDailyBreakdown,
    };
  }
}

/// 📊 Working Hours Period Summary (for multiple months)
class WorkingHoursPeriodSummary {
  final int employeeId;
  final String employeeName;
  final DateTime fromDate;
  final DateTime toDate;
  final List<MonthlyWorkingHoursSummary> monthlySummaries;
  final double totalHours;
  final double totalWorkingDays;
  final double averageHoursPerMonth;
  final double averageWorkingDaysPerMonth;
  final DateTime calculatedAt;

  WorkingHoursPeriodSummary({
    required this.employeeId,
    required this.employeeName,
    required this.fromDate,
    required this.toDate,
    required this.monthlySummaries,
    required this.totalHours,
    required this.totalWorkingDays,
    required this.averageHoursPerMonth,
    required this.averageWorkingDaysPerMonth,
    required this.calculatedAt,
  });

  factory WorkingHoursPeriodSummary.fromJson(Map<String, dynamic> json) {
    return WorkingHoursPeriodSummary(
      employeeId: json['employeeId'] as int,
      employeeName: json['employeeName'] as String,
      fromDate: DateTime.parse(json['fromDate'] as String),
      toDate: DateTime.parse(json['toDate'] as String),
      monthlySummaries: (json['monthlySummaries'] as List<dynamic>)
          .map((e) => MonthlyWorkingHoursSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalHours: (json['totalHours'] as num).toDouble(),
      totalWorkingDays: (json['totalWorkingDays'] as num).toDouble(),
      averageHoursPerMonth: (json['averageHoursPerMonth'] as num).toDouble(),
      averageWorkingDaysPerMonth: (json['averageWorkingDaysPerMonth'] as num).toDouble(),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'fromDate': fromDate.toIso8601String(),
      'toDate': toDate.toIso8601String(),
      'monthlySummaries': monthlySummaries.map((e) => e.toJson()).toList(),
      'totalHours': totalHours,
      'totalWorkingDays': totalWorkingDays,
      'averageHoursPerMonth': averageHoursPerMonth,
      'averageWorkingDaysPerMonth': averageWorkingDaysPerMonth,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  /// Helper to get period description
  String get periodDescription {
    if (fromDate.year == toDate.year && fromDate.month == toDate.month) {
      return 'Tháng ${fromDate.month}/${fromDate.year}';
    }
    return 'Từ ${fromDate.month}/${fromDate.year} đến ${toDate.month}/${toDate.year}';
  }
  
  /// Helper to get formatted total hours
  String get formattedTotalHours => '${totalHours.toStringAsFixed(1)}h';
  
  /// Helper to get formatted total working days
  String get formattedTotalWorkingDays => '${totalWorkingDays.toStringAsFixed(1)} ngày';
}
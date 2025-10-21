import 'dart:convert';
import '../models/dto/payroll_dtos.dart';
import '../utils/app_logger.dart';
import '../utils/http_client.dart';
import 'api_service.dart';

class PayrollApiService extends BaseApiService {
  static const String _endpoint = '/payroll';

  // ==================== PAYROLL PERIOD ====================

  /// POST /api/payroll/periods
  /// Tạo kỳ lương mới (Tháng)
  Future<ApiResponse<PayrollPeriodResponse>> createPayrollPeriod(CreatePayrollPeriodRequest request) async {
    AppLogger.apiRequest('$_endpoint/periods', method: 'POST', data: request.toJson());
    
    final response = await handleRequest(
      () async => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/periods'),
        headers: await ApiConfig.getAuthenticatedHeaders(), //  FIXED: Use auth headers
        body: json.encode(request.toJson()),
      ),
      (json) => PayrollPeriodResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/periods',
      success: response.success,
      message: response.message,
      data: response.data != null ? 'Period: ${response.data!.periodName}' : null,
    );
    
    return response;
  }

  /// GET /api/payroll/periods
  /// Lấy danh sách tất cả kỳ lương
  Future<ApiResponse<List<PayrollPeriodResponse>>> getPayrollPeriods() async {
    AppLogger.apiRequest('$_endpoint/periods', method: 'GET');
    
    final response = await handleListRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/periods'),
        headers: await ApiConfig.getAuthenticatedHeaders(), //  FIXED: Use auth headers
      ),
      (json) => PayrollPeriodResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/periods',
      success: response.success,
      message: response.message,
      data: response.data != null ? 'Count: ${response.data!.length}' : null,
    );
    
    return response;
  }

  /// GET /api/payroll/periods/{id}
  /// Lấy thông tin kỳ lương theo ID
  Future<ApiResponse<PayrollPeriodResponse>> getPayrollPeriodById(int id) async {
    AppLogger.apiRequest('$_endpoint/periods/$id', method: 'GET');
    
    final response = await handleRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/periods/$id'),
        headers: await ApiConfig.getAuthenticatedHeaders(), //  FIXED: Use auth headers
      ),
      (json) => PayrollPeriodResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/periods/$id',
      success: response.success,
      message: response.message,
      data: response.data != null ? 'Period: ${response.data!.periodName}' : null,
    );
    
    return response;
  }

  // ==================== PAYROLL RULE ====================

  /// POST /api/payroll/rules
  /// Tạo hoặc cập nhật quy tắc tính lương cho nhân viên
  Future<ApiResponse<PayrollRuleResponse>> createOrUpdatePayrollRule(CreatePayrollRuleRequest request) async {
    AppLogger.apiRequest('$_endpoint/rules', method: 'POST', data: {
      'employeeId': request.employeeId,
      'baseSalary': request.baseSalary,
      'standardWorkingDays': request.standardWorkingDays,
    });
    
    final response = await handleRequest(
      () async => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/rules'),
        headers: await ApiConfig.getAuthenticatedHeaders(), //  FIXED: Use auth headers
        body: json.encode(request.toJson()),
      ),
      (json) => PayrollRuleResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/rules',
      success: response.success,
      message: response.message,
      data: response.data != null ? 'RuleId: ${response.data!.id}' : null,
    );
    
    return response;
  }

  /// GET /api/payroll/rules/employee/{employeeId}
  /// Lấy quy tắc tính lương của nhân viên
  Future<ApiResponse<PayrollRuleResponse>> getPayrollRuleByEmployeeId(int employeeId) async {
    AppLogger.apiRequest('$_endpoint/rules/employee/$employeeId', method: 'GET');
    
    final response = await handleRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/rules/employee/$employeeId'),
        headers: await ApiConfig.getAuthenticatedHeaders(), //  FIXED: Use auth headers
      ),
      (json) => PayrollRuleResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/rules/employee/$employeeId',
      success: response.success,
      message: response.message,
      data: response.data != null ? 'BaseSalary: ${response.data!.baseSalary}' : null,
    );
    
    return response;
  }

  /// GET /api/payroll/rules
  /// Lấy tất cả quy tắc tính lương
  Future<ApiResponse<List<PayrollRuleResponse>>> getAllPayrollRules() async {
    AppLogger.apiRequest('$_endpoint/rules', method: 'GET');
    
    final response = await handleListRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/rules'),
        headers: await ApiConfig.getAuthenticatedHeaders(), //  FIXED: Use auth headers
      ),
      (json) => PayrollRuleResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/rules',
      success: response.success,
      message: response.message,
      data: response.data != null ? 'Count: ${response.data!.length}' : null,
    );
    
    return response;
  }

  // ==================== ALLOWANCE ====================

  /// POST /api/payroll/allowances
  /// Tạo phụ cấp hoặc khấu trừ cho nhân viên
  Future<ApiResponse<AllowanceResponse>> createAllowance(CreateAllowanceRequest request) async {
    AppLogger.apiRequest('$_endpoint/allowances', method: 'POST', data: {
      'employeeId': request.employeeId,
      'allowanceType': request.allowanceType,
      'amount': request.amount,
    });
    
    final response = await handleRequest(
      () async => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/allowances'),
        headers: await ApiConfig.getAuthenticatedHeaders(), //  FIXED: Use auth headers
        body: json.encode(request.toJson()),
      ),
      (json) => AllowanceResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/allowances',
      success: response.success,
      message: response.message,
      data: response.data != null ? 'AllowanceId: ${response.data!.id}' : null,
    );
    
    return response;
  }

  /// GET /api/payroll/allowances/employee/{employeeId}
  /// Lấy danh sách phụ cấp/khấu trừ của nhân viên
  Future<ApiResponse<List<AllowanceResponse>>> getEmployeeAllowances(int employeeId) async {
    AppLogger.apiRequest('$_endpoint/allowances/employee/$employeeId', method: 'GET');
    
    final response = await handleListRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/allowances/employee/$employeeId'),
        headers: await ApiConfig.getAuthenticatedHeaders(), //  FIXED: Use auth headers
      ),
      (json) => AllowanceResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/allowances/employee/$employeeId',
      success: response.success,
      message: response.message,
      data: response.data != null ? 'Count: ${response.data!.length}' : null,
    );
    
    return response;
  }

  // ==================== PAYROLL GENERATION (CORE) ====================

  /// POST /api/payroll/generate/{periodId}
  /// 🔥 MAIN ENDPOINT: Tính lương cho tất cả nhân viên trong kỳ
  /// Áp dụng 6 bước logic: Chấm công -> OT -> Gross -> BH -> PIT -> Net
  Future<ApiResponse<GeneratePayrollResponse>> generatePayroll(int periodId) async {
    AppLogger.apiRequest('$_endpoint/generate/$periodId', method: 'POST');
    
    final response = await handleRequest(
      () async => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/generate/$periodId'),
        headers: await ApiConfig.getAuthenticatedHeaders(), //  FIXED: Use auth headers
      ),
      (json) => GeneratePayrollResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/generate/$periodId',
      success: response.success,
      message: response.message,
      data: response.data != null 
        ? 'Total: ${response.data!.totalEmployees}, Success: ${response.data!.successCount}, Failed: ${response.data!.failedCount}'
        : null,
    );
    
    return response;
  }

  // ==================== PAYROLL REPORTS ====================

  /// GET /api/payroll/summary/{periodId}
  /// Lấy tổng hợp bảng lương (Summary) của kỳ
  Future<ApiResponse<PayrollSummaryResponse>> getPayrollSummary(int periodId) async {
    AppLogger.apiRequest('$_endpoint/summary/$periodId', method: 'GET');
    
    final response = await handleRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/summary/$periodId'),
        headers: await ApiConfig.getAuthenticatedHeaders(), //  FIXED: Use auth headers
      ),
      (json) => PayrollSummaryResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/summary/$periodId',
      success: response.success,
      message: response.message,
      data: response.data != null 
        ? 'Employees: ${response.data!.totalEmployees}, NetSalary: ${response.data!.totalNetSalary}'
        : null,
    );
    
    return response;
  }

  /// GET /api/payroll/records/period/{periodId}/employee/{employeeId}
  /// Lấy bảng lương của 1 nhân viên trong kỳ
  Future<ApiResponse<PayrollRecordResponse>> getEmployeePayroll(int periodId, int employeeId) async {
    AppLogger.apiRequest('$_endpoint/records/period/$periodId/employee/$employeeId', method: 'GET');
    
    final response = await handleRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/records/period/$periodId/employee/$employeeId'),
        headers: await ApiConfig.getAuthenticatedHeaders(), //  FIXED: Use auth headers
      ),
      (json) => PayrollRecordResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/records/period/$periodId/employee/$employeeId',
      success: response.success,
      message: response.message,
      data: response.data != null 
        ? 'Employee: ${response.data!.employeeName}, NetSalary: ${response.data!.netSalary}'
        : null,
    );
    
    return response;
  }

  // ==================== EXTENDED FEATURES ====================

  /// GET /api/payroll/records/period/{periodId}
  /// Lấy danh sách tất cả bảng lương nhân viên trong kỳ (REAL DATA)
  /// ✅ FIXED: Backend trả về object { period, records, totalRecords }, không phải array
  Future<ApiResponse<PayrollRecordsListResponse>> getPayrollRecords(int periodId) async {
    AppLogger.apiRequest('$_endpoint/records/period/$periodId', method: 'GET');
    
    try {
      // Get raw HTTP response first for debugging
      final httpResponse = await CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/records/period/$periodId'),
        headers: await ApiConfig.getAuthenticatedHeaders(), //  FIXED: Use auth headers
      );
      
      // 🔍 DEBUG: Log raw response body to see what backend actually returns
      AppLogger.debug('Raw response body: ${httpResponse.body}', tag: 'PayrollAPI');
      
      // Now parse using handleRequest
      final response = await handleRequest(
        () => Future.value(httpResponse),
        (json) => PayrollRecordsListResponse.fromJson(json),
      );
      
      // 🔍 DEBUG: Log parsed data details
      if (response.data != null) {
        AppLogger.debug(
          'Parsed data - records.length: ${response.data!.records.length}, totalRecords: ${response.data!.totalRecords}, periodName: ${response.data!.periodName ?? "null"}',
          tag: 'PayrollAPI',
        );
      }
      
      AppLogger.apiResponse(
        '$_endpoint/records/period/$periodId',
        success: response.success,
        message: response.message,
        data: response.data != null ? 'Records: ${response.data!.records.length}, Total: ${response.data!.totalRecords}' : null,
      );
      
      return response;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to get payroll records',
        error: e,
        stackTrace: stackTrace,
        tag: 'PayrollAPI',
      );
      return ApiResponse.error('Failed to get payroll records: $e');
    }
  }

  /// POST /api/payroll/adjustments
  /// Tạo điều chỉnh lương (thưởng, phạt, phụ cấp đột xuất)
  Future<ApiResponse<SalaryAdjustmentResponse>> createSalaryAdjustment(CreateSalaryAdjustmentRequest request) async {
    AppLogger.apiRequest('$_endpoint/adjustments', method: 'POST', data: {
      'employeeId': request.employeeId,
      'periodId': request.periodId,
      'adjustmentType': request.adjustmentType,
      'amount': request.amount,
    });
    
    final response = await handleRequest(
      () async => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/adjustments'),
        headers: await ApiConfig.getAuthenticatedHeaders(), //  FIXED: Use auth headers
        body: json.encode(request.toJson()),
      ),
      (json) => SalaryAdjustmentResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/adjustments',
      success: response.success,
      message: response.message,
      data: response.data != null ? 'Type: ${response.data!.adjustmentType}, Amount: ${response.data!.amount}' : null,
    );
    
    return response;
  }

  /// GET /api/payroll/adjustments/employee/{employeeId}
  /// Lấy danh sách điều chỉnh lương của nhân viên
  Future<ApiResponse<List<SalaryAdjustmentResponse>>> getEmployeeAdjustments(int employeeId) async {
    AppLogger.apiRequest('$_endpoint/adjustments/employee/$employeeId', method: 'GET');
    
    final response = await handleListRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/adjustments/employee/$employeeId'),
        headers: await ApiConfig.getAuthenticatedHeaders(), //  FIXED: Use auth headers
      ),
      (json) => SalaryAdjustmentResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/adjustments/employee/$employeeId',
      success: response.success,
      message: response.message,
      data: response.data != null ? 'Adjustments: ${response.data!.length}' : null,
    );
    
    return response;
  }

  /// PUT /api/payroll/adjustment/{id} 🆕 NEW METHOD (V2.1)
  /// Cập nhật điều chỉnh lương (sửa thưởng/phạt)
  /// Chỉ cho phép sửa những adjustment chưa được processed
  Future<ApiResponse<SalaryAdjustmentResponse>> updateSalaryAdjustment(
    int adjustmentId, 
    UpdateSalaryAdjustmentRequest request
  ) async {
    AppLogger.apiRequest('$_endpoint/adjustment/$adjustmentId', method: 'PUT', data: {
      'adjustmentType': request.adjustmentType,
      'amount': request.amount,
      'effectiveDate': request.effectiveDate.toIso8601String(),
      'description': request.description,
      'updatedBy': request.updatedBy,
      'updateReason': request.updateReason,
    });
    
    final response = await handleRequest(
      () async => CustomHttpClient.put(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/adjustment/$adjustmentId'),
        headers: await ApiConfig.getAuthenticatedHeaders(),
        body: json.encode(request.toJson()),
      ),
      (json) => SalaryAdjustmentResponse.fromJson(json['data'] ?? json), // Handle nested response
    );
    
    AppLogger.apiResponse(
      '$_endpoint/adjustment/$adjustmentId',
      success: response.success,
      message: response.message,
      data: response.data != null 
        ? 'Updated: ${response.data!.adjustmentType} - ${response.data!.amount}' 
        : null,
    );
    
    return response;
  }

  /// POST /api/payroll/recalculate/{periodId} 🔄 RECALCULATE METHOD  
  /// Tính toán lại lương cho kỳ (Bắt buộc gọi sau mọi thay đổi)
  Future<ApiResponse<RecalculatePayrollResponse>> recalculatePayroll(int periodId) async {
    AppLogger.apiRequest('$_endpoint/recalculate/$periodId', method: 'POST');
    
    final response = await handleRequest(
      () async => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/recalculate/$periodId'),
        headers: await ApiConfig.getAuthenticatedHeaders(),
      ),
      (json) => RecalculatePayrollResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/recalculate/$periodId',
      success: response.success,
      message: response.message,
      data: response.data != null 
        ? 'Recalculated: ${response.data!.recalculatedCount}/${response.data!.totalEmployees}' 
        : null,
    );
    
    return response;
  }

  /// POST /api/payroll/attendance/correct
  /// Chỉnh sửa chấm công (sửa ngày công, giờ OT)
  Future<ApiResponse<AttendanceCorrectionResponse>> correctAttendance(CorrectAttendanceRequest request) async {
    AppLogger.apiRequest('$_endpoint/attendance/correct', method: 'POST', data: {
      'employeeId': request.employeeId,
      'periodId': request.periodId,
      'date': request.date.toString(),
      'workingDays': request.workingDays,
      'overtimeHours': request.overtimeHours,
    });
    
    final response = await handleRequest(
      () async => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/attendance/correct'),
        headers: await ApiConfig.getAuthenticatedHeaders(), //  FIXED: Use auth headers
        body: json.encode(request.toJson()),
      ),
      (json) => AttendanceCorrectionResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/attendance/correct',
      success: response.success,
      message: response.message,
      data: response.data != null ? 'Employee: ${response.data!.employeeId}, Success: ${response.data!.success}' : null,
    );
    
    return response;
  }



  /// PUT /api/payroll/periods/{periodId}/status
  /// Cập nhật trạng thái kỳ lương (Draft/Processing/Closed)
  Future<ApiResponse<PayrollPeriodResponse>> updatePeriodStatus(int periodId, UpdatePeriodStatusRequest request) async {
    AppLogger.apiRequest('$_endpoint/periods/$periodId/status', method: 'PUT', data: {
      'status': request.status,
      'reason': request.reason,
    });
    
    final response = await handleRequest(
      () async => CustomHttpClient.put(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/periods/$periodId/status'),
        headers: await ApiConfig.getAuthenticatedHeaders(), //  FIXED: Use auth headers
        body: json.encode(request.toJson()),
      ),
      (json) => PayrollPeriodResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/periods/$periodId/status',
      success: response.success,
      message: response.message,
      data: response.data != null ? 'Status: ${request.status}' : null,
    );
    
    return response;
  }

  // ==================== UTILITIES ====================

  /// GET /api/payroll/health
  /// Health check endpoint
  Future<ApiResponse<Map<String, dynamic>>> healthCheck() async {
    AppLogger.apiRequest('$_endpoint/health', method: 'GET');
    
    final response = await handleRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/health'),
        headers: await ApiConfig.getAuthenticatedHeaders(), //  FIXED: Use auth headers
      ),
      (json) => json,
    );
    
    AppLogger.apiResponse(
      '$_endpoint/health',
      success: response.success,
      message: response.message,
    );
    
    return response;
  }

  // ==================== AUDIT LOG (NEW - V3) ====================

  /// GET /api/payroll/audit
  /// Lấy danh sách audit logs với filters
  Future<ApiResponse<List<AuditLogResponse>>> getAuditLogs({
    String? entityType,
    int? employeeId,
    String? action,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    
    if (entityType != null) queryParams['entityType'] = entityType;
    if (employeeId != null) queryParams['employeeId'] = employeeId.toString();
    if (action != null) queryParams['action'] = action;
    if (fromDate != null) queryParams['fromDate'] = fromDate.toIso8601String();
    if (toDate != null) queryParams['toDate'] = toDate.toIso8601String();
    
    final uri = Uri.parse('${ApiConfig.baseUrl}$_endpoint/audit')
        .replace(queryParameters: queryParams);
    
    AppLogger.apiRequest('$_endpoint/audit', method: 'GET', data: queryParams);
    
    final response = await handleListRequest(
      () async => CustomHttpClient.get(uri, headers: await ApiConfig.getAuthenticatedHeaders()), // ✅ FIXED: Use auth headers
      (json) => AuditLogResponse.fromJson(json),
    );
    
    AppLogger.apiResponse(
      '$_endpoint/audit',
      success: response.success,
      message: response.message,
      data: response.data != null ? 'Count: ${response.data!.length}' : null,
    );
    
    return response;
  }
}

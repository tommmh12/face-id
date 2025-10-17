import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dto/payroll_dtos.dart';
import 'api_service.dart';

class PayrollApiService extends BaseApiService {
  static const String _endpoint = '/payroll';

  // ==================== PAYROLL PERIOD ====================

  /// POST /api/payroll/periods
  /// Tạo kỳ lương mới (Tháng)
  Future<ApiResponse<PayrollPeriodResponse>> createPayrollPeriod(CreatePayrollPeriodRequest request) async {
    final httpRequest = http.post(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/periods'),
      headers: ApiConfig.headers,
      body: json.encode(request.toJson()),
    );

    return handleRequest(httpRequest, (json) => PayrollPeriodResponse.fromJson(json));
  }

  /// GET /api/payroll/periods
  /// Lấy danh sách tất cả kỳ lương
  Future<ApiResponse<List<PayrollPeriodResponse>>> getPayrollPeriods() async {
    final request = http.get(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/periods'),
      headers: ApiConfig.headers,
    );

    return handleListRequest(request, (json) => PayrollPeriodResponse.fromJson(json));
  }

  /// GET /api/payroll/periods/{id}
  /// Lấy thông tin kỳ lương theo ID
  Future<ApiResponse<PayrollPeriodResponse>> getPayrollPeriodById(int id) async {
    final request = http.get(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/periods/$id'),
      headers: ApiConfig.headers,
    );

    return handleRequest(request, (json) => PayrollPeriodResponse.fromJson(json));
  }

  // ==================== PAYROLL RULE ====================

  /// POST /api/payroll/rules
  /// Tạo hoặc cập nhật quy tắc tính lương cho nhân viên
  Future<ApiResponse<PayrollRuleResponse>> createOrUpdatePayrollRule(CreatePayrollRuleRequest request) async {
    final httpRequest = http.post(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/rules'),
      headers: ApiConfig.headers,
      body: json.encode(request.toJson()),
    );

    return handleRequest(httpRequest, (json) => PayrollRuleResponse.fromJson(json));
  }

  /// GET /api/payroll/rules/employee/{employeeId}
  /// Lấy quy tắc tính lương của nhân viên
  Future<ApiResponse<PayrollRuleResponse>> getPayrollRuleByEmployeeId(int employeeId) async {
    final request = http.get(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/rules/employee/$employeeId'),
      headers: ApiConfig.headers,
    );

    return handleRequest(request, (json) => PayrollRuleResponse.fromJson(json));
  }

  /// GET /api/payroll/rules
  /// Lấy tất cả quy tắc tính lương
  Future<ApiResponse<List<PayrollRuleResponse>>> getAllPayrollRules() async {
    final request = http.get(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/rules'),
      headers: ApiConfig.headers,
    );

    return handleListRequest(request, (json) => PayrollRuleResponse.fromJson(json));
  }

  // ==================== ALLOWANCE ====================

  /// POST /api/payroll/allowances
  /// Tạo phụ cấp hoặc khấu trừ cho nhân viên
  Future<ApiResponse<AllowanceResponse>> createAllowance(CreateAllowanceRequest request) async {
    final httpRequest = http.post(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/allowances'),
      headers: ApiConfig.headers,
      body: json.encode(request.toJson()),
    );

    return handleRequest(httpRequest, (json) => AllowanceResponse.fromJson(json));
  }

  /// GET /api/payroll/allowances/employee/{employeeId}
  /// Lấy danh sách phụ cấp/khấu trừ của nhân viên
  Future<ApiResponse<List<AllowanceResponse>>> getEmployeeAllowances(int employeeId) async {
    final request = http.get(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/allowances/employee/$employeeId'),
      headers: ApiConfig.headers,
    );

    return handleListRequest(request, (json) => AllowanceResponse.fromJson(json));
  }

  // ==================== PAYROLL GENERATION (CORE) ====================

  /// POST /api/payroll/generate/{periodId}
  /// 🔥 MAIN ENDPOINT: Tính lương cho tất cả nhân viên trong kỳ
  /// Áp dụng 6 bước logic: Chấm công -> OT -> Gross -> BH -> PIT -> Net
  Future<ApiResponse<GeneratePayrollResponse>> generatePayroll(int periodId) async {
    final request = http.post(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/generate/$periodId'),
      headers: ApiConfig.headers,
    );

    return handleRequest(request, (json) => GeneratePayrollResponse.fromJson(json));
  }

  // ==================== PAYROLL REPORTS ====================

  /// GET /api/payroll/summary/{periodId}
  /// Lấy tổng hợp bảng lương (Summary) của kỳ
  Future<ApiResponse<PayrollSummaryResponse>> getPayrollSummary(int periodId) async {
    final request = http.get(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/summary/$periodId'),
      headers: ApiConfig.headers,
    );

    return handleRequest(request, (json) => PayrollSummaryResponse.fromJson(json));
  }

  /// GET /api/payroll/records/period/{periodId}/employee/{employeeId}
  /// Lấy bảng lương của 1 nhân viên trong kỳ
  Future<ApiResponse<PayrollRecordResponse>> getEmployeePayroll(int periodId, int employeeId) async {
    final request = http.get(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/records/period/$periodId/employee/$employeeId'),
      headers: ApiConfig.headers,
    );

    return handleRequest(request, (json) => PayrollRecordResponse.fromJson(json));
  }

  // ==================== UTILITIES ====================

  /// GET /api/payroll/health
  /// Health check endpoint
  Future<ApiResponse<Map<String, dynamic>>> healthCheck() async {
    final request = http.get(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/health'),
      headers: ApiConfig.headers,
    );

    return handleRequest(request, (json) => json);
  }
}
import 'dart:convert';
import '../models/department.dart';
import '../models/employee.dart';
import '../models/dto/employee_dtos.dart';
import '../utils/http_client.dart';
import 'api_service.dart';

class EmployeeApiService extends BaseApiService {
  static const String _endpoint = '/employee';

  // ==================== DEPARTMENTS ====================

  /// GET /api/employee/departments
  /// Lấy danh sách tất cả phòng ban
  Future<ApiResponse<List<Department>>> getDepartments() async {
    return handleListRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/departments'),
        headers: await ApiConfig.getAuthenticatedHeaders(), // ✅ FIXED: Use auth headers
      ),
      (json) => Department.fromJson(json),
    );
  }

  // ==================== EMPLOYEE CRUD ====================

  /// POST /api/employee
  /// Tạo nhân viên mới (chưa có face)
  Future<ApiResponse<CreateEmployeeResponse>> createEmployee(CreateEmployeeRequest request) async {
    return handleRequest(
      () async => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint'),
        headers: await ApiConfig.getAuthenticatedHeaders(), // ✅ FIXED: Use auth headers
        body: json.encode(request.toJson()),
      ),
      (json) => CreateEmployeeResponse.fromJson(json),
    );
  }

  /// GET /api/employee
  /// Lấy danh sách tất cả nhân viên
  Future<ApiResponse<List<Employee>>> getAllEmployees() async {
    return handleListRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint'),
        headers: await ApiConfig.getAuthenticatedHeaders(), // ✅ FIXED: Use auth headers
      ),
      (json) => Employee.fromJson(json),
    );
  }

  /// GET /api/employee/{id}
  /// Lấy thông tin nhân viên theo ID
  Future<ApiResponse<Employee>> getEmployeeById(int id) async {
    return handleRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id'),
        headers: await ApiConfig.getAuthenticatedHeaders(), // ✅ FIXED: Use auth headers
      ),
      (json) => Employee.fromJson(json),
    );
  }

  /// GET /api/employee/department/{departmentId}
  /// Lấy danh sách nhân viên theo phòng ban
  Future<ApiResponse<List<Employee>>> getEmployeesByDepartment(int departmentId) async {
    return handleListRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/department/$departmentId'),
        headers: await ApiConfig.getAuthenticatedHeaders(), // ✅ FIXED: Use auth headers
      ),
      (json) => Employee.fromJson(json),
    );
  }

  // ==================== FACE REGISTRATION ====================

  /// POST /api/employee/register-face
  /// Đăng ký khuôn mặt cho nhân viên
  Future<ApiResponse<RegisterEmployeeFaceResponse>> registerFace(RegisterEmployeeFaceRequest request) async {
    return handleRequest(
      () async => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/register-face'),
        headers: await ApiConfig.getAuthenticatedHeaders(), // ✅ FIXED: Use auth headers
        body: json.encode(request.toJson()),
      ),
      (json) => RegisterEmployeeFaceResponse.fromJson(json),
    );
  }

  /// POST /api/employee/verify-face
  /// Verify khuôn mặt và chấm công (realtime)
  Future<ApiResponse<VerifyEmployeeFaceResponse>> verifyFace(VerifyFaceRequest request) async {
    return handleRequest(
      () async => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/verify-face'),
        headers: await ApiConfig.getAuthenticatedHeaders(), // ✅ FIXED: Use auth headers
        body: json.encode(request.toJson()),
      ),
      (json) => VerifyEmployeeFaceResponse.fromJson(json),
    );
  }

  // ==================== UPDATE OPERATIONS ====================

  /// PUT /api/employee/{id} - Cập nhật thông tin nhân viên
  /// Policy: [Authorize(Policy = "RequireHRRole")] - HR or Admin
  Future<ApiResponse<UpdateEmployeeResponse>> updateEmployee(int id, UpdateEmployeeRequest request) async {
    return handleRequest(
      () async => CustomHttpClient.put(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id'),
        headers: await ApiConfig.getAuthenticatedHeaders(),
        body: json.encode(request.toJson()),
      ),
      (json) => UpdateEmployeeResponse.fromJson(json),
    );
  }

  /// DELETE /api/employee/{id} - Xóa nhân viên (soft delete)
  /// Policy: [Authorize(Policy = "RequireAdminRole")] - Admin only
  Future<ApiResponse<DeleteEmployeeResponse>> deleteEmployee(int id, {String? reason}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id');
    final uriWithReason = reason != null 
        ? uri.replace(queryParameters: {'reason': reason})
        : uri;

    return handleRequest(
      () async => CustomHttpClient.delete(
        uriWithReason,
        headers: await ApiConfig.getAuthenticatedHeaders(),
      ),
      (json) => DeleteEmployeeResponse.fromJson(json),
    );
  }

  /// POST /api/employee/{id}/restore - Khôi phục nhân viên
  /// Policy: [Authorize(Policy = "RequireAdminRole")] - Admin only
  Future<ApiResponse<RestoreEmployeeResponse>> restoreEmployee(int id, {String? reason}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id/restore');
    final uriWithReason = reason != null 
        ? uri.replace(queryParameters: {'reason': reason})
        : uri;

    return handleRequest(
      () async => CustomHttpClient.post(
        uriWithReason,
        headers: await ApiConfig.getAuthenticatedHeaders(),
      ),
      (json) => RestoreEmployeeResponse.fromJson(json),
    );
  }

  // ==================== ROLE & STATUS MANAGEMENT ====================

  /// PUT /api/employee/{id}/role - Thay đổi role nhân viên
  /// Policy: [Authorize(Policy = "RequireAdminRole")] - Admin only
  Future<ApiResponse<ChangeRoleResponse>> changeEmployeeRole(int id, ChangeRoleRequest request) async {
    return handleRequest(
      () async => CustomHttpClient.put(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id/role'),
        headers: await ApiConfig.getAuthenticatedHeaders(),
        body: json.encode(request.toJson()),
      ),
      (json) => ChangeRoleResponse.fromJson(json),
    );
  }

  /// PUT /api/employee/{id}/status - Thay đổi trạng thái nhân viên
  /// Policy: [Authorize(Policy = "RequireHRRole")] - HR or Admin
  Future<ApiResponse<ChangeStatusResponse>> changeEmployeeStatus(int id, ChangeStatusRequest request) async {
    return handleRequest(
      () async => CustomHttpClient.put(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id/status'),
        headers: await ApiConfig.getAuthenticatedHeaders(),
        body: json.encode(request.toJson()),
      ),
      (json) => ChangeStatusResponse.fromJson(json),
    );
  }

  /// PUT /api/employee/{id}/department - Cập nhật phòng ban nhân viên
  /// Policy: [Authorize(Policy = "RequireAdminRole")] - Admin only
  Future<ApiResponse<UpdateDepartmentResponse>> updateEmployeeDepartment(int id, UpdateDepartmentRequest request) async {
    return handleRequest(
      () async => CustomHttpClient.put(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id/department'),
        headers: await ApiConfig.getAuthenticatedHeaders(),
        body: json.encode(request.toJson()),
      ),
      (json) => UpdateDepartmentResponse.fromJson(json),
    );
  }

  // ==================== ACCOUNT MANAGEMENT ====================

  /// POST /api/employee/{id}/provision-account - Cấp tài khoản cho nhân viên
  /// Policy: [Authorize(Policy = "RequireHRRole")] - HR or Admin
  Future<ApiResponse<ProvisionAccountResponse>> provisionAccount(int id, ProvisionAccountRequest request) async {
    return handleRequest(
      () async => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id/provision-account'),
        headers: await ApiConfig.getAuthenticatedHeaders(),
        body: json.encode(request.toJson()),
      ),
      (json) => ProvisionAccountResponse.fromJson(json),
    );
  }

  /// POST /api/employee/{id}/provision-with-email - Cấp tài khoản và gửi email
  /// Policy: [Authorize(Policy = "RequireHRRole")] - HR or Admin
  Future<ApiResponse<ProvisionAccountWithEmailResponse>> provisionAccountWithEmail(int id, ProvisionAccountRequest request) async {
    return handleRequest(
      () async => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id/provision-with-email'),
        headers: await ApiConfig.getAuthenticatedHeaders(),
        body: json.encode(request.toJson()),
      ),
      (json) => ProvisionAccountWithEmailResponse.fromJson(json),
    );
  }

  // ==================== PASSWORD MANAGEMENT ====================

  /// PUT /api/employee/change-password - Đổi mật khẩu của chính mình
  /// Policy: [Authorize] - User must be authenticated
  Future<ApiResponse<ChangePasswordResponse>> changePassword(ChangePasswordRequest request) async {
    return handleRequest(
      () async => CustomHttpClient.put(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/change-password'),
        headers: await ApiConfig.getAuthenticatedHeaders(),
        body: json.encode(request.toJson()),
      ),
      (json) => ChangePasswordResponse.fromJson(json),
    );
  }

  /// POST /api/employee/reset-password - Reset mật khẩu cho nhân viên khác
  /// Policy: [Authorize(Policy = "RequireHRRole")] - HR or Admin
  Future<ApiResponse<ResetPasswordResponse>> resetPassword(ResetPasswordRequest request) async {
    return handleRequest(
      () async => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/reset-password'),
        headers: await ApiConfig.getAuthenticatedHeaders(),
        body: json.encode(request.toJson()),
      ),
      (json) => ResetPasswordResponse.fromJson(json),
    );
  }

  // ==================== AUTHENTICATION ====================

  /// POST /api/employee/login - Đăng nhập bằng Email hoặc Employee Code
  /// Policy: [AllowAnonymous]
  Future<ApiResponse<LoginResponse>> login(LoginRequest request) async {
    return handleRequest(
      () async => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/login'),
        headers: ApiConfig.headers, // No auth needed for login
        body: json.encode(request.toJson()),
      ),
      (json) => LoginResponse.fromJson(json),
    );
  }

  // ==================== DIAGNOSTIC TOOLS ====================

  /// GET /api/employee/{id}/diagnose - Chẩn đoán vấn đề tài khoản nhân viên
  /// Policy: [Authorize(Policy = "RequireAdminRole")] - Admin only
  Future<ApiResponse<Map<String, dynamic>>> diagnoseEmployee(int id) async {
    return handleRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id/diagnose'),
        headers: await ApiConfig.getAuthenticatedHeaders(),
      ),
      (json) => json,
    );
  }

  // ==================== HEALTH CHECK ====================

  /// GET /api/employee/health - Health check
  /// Policy: [AllowAnonymous]
  Future<ApiResponse<Map<String, dynamic>>> healthCheck() async {
    return handleRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/health'),
        headers: ApiConfig.headers, // No auth needed for health check
      ),
      (json) => json,
    );
  }
}
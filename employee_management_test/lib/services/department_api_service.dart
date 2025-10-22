import 'dart:convert';
import '../models/department.dart';
import '../models/employee.dart';
import '../models/dto/department_dtos.dart';
import '../utils/http_client.dart';
import 'api_service.dart';

/// API Service cho Department Management  
/// Tương ứng với backend DepartmentController
/// Sử dụng Vietnam timezone (UTC+7) cho tất cả operations
class DepartmentApiService extends BaseApiService {
  static const String _endpoint = '/department';

  // ==================== READ OPERATIONS ====================

  /// GET /api/department - Lấy tất cả phòng ban
  /// Policy: [Authorize(Policy = "RequireHRRole")] - HR or Admin
  Future<ApiResponse<List<Department>>> getAllDepartments({bool includeInactive = false}) async {
    return handleListRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint?includeInactive=$includeInactive'),
        headers: await ApiConfig.getAuthenticatedHeaders(),
      ),
      (json) => Department.fromJson(json),
    );
  }

  /// GET /api/department/{id} - Lấy chi tiết phòng ban
  /// Policy: [Authorize] - Any authenticated user
  Future<ApiResponse<Department>> getDepartmentById(int id) async {
    return handleRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id'),
        headers: await ApiConfig.getAuthenticatedHeaders(),
      ),
      (json) => Department.fromJson(json),
    );
  }

  /// GET /api/department/dropdown - Lấy danh sách cho dropdown
  /// Policy: [AllowAnonymous] - For public use
  Future<ApiResponse<List<DropdownDepartment>>> getDepartmentsForDropdown() async {
    return handleListRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/dropdown'),
        headers: ApiConfig.headers,
      ),
      (json) => DropdownDepartment.fromJson(json),
    );
  }

  // ==================== CREATE OPERATION ====================

  /// POST /api/department - Tạo phòng ban mới
  /// Policy: [Authorize(Policy = "RequireAdminRole")] - Admin only
  Future<ApiResponse<CreateDepartmentResponse>> createDepartment(CreateDepartmentRequest request) async {
    return handleRequest(
      () async => CustomHttpClient.post(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint'),
        headers: await ApiConfig.getAuthenticatedHeaders(),
        body: json.encode(request.toJson()),
      ),
      (json) => CreateDepartmentResponse.fromJson(json),
    );
  }

  // ==================== UPDATE OPERATION ====================

  /// PUT /api/department/{id} - Cập nhật thông tin phòng ban
  /// Policy: [Authorize(Policy = "RequireAdminRole")] - Admin only
  Future<ApiResponse<UpdateDepartmentInfoResponse>> updateDepartment(int id, UpdateDepartmentInfoRequest request) async {
    return handleRequest(
      () async => CustomHttpClient.put(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id'),
        headers: await ApiConfig.getAuthenticatedHeaders(),
        body: json.encode(request.toJson()),
      ),
      (json) => UpdateDepartmentInfoResponse.fromJson(json),
    );
  }

  // ==================== DELETE OPERATIONS ====================

  /// DELETE /api/department/{id} - Xóa phòng ban (soft delete)
  /// Policy: [Authorize(Policy = "RequireAdminRole")] - Admin only
  Future<ApiResponse<DeleteDepartmentResponse>> deleteDepartment(int id, {String? reason}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id');
    final uriWithReason = reason != null 
        ? uri.replace(queryParameters: {'reason': reason})
        : uri;

    return handleRequest(
      () async => CustomHttpClient.delete(
        uriWithReason,
        headers: await ApiConfig.getAuthenticatedHeaders(),
      ),
      (json) => DeleteDepartmentResponse.fromJson(json),
    );
  }

  /// POST /api/department/{id}/restore - Khôi phục phòng ban
  /// Policy: [Authorize(Policy = "RequireAdminRole")] - Admin only
  Future<ApiResponse<RestoreDepartmentResponse>> restoreDepartment(int id, {String? reason}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id/restore');
    final uriWithReason = reason != null 
        ? uri.replace(queryParameters: {'reason': reason})
        : uri;

    return handleRequest(
      () async => CustomHttpClient.post(
        uriWithReason,
        headers: await ApiConfig.getAuthenticatedHeaders(),
      ),
      (json) => RestoreDepartmentResponse.fromJson(json),
    );
  }

  // ==================== STATISTICS & EMPLOYEES ====================

  /// GET /api/department/{id}/statistics - Lấy thống kê phòng ban
  /// Policy: [Authorize(Policy = "RequireHRRole")] - HR or Admin
  Future<ApiResponse<DepartmentStatistics>> getDepartmentStatistics(int id) async {
    return handleRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id/statistics'),
        headers: await ApiConfig.getAuthenticatedHeaders(),
      ),
      (json) => DepartmentStatistics.fromJson(json),
    );
  }

  /// GET /api/department/{id}/employees - Lấy nhân viên trong phòng ban
  /// Policy: [Authorize(Policy = "RequireHRRole")] - HR or Admin
  Future<ApiResponse<List<Employee>>> getDepartmentEmployees(int id, {bool includeInactive = false}) async {
    return handleListRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id/employees?includeInactive=$includeInactive'),
        headers: await ApiConfig.getAuthenticatedHeaders(),
      ),
      (json) => Employee.fromJson(json),
    );
  }

  // ==================== HEALTH CHECK ====================

  /// GET /api/department/health - Health check
  /// Policy: [AllowAnonymous]
  Future<ApiResponse<Map<String, dynamic>>> healthCheck() async {
    return handleRequest(
      () async => CustomHttpClient.get(
        Uri.parse('${ApiConfig.baseUrl}$_endpoint/health'),
        headers: ApiConfig.headers,
      ),
      (json) => json,
    );
  }
}
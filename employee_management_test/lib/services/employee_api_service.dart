import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/department.dart';
import '../models/employee.dart';
import '../models/dto/employee_dtos.dart';
import 'api_service.dart';

class EmployeeApiService extends BaseApiService {
  static const String _endpoint = '/employee';

  // ==================== DEPARTMENTS ====================

  /// GET /api/employee/departments
  /// Lấy danh sách tất cả phòng ban
  Future<ApiResponse<List<Department>>> getDepartments() async {
    final request = http.get(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/departments'),
      headers: ApiConfig.headers,
    );

    return handleListRequest(request, (json) => Department.fromJson(json));
  }

  // ==================== EMPLOYEE CRUD ====================

  /// POST /api/employee
  /// Tạo nhân viên mới (chưa có face)
  Future<ApiResponse<CreateEmployeeResponse>> createEmployee(CreateEmployeeRequest request) async {
    final httpRequest = http.post(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint'),
      headers: ApiConfig.headers,
      body: json.encode(request.toJson()),
    );

    return handleRequest(httpRequest, (json) => CreateEmployeeResponse.fromJson(json));
  }

  /// GET /api/employee
  /// Lấy danh sách tất cả nhân viên
  Future<ApiResponse<List<Employee>>> getAllEmployees() async {
    final request = http.get(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint'),
      headers: ApiConfig.headers,
    );

    return handleListRequest(request, (json) => Employee.fromJson(json));
  }

  /// GET /api/employee/{id}
  /// Lấy thông tin nhân viên theo ID
  Future<ApiResponse<Employee>> getEmployeeById(int id) async {
    final request = http.get(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/$id'),
      headers: ApiConfig.headers,
    );

    return handleRequest(request, (json) => Employee.fromJson(json));
  }

  /// GET /api/employee/department/{departmentId}
  /// Lấy danh sách nhân viên theo phòng ban
  Future<ApiResponse<List<Employee>>> getEmployeesByDepartment(int departmentId) async {
    final request = http.get(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/department/$departmentId'),
      headers: ApiConfig.headers,
    );

    return handleListRequest(request, (json) => Employee.fromJson(json));
  }

  // ==================== FACE REGISTRATION ====================

  /// POST /api/employee/register-face
  /// Đăng ký khuôn mặt cho nhân viên
  Future<ApiResponse<RegisterEmployeeFaceResponse>> registerFace(RegisterEmployeeFaceRequest request) async {
    final httpRequest = http.post(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/register-face'),
      headers: ApiConfig.headers,
      body: json.encode(request.toJson()),
    );

    return handleRequest(httpRequest, (json) => RegisterEmployeeFaceResponse.fromJson(json));
  }

  /// POST /api/employee/verify-face
  /// Verify khuôn mặt và chấm công (realtime)
  Future<ApiResponse<VerifyEmployeeFaceResponse>> verifyFace(VerifyFaceRequest request) async {
    final httpRequest = http.post(
      Uri.parse('${ApiConfig.baseUrl}$_endpoint/verify-face'),
      headers: ApiConfig.headers,
      body: json.encode(request.toJson()),
    );

    return handleRequest(httpRequest, (json) => VerifyEmployeeFaceResponse.fromJson(json));
  }
}
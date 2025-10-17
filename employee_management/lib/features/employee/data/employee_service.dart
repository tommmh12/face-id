import '../../../../core/api_client.dart';
import 'models/employee_model.dart';

class EmployeeService {
  final ApiClient _apiClient;

  EmployeeService(this._apiClient);

  // GET /api/Employee - Lấy tất cả nhân viên
  // API trả về array trực tiếp
  Future<List<Employee>> getAllEmployees() async {
    try {
      final response = await _apiClient.get('/api/Employee');
      
      if (response.containsKey('data') && response['data'] != null) {
        final data = response['data'];
        if (data is List) {
          return data.map((json) => Employee.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      print('ERROR getAllEmployees: $e');
      throw Exception('Không thể tải danh sách nhân viên: $e');
    }
  }

  // GET /api/Employee/{id} - Lấy thông tin nhân viên theo ID
  // API trả về object trực tiếp: {id, employeeCode, fullName, ...}
  Future<Employee> getEmployeeById(int id) async {
    try {
      final response = await _apiClient.get('/api/Employee/$id');
      
      // Response có thể là object trực tiếp hoặc wrapped trong {data: {...}}
      if (response.containsKey('data') && response['data'] is Map) {
        return Employee.fromJson(response['data'] as Map<String, dynamic>);
      }
      
      // Nếu response chính là employee object
      return Employee.fromJson(response);
    } catch (e) {
      print('ERROR getEmployeeById: $e');
      throw Exception('Không thể tải thông tin nhân viên: $e');
    }
  }

  // GET /api/Employee/department/{departmentId} - Lấy nhân viên theo phòng ban
  // API trả về array trực tiếp
  Future<List<Employee>> getEmployeesByDepartment(int departmentId) async {
    try {
      final response = await _apiClient.get('/api/Employee/department/$departmentId');
      
      if (response.containsKey('data') && response['data'] != null) {
        final data = response['data'];
        if (data is List) {
          return data.map((json) => Employee.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      print('ERROR getEmployeesByDepartment: $e');
      throw Exception('Không thể tải danh sách nhân viên: $e');
    }
  }

  // POST /api/Employee - Tạo nhân viên mới
  Future<Employee> createEmployee(CreateEmployeeRequest request) async {
    try {
      final response = await _apiClient.post(
        '/api/Employee',
        data: request.toJson(),
      );
      if (response['success'] == true && response['data'] != null) {
        return Employee.fromJson(response['data'] as Map<String, dynamic>);
      }
      throw Exception('Không thể tạo nhân viên');
    } catch (e) {
      throw Exception('Lỗi tạo nhân viên: $e');
    }
  }

  // POST /api/Employee/register-face - Đăng ký khuôn mặt
  Future<Map<String, dynamic>> registerFace(RegisterFaceRequest request) async {
    try {
      final response = await _apiClient.post(
        '/api/Employee/register-face',
        data: request.toJson(),
      );
      return response;
    } catch (e) {
      throw Exception('Lỗi đăng ký khuôn mặt: $e');
    }
  }

  // POST /api/Employee/verify-face - Xác thực khuôn mặt
  Future<Map<String, dynamic>> verifyFace(VerifyFaceRequest request) async {
    try {
      final response = await _apiClient.post(
        '/api/Employee/verify-face',
        data: request.toJson(),
      );
      return response;
    } catch (e) {
      throw Exception('Lỗi xác thực khuôn mặt: $e');
    }
  }
}

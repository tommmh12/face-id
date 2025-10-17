import '../../../../core/api_client.dart';
import 'models/department_model.dart';

class DepartmentService {
  final ApiClient _apiClient;

  DepartmentService(this._apiClient);

  // GET /api/Employee/departments - Lấy tất cả phòng ban
  // API trả về array trực tiếp: [{id, code, name, ...}, ...]
  Future<List<Department>> getAllDepartments() async {
    try {
      final response = await _apiClient.get('/api/Employee/departments');
      
      // Response đã được wrap trong _handleResponse thành {success: true, data: [...]}
      if (response.containsKey('data') && response['data'] != null) {
        final data = response['data'];
        
        if (data is List) {
          return data.map((json) => Department.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('ERROR getAllDepartments: $e');
      throw Exception('Không thể tải danh sách phòng ban: $e');
    }
  }
}

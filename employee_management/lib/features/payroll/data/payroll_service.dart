import '../../../../core/api_client.dart';
import 'models/payroll_model.dart';

class PayrollService {
  final ApiClient _apiClient;

  PayrollService(this._apiClient);

  // GET /api/Payroll/periods - Lấy tất cả kỳ lương
  // API trả về array trực tiếp
  Future<List<PayrollPeriod>> getAllPeriods() async {
    try {
      final response = await _apiClient.get('/api/Payroll/periods');
      
      if (response.containsKey('data') && response['data'] != null) {
        final data = response['data'];
        if (data is List) {
          return data.map((json) => PayrollPeriod.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      print('ERROR getAllPeriods: $e');
      throw Exception('Không thể tải danh sách kỳ lương: $e');
    }
  }

  // POST /api/Payroll/periods - Tạo kỳ lương mới
  // API trả về object trực tiếp
  Future<PayrollPeriod> createPeriod(CreatePayrollPeriodRequest request) async {
    try {
      final response = await _apiClient.post(
        '/api/Payroll/periods',
        data: request.toJson(),
      );
      
      // POST có thể trả về object trực tiếp hoặc wrapped
      if (response.containsKey('data') && response['data'] is Map) {
        return PayrollPeriod.fromJson(response['data'] as Map<String, dynamic>);
      }
      return PayrollPeriod.fromJson(response);
    } catch (e) {
      print('ERROR createPeriod: $e');
      throw Exception('Lỗi tạo kỳ lương: $e');
    }
  }

  // GET /api/Payroll/rules - Lấy tất cả quy tắc lương
  // API trả về array trực tiếp
  Future<List<PayrollRule>> getAllRules() async {
    try {
      final response = await _apiClient.get('/api/Payroll/rules');
      
      if (response.containsKey('data') && response['data'] != null) {
        final data = response['data'];
        if (data is List) {
          return data.map((json) => PayrollRule.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      print('ERROR getAllRules: $e');
      throw Exception('Không thể tải danh sách quy tắc lương: $e');
    }
  }

  // GET /api/Payroll/rules/employee/{employeeId} - Lấy quy tắc lương của nhân viên
  // API trả về object trực tiếp
  Future<PayrollRule?> getEmployeeRule(int employeeId) async {
    try {
      final response = await _apiClient.get('/api/Payroll/rules/employee/$employeeId');
      
      if (response.containsKey('data') && response['data'] is Map) {
        return PayrollRule.fromJson(response['data'] as Map<String, dynamic>);
      }
      return PayrollRule.fromJson(response);
    } catch (e) {
      print('ERROR getEmployeeRule: $e');
      return null; // Trả về null nếu không tìm thấy
    }
  }

  // POST /api/Payroll/rules - Tạo hoặc cập nhật quy tắc lương
  // API trả về object trực tiếp
  Future<PayrollRule> createOrUpdateRule(CreatePayrollRuleRequest request) async {
    try {
      final response = await _apiClient.post(
        '/api/Payroll/rules',
        data: request.toJson(),
      );
      
      if (response.containsKey('data') && response['data'] is Map) {
        return PayrollRule.fromJson(response['data'] as Map<String, dynamic>);
      }
      return PayrollRule.fromJson(response);
    } catch (e) {
      print('ERROR createOrUpdateRule: $e');
      throw Exception('Lỗi lưu quy tắc lương: $e');
    }
  }

  // GET /api/Payroll/allowances/employee/{employeeId} - Lấy phụ cấp của nhân viên
  // API trả về array trực tiếp
  Future<List<PayrollAllowance>> getEmployeeAllowances(int employeeId) async {
    try {
      final response = await _apiClient.get('/api/Payroll/allowances/employee/$employeeId');
      
      if (response.containsKey('data') && response['data'] != null) {
        final data = response['data'];
        if (data is List) {
          return data.map((json) => PayrollAllowance.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      print('ERROR getEmployeeAllowances: $e');
      throw Exception('Không thể tải danh sách phụ cấp: $e');
    }
  }

  // POST /api/Payroll/generate/{periodId} - Tạo bảng lương
  Future<Map<String, dynamic>> generatePayroll(int periodId) async {
    try {
      final response = await _apiClient.post('/api/Payroll/generate/$periodId');
      return response;
    } catch (e) {
      throw Exception('Lỗi tạo bảng lương: $e');
    }
  }

  // GET /api/Payroll/summary/{periodId} - Lấy tổng hợp lương
  // API trả về object có structure: {periodId, periodName, ..., records: [...]}
  Future<List<PayrollRecord>> getPayrollSummary(int periodId) async {
    try {
      final response = await _apiClient.get('/api/Payroll/summary/$periodId');
      
      // Nếu có key 'records' trong response
      if (response.containsKey('records') && response['records'] != null) {
        final data = response['records'];
        if (data is List) {
          return data.map((json) => PayrollRecord.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      
      // Nếu response wrapped trong {data: {records: [...]}}
      if (response.containsKey('data') && response['data'] is Map) {
        final dataMap = response['data'] as Map<String, dynamic>;
        if (dataMap.containsKey('records') && dataMap['records'] is List) {
          final records = dataMap['records'] as List;
          return records.map((json) => PayrollRecord.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('ERROR getPayrollSummary: $e');
      throw Exception('Không thể tải tổng hợp lương: $e');
    }
  }

  // GET /api/Payroll/records/period/{periodId}/employee/{employeeId}
  // API trả về object trực tiếp
  Future<PayrollRecord?> getEmployeePayrollRecord(int periodId, int employeeId) async {
    try {
      final response = await _apiClient.get(
        '/api/Payroll/records/period/$periodId/employee/$employeeId',
      );
      
      if (response.containsKey('data') && response['data'] is Map) {
        return PayrollRecord.fromJson(response['data'] as Map<String, dynamic>);
      }
      return PayrollRecord.fromJson(response);
    } catch (e) {
      print('ERROR getEmployeePayrollRecord: $e');
      return null; // Trả về null nếu không tìm thấy
    }
  }
}

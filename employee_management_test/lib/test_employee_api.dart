import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:employee_management_test/services/employee_api_service.dart';
import 'package:employee_management_test/models/employee.dart';
import 'package:employee_management_test/services/secure_storage_service.dart';
import 'package:employee_management_test/config/app_config.dart';

/// File test để kiểm tra API employee có hoạt động đúng không
///
/// Cách chạy:
/// 1. Thêm route trong main.dart: '/test/employee': (context) => TestEmployeeApiScreen(),
/// 2. Navigate đến màn hình này: Navigator.pushNamed(context, '/test/employee');
/// 3. Nhập employeeId và nhấn "Test API"
/// 4. Xem kết quả: API response raw và Employee object parsed

class TestEmployeeApiScreen extends StatefulWidget {
  const TestEmployeeApiScreen({Key? key}) : super(key: key);

  @override
  State<TestEmployeeApiScreen> createState() => _TestEmployeeApiScreenState();
}

class _TestEmployeeApiScreenState extends State<TestEmployeeApiScreen> {
  final EmployeeApiService _employeeService = EmployeeApiService();
  final TextEditingController _idController = TextEditingController(text: '23');

  String _apiResponse = '';
  Employee? _employee;
  bool _isLoading = false;
  String? _error;

  Future<void> _testApi() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _apiResponse = '';
      _employee = null;
    });

    try {
      final employeeId = int.parse(_idController.text);

      // Test API call với raw HTTP để xem response thật
      print('🔍 Testing API call for employee ID: $employeeId');

      // [DEBUG] Call trực tiếp HTTP để xem raw response
      final token = await SecureStorageService.readToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse('${AppConfig.baseUrl}/employee/$employeeId');
      print('📡 Request URL: $uri');
      print('🔐 Has Token: ${token != null && token.isNotEmpty}');

      final rawResponse = await http.get(uri, headers: headers);
      print('📥 Raw Response Status: ${rawResponse.statusCode}');
      print('📥 Raw Response Body: ${rawResponse.body}');

      // Call qua service để parse
      final response = await _employeeService.getEmployeeById(employeeId);

      print('✅ API Response received:');
      print('Success: ${response.success}');
      print('Message: ${response.message}');

      setState(() {
        _apiResponse =
            '=== RAW HTTP RESPONSE ===\n'
            'Status: ${rawResponse.statusCode}\n'
            'Body: ${rawResponse.body}\n\n'
            '=== PARSED RESPONSE ===\n'
            'Success: ${response.success}\n'
            'Message: ${response.message}\n'
            'Data: ${response.data?.toJson()}';

        if (response.success && response.data != null) {
          _employee = response.data;

          print('✅ Employee parsed successfully:');
          print('  - ID: ${_employee!.id}');
          print('  - Code: ${_employee!.employeeCode}');
          print('  - Name: ${_employee!.fullName}');
          print('  - Email: ${_employee!.email}');
          print('  - Phone: ${_employee!.phoneNumber}');
          print('  - Position: ${_employee!.position}');
        } else {
          _error = response.message ?? 'Không tìm thấy dữ liệu';
        }
      });
    } catch (e, stackTrace) {
      print('❌ Error testing API: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Employee API'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nhập Employee ID để test:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _idController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Employee ID',
                              hintText: 'Ví dụ: 23',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testApi,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Test API'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Error display
            if (_error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Lỗi:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_error!),
                    ],
                  ),
                ),
              ),

            // API Response
            if (_apiResponse.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📡 API Response (Raw):',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          _apiResponse,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Parsed Employee
            if (_employee != null)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            '✅ Employee Object (Parsed):',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('ID', _employee!.id.toString()),
                      _buildInfoRow('Mã NV', _employee!.employeeCode),
                      _buildInfoRow('Họ tên', _employee!.fullName),
                      _buildInfoRow('Email', _employee!.email ?? 'Chưa có'),
                      _buildInfoRow('SĐT', _employee!.phoneNumber ?? 'Chưa có'),
                      _buildInfoRow(
                        'Chức vụ',
                        _employee!.position ?? 'Chưa có',
                      ),
                      _buildInfoRow(
                        'Phòng ban ID',
                        _employee!.departmentId.toString(),
                      ),
                      _buildInfoRow(
                        'Trạng thái',
                        _employee!.isActive ? 'Đang làm việc' : 'Đã nghỉ',
                      ),
                      _buildInfoRow(
                        'Face ID',
                        _employee!.isFaceRegistered
                            ? 'Đã đăng ký'
                            : 'Chưa đăng ký',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: value.contains('Chưa có') ? Colors.red : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }
}

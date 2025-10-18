import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../models/department.dart';
import '../../services/employee_api_service.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final EmployeeApiService _employeeService = EmployeeApiService();
  List<Employee> _employees = [];
  List<Department> _departments = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load departments
      final departmentsResponse = await _employeeService.getDepartments();
      if (departmentsResponse.success && departmentsResponse.data != null) {
        _departments = departmentsResponse.data!;
      }

      // Load employees
      await _loadEmployees();
    } catch (e) {
      setState(() {
        _error = 'Lỗi tải dữ liệu: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final response = _selectedDepartmentId != null
          ? await _employeeService.getEmployeesByDepartment(_selectedDepartmentId!)
          : await _employeeService.getAllEmployees();

      if (response.success && response.data != null) {
        setState(() {
          _employees = response.data!;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Lỗi tải danh sách nhân viên';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối: ${e.toString()}';
      });
    }
  }

  String _getDepartmentName(int departmentId) {
    final department = _departments.firstWhere(
      (dept) => dept.id == departmentId,
      orElse: () => Department(
        id: -1,
        code: null,
        name: 'Unknown',
        createdAt: DateTime.now(),
        isActive: false,
      ),
    );
    return department.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh Sách Nhân Viên'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Department Filter
          if (_departments.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<int?>(
                initialValue: _selectedDepartmentId,
                decoration: const InputDecoration(
                  labelText: 'Lọc theo phòng ban',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Tất cả phòng ban'),
                  ),
                  ..._departments.map((dept) => DropdownMenuItem<int?>(
                        value: dept.id,
                        child: Text(dept.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedDepartmentId = value;
                  });
                  _loadEmployees();
                },
              ),
            ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _employees.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Không có nhân viên nào',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _employees.length,
                            itemBuilder: (context, index) {
                              final employee = _employees[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: employee.isFaceRegistered
                                        ? Colors.green
                                        : Colors.grey,
                                    child: Icon(
                                      employee.isFaceRegistered
                                          ? Icons.face
                                          : Icons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    employee.fullName,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Mã NV: ${employee.employeeCode}'),
                                      Text('Phòng ban: ${_getDepartmentName(employee.departmentId)}'),
                                      if (employee.position != null)
                                        Text('Chức vụ: ${employee.position}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!employee.isFaceRegistered)
                                        IconButton(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/face/register',
                                              arguments: employee,
                                            );
                                          },
                                          icon: const Icon(Icons.face_retouching_natural),
                                          tooltip: 'Đăng ký Face ID',
                                        ),
                                      Icon(
                                        employee.isActive
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: employee.isActive
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  onTap: () {
                                    // Navigate to employee detail screen
                                    Navigator.pushNamed(
                                      context,
                                      '/employee/detail',
                                      arguments: {'employeeId': employee.id},
                                    ).then((_) => _loadData());
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/employee/create').then((_) {
            // Refresh the list after creating a new employee
            _loadData();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
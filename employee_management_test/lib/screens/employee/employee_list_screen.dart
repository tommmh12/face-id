import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/employee.dart';
import '../../models/department.dart';
import '../../services/employee_api_service.dart';
import '../../providers/employee_provider.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final EmployeeApiService _employeeService = EmployeeApiService();
  List<Department> _departments = [];
  int? _selectedDepartmentId;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load departments
    try {
      final departmentsResponse = await _employeeService.getDepartments();
      if (departmentsResponse.success && departmentsResponse.data != null && mounted) {
        setState(() {
          _departments = departmentsResponse.data!;
        });
      }
    } catch (e) {
      debugPrint('Error loading departments: $e');
    }

    // Load employees using provider
    if (mounted) {
      Provider.of<EmployeeProvider>(context, listen: false)
          .fetchEmployees(_showInactive);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quản lý nhân viên',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Danh sách tất cả nhân viên',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                Provider.of<EmployeeProvider>(context, listen: false)
                    .refreshEmployees(_showInactive);
              },
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: Consumer<EmployeeProvider>(
              builder: (context, employeeProvider, child) {
                if (employeeProvider.isLoading) {
                  return _buildLoadingState();
                }

                if (employeeProvider.error != null) {
                  return _buildErrorState(employeeProvider.error!);
                }

                final employees = _getFilteredEmployees(employeeProvider.employees);

                if (employees.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildEmployeeList(employees);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/employee/create').then((_) {
            Provider.of<EmployeeProvider>(context, listen: false)
                .refreshEmployees(_showInactive);
          });
        },
        backgroundColor: const Color(0xFF1E88E5),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Thêm nhân viên',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _selectedDepartmentId,
                  decoration: InputDecoration(
                    labelText: 'Phòng ban',
                    prefixIcon: const Icon(Icons.business_rounded, color: Color(0xFF1E88E5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E4E7)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E4E7)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFF),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  color: _showInactive ? const Color(0xFF1E88E5) : const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E88E5)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _showInactive = !_showInactive;
                      });
                      Provider.of<EmployeeProvider>(context, listen: false)
                          .fetchEmployees(_showInactive);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showInactive ? Icons.visibility_off : Icons.visibility,
                            color: _showInactive ? Colors.white : const Color(0xFF1E88E5),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _showInactive ? 'Ẩn nghỉ việc' : 'Hiện nghỉ việc',
                            style: TextStyle(
                              color: _showInactive ? Colors.white : const Color(0xFF1E88E5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Employee> _getFilteredEmployees(List<Employee> employees) {
    return employees.where((employee) {
      if (_selectedDepartmentId != null && employee.departmentId != _selectedDepartmentId) {
        return false;
      }
      return true;
    }).toList();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
          ),
          SizedBox(height: 16),
          Text(
            'Đang tải danh sách nhân viên...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade400,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Provider.of<EmployeeProvider>(context, listen: false)
                  .refreshEmployees(_showInactive);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E4E7)),
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              color: Color(0xFF1E88E5),
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có nhân viên nào',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thêm nhân viên đầu tiên để bắt đầu',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/employee/create').then((_) {
                Provider.of<EmployeeProvider>(context, listen: false)
                    .refreshEmployees(_showInactive);
              });
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm nhân viên'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList(List<Employee> employees) {
    return RefreshIndicator(
      color: const Color(0xFF1E88E5),
      onRefresh: () async {
        await Provider.of<EmployeeProvider>(context, listen: false)
            .refreshEmployees(_showInactive);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: employees.length,
        itemBuilder: (context, index) {
          final employee = employees[index];
          return _buildEmployeeCard(employee);
        },
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/employee/detail',
              arguments: {'employeeId': employee.id},
            ).then((_) {
              Provider.of<EmployeeProvider>(context, listen: false)
                  .refreshEmployees(_showInactive);
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildEmployeeAvatar(employee),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEmployeeInfo(employee),
                ),
                const SizedBox(width: 12),
                _buildEmployeeStatus(employee),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeAvatar(Employee employee) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          employee.fullName.isNotEmpty ? employee.fullName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeInfo(Employee employee) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          employee.fullName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          employee.employeeCode,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1E88E5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.business_rounded,
              size: 14,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _getDepartmentName(employee.departmentId),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmployeeStatus(Employee employee) {
    final statusInfo = _getStatusInfo(employee);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: statusInfo['color'],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: statusInfo['color'].withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          statusInfo['text'],
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getStatusInfo(Employee employee) {
    switch (employee.currentStatus?.toLowerCase()) {
      case 'working':
        return {
          'color': Colors.green,
          'text': 'Làm việc',
        };
      case 'on_break':
        return {
          'color': Colors.orange,
          'text': 'Nghỉ giải lao',
        };
      case 'offline':
        return {
          'color': Colors.grey,
          'text': 'Offline',
        };
      default:
        return {
          'color': const Color.fromARGB(255, 247, 0, 255),
          'text': 'Không xác định',
        };
    }
  }

  String _getDepartmentName(int? departmentId) {
    if (departmentId == null) return 'Chưa phân công';
    
    final department = _departments.firstWhere(
      (dept) => dept.id == departmentId,
      orElse: () => Department(
        id: 0, 
        name: 'Không xác định', 
        description: '', 
        createdAt: DateTime.now(), 
        isActive: true
      ),
    );
    
    return department.name;
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../../../core/app_routes.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../data/department_service.dart';
import '../data/models/department_model.dart';
import '../../employee/data/employee_service.dart';

class DepartmentPage extends StatefulWidget {
  const DepartmentPage({super.key});

  @override
  State<DepartmentPage> createState() => _DepartmentPageState();
}

class _DepartmentPageState extends State<DepartmentPage> {
  final ApiClient _apiClient = ApiClient();
  late final DepartmentService _departmentService;
  late final EmployeeService _employeeService;

  List<Department> _departments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _departmentService = DepartmentService(_apiClient);
    _employeeService = EmployeeService(_apiClient);
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final departments = await _departmentService.getAllDepartments();
      setState(() {
        _departments = departments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách phòng ban'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDepartments,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Đang tải danh sách phòng ban...');
    }

    if (_error != null) {
      return ErrorStateWidget(
        message: _error!,
        onRetry: _loadDepartments,
      );
    }

    if (_departments.isEmpty) {
      return const EmptyWidget(
        icon: Icons.business_outlined,
        message: 'Không có phòng ban nào',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDepartments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _departments.length,
        itemBuilder: (context, index) {
          final department = _departments[index];
          return _buildDepartmentCard(department);
        },
      ),
    );
  }

  Widget _buildDepartmentCard(Department department) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.business,
            color: AppTheme.primaryBlue,
          ),
        ),
        title: Text(
          department.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mã: ${department.code}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people, size: 14, color: AppTheme.darkGray),
                const SizedBox(width: 4),
                Text(
                  '${department.employeeCount} nhân viên',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (department.description != null) ...[
                  const Text(
                    'Mô tả:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    department.description!,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _viewDepartmentEmployees(department),
                    icon: const Icon(Icons.people),
                    label: const Text('Xem danh sách nhân viên'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewDepartmentEmployees(Department department) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final employees = await _employeeService.getEmployeesByDepartment(department.id);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Nhân viên - ${department.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: employees.isEmpty
                ? const Center(
                    child: Text('Chưa có nhân viên nào trong phòng ban này'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      final emp = employees[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(emp.fullName[0]),
                        ),
                        title: Text(emp.fullName),
                        subtitle: Text(emp.employeeCode),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            AppRoutes.employeeDetail,
                            arguments: emp.id,
                          );
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
}

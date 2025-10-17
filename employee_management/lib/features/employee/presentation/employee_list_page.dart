import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/app_routes.dart';
import '../../../core/api_client.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../data/employee_service.dart';
import '../data/models/employee_model.dart';
import '../../department/data/department_service.dart';
import '../../department/data/models/department_model.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  final ApiClient _apiClient = ApiClient();
  late final EmployeeService _employeeService;
  late final DepartmentService _departmentService;

  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  List<Department> _departments = [];
  
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  int? _selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    _employeeService = EmployeeService(_apiClient);
    _departmentService = DepartmentService(_apiClient);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _employeeService.getAllEmployees(),
        _departmentService.getAllDepartments(),
      ]);

      setState(() {
        _employees = results[0] as List<Employee>;
        _departments = results[1] as List<Department>;
        _filteredEmployees = _employees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterEmployees() {
    setState(() {
      _filteredEmployees = _employees.where((emp) {
        final matchesSearch = _searchQuery.isEmpty ||
            emp.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            emp.employeeCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (emp.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

        final matchesDepartment = _selectedDepartmentId == null ||
            emp.departmentId == _selectedDepartmentId;

        return matchesSearch && matchesDepartment;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách nhân viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEmployeeDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm nhân viên'),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm theo tên, mã, email...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _filterEmployees();
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              decoration: const InputDecoration(
                labelText: 'Lọc theo phòng ban',
                border: OutlineInputBorder(),
              ),
              value: _selectedDepartmentId,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Tất cả phòng ban'),
                ),
                ..._departments.map((dept) => DropdownMenuItem(
                      value: dept.id,
                      child: Text(dept.name),
                    )),
              ],
              onChanged: (value) {
                setState(() => _selectedDepartmentId = value);
                _filterEmployees();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Đang tải danh sách nhân viên...');
    }

    if (_error != null) {
      return ErrorStateWidget(
        message: _error!,
        onRetry: _loadData,
      );
    }

    if (_filteredEmployees.isEmpty) {
      return const EmptyWidget(
        icon: Icons.people_outline,
        message: 'Không tìm thấy nhân viên nào',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredEmployees.length,
        itemBuilder: (context, index) {
          final employee = _filteredEmployees[index];
          return _buildEmployeeCard(employee);
        },
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
          child: employee.faceImageUrl != null
              ? ClipOval(
                  child: Image.network(
                    employee.faceImageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person,
                        color: AppTheme.primaryBlue,
                        size: 32,
                      );
                    },
                  ),
                )
              : const Icon(
                  Icons.person,
                  color: AppTheme.primaryBlue,
                  size: 32,
                ),
        ),
        title: Text(
          employee.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Mã: ${employee.employeeCode}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              employee.departmentName ?? 'N/A',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            StatusBadge(isActive: employee.isActive),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          await Navigator.pushNamed(
            context,
            AppRoutes.employeeDetail,
            arguments: employee.id,
          );
          _loadData();
        },
      ),
    );
  }

  void _showAddEmployeeDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEmployeeDialog(
        departments: _departments,
        onSuccess: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }
}

class AddEmployeeDialog extends StatefulWidget {
  final List<Department> departments;
  final VoidCallback onSuccess;

  const AddEmployeeDialog({
    super.key,
    required this.departments,
    required this.onSuccess,
  });

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _employeeCodeController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();
  
  int? _selectedDepartmentId;
  DateTime? _dateOfBirth;
  DateTime? _joinDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _employeeCodeController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phòng ban')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ApiClient();
      final employeeService = EmployeeService(apiClient);

      final request = CreateEmployeeRequest(
        fullName: _fullNameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        departmentId: _selectedDepartmentId!,
        position: _positionController.text.isNotEmpty ? _positionController.text : null,
        dateOfBirth: _dateOfBirth,
        joinDate: _joinDate ?? DateTime.now(),
      );

      await employeeService.createEmployee(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo nhân viên thành công!')),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm nhân viên mới'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Vui lòng nhập email';
                  if (!value!.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Phòng ban *',
                  border: OutlineInputBorder(),
                ),
                value: _selectedDepartmentId,
                items: widget.departments
                    .map((dept) => DropdownMenuItem(
                          value: dept.id,
                          child: Text(dept.name),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedDepartmentId = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Chức vụ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Tạo mới'),
        ),
      ],
    );
  }
}

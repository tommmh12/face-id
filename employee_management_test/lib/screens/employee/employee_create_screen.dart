import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/department.dart';
import '../../models/dto/employee_dtos.dart';
import '../../services/employee_api_service.dart';

class EmployeeCreateScreen extends StatefulWidget {
  const EmployeeCreateScreen({super.key});

  @override
  State<EmployeeCreateScreen> createState() => _EmployeeCreateScreenState();
}

class _EmployeeCreateScreenState extends State<EmployeeCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final EmployeeApiService _employeeService = EmployeeApiService();

  // Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();

  // Form data
  List<Department> _departments = [];
  int? _selectedDepartmentId;
  DateTime? _selectedDateOfBirth;
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _employeeService.getDepartments();
      if (response.success && response.data != null) {
        setState(() {
          _departments = response.data!;
        });
      } else {
        _showErrorSnackBar('Lỗi tải danh sách phòng ban: ${response.message}');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi kết nối: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedDepartmentId == null) {
      if (_selectedDepartmentId == null) {
        _showErrorSnackBar('Vui lòng chọn phòng ban');
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = CreateEmployeeRequest(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        departmentId: _selectedDepartmentId!,
        position: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
      );

      final response = await _employeeService.createEmployee(request);

      if (response.success && response.data != null) {
        _showSuccessDialog(response.data!);
      } else {
        _showErrorSnackBar(response.message ?? 'Lỗi tạo nhân viên');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi kết nối: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSuccessDialog(CreateEmployeeResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Thành Công'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nhân viên đã được tạo thành công!'),
            const SizedBox(height: 8),
            if (response.employeeCode != null)
              Text(
                'Mã nhân viên: ${response.employeeCode}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to list
            },
            child: const Text('Quay lại danh sách'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _resetForm(); // Reset form for new entry
            },
            child: const Text('Tạo nhân viên khác'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _fullNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _positionController.clear();
    setState(() {
      _selectedDepartmentId = null;
      _selectedDateOfBirth = null;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Nhân Viên Mới'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập họ và tên';
                        }
                        if (value.trim().length < 2) {
                          return 'Họ và tên phải có ít nhất 2 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Email không hợp lệ';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
                            return 'Số điện thoại không hợp lệ (10-11 số)';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Department
                    DropdownButtonFormField<int>(
                      initialValue: _selectedDepartmentId,
                      decoration: const InputDecoration(
                        labelText: 'Phòng ban *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      items: _departments.map((dept) => DropdownMenuItem<int>(
                        value: dept.id,
                        child: Text('${dept.code} - ${dept.name}'),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDepartmentId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Vui lòng chọn phòng ban';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Position
                    TextFormField(
                      controller: _positionController,
                      decoration: const InputDecoration(
                        labelText: 'Chức vụ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth
                    InkWell(
                      onTap: _selectDateOfBirth,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày sinh',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDateOfBirth != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedDateOfBirth!)
                              : 'Chọn ngày sinh',
                          style: TextStyle(
                            color: _selectedDateOfBirth != null
                                ? Theme.of(context).textTheme.bodyLarge?.color
                                : Theme.of(context).hintColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Tạo Nhân Viên',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    super.dispose();
  }
}
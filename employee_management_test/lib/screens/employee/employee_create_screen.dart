import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/department.dart';
import '../../models/dto/employee_dtos.dart';
import '../../services/employee_api_service.dart';
import '../../config/app_theme.dart';

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
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // 18 years ago
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
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        departmentId: _selectedDepartmentId!,
        position: _positionController.text.trim().isEmpty
            ? null
            : _positionController.text.trim(),
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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: const Text(
          'Tạo Nhân Viên Mới',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryBlue,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryBlue,
                            AppColors.primaryDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.large,
                        ),
                        boxShadow: AppShadows.medium,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.medium,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_add,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thêm nhân viên mới',
                                  style: AppTextStyles.h3.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Điền thông tin cơ bản',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // Full Name
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Họ và tên *',
                      icon: Icons.person,
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
                    const SizedBox(height: AppSpacing.lg),

                    // Email
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Email không hợp lệ';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Phone Number
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value)) {
                            return 'Số điện thoại không hợp lệ (10-11 số)';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Department
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.medium,
                        ),
                        boxShadow: AppShadows.small,
                      ),
                      child: DropdownButtonFormField<int>(
                        value: _selectedDepartmentId,
                        decoration: const InputDecoration(
                          labelText: 'Phòng ban *',
                          prefixIcon: Icon(
                            Icons.business,
                            color: AppColors.primaryBlue,
                          ),
                          border: InputBorder.none,
                        ),
                        items: _departments
                            .map(
                              (dept) => DropdownMenuItem<int>(
                                value: dept.id,
                                child: Text('${dept.code} - ${dept.name}'),
                              ),
                            )
                            .toList(),
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
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Position
                    _buildTextField(
                      controller: _positionController,
                      label: 'Chức vụ',
                      icon: Icons.work,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Date of Birth
                    InkWell(
                      onTap: _selectDateOfBirth,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.medium,
                          ),
                          boxShadow: AppShadows.small,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ngày sinh',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedDateOfBirth != null
                                        ? DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(_selectedDateOfBirth!)
                                        : 'Chọn ngày sinh',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: _selectedDateOfBirth != null
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),

                    // Submit Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryBlue,
                            AppColors.primaryDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.medium,
                        ),
                        boxShadow: AppShadows.medium,
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.medium,
                            ),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_circle),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tạo Nhân Viên',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryBlue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: const BorderSide(color: AppColors.errorColor, width: 2),
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

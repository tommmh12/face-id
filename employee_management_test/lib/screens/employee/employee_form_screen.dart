import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../models/department.dart';
import '../../services/employee_api_service.dart';
import '../../config/app_theme.dart';
import '../../models/dto/employee_dtos.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Employee? employee; // Null = Create, Not null = Edit

  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final EmployeeApiService _employeeService = EmployeeApiService();

  // Form controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();

  // State
  int? _selectedDepartmentId;
  DateTime? _dateOfBirth;
  DateTime? _joinDate;
  bool _isActive = true;
  bool _isLoading = false;
  List<Department> _departments = [];

  bool get isEditMode => widget.employee != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _populateForm();
    } else {
      _joinDate = DateTime.now();
    }
    _loadDepartments();
  }

  void _populateForm() {
    final emp = widget.employee!;
    _fullNameController.text = emp.fullName;
    _emailController.text = emp.email ?? '';
    _phoneController.text = emp.phoneNumber ?? '';
    _positionController.text = emp.position ?? '';
    _selectedDepartmentId = emp.departmentId;
    _dateOfBirth = emp.dateOfBirth;
    _joinDate = emp.joinDate;
    _isActive = emp.isActive;
  }

  Future<void> _loadDepartments() async {
    try {
      final response = await _employeeService.getDepartments();
      if (response.success && response.data != null && mounted) {
        setState(() {
          _departments = response.data!;
          
          // Validate and fix _selectedDepartmentId
          if (_selectedDepartmentId != null) {
            // Check if selected department exists in the list
            final exists = _departments.any((dept) => dept.id == _selectedDepartmentId);
            if (!exists) {
              _selectedDepartmentId = null; // Reset if not found
            }
          }
          
          // Set default department if not set and list is not empty
          if (_selectedDepartmentId == null && _departments.isNotEmpty) {
            _selectedDepartmentId = _departments.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải phòng ban: $e')));
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isJoinDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isJoinDate
          ? (_joinDate ?? DateTime.now())
          : (_dateOfBirth ??
                DateTime.now().subtract(const Duration(days: 365 * 25))),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isJoinDate) {
          _joinDate = picked;
        } else {
          _dateOfBirth = picked;
        }
      });
    }
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn phòng ban')));
      return;
    }

    setState(() {
      _isLoading = true;
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
        dateOfBirth: _dateOfBirth,
      );

      final response = await _employeeService.createEmployee(request);

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditMode
                  ? 'Cập nhật thành công!'
                  : 'Thêm nhân viên thành công!',
            ),
            backgroundColor: AppColors.successColor,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Có lỗi xảy ra'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Chỉnh Sửa Nhân Viên' : 'Thêm Nhân Viên',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.large),
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
                      child: Icon(
                        isEditMode ? Icons.edit : Icons.person_add,
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
                            isEditMode
                                ? 'Cập nhật thông tin'
                                : 'Thêm nhân viên mới',
                            style: AppTextStyles.h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEditMode
                                ? 'Chỉnh sửa thông tin nhân viên'
                                : 'Điền thông tin nhân viên mới',
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
                label: 'Họ tên',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập họ tên';
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

              // Phone
              _buildTextField(
                controller: _phoneController,
                label: 'Số điện thoại',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Position
              _buildTextField(
                controller: _positionController,
                label: 'Chức vụ',
                icon: Icons.work,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Department Dropdown
              _buildDepartmentDropdown(),
              const SizedBox(height: AppSpacing.lg),

              // Date of Birth
              _buildDateField(
                label: 'Ngày sinh',
                date: _dateOfBirth,
                onTap: () => _selectDate(context, false),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Join Date
              _buildDateField(
                label: 'Ngày vào làm',
                date: _joinDate,
                onTap: () => _selectDate(context, true),
                isRequired: true,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Active Status
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  boxShadow: AppShadows.small,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.toggle_on, color: AppColors.primaryBlue),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Trạng thái hoạt động',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: AppColors.primaryBlue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // Save Button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  boxShadow: AppShadows.medium,
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveEmployee,
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
                  child: _isLoading
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
                            Icon(isEditMode ? Icons.check : Icons.add_circle),
                            const SizedBox(width: 8),
                            Text(
                              isEditMode
                                  ? 'Cập Nhật Thông Tin'
                                  : 'Thêm Nhân Viên',
                              style: const TextStyle(
                                fontSize: 16,
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

  Widget _buildDepartmentDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        boxShadow: AppShadows.small,
      ),
      child: DropdownButtonFormField<int>(
        value: _departments.any((dept) => dept.id == _selectedDepartmentId) 
            ? _selectedDepartmentId 
            : null,
        decoration: const InputDecoration(
          labelText: 'Phòng ban',
          prefixIcon: Icon(Icons.business, color: AppColors.primaryBlue),
          border: InputBorder.none,
        ),
        items: _departments.map((dept) {
          return DropdownMenuItem(value: dept.id, child: Text(dept.name));
        }).toList(),
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
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    bool isRequired = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          boxShadow: AppShadows.small,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label + (isRequired ? ' *' : ''),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Chọn ngày',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: date != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

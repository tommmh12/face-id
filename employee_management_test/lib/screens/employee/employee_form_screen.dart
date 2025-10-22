import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../models/department.dart';
import '../../services/employee_api_service.dart';
import '../../config/app_theme.dart';
import '../../models/dto/employee_dtos.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Employee? employee; // null => create, not null => edit
  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeService = EmployeeApiService();

  // Controllers
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
    if (isEditMode) _fillFormData();
    _joinDate ??= DateTime.now();
    _loadDepartments();
  }

  void _fillFormData() {
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
      final res = await _employeeService.getDepartments();
      if (!mounted) return;
      if (res.success && res.data != null) {
        setState(() {
          _departments = res.data!;
          _selectedDepartmentId ??=
              _departments.isNotEmpty ? _departments.first.id : null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải phòng ban: $e')),
        );
      }
    }
  }

  Future<void> _pickDate(BuildContext context, bool isJoinDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isJoinDate
          ? (_joinDate ?? DateTime.now())
          : (_dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25))),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryBlue),
        ),
        child: child!,
      ),
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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phòng ban')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final req = CreateEmployeeRequest(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        departmentId: _selectedDepartmentId!,
        position: _positionController.text.trim().isEmpty ? null : _positionController.text.trim(),
        dateOfBirth: _dateOfBirth,
      );

      final res = await (isEditMode
          ? _employeeService.updateEmployee(widget.employee!.id, req)
          : _employeeService.createEmployee(req));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? (isEditMode ? 'Cập nhật thành công' : 'Thêm nhân viên thành công')),
          backgroundColor:
              res.success ? AppColors.successColor : AppColors.errorColor,
        ),
      );

      if (res.success) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    return Stack(
      children: [
        Scaffold(
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
                  _buildHeaderCard(),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Họ tên',
                    icon: Icons.person,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Vui lòng nhập họ tên' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(v)) {
                          return 'Email không hợp lệ';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Số điện thoại',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v != null && v.isNotEmpty && !RegExp(r'^[0-9]{9,11}$').hasMatch(v)) {
                        return 'Số điện thoại không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTextField(
                    controller: _positionController,
                    label: 'Chức vụ',
                    icon: Icons.work,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDepartmentDropdown(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDateField(
                    label: 'Ngày sinh',
                    date: _dateOfBirth,
                    onTap: () => _pickDate(context, false),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDateField(
                    label: 'Ngày vào làm',
                    date: _joinDate,
                    onTap: () => _pickDate(context, true),
                    isRequired: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildActiveSwitch(),
                  const SizedBox(height: AppSpacing.xxxl),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),

        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Container(
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
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
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
                  isEditMode ? 'Cập nhật thông tin' : 'Thêm nhân viên mới',
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
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
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
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedDepartmentId,
      items: _departments
          .map((dept) => DropdownMenuItem(value: dept.id, child: Text(dept.name)))
          .toList(),
      decoration: InputDecoration(
        labelText: 'Phòng ban',
        prefixIcon: const Icon(Icons.business, color: AppColors.primaryBlue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (v) => setState(() => _selectedDepartmentId = v),
      validator: (v) => v == null ? 'Vui lòng chọn phòng ban' : null,
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
                  Text('$label${isRequired ? " *" : ""}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
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

  Widget _buildActiveSwitch() => Container(
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
              child: Text('Trạng thái hoạt động',
                  style: AppTextStyles.bodyMedium),
            ),
            Switch(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              activeColor: AppColors.primaryBlue,
            ),
          ],
        ),
      );

  Widget _buildSaveButton() => ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveEmployee,
        icon: Icon(isEditMode ? Icons.check : Icons.add_circle),
        label: Text(
          isEditMode ? 'Cập nhật thông tin' : 'Thêm nhân viên',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          ),
        ),
      );
}

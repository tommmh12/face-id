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
  final _employeeService = EmployeeApiService();

  // Controllers
  final _controllers = {
    'fullName': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'position': TextEditingController(),
  };

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

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ==========================================================
  // 🏢 Load danh sách phòng ban
  // ==========================================================
  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);

    try {
      final response = await _employeeService.getDepartments();
      if (response.success && response.data != null && mounted) {
        setState(() => _departments = response.data!);
      } else {
        _showSnackBar('Lỗi tải danh sách phòng ban: ${response.message}', true);
      }
    } catch (e) {
      _showSnackBar('Lỗi kết nối: ${e.toString()}', true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================================
  // 📅 Chọn ngày sinh
  // ==========================================================
  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() => _selectedDateOfBirth = picked);
    }
  }

  // ==========================================================
  // 💾 Submit form
  // ==========================================================
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDepartmentId == null) {
      _showSnackBar('Vui lòng chọn phòng ban', true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = CreateEmployeeRequest(
        fullName: _controllers['fullName']!.text.trim(),
        email: _controllers['email']!.text.trim().isEmpty
            ? null
            : _controllers['email']!.text.trim(),
        phoneNumber: _controllers['phone']!.text.trim().isEmpty
            ? null
            : _controllers['phone']!.text.trim(),
        departmentId: _selectedDepartmentId!,
        position: _controllers['position']!.text.trim().isEmpty
            ? null
            : _controllers['position']!.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
      );

      final response = await _employeeService.createEmployee(request);

      if (response.success && response.data != null) {
        _showSuccessDialog(response.data!);
      } else {
        _showSnackBar(response.message ?? 'Lỗi tạo nhân viên', true);
      }
    } catch (e) {
      _showSnackBar('Lỗi kết nối: ${e.toString()}', true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ==========================================================
  // ✅ Dialog khi tạo thành công
  // ==========================================================
  void _showSuccessDialog(CreateEmployeeResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Thành công'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhân viên đã được tạo thành công!'),
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
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Quay lại danh sách'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            label: const Text('Tạo nhân viên khác'),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 🧹 Reset form
  // ==========================================================
  void _resetForm() {
    _formKey.currentState?.reset();
    for (final controller in _controllers.values) {
      controller.clear();
    }
    setState(() {
      _selectedDepartmentId = null;
      _selectedDateOfBirth = null;
    });
  }

  // ==========================================================
  // ⚠️ Hiển thị snackbar
  // ==========================================================
  void _showSnackBar(String message, [bool isError = false]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // ==========================================================
  // 🧱 UI Build
  // ==========================================================
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
                valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
              ),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildTextField(
                        controller: _controllers['fullName']!,
                        label: 'Họ và tên *',
                        icon: Icons.person,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Vui lòng nhập họ và tên'
                            : (v.trim().length < 2
                                ? 'Họ và tên phải có ít nhất 2 ký tự'
                                : null),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _controllers['email']!,
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
                        controller: _controllers['phone']!,
                        label: 'Số điện thoại',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            if (!RegExp(r'^[0-9]{10,11}$').hasMatch(v)) {
                              return 'Số điện thoại không hợp lệ (10-11 số)';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildDepartmentDropdown(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildTextField(
                        controller: _controllers['position']!,
                        label: 'Chức vụ',
                        icon: Icons.work,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildDatePicker(),
                      const SizedBox(height: AppSpacing.xxxl),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ==========================================================
  // 🎨 UI Components
  // ==========================================================

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.gradientSoftBlue,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(AppBorderRadius.large),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded, 
                  color: Colors.white, 
                  size: 36,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thêm Nhân Viên Mới',
                      style: AppTextStyles.h3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppBorderRadius.rounded),
                      ),
                      child: Text(
                        'Điền thông tin cơ bản',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Progress indicator or steps
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Sau khi tạo, bạn có thể đăng ký Face ID cho nhân viên',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        boxShadow: AppShadows.small,
        border: Border.all(
          color: AppColors.borderLight,
          width: 1.5,
        ),
      ),
      child: DropdownButtonFormField<int>(
        value: _selectedDepartmentId,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: 'Phòng ban *',
          labelStyle: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.gradientSoftTeal,
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.small),
            ),
            child: const Icon(
              Icons.business_rounded, 
              color: Colors.white,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
        ),
        dropdownColor: Colors.white,
        items: _departments
            .map(
              (dept) => DropdownMenuItem<int>(
                value: dept.id,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppColors.gradientSoftTeal,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${dept.code} - ${dept.name}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => _selectedDepartmentId = value),
        validator: (value) =>
            value == null ? 'Vui lòng chọn phòng ban' : null,
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: AppShadows.small,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectDateOfBirth,
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppBorderRadius.large),
              border: Border.all(
                color: _selectedDateOfBirth != null 
                    ? AppColors.primaryBlue.withOpacity(0.3)
                    : AppColors.borderLight,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _selectedDateOfBirth != null
                          ? AppColors.gradientSoftGreen
                          : [
                              AppColors.textTertiary.withOpacity(0.3),
                              AppColors.textTertiary.withOpacity(0.5),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded, 
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ngày sinh',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _selectedDateOfBirth != null
                            ? DateFormat('EEEE, dd/MM/yyyy', 'vi_VN')
                                .format(_selectedDateOfBirth!)
                            : 'Chọn ngày sinh của nhân viên',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _selectedDateOfBirth != null
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          fontWeight: _selectedDateOfBirth != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  ),
                  child: Icon(
                    Icons.arrow_drop_down_rounded, 
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.gradientSoftGreen,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        boxShadow: [
          BoxShadow(
            color: AppColors.successColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
          ),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Đang tạo nhân viên...',
                    style: AppTextStyles.buttonLarge.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(AppBorderRadius.small),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Tạo Nhân Viên',
                    style: AppTextStyles.buttonLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
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
    return Container(
      decoration: BoxDecoration(
        boxShadow: AppShadows.small,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.gradientSoftBlue,
              ),
              borderRadius: BorderRadius.circular(AppBorderRadius.small),
            ),
            child: Icon(
              icon, 
              color: Colors.white,
              size: 20,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
            borderSide: BorderSide(
              color: AppColors.borderLight,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
            borderSide: BorderSide(
              color: AppColors.primaryBlue,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
            borderSide: BorderSide(
              color: AppColors.errorColor,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
            borderSide: BorderSide(
              color: AppColors.errorColor,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

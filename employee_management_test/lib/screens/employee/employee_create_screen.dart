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
            child: const Icon(Icons.person_add, color: Colors.white, size: 32),
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
                  'Điền thông tin cơ bản bên dưới',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        boxShadow: AppShadows.small,
      ),
      child: DropdownButtonFormField<int>(
        value: _selectedDepartmentId,
        decoration: const InputDecoration(
          labelText: 'Phòng ban *',
          prefixIcon: Icon(Icons.business, color: AppColors.primaryBlue),
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
        onChanged: (value) => setState(() => _selectedDepartmentId = value),
        validator: (value) =>
            value == null ? 'Vui lòng chọn phòng ban' : null,
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDateOfBirth,
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
                  Text('Ngày sinh',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    _selectedDateOfBirth != null
                        ? DateFormat('dd/MM/yyyy')
                            .format(_selectedDateOfBirth!)
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
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        boxShadow: AppShadows.medium,
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_alt_1),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employee.dart';
import '../../models/dto/payroll_dtos.dart';
import '../../services/employee_api_service.dart';
import '../../services/payroll_api_service.dart';
import '../../config/app_theme.dart';
import '../payroll/widgets/edit_adjustment_dialog.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final int employeeId;

  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  final EmployeeApiService _employeeService = EmployeeApiService();
  final PayrollApiService _payrollService = PayrollApiService();
  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  Employee? _employee;
  List<SalaryAdjustmentResponse> _salaryAdjustments = [];
  PayrollRecordResponse? _currentPayroll;
  bool _isLoading = true;
  bool _isLoadingAdjustments = false;
  bool _isLoadingPayroll = false;
  String? _error;

  /// Safe currency formatting với error handling
  String _safeCurrencyFormat(dynamic value) {
    try {
      if (value == null) return '₫0';

      final double amount = value is double
          ? value
          : double.tryParse(value.toString()) ?? 0.0;
      return _currencyFormat.format(amount);
    } catch (e) {
      debugPrint('Currency format error: $e');
      return '₫0';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadEmployeeDetails();
  }

  Future<void> _loadEmployeeDetails() async {
    if (!mounted) return;

    print(
      '🔍 [EmployeeDetail] Loading employee details for ID: ${widget.employeeId}',
    );

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📡 [EmployeeDetail] Calling getEmployeeById API...');
      final response = await _employeeService.getEmployeeById(
        widget.employeeId,
      );

      print('📥 [EmployeeDetail] API Response received:');
      print('   Success: ${response.success}');
      print('   Message: ${response.message}');
      print('   Data: ${response.data?.toJson()}');

      if (!mounted) return;

      if (response.success && response.data != null) {
        print(
          '✅ [EmployeeDetail] Employee loaded successfully: ${response.data!.fullName}',
        );
        setState(() {
          _employee = response.data!;
        });

        // Load salary adjustments and current payroll after employee data is loaded
        await _loadSalaryAdjustments();
        await _loadCurrentPayroll();
      } else {
        print(
          '❌ [EmployeeDetail] Failed to load employee: ${response.message}',
        );
        if (!mounted) return;
        setState(() {
          _error = response.message ?? 'Không thể tải thông tin nhân viên';
        });
      }
    } catch (e, stackTrace) {
      print('❌ [EmployeeDetail] Exception: $e');
      print('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _error = 'Lỗi: ${e.toString()}';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEmployee() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa nhân viên "${_employee?.fullName ?? 'Chưa có tên'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // TODO: Implement delete API call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng xóa sẽ được triển khai sau')),
    );
  }

  Future<void> _updateFaceId() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật Face ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _employee!.isFaceRegistered
                  ? 'Nhân viên đã có Face ID đăng ký.\nBạn muốn đăng ký lại khuôn mặt mới?'
                  : 'Nhân viên chưa có Face ID.\nBạn muốn đăng ký khuôn mặt?',
            ),
            if (_employee!.isFaceRegistered) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ảnh cũ sẽ bị xóa và thay bằng ảnh mới',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _employee!.isFaceRegistered
                  ? Colors.orange
                  : AppColors.primaryBlue,
            ),
            child: Text(
              _employee!.isFaceRegistered ? 'Đăng ký lại' : 'Đăng ký',
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Navigate to Face Registration with employee info
    final result = await Navigator.pushNamed(
      context,
      '/face/register',
      arguments: {
        'employee': _employee,
        'isReRegister': _employee!.isFaceRegistered,
      },
    );

    // Reload employee data if face was registered/re-registered
    if (result == true) {
      _loadEmployeeDetails();
    }
  }

  Future<void> _loadSalaryAdjustments() async {
    if (_employee == null) return;

    setState(() {
      _isLoadingAdjustments = true;
    });

    try {
      final response = await _payrollService.getEmployeeAdjustments(
        widget.employeeId,
      );

      if (response.success && response.data != null) {
        setState(() {
          _salaryAdjustments = response.data!;
        });
      }
    } catch (e) {
      // Silent error for adjustments - không ảnh hưởng đến thông tin chính
      debugPrint('Failed to load salary adjustments: $e');
    } finally {
      setState(() {
        _isLoadingAdjustments = false;
      });
    }
  }

  Future<void> _loadCurrentPayroll() async {
    if (_employee == null || !mounted) return;

    setState(() {
      _isLoadingPayroll = true;
    });

    try {
      // Get current period (assume period ID = 1 for now)
      // TODO: Get actual current period from API
      final response = await _payrollService.getEmployeePayroll(
        1,
        widget.employeeId,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _currentPayroll = response.data!;
        });
      } else {
        // Log the error message for debugging
        debugPrint('Failed to load payroll: ${response.message}');
      }
    } catch (e, stackTrace) {
      // Silent error for payroll - không ảnh hưởng đến thông tin chính
      debugPrint('Failed to load current payroll: $e');
      debugPrint('Stack trace: $stackTrace');

      // Optionally show a user-friendly message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải thông tin lương: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPayroll = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: const Text('Chi Tiết Nhân Viên'),
        actions: [
          if (_employee != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    Navigator.pushNamed(
                      context,
                      '/employee/edit',
                      arguments: {'employee': _employee},
                    ).then((_) => _loadEmployeeDetails());
                    break;
                  case 'update_face':
                    _updateFaceId();
                    break;
                  case 'delete':
                    _deleteEmployee();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 12),
                      Text('Chỉnh sửa'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'update_face',
                  child: Row(
                    children: [
                      Icon(Icons.face, size: 20),
                      SizedBox(width: 12),
                      Text('Cập nhật Face ID'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Xóa nhân viên',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildSafeBody(),
      bottomNavigationBar: _employee != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/employee/edit',
                            arguments: {'employee': _employee},
                          ).then((_) => _loadEmployeeDetails());
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Chỉnh sửa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _updateFaceId,
                        icon: const Icon(Icons.face),
                        label: const Text('Face ID'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  /// Safe wrapper cho body với error boundary
  Widget _buildSafeBody() {
    try {
      return _buildBody();
    } catch (e, stackTrace) {
      debugPrint('Error building body: $e');
      debugPrint('Stack trace: $stackTrace');

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Đã xảy ra lỗi khi hiển thị thông tin',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Lỗi: $e',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                  _loadEmployeeDetails();
                },
                child: const Text('Thử lại'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
            const SizedBox(height: 16),
            Text(_error!, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEmployeeDetails,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_employee == null) {
      return const Center(child: Text('Không tìm thấy thông tin nhân viên'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar & Name Card
          _buildProfileCard(),
          const SizedBox(height: AppSpacing.lg),

          // Information Sections
          _buildSection(
            title: 'Thông tin cơ bản',
            children: [
              _buildInfoRow('Mã nhân viên', '#${_employee!.id}'),
              _buildInfoRow('Họ tên', _employee!.fullName),
              _buildInfoRow('Email', _employee!.email ?? 'Chưa có'),
              _buildInfoRow(
                'Số điện thoại',
                _employee!.phoneNumber ?? 'Chưa có',
              ),
              _buildInfoRow('Chức vụ', _employee!.position ?? 'Chưa có'),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          _buildSection(
            title: 'Phòng ban',
            children: [
              _buildInfoRow('Phòng ban', 'ID: ${_employee!.departmentId}'),
              // TODO: Load department name
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          _buildSection(
            title: 'Face ID',
            children: [
              _buildInfoRow(
                'Trạng thái',
                _employee!.isFaceRegistered ? 'Đã đăng ký' : 'Chưa đăng ký',
                valueColor: _employee!.isFaceRegistered
                    ? AppColors.successColor
                    : AppColors.errorColor,
              ),
              if (_employee!.faceImageUrl != null)
                _buildInfoRow('Face URL', _employee!.faceImageUrl!),
              if (_employee!.faceRegisteredAt != null)
                _buildInfoRow(
                  'Ngày đăng ký',
                  _formatDate(_employee!.faceRegisteredAt!),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // 💰 Current Salary Information Section
          _buildCurrentSalarySection(),

          const SizedBox(height: AppSpacing.lg),

          // 💰 Salary Adjustments Section
          _buildSalaryAdjustmentsSection(),

          const SizedBox(height: AppSpacing.lg),

          _buildSection(
            title: 'Thông tin khác',
            children: [
              _buildInfoRow(
                'Trạng thái',
                _employee!.isActive ? 'Đang làm việc' : 'Đã nghỉ',
                valueColor: _employee!.isActive
                    ? AppColors.successColor
                    : AppColors.textSecondary,
              ),
              _buildInfoRow('Ngày vào làm', _formatDate(_employee!.joinDate)),
              _buildInfoRow(
                'Ngày tạo hồ sơ',
                _formatDate(_employee!.createdAt),
              ),
            ],
          ),

          const SizedBox(height: 100), // Space for bottom buttons
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _employee!.isActive ? AppColors.primaryBlue : Colors.grey.shade600,
            _employee!.isActive ? AppColors.primaryDark : Colors.grey.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        boxShadow: [
          BoxShadow(
            color: (_employee!.isActive ? AppColors.primaryBlue : Colors.grey)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with badge
          Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _employee!.isFaceRegistered
                      ? Icons.face_retouching_natural
                      : Icons.person_outline,
                  size: 55,
                  color: Colors.white,
                ),
              ),
              if (_employee!.isFaceRegistered)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.successColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Name
          Text(
            _employee!.fullName.isNotEmpty
                ? _employee!.fullName
                : 'Chưa có tên',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Employee Code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _employee!.employeeCode.isNotEmpty
                  ? _employee!.employeeCode
                  : 'EMP${_employee!.id}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Position
          Text(
            _employee!.position ?? 'Chưa có chức vụ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: _employee!.isActive
                  ? Colors.white.withOpacity(0.25)
                  : Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _employee!.isActive
                        ? Colors.greenAccent.shade200
                        : Colors.red.shade200,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _employee!.isActive ? 'Đang làm việc' : 'Đã nghỉ việc',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.h5.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.bgColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 💰 CURRENT SALARY INFORMATION SECTION
  Widget _buildCurrentSalarySection() {
    return _buildSection(
      title: '💰 Thông tin lương hiện tại',
      children: [
        if (_isLoadingPayroll) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ] else if (_currentPayroll == null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chưa có dữ liệu lương cho kỳ hiện tại.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhân viên này có thể chưa được tính lương hoặc chưa có trong kỳ lương hiện tại.',
                  style: TextStyle(color: Colors.orange.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons for salary management
          _buildSalaryActionButtons(),
        ] else ...[
          // Salary overview card
          _buildSalaryOverviewCard(),
          const SizedBox(height: 16),
          // Salary breakdown
          _buildSalaryBreakdown(),
          const SizedBox(height: 16),
          // Action buttons
          _buildSalaryActionButtons(),
        ],
      ],
    );
  }

  /// 📊 Salary Overview Card
  Widget _buildSalaryOverviewCard() {
    if (_currentPayroll == null) return const SizedBox();

    final isNegative = _currentPayroll!.netSalary < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNegative
              ? [Colors.red.shade400, Colors.red.shade600]
              : [AppColors.primaryBlue, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isNegative ? Colors.red : AppColors.primaryBlue)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isNegative) ...[
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
              ],
              const Text(
                'LƯƠNG THỰC NHẬN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _safeCurrencyFormat(_currentPayroll!.netSalary),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                'Kỳ lương hiện tại',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📋 Salary Breakdown
  Widget _buildSalaryBreakdown() {
    if (_currentPayroll == null) return const SizedBox();

    return Column(
      children: [
        // Income section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.add_circle,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thu nhập',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSalaryInfoRow(
                'Lương cơ bản',
                _currentPayroll!.baseSalaryActual,
              ),
              _buildSalaryInfoRow(
                'Thu nhập OT',
                _currentPayroll!.totalOTPayment,
              ),
              _buildSalaryInfoRow('Phụ cấp', _currentPayroll!.totalAllowances),
              _buildSalaryInfoRow('Thưởng', _currentPayroll!.bonus),
              const Divider(),
              _buildSalaryInfoRow(
                'Tổng thu nhập',
                _currentPayroll!.adjustedGrossIncome,
                isBold: true,
                color: Colors.green.shade700,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Deduction section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.remove_circle,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Khấu trừ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSalaryInfoRow(
                'Bảo hiểm XH/YT/TN',
                _currentPayroll!.insuranceDeduction,
              ),
              _buildSalaryInfoRow('Thuế TNCN', _currentPayroll!.pitDeduction),
              _buildSalaryInfoRow(
                'Khấu trừ khác',
                _currentPayroll!.otherDeductions,
              ),
              const Divider(),
              _buildSalaryInfoRow(
                'Tổng khấu trừ',
                _currentPayroll!.insuranceDeduction +
                    _currentPayroll!.pitDeduction +
                    _currentPayroll!.otherDeductions,
                isBold: true,
                color: Colors.red.shade700,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalaryInfoRow(
    String label,
    double value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
          Text(
            _safeCurrencyFormat(value),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Salary Action Buttons
  Widget _buildSalaryActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Nếu màn hình nhỏ, hiển thị theo cột
        if (constraints.maxWidth < 500) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddAdjustmentDialog(type: 'BONUS'),
                      icon: const Icon(
                        Icons.star_rounded,
                        color: Colors.green,
                        size: 16,
                      ),
                      label: const Text(
                        'Thưởng',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showAddAdjustmentDialog(type: 'PENALTY'),
                      icon: const Icon(
                        Icons.warning_rounded,
                        color: Colors.red,
                        size: 16,
                      ),
                      label: const Text(
                        'Phạt',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to full salary detail screen
                    Navigator.pushNamed(
                      context,
                      '/payroll/employee-detail',
                      arguments: {
                        'periodId': 1, // TODO: Get current period ID
                        'employeeId': widget.employeeId,
                        'employeeName': _employee?.fullName ?? 'Chưa có tên',
                        'employeeCode': _employee?.employeeCode,
                        'department': 'ID: ${_employee?.departmentId ?? ''}',
                        'position': _employee?.position,
                      },
                    );
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text(
                    'Xem chi tiết',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          );
        }

        // Màn hình lớn, hiển thị theo hàng
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showAddAdjustmentDialog(type: 'BONUS'),
                icon: const Icon(Icons.star_rounded, color: Colors.green),
                label: const Text(
                  'Thêm thưởng',
                  style: TextStyle(color: Colors.green),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showAddAdjustmentDialog(type: 'PENALTY'),
                icon: const Icon(Icons.warning_rounded, color: Colors.red),
                label: const Text(
                  'Thêm phạt',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to full salary detail screen
                  Navigator.pushNamed(
                    context,
                    '/payroll/employee-detail',
                    arguments: {
                      'periodId': 1, // TODO: Get current period ID
                      'employeeId': widget.employeeId,
                      'employeeName': _employee?.fullName ?? 'Chưa có tên',
                      'employeeCode': _employee?.employeeCode,
                      'department': 'ID: ${_employee?.departmentId ?? ''}',
                      'position': _employee?.position,
                    },
                  );
                },
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Xem chi tiết'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 💰 SALARY ADJUSTMENTS SECTION WITH EDIT FUNCTIONALITY
  Widget _buildSalaryAdjustmentsSection() {
    return _buildSection(
      title: '💰 Điều chỉnh lương',
      children: [
        if (_isLoadingAdjustments) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ] else if (_salaryAdjustments.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Chưa có khoản điều chỉnh lương nào',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        ] else ...[
          // Adjustments List
          ...(_salaryAdjustments
              .take(5)
              .map((adjustment) => _buildAdjustmentCard(adjustment))),

          if (_salaryAdjustments.length > 5) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                // TODO: Navigate to full adjustments list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Showing ${_salaryAdjustments.length} adjustments',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.expand_more, size: 18),
              label: Text('Xem tất cả (${_salaryAdjustments.length} khoản)'),
            ),
          ],
        ],
      ],
    );
  }

  /// 🎯 Individual Adjustment Card with Edit Button
  Widget _buildAdjustmentCard(SalaryAdjustmentResponse adjustment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: adjustment.getTypeColor().withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: adjustment.getTypeColor().withAlpha(50)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: adjustment.getTypeColor().withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getAdjustmentIcon(adjustment.adjustmentType),
                color: adjustment.getTypeColor(),
                size: 16,
              ),
            ),

            const SizedBox(width: 8),

            // Content - Flexible để tránh overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Type và Amount - Flexible row
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          adjustment.getTypeLabel(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: adjustment.getTypeColor(),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _safeCurrencyFormat(adjustment.amount.abs()),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: adjustment.getTypeColor(),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Description
                  Text(
                    adjustment.description.isNotEmpty
                        ? adjustment.description
                        : 'Không có mô tả',
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Date và Status
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(adjustment.effectiveDate),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!adjustment.canEdit) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'Đã xử lý',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Edit Button - Fixed width
            if (adjustment.canEdit) ...[
              const SizedBox(width: 4),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  onPressed: () => _editAdjustment(adjustment),
                  icon: const Icon(Icons.edit_rounded),
                  iconSize: 16,
                  color: adjustment.getTypeColor(),
                  tooltip: 'Sửa',
                  style: IconButton.styleFrom(
                    backgroundColor: adjustment.getTypeColor().withAlpha(25),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(width: 4),
              SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getAdjustmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bonus':
        return Icons.star_rounded;
      case 'penalty':
        return Icons.warning_rounded;
      case 'correction':
        return Icons.tune_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  /// 🎯 EDIT ADJUSTMENT ACTION
  void _editAdjustment(SalaryAdjustmentResponse adjustment) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditAdjustmentDialog(
        adjustment: adjustment,
        periodId: 1, // TODO: Get current period ID
        onUpdated: () {
          // Reload both employee data and adjustments
          _loadEmployeeDetails();
        },
      ),
    );

    if (result == true) {
      // Additional actions if needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Điều chỉnh lương đã được cập nhật thành công!'),
          backgroundColor: Color(0xFF34C759),
        ),
      );
    }
  }

  /// 💰 Show Add Adjustment Dialog
  void _showAddAdjustmentDialog({String type = 'BONUS'}) {
    final reasonController = TextEditingController();
    final amountController = TextEditingController();

    final isBonus = type.toUpperCase() == 'BONUS';
    final typeName = isBonus ? 'thưởng' : 'phạt';
    final typeColor = isBonus ? Colors.green : Colors.red;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isBonus ? Icons.star_rounded : Icons.warning_rounded,
              color: typeColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text('Thêm $typeName'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do',
                border: OutlineInputBorder(),
                hintText: 'Nhập lý do điều chỉnh...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Số tiền',
                border: OutlineInputBorder(),
                suffixText: '₫',
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount =
                  double.tryParse(amountController.text.replaceAll(',', '')) ??
                  0;
              if (reasonController.text.isEmpty || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập đầy đủ thông tin hợp lệ'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final request = CreateSalaryAdjustmentRequest(
                  employeeId: widget.employeeId,
                  periodId: 1, // TODO: Get current period ID
                  adjustmentType: type,
                  reason: reasonController.text,
                  amount: type.toUpperCase() == 'PENALTY' ? -amount : amount,
                  adjustmentDate: DateTime.now(),
                  approvedBy: 'HR', // TODO: Get from auth
                );

                final response = await _payrollService.createSalaryAdjustment(
                  request,
                );

                // Close loading
                if (mounted) Navigator.pop(context);

                if (response.success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Đã thêm $typeName thành công!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );

                  // Reload data
                  _loadEmployeeDetails();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Lỗi: ${response.message ?? "Không thể thêm $typeName"}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                // Close loading
                if (mounted) Navigator.pop(context);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: typeColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Thêm $typeName'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

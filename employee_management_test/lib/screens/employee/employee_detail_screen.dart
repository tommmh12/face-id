import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../services/employee_api_service.dart';
import '../../config/app_theme.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final int employeeId;

  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  final EmployeeApiService _employeeService = EmployeeApiService();
  Employee? _employee;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmployeeDetails();
  }

  Future<void> _loadEmployeeDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _employeeService.getEmployeeById(
        widget.employeeId,
      );

      if (response.success && response.data != null) {
        setState(() {
          _employee = response.data!;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Không thể tải thông tin nhân viên';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi: ${e.toString()}';
      });
    } finally {
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
          'Bạn có chắc muốn xóa nhân viên "${_employee?.fullName}"?',
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
      body: _buildBody(),
      bottomNavigationBar: _employee != null
          ? Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Edit Button
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppColors.gradientSoftBlue,
                          ),
                          borderRadius: BorderRadius.circular(AppBorderRadius.large),
                          boxShadow: AppShadows.small,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/employee/edit',
                              arguments: {'employee': _employee},
                            ).then((_) => _loadEmployeeDetails());
                          },
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Chỉnh sửa',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Face ID Button
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _employee!.isFaceRegistered
                                ? AppColors.gradientSoftOrange  // Re-register
                                : AppColors.gradientSoftGreen,  // First register
                          ),
                          borderRadius: BorderRadius.circular(AppBorderRadius.large),
                          boxShadow: AppShadows.small,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _updateFaceId,
                          icon: Icon(
                            _employee!.isFaceRegistered
                                ? Icons.face_retouching_natural_rounded
                                : Icons.face_rounded,
                            color: Colors.white,
                          ),
                          label: Text(
                            _employee!.isFaceRegistered ? 'Cập nhật' : 'Đăng ký',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          ),
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
          // Enhanced Avatar with multiple badges
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  _employee!.isFaceRegistered
                      ? Icons.face_retouching_natural_rounded
                      : Icons.person_outline_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              // Face ID Badge
              if (_employee!.isFaceRegistered)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.gradientSoftGreen,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: AppShadows.medium,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              // Active Status Badge - Top Right
              Positioned(
                right: 8,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _employee!.isActive
                        ? AppColors.successColor
                        : AppColors.errorColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: AppShadows.small,
                  ),
                  child: Icon(
                    _employee!.isActive
                        ? Icons.work_rounded
                        : Icons.work_off_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Name
          Text(
            _employee!.fullName,
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
              _employee!.employeeCode,
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
          // Enhanced Status Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Work Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: _employee!.isActive
                      ? Colors.white.withOpacity(0.25)
                      : Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _employee!.isActive
                            ? Colors.greenAccent.shade200
                            : Colors.red.shade200,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _employee!.isActive
                                ? Colors.greenAccent.withOpacity(0.5)
                                : Colors.red.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _employee!.isActive ? 'Đang làm việc' : 'Đã nghỉ việc',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Face ID Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: _employee!.isFaceRegistered
                      ? Colors.white.withOpacity(0.25)
                      : Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _employee!.isFaceRegistered
                          ? Icons.face_retouching_natural_rounded
                          : Icons.face_retouching_off_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _employee!.isFaceRegistered ? 'Face ID' : 'No Face ID',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.bgColor,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  height: 2,
                  width: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.gradientSoftBlue,
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

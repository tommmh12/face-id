import 'package:flutter/material.dart';
import '../../models/employee.dart';
import '../../services/employee_api_service.dart';
import '../../config/app_theme.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final int employeeId;

  const EmployeeDetailScreen({
    super.key,
    required this.employeeId,
  });

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
      final response = await _employeeService.getEmployeeById(widget.employeeId);
      
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
        content: Text('Bạn có chắc muốn xóa nhân viên "${_employee?.fullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
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
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
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
            child: Text(_employee!.isFaceRegistered ? 'Đăng ký lại' : 'Đăng ký'),
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
                      Text('Xóa nhân viên', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(),
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
              _buildInfoRow('Số điện thoại', _employee!.phoneNumber ?? 'Chưa có'),
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
                _buildInfoRow('Ngày đăng ký', _formatDate(_employee!.faceRegisteredAt!)),
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
              _buildInfoRow(
                'Ngày vào làm',
                _formatDate(_employee!.joinDate),
              ),
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
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Icon(
              _employee!.isFaceRegistered ? Icons.face : Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _employee!.fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _employee!.position ?? 'Chưa có chức vụ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _employee!.isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _employee!.isActive ? 'Đang làm việc' : 'Đã nghỉ',
                  style: const TextStyle(
                    color: Colors.white,
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h4),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

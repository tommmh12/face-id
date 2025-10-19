import 'package:flutter/material.dart';

/// 🏢 Employee Management Hub Screen
/// 
/// Navigation hub for all HR-related functions:
/// - Employee CRUD operations
/// - Face ID registration & updates
/// - Department management
/// - Account provisioning & password reset
class EmployeeManagementHubScreen extends StatelessWidget {
  const EmployeeManagementHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Nhân Viên'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Hệ Thống Face ID',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Chấm công thông minh • Tính lương tự động',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions Section
            const Text(
              'Chấm Công Nhanh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Check In/Out Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.login,
                    title: 'Check In',
                    subtitle: 'Vào làm',
                    color: Colors.green,
                    onTap: () => Navigator.pushNamed(context, '/face/checkin'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.logout,
                    title: 'Check Out',
                    subtitle: 'Tan làm',
                    color: Colors.red,
                    onTap: () => Navigator.pushNamed(context, '/face/checkout'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Main Functions Section
            const Text(
              'Chức Năng Chính',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Main Function Tiles
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildMainFunctionTile(
                  context,
                  icon: Icons.people,
                  title: 'Quản Lý Nhân Viên',
                  subtitle: 'Thêm, sửa, xóa thông tin nhân viên',
                  color: const Color(0xFF1E88E5),
                  onTap: () => Navigator.pushNamed(context, '/employees'),
                ),
                _buildMainFunctionTile(
                  context,
                  icon: Icons.business,
                  title: 'Quản Lý Phòng Ban',
                  subtitle: 'Tổ chức và phân chia phòng ban',
                  color: const Color(0xFFFF9800),
                  onTap: () => Navigator.pushNamed(context, '/departments'),
                ),
                _buildMainFunctionTile(
                  context,
                  icon: Icons.face_retouching_natural,
                  title: 'Đăng Ký & Cập Nhật Face',
                  subtitle: 'Đăng ký khuôn mặt cho nhân viên',
                  color: const Color(0xFF9C27B0),
                  onTap: () => Navigator.pushNamed(context, '/face/register'),
                ),
                _buildMainFunctionTile(
                  context,
                  icon: Icons.camera_alt,
                  title: 'Chấm Công Face ID',
                  subtitle: 'Check in/out bằng nhận diện khuôn mặt',
                  color: const Color(0xFFFF5722),
                  onTap: () => Navigator.pushNamed(context, '/face/checkin'),
                ),
                _buildMainFunctionTile(
                  context,
                  icon: Icons.account_circle,
                  title: 'Cấp Tài Khoản',
                  subtitle: 'Tạo tài khoản đăng nhập',
                  color: const Color(0xFF607D8B),
                  onTap: () => _showProvisionAccountDialog(context),
                ),
                _buildMainFunctionTile(
                  context,
                  icon: Icons.lock_reset,
                  title: 'Reset Password',
                  subtitle: 'Đặt lại mật khẩu nhân viên',
                  color: const Color(0xFFF44336),
                  onTap: () => _showResetPasswordDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainFunctionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProvisionAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cấp Tài Khoản'),
        content: const Text('Tính năng cấp tài khoản đang được phát triển.\n\nSẽ tích hợp với API: POST /provision-account'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Mật Khẩu'),
        content: const Text('Tính năng reset mật khẩu đang được phát triển.\n\nSẽ tích hợp với API: POST /reset-password'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
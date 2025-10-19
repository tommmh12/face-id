import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

/// HR Dashboard - Human Resources Management (Level 1)
/// 
/// Features:
/// - Account Provisioning (Auto-assign role for ADMIN/HR depts)
/// - Employee Management (View, Status change)
/// - Payroll Management (Full access)
/// - Attendance Management
/// - Reset Passwords
/// 
/// Restrictions:
/// - ❌ Cannot change roles (Admin only)
/// - ❌ Cannot delete employees
/// - ❌ Cannot access system configuration
class HRDashboard extends StatefulWidget {
  const HRDashboard({super.key});

  @override
  State<HRDashboard> createState() => _HRDashboardState();
}

class _HRDashboardState extends State<HRDashboard> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await _authService.getCurrentUser();
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải thông tin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng xuất: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final fullName = _userData?['fullName'] ?? 'HR';
    final email = _userData?['email'] ?? '';
    final roleName = _userData?['roleName'] ?? 'HR';

    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Dashboard'),
        actions: [
          // User Profile Button
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: const Color(0xFF43A047),
              child: Text(
                fullName.isNotEmpty ? fullName[0].toUpperCase() : 'H',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF43A047).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        roleName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF43A047),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF43A047).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.people_alt,
                            color: Color(0xFF43A047),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xin chào, $fullName!',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Nhân sự - Quản lý nhân viên & bảng lương',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // HR Tasks Section
            const Text(
              'Nhiệm vụ HR',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // HR Tasks Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildQuickAccessCard(
                  icon: Icons.people,
                  title: 'Nhân viên',
                  subtitle: 'Quản lý hồ sơ',
                  color: const Color(0xFF1E88E5),
                  onTap: () => Navigator.pushNamed(context, '/employees'),
                ),
                _buildQuickAccessCard(
                  icon: Icons.payment,
                  title: 'Bảng lương',
                  subtitle: 'Tính & phát lương',
                  color: const Color(0xFF43A047),
                  onTap: () => Navigator.pushNamed(context, '/payroll'),
                ),
                _buildQuickAccessCard(
                  icon: Icons.how_to_reg,
                  title: 'Chấm công',
                  subtitle: 'Điểm danh',
                  color: const Color(0xFF00BCD4),
                  onTap: () => Navigator.pushNamed(context, '/face/checkin'),
                ),
                _buildQuickAccessCard(
                  icon: Icons.bar_chart,
                  title: 'Báo cáo',
                  subtitle: 'Thống kê',
                  color: const Color(0xFFF44336),
                  onTap: () => Navigator.pushNamed(context, '/payroll/chart'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Permissions Info Card
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.amber,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Quyền hạn HR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionRow(
                      icon: Icons.check_circle,
                      text: 'Cấp tài khoản cho nhân viên mới',
                      isAllowed: true,
                    ),
                    _buildPermissionRow(
                      icon: Icons.check_circle,
                      text: 'Quản lý bảng lương & phụ cấp',
                      isAllowed: true,
                    ),
                    _buildPermissionRow(
                      icon: Icons.check_circle,
                      text: 'Đặt lại mật khẩu cho nhân viên',
                      isAllowed: true,
                    ),
                    _buildPermissionRow(
                      icon: Icons.cancel,
                      text: 'Thay đổi vai trò (chỉ Admin)',
                      isAllowed: false,
                    ),
                    _buildPermissionRow(
                      icon: Icons.cancel,
                      text: 'Xóa nhân viên (chỉ Admin)',
                      isAllowed: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required String text,
    required bool isAllowed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isAllowed ? const Color(0xFF43A047) : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isAllowed ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

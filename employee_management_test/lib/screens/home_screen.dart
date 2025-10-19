import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(AppBorderRadius.small),
              ),
              child: const Icon(
                Icons.business_center,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản Lý Nhân Viên',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Chấm công & Lương',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Banner
              Container(
                margin: const EdgeInsets.all(AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.large),
                  boxShadow: AppShadows.primaryShadow(opacity: 0.3),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.face_retouching_natural,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'Hệ Thống Face ID',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Chấm công thông minh • Tính lương tự động',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chấm Công Nhanh', style: AppTextStyles.h5),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            context,
                            icon: Icons.login_rounded,
                            label: 'Check In',
                            color: AppColors.successColor,
                            lightColor: AppColors.successLight,
                            onTap: () =>
                                Navigator.pushNamed(context, '/face/checkin'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildQuickActionButton(
                            context,
                            icon: Icons.logout_rounded,
                            label: 'Check Out',
                            color: AppColors.errorColor,
                            lightColor: AppColors.errorLight,
                            onTap: () =>
                                Navigator.pushNamed(context, '/face/checkin'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Main Features
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chức Năng Chính', style: AppTextStyles.h5),
                    const SizedBox(height: AppSpacing.md),
                    _buildFeatureCard(
                      context,
                      icon: Icons.people_alt_rounded,
                      title: 'Quản Lý Nhân Viên',
                      subtitle: 'Thêm, sửa, xóa thông tin nhân viên',
                      color: AppColors.primaryBlue,
                      lightColor: AppColors.primaryLighter,
                      onTap: () => Navigator.pushNamed(context, '/employees'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildFeatureCard(
                      context,
                      icon: Icons.business_rounded,
                      title: 'Quản Lý Phòng Ban',
                      subtitle: 'Tổ chức và phân chia phòng ban',
                      color: AppColors.secondaryTeal,
                      lightColor: AppColors.secondaryTealLight,
                      onTap: () => Navigator.pushNamed(context, '/departments'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildFeatureCard(
                      context,
                      icon: Icons.face_retouching_natural,
                      title: 'Đăng Ký Face ID',
                      subtitle: 'Đăng ký khuôn mặt cho nhân viên',
                      color: AppColors.secondaryGreen,
                      lightColor: AppColors.secondaryGreenLight,
                      onTap: () =>
                          Navigator.pushNamed(context, '/face/register'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildFeatureCard(
                      context,
                      icon: Icons.camera_alt_rounded,
                      title: 'Chấm Công Face ID',
                      subtitle: 'Check in/out bằng nhận diện khuôn mặt',
                      color: AppColors.secondaryOrange,
                      lightColor: AppColors.secondaryOrangeLight,
                      onTap: () =>
                          Navigator.pushNamed(context, '/face/checkin'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildFeatureCard(
                      context,
                      icon: Icons.attach_money_rounded,
                      title: 'Quản Lý Lương',
                      subtitle: 'Tính toán và quản lý lương nhân viên',
                      color: AppColors.secondaryPurple,
                      lightColor: AppColors.secondaryPurpleLight,
                      onTap: () => Navigator.pushNamed(context, '/payroll'),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color lightColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        child: Ink(
          decoration: BoxDecoration(
            color: lightColor,
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color lightColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.large),
            boxShadow: AppShadows.small,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: lightColor,
                    borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

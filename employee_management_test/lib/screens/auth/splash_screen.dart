import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_logger.dart';

/// 🚀 Splash Screen - App Initialization
/// 
/// Features:
/// - Check if user is logged in
/// - Validate JWT token
/// - Auto-navigate to appropriate screen:
///   - Login Screen (if not logged in or token expired)
///   - Dashboard (if logged in with valid token)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    AppLogger.startOperation('App Initialization - Session Check');

    try {
      // Wait minimum 1.5 seconds for splash animation
      await Future.delayed(const Duration(milliseconds: 1500));

      // [1] Check if user is logged in
      final isLoggedIn = await _authService.isLoggedIn();

      if (!mounted) return;

      if (isLoggedIn) {
        // [2] User is logged in - navigate to appropriate dashboard
        final route = await _authService.getDashboardRoute();
        
        AppLogger.success(
          'User session valid - navigating to: $route',
          tag: 'Splash',
        );

        if (!mounted) return;

        // Navigate to dashboard
        Navigator.of(context).pushReplacementNamed(route);
      } else {
        // [3] User not logged in - navigate to login
        AppLogger.info('No valid session - navigating to login', tag: 'Splash');

        if (!mounted) return;

        Navigator.of(context).pushReplacementNamed('/login');
      }

      AppLogger.endOperation('App Initialization - Session Check', success: true);
    } catch (e) {
      AppLogger.error(
        'Session check failed',
        error: e,
        tag: 'Splash',
      );
      AppLogger.endOperation('App Initialization - Session Check', success: false);

      if (!mounted) return;

      // On error, go to login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0A84FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                size: 60,
                color: Color(0xFF0A84FF),
              ),
            ),

            const SizedBox(height: 32),

            // App Name
            const Text(
              'Quản lý Nhân viên',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Employee Management System',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 48),

            // Loading Indicator
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Đang khởi động...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

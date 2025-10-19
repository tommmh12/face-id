import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/loading_service.dart';
import '../../services/api_error_handler.dart';
import '../../utils/app_logger.dart';

/// 🔐 Login Screen
/// 
/// Features:
/// - Login with Email OR Employee Code
/// - Password visibility toggle
/// - Form validation
/// - Loading state
/// - Error handling
/// - Role-based navigation
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ✅ Use LoadingService instead of local state
    final loadingService = context.read<LoadingService>();

    try {
      // ✅ Show loading with custom message
      loadingService.show('Đang đăng nhập...');

      // Call login API
      final response = await _authService.login(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      );

      // ✅ Hide loading
      loadingService.hide();

      if (!mounted) return;

      // ✅ Show success message using ApiErrorHandler
      ApiErrorHandler.showSuccess(
        context,
        'Xin chào, ${response.fullName}!\n${response.roleDisplayName}',
        duration: const Duration(seconds: 2),
      );

      // Navigate to appropriate dashboard based on role
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;

      // Navigate and remove all previous routes
      Navigator.of(context).pushNamedAndRemoveUntil(
        response.dashboardRoute,
        (route) => false,
      );
    } catch (e) {
      // ✅ Hide loading on error
      loadingService.hide();

      if (!mounted) return;

      // ✅ Show error using ApiErrorHandler
      ApiErrorHandler.handleException(context, e);
      
      AppLogger.error('Login failed', error: e, tag: 'LoginScreen');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Icon(
                    Icons.account_circle,
                    size: 100,
                    color: const Color(0xFF0A84FF),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    'Đăng nhập',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Hệ thống Quản lý Nhân viên',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Identifier Input (Email or Employee Code)
                  TextFormField(
                    controller: _identifierController,
                    decoration: InputDecoration(
                      labelText: 'Email hoặc Mã NV',
                      hintText: 'Ví dụ: admin@company.com hoặc EMP001',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập Email hoặc Mã NV';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      hintText: 'Nhập mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value.length < 4) {
                        return 'Mật khẩu phải có ít nhất 4 ký tự';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Login Button (LoadingService blocks UI globally)
                  FilledButton(
                    onPressed: _handleLogin,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: const Color(0xFF0A84FF),
                    ),
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Forgot Password (Optional - for future)
                  TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tính năng này sẽ được bổ sung sau'),
                        ),
                      );
                    },
                    child: Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A84FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0A84FF).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF0A84FF),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Hướng dẫn đăng nhập',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0A84FF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Admin', 'admin@company.com', 'admin123'),
                        const SizedBox(height: 8),
                        _buildInfoRow('HR', 'hr@company.com', 'hr123'),
                        const SizedBox(height: 8),
                        _buildInfoRow('NV', 'user@company.com', 'user123'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String role, String email, String password) {
    return Row(
      children: [
        Container(
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A84FF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            role,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A84FF),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$email / $password',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

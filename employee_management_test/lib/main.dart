import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/admin_dashboard.dart';
import 'screens/dashboard/hr_dashboard.dart';
import 'screens/dashboard/employee_dashboard.dart';
import 'screens/home_screen.dart';
import 'screens/employee/employee_list_screen.dart';
import 'screens/employee/employee_create_screen.dart';
import 'screens/employee/employee_detail_screen.dart';
import 'screens/employee/employee_form_screen.dart';
import 'screens/employee/employee_management_hub_screen.dart';
import 'screens/department/department_management_screen.dart';
import 'screens/face/face_register_screen.dart';
import 'screens/face/face_checkin_screen.dart';
import 'screens/payroll/payroll_dashboard_screen.dart';
import 'screens/payroll/payroll_report_screen.dart';
import 'screens/payroll/payroll_rule_setup_screen.dart';
import 'screens/payroll/allowance_management_screen.dart';
import 'screens/payroll/employee_payroll_detail_screen.dart';
import 'screens/payroll/employee_salary_detail_screen_v2.dart';
import 'screens/payroll/payroll_chart_screen.dart';
import 'screens/api_test_screen.dart';
import 'services/loading_service.dart';
import 'utils/camera_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale data for date formatting
  await initializeDateFormatting('vi_VN', null);

  // Initialize camera
  try {
    await CameraHelper.initializeCamera();
  } catch (e) {
    debugPrint('Camera initialization failed: $e');
  }

  // ✅ Setup Provider with LoadingService
  runApp(
    ChangeNotifierProvider(
      create: (_) => LoadingService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Management & Face ID',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
          primary: const Color(0xFF1E88E5),
          secondary: const Color(0xFF43A047),
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A1A),
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1A1A1A), size: 24),
        ),

        // Card Theme
        cardTheme: CardThemeData(
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.04),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
        ),

        // Button Themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE0E0E0),
            disabledForegroundColor: const Color(0xFF999999),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1E88E5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1E88E5),
            side: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
        ),

        // Floating Action Button
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),

        // Dialog Theme
        dialogTheme: DialogThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
        ),

        // Snackbar Theme
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentTextStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Divider Theme
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE5E7EB),
          thickness: 1,
          space: 1,
        ),

        // Scaffold Background
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      
      // ✅ Global Loading Overlay
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            // Listen to LoadingService and show overlay when loading
            Consumer<LoadingService>(
              builder: (context, loading, _) {
                return loading.isLoading
                    ? const GlobalLoadingOverlay()
                    : const SizedBox.shrink();
              },
            ),
          ],
        );
      },
      
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/': (context) => const HomeScreen(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/hr-dashboard': (context) => const HRDashboard(),
        '/employee-dashboard': (context) => const EmployeeDashboard(),
        '/employees': (context) => const EmployeeListScreen(),
        '/employee/create': (context) => const EmployeeCreateScreen(),
        '/employee/hub': (context) => const EmployeeManagementHubScreen(),
        '/departments': (context) => const DepartmentManagementScreen(),
        '/face/register': (context) => const FaceRegisterScreen(),
        '/face/checkin': (context) => const FaceCheckinScreen(),
        '/payroll': (context) => const PayrollDashboardScreen(),
        '/payroll/chart': (context) => const PayrollChartScreen(),
        '/api-test': (context) => const ApiTestScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle routes with parameters
        if (settings.name == '/employee/detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) =>
                EmployeeDetailScreen(employeeId: args['employeeId']),
          );
        }
        if (settings.name == '/employee/edit') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) =>
                EmployeeFormScreen(employee: args['employee']),
          );
        }
        
        // Payroll routes with parameters
        if (settings.name == '/payroll/report') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PayrollReportScreen(
              periodId: args['periodId'],
            ),
          );
        }
        if (settings.name == '/payroll/rule-setup') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PayrollRuleSetupScreen(
              employeeId: args['employeeId'],
              employeeName: args['employeeName'],
            ),
          );
        }
        if (settings.name == '/payroll/allowance') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => AllowanceManagementScreen(
              employeeId: args['employeeId'],
              employeeName: args['employeeName'],
            ),
          );
        }
        if (settings.name == '/payroll/employee-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => EmployeePayrollDetailScreen(
              periodId: args['periodId'],
              employeeId: args['employeeId'],
              employeeName: args['employeeName'],
            ),
          );
        }
        if (settings.name == '/payroll/employee-detail-v2') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => EmployeeSalaryDetailScreenV2(
              periodId: args['periodId'],
              employeeId: args['employeeId'],
            ),
          );
        }
        
        return null;
      },
    );
  }
}

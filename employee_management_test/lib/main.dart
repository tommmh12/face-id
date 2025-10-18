import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'screens/employee/employee_list_screen.dart';
import 'screens/employee/employee_create_screen.dart';
import 'screens/employee/employee_detail_screen.dart';
import 'screens/employee/employee_form_screen.dart';
import 'screens/department/department_management_screen.dart';
import 'screens/face/face_register_screen.dart';
import 'screens/face/face_checkin_screen.dart';
import 'screens/payroll/payroll_dashboard_screen.dart';
import 'screens/api_test_screen.dart';
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
  
  runApp(const MyApp());
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
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/employees': (context) => const EmployeeListScreen(),
        '/employee/create': (context) => const EmployeeCreateScreen(),
        '/departments': (context) => const DepartmentManagementScreen(),
        '/face/register': (context) => const FaceRegisterScreen(),
        '/face/checkin': (context) => const FaceCheckinScreen(),
        '/payroll': (context) => const PayrollDashboardScreen(),
        '/api-test': (context) => const ApiTestScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle routes with parameters
        if (settings.name == '/employee/detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => EmployeeDetailScreen(
              employeeId: args['employeeId'],
            ),
          );
        }
        if (settings.name == '/employee/edit') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => EmployeeFormScreen(
              employee: args['employee'],
            ),
          );
        }
        return null;
      },
    );
  }
}
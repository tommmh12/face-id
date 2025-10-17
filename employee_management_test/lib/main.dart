import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/employee/employee_list_screen.dart';
import 'screens/employee/employee_create_screen.dart';
import 'screens/face/face_register_screen.dart';
import 'screens/face/face_checkin_screen.dart';
import 'screens/payroll/payroll_dashboard_screen.dart';
import 'utils/camera_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    return MultiProvider(
      providers: [
        // Add providers here if needed for state management
      ],
      child: MaterialApp(
        title: 'Employee Management & Face ID',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/employees': (context) => const EmployeeListScreen(),
          '/employee/create': (context) => const EmployeeCreateScreen(),
          '/face/register': (context) => const FaceRegisterScreen(),
          '/face/checkin': (context) => const FaceCheckinScreen(),
          '/payroll': (context) => const PayrollDashboardScreen(),
        },
      ),
    );
  }
}
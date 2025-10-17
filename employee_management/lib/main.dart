import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/app_routes.dart';

void main() {
  runApp(const EmployeeManagementApp());
}

class EmployeeManagementApp extends StatelessWidget {
  const EmployeeManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: AppRoutes.getRoutes(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: AppRoutes.dashboard,
    );
  }
}

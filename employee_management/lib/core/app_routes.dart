import 'package:flutter/material.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/employee/presentation/employee_list_page.dart';
import '../features/employee/presentation/employee_detail_page.dart';
import '../features/department/presentation/department_page.dart';
import '../features/payroll/presentation/payroll_page.dart';
import '../features/payroll/presentation/payroll_detail_page.dart';
import '../features/settings/presentation/health_page.dart';

class AppRoutes {
  static const String dashboard = '/';
  static const String employeeList = '/employees';
  static const String employeeDetail = '/employee-detail';
  static const String departments = '/departments';
  static const String payroll = '/payroll';
  static const String payrollDetail = '/payroll-detail';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      dashboard: (context) => const DashboardPage(),
      employeeList: (context) => const EmployeeListPage(),
      departments: (context) => const DepartmentPage(),
      payroll: (context) => const PayrollPage(),
      settings: (context) => const HealthPage(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case employeeDetail:
        final employeeId = settings.arguments as int?;
        return MaterialPageRoute(
          builder: (context) => EmployeeDetailPage(employeeId: employeeId),
        );
      case payrollDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => PayrollDetailPage(
            periodId: args?['periodId'] as int?,
            employeeId: args?['employeeId'] as int?,
          ),
        );
      default:
        return null;
    }
  }
}

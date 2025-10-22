import 'package:flutter/foundation.dart';
import '../models/employee.dart';
import '../services/employee_api_service.dart';

class EmployeeProvider with ChangeNotifier {
  final EmployeeApiService _employeeService = EmployeeApiService();

  // State variables
  List<Employee> _employees = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch employees based on active/inactive status
  Future<void> fetchEmployees(bool showInactive) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _employeeService.getAllEmployees();
      
      if (response.success && response.data != null) {
        // Filter employees based on showInactive parameter
        _employees = showInactive 
            ? response.data!.where((employee) => !employee.isActive).toList()
            : response.data!.where((employee) => employee.isActive).toList();
        _setError(null);
      } else {
        _setError(response.message ?? 'Không thể tải danh sách nhân viên');
        _employees = [];
      }
    } catch (e) {
      _setError('Lỗi kết nối: $e');
      _employees = [];
      debugPrint('EmployeeProvider.fetchEmployees error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh employee list with current filter
  Future<void> refreshEmployees(bool showInactive) async {
    await fetchEmployees(showInactive);
  }

  /// Update a specific employee in the list (useful after editing)
  void updateEmployee(Employee updatedEmployee) {
    final index = _employees.indexWhere((emp) => emp.id == updatedEmployee.id);
    if (index != -1) {
      _employees[index] = updatedEmployee;
      notifyListeners();
    }
  }

  /// Remove employee from list (after deletion)
  void removeEmployee(int employeeId) {
    _employees.removeWhere((emp) => emp.id == employeeId);
    notifyListeners();
  }

  /// Add employee to list (after creation)
  void addEmployee(Employee newEmployee) {
    _employees.insert(0, newEmployee);
    notifyListeners();
  }

  /// Clear all data
  void clearData() {
    _employees = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _employees.clear();
    super.dispose();
  }
}
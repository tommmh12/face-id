/// 🔐 Permission Helper - Role-based Access Control
/// 
/// Features:
/// - Check user permissions for payroll operations
/// - Role-based access (Admin, HR, Manager, Employee)
/// - Action-level permissions (view, edit, export, approve)
/// 
/// Usage:
/// ```dart
/// if (PermissionHelper.canEditPayroll(currentUser)) {
///   // Show edit button
/// }
/// ```
class PermissionHelper {
  
  // ============ ROLE DEFINITIONS ============
  
  static const String roleAdmin = 'Admin';
  static const String roleHR = 'HR';
  static const String roleManager = 'Manager';
  static const String roleEmployee = 'Employee';

  // ============ PAYROLL PERMISSIONS ============

  /// Check if user can view payroll dashboard
  /// All authenticated users can view
  static bool canViewPayrollDashboard(User? user) {
    return user != null; // All logged-in users
  }

  /// Check if user can view all employee payrolls
  /// Only Admin and HR can view all
  static bool canViewAllPayrolls(User? user) {
    if (user == null) return false;
    return user.role == roleAdmin || user.role == roleHR;
  }

  /// Check if user can view specific employee payroll
  /// - Admin/HR: Can view all
  /// - Manager: Can view their team
  /// - Employee: Can view only their own
  static bool canViewEmployeePayroll(User? user, int employeeId) {
    if (user == null) return false;
    
    // Admin and HR can view all
    if (user.role == roleAdmin || user.role == roleHR) {
      return true;
    }
    
    // Employee can view only their own
    if (user.role == roleEmployee) {
      return user.employeeId == employeeId;
    }
    
    // Manager can view their team (TODO: Implement team check)
    if (user.role == roleManager) {
      // return user.teamMemberIds.contains(employeeId);
      return true; // Temporary: Allow all for now
    }
    
    return false;
  }

  /// Check if user can edit payroll (add adjustments, corrections)
  /// Only Admin and HR can edit
  static bool canEditPayroll(User? user) {
    if (user == null) return false;
    return user.role == roleAdmin || user.role == roleHR;
  }

  /// Check if user can create salary adjustments
  /// Only Admin and HR can create adjustments
  static bool canCreateAdjustment(User? user) {
    return canEditPayroll(user);
  }

  /// Check if user can correct attendance
  /// Only Admin and HR can correct attendance
  static bool canCorrectAttendance(User? user) {
    return canEditPayroll(user);
  }

  /// Check if user can recalculate payroll
  /// Only Admin and HR can trigger recalculation
  static bool canRecalculatePayroll(User? user) {
    return canEditPayroll(user);
  }

  /// Check if user can export PDF
  /// - Admin/HR: Can export all reports
  /// - Employee: Can export only their own payslip
  static bool canExportPDF(User? user, {int? employeeId}) {
    if (user == null) return false;
    
    // Admin and HR can export anything
    if (user.role == roleAdmin || user.role == roleHR) {
      return true;
    }
    
    // Employee can export only their own
    if (employeeId != null) {
      return user.employeeId == employeeId;
    }
    
    return false;
  }

  /// Check if user can close payroll period
  /// Only Admin can close periods
  static bool canClosePayrollPeriod(User? user) {
    if (user == null) return false;
    return user.role == roleAdmin;
  }

  /// Check if user can create payroll period
  /// Only Admin and HR can create periods
  static bool canCreatePayrollPeriod(User? user) {
    if (user == null) return false;
    return user.role == roleAdmin || user.role == roleHR;
  }

  /// Check if user can generate payroll
  /// Only Admin and HR can generate payroll
  static bool canGeneratePayroll(User? user) {
    return canEditPayroll(user);
  }

  /// Check if user can view audit logs
  /// Only Admin can view audit logs
  static bool canViewAuditLog(User? user) {
    if (user == null) return false;
    return user.role == roleAdmin;
  }

  /// Check if user can manage payroll rules
  /// Only Admin and HR can manage rules
  static bool canManagePayrollRules(User? user) {
    if (user == null) return false;
    return user.role == roleAdmin || user.role == roleHR;
  }

  /// Check if user can manage allowances
  /// Only Admin and HR can manage allowances
  static bool canManageAllowances(User? user) {
    return canManagePayrollRules(user);
  }

  // ============ EMPLOYEE PERMISSIONS ============

  /// Check if user can view all employees
  static bool canViewAllEmployees(User? user) {
    if (user == null) return false;
    return user.role == roleAdmin || 
           user.role == roleHR || 
           user.role == roleManager;
  }

  /// Check if user can create employee
  static bool canCreateEmployee(User? user) {
    if (user == null) return false;
    return user.role == roleAdmin || user.role == roleHR;
  }

  /// Check if user can edit employee
  static bool canEditEmployee(User? user) {
    return canCreateEmployee(user);
  }

  /// Check if user can delete employee
  static bool canDeleteEmployee(User? user) {
    if (user == null) return false;
    return user.role == roleAdmin; // Only admin can delete
  }

  // ============ HELPER METHODS ============

  /// Check if user is admin
  static bool isAdmin(User? user) {
    return user?.role == roleAdmin;
  }

  /// Check if user is HR
  static bool isHR(User? user) {
    return user?.role == roleHR;
  }

  /// Check if user is manager
  static bool isManager(User? user) {
    return user?.role == roleManager;
  }

  /// Check if user is employee
  static bool isEmployee(User? user) {
    return user?.role == roleEmployee;
  }

  /// Get user role display name
  static String getRoleDisplayName(String role) {
    switch (role) {
      case roleAdmin:
        return 'Quản trị viên';
      case roleHR:
        return 'Nhân sự';
      case roleManager:
        return 'Quản lý';
      case roleEmployee:
        return 'Nhân viên';
      default:
        return 'Không xác định';
    }
  }

  /// Get permissions summary for role
  static Map<String, bool> getRolePermissions(String role) {
    final user = User(id: 0, role: role, employeeId: 0, username: '');
    
    return {
      'view_dashboard': canViewPayrollDashboard(user),
      'view_all_payrolls': canViewAllPayrolls(user),
      'edit_payroll': canEditPayroll(user),
      'export_pdf': canExportPDF(user),
      'close_period': canClosePayrollPeriod(user),
      'view_audit_log': canViewAuditLog(user),
      'manage_rules': canManagePayrollRules(user),
      'view_all_employees': canViewAllEmployees(user),
      'create_employee': canCreateEmployee(user),
      'delete_employee': canDeleteEmployee(user),
    };
  }
}

// ============ USER MODEL ============

/// Simple User model for permission checking
/// TODO: Replace with actual auth service user model
class User {
  final int id;
  final String username;
  final String role;
  final int employeeId;
  final String? email;
  final String? fullName;
  
  User({
    required this.id,
    required this.username,
    required this.role,
    required this.employeeId,
    this.email,
    this.fullName,
  });

  /// Factory constructor from JSON (for auth response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      role: json['role'] ?? 'Employee',
      employeeId: json['employeeId'] ?? 0,
      email: json['email'],
      fullName: json['fullName'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'employeeId': employeeId,
      'email': email,
      'fullName': fullName,
    };
  }

  /// Check if this user is admin
  bool get isAdmin => role == PermissionHelper.roleAdmin;

  /// Check if this user is HR
  bool get isHR => role == PermissionHelper.roleHR;

  /// Check if this user is manager
  bool get isManager => role == PermissionHelper.roleManager;

  /// Check if this user is employee
  bool get isEmployee => role == PermissionHelper.roleEmployee;
}

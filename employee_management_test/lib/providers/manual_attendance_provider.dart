import 'package:flutter/material.dart';
import '../models/dto/manual_attendance_dtos.dart';
import '../models/dto/today_attendance_dto.dart';
import '../models/employee.dart';
import '../models/department.dart';
import '../services/attendance_api_service.dart';
import '../services/employee_api_service.dart';
import '../services/department_api_service.dart';

/// Provider for Manual Batch Attendance screen state management
/// Quản lý trạng thái màn hình Chấm công thủ công hàng loạt
class ManualAttendanceProvider with ChangeNotifier {
  final AttendanceApiService _attendanceService = AttendanceApiService();
  final EmployeeApiService _employeeService = EmployeeApiService();
  final DepartmentApiService _departmentService = DepartmentApiService();

  // ==================== STATE VARIABLES ====================

  // Loading states
  bool _isLoadingDepartments = false;
  bool _isLoadingEmployees = false;
  bool _isProcessingBatch = false;
  bool _isPreviewMode = false;

  // Data
  DateTime _selectedDate = DateTime.now();
  int? _selectedDepartmentId;
  List<Department> _departments = [];
  List<Employee> _allEmployees = [];
  List<TodayAttendanceApiResponse> _todayAttendances = [];
  List<EmployeeAttendanceModel> _employeeAttendanceList = [];
  String _reason = '';

  // Results
  ManualBatchAttendanceResponse? _lastProcessResult;
  Map<String, dynamic>? _lastPreviewResult;
  String? _errorMessage;

  // ==================== GETTERS ====================

  bool get isLoadingDepartments => _isLoadingDepartments;
  bool get isLoadingEmployees => _isLoadingEmployees;
  bool get isProcessingBatch => _isProcessingBatch;
  bool get isPreviewMode => _isPreviewMode;

  DateTime get selectedDate => _selectedDate;
  int? get selectedDepartmentId => _selectedDepartmentId;
  List<Department> get departments => _departments;
  List<EmployeeAttendanceModel> get employeeAttendanceList => _employeeAttendanceList;
  String get reason => _reason;

  ManualBatchAttendanceResponse? get lastProcessResult => _lastProcessResult;
  Map<String, dynamic>? get lastPreviewResult => _lastPreviewResult;
  String? get errorMessage => _errorMessage;

  // Computed getters
  bool get hasSelectedDepartment => _selectedDepartmentId != null;
  bool get hasEmployees => _employeeAttendanceList.isNotEmpty;
  bool get canProcess => hasSelectedDepartment && hasEmployees && _reason.trim().isNotEmpty;

  /// Get employees that have been modified (dirty)
  List<EmployeeAttendanceModel> get modifiedEmployees {
    return _employeeAttendanceList.where((emp) => emp.isDirty).toList();
  }

  /// Get count of employees by status
  Map<String, int> get employeeStatusCounts {
    final counts = <String, int>{};
    for (final emp in _employeeAttendanceList) {
      final status = emp.effectiveStatus;
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  /// Get summary statistics
  String get summaryText {
    if (!hasEmployees) return 'Chưa có dữ liệu';
    
    final total = _employeeAttendanceList.length;
    final edited = modifiedEmployees.length;
    final autoChecked = _employeeAttendanceList.where((e) => !e.isEditable).length;
    
    return 'Tổng: $total NV | Đã check-in tự động: $autoChecked | Chỉnh sửa: $edited';
  }

  // ==================== INITIALIZATION ====================

  /// Initialize the provider (load departments)
  Future<void> initialize() async {
    debugPrint('🔄 ManualAttendanceProvider: Initializing...');
    await loadDepartments();
  }

  /// Load departments for dropdown
  Future<void> loadDepartments() async {
    if (_isLoadingDepartments) return;

    _isLoadingDepartments = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('📂 Loading departments...');
      final departmentsResponse = await _departmentService.getAllDepartments();
      _departments = departmentsResponse.data ?? [];
      debugPrint('✅ Loaded ${_departments.length} departments');
    } catch (e) {
      debugPrint('❌ Error loading departments: $e');
      _errorMessage = 'Lỗi tải danh sách phòng ban: $e';
    } finally {
      _isLoadingDepartments = false;
      notifyListeners();
    }
  }

  // ==================== DATE & DEPARTMENT SELECTION ====================

  /// Update selected date
  void updateSelectedDate(DateTime date) {
    if (_selectedDate == date) return;
    
    _selectedDate = date;
    debugPrint('📅 Date updated: ${date.toIso8601String().split('T')[0]}');
    
    // Reload employees if department is selected
    if (_selectedDepartmentId != null) {
      loadEmployeesForDepartment(_selectedDepartmentId!);
    }
    
    notifyListeners();
  }

  /// Update selected department
  void updateSelectedDepartment(int? departmentId) {
    if (_selectedDepartmentId == departmentId) return;
    
    _selectedDepartmentId = departmentId;
    debugPrint('🏢 Department updated: $departmentId');
    
    // Clear previous data
    _allEmployees.clear();
    _todayAttendances.clear();
    _employeeAttendanceList.clear();
    _lastProcessResult = null;
    _lastPreviewResult = null;
    
    // Load employees if department is selected
    if (departmentId != null) {
      loadEmployeesForDepartment(departmentId);
    }
    
    notifyListeners();
  }

  /// Update reason text
  void updateReason(String reason) {
    _reason = reason;
    notifyListeners();
  }

  // ==================== EMPLOYEE DATA LOADING ====================

  /// Load employees for selected department and merge with attendance data
  Future<void> loadEmployeesForDepartment(int departmentId) async {
    if (_isLoadingEmployees) return;

    _isLoadingEmployees = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('👥 Loading employees for department $departmentId...');
      debugPrint('📅 For date: ${_selectedDate.toIso8601String().split('T')[0]}');

      // API Call 1: Get all employees in department
      final allEmployeesResponse = await _employeeService.getEmployeesByDepartment(departmentId);
      _allEmployees = allEmployeesResponse.data ?? [];
      debugPrint('✅ Loaded ${_allEmployees.length} employees');

      // API Call 2: Get today's attendance for department
      try {
        _todayAttendances = await _attendanceService.getTodayAttendanceForDepartment(
          departmentId,
          date: _selectedDate,
        );
        debugPrint('✅ Loaded ${_todayAttendances.length} attendance records');
      } catch (e) {
        debugPrint('⚠️ Warning: Could not load attendance data: $e');
        _todayAttendances = []; // Continue without attendance data
      }

      // Merge data
      _mergeEmployeeAttendanceData();
      
      debugPrint('🔄 Merged data: ${_employeeAttendanceList.length} items');
      
    } catch (e) {
      debugPrint('❌ Error loading employees: $e');
      _errorMessage = 'Lỗi tải danh sách nhân viên: $e';
    } finally {
      _isLoadingEmployees = false;
      notifyListeners();
    }
  }

  /// Merge employee data with attendance data
  void _mergeEmployeeAttendanceData() {
    _employeeAttendanceList.clear();

    for (final employee in _allEmployees) {
      // Find matching attendance record
      final attendanceRecord = _todayAttendances
          .where((att) => att.employeeId == employee.id)
          .firstOrNull;

      final bool hasAttendance = attendanceRecord != null;
      final bool isEditable = !hasAttendance; // Can only edit if no auto attendance

      String originalStatus;
      DateTime? originalCheckIn;
      DateTime? originalCheckOut;
      String? originalCheckInDisplay;
      String? originalCheckOutDisplay;

      if (hasAttendance) {
        // Determine status from attendance data
        if (attendanceRecord.checkIn != null && attendanceRecord.checkOut != null) {
          originalStatus = AttendanceStatus.present;
        } else if (attendanceRecord.checkIn != null) {
          // Check if late (after 8:30 AM for example)
          final checkInTime = attendanceRecord.checkIn!.checkTime;
          final hour = checkInTime.hour;
          final minute = checkInTime.minute;
          final isLate = hour > 8 || (hour == 8 && minute > 30);
          originalStatus = isLate ? AttendanceStatus.late : AttendanceStatus.present;
        } else {
          originalStatus = AttendanceStatus.notChecked;
        }

        originalCheckIn = attendanceRecord.checkIn?.checkTime;
        originalCheckOut = attendanceRecord.checkOut?.checkTime;
        originalCheckInDisplay = attendanceRecord.checkIn?.checkTimeDisplay;
        originalCheckOutDisplay = attendanceRecord.checkOut?.checkTimeDisplay;
      } else {
        originalStatus = AttendanceStatus.notChecked;
      }

      // Build automatic attendance info
      String? autoAttendanceInfo;
      if (hasAttendance) {
        final checkInDisplay = attendanceRecord.checkIn?.checkTimeDisplay ?? '';
        final checkOutDisplay = attendanceRecord.checkOut?.checkTimeDisplay ?? '';
        if (checkInDisplay.isNotEmpty && checkOutDisplay.isNotEmpty) {
          autoAttendanceInfo = 'Đã chấm công: $checkInDisplay - $checkOutDisplay';
        } else if (checkInDisplay.isNotEmpty) {
          autoAttendanceInfo = 'Đã vào làm: $checkInDisplay';
        } else {
          autoAttendanceInfo = 'Có dữ liệu chấm công';
        }
      }

      final model = EmployeeAttendanceModel(
        employeeId: employee.id,
        employeeCode: employee.employeeCode,
        employeeName: employee.fullName,
        departmentName: employee.departmentName ?? 'N/A',
        isEditable: isEditable,
        originalStatus: originalStatus,
        originalCheckIn: originalCheckIn,
        originalCheckOut: originalCheckOut,
        originalCheckInDisplay: originalCheckInDisplay,
        originalCheckOutDisplay: originalCheckOutDisplay,
        automaticAttendanceInfo: autoAttendanceInfo,
      );

      _employeeAttendanceList.add(model);
    }

    // Sort: editable items first, then by employee code
    _employeeAttendanceList.sort((a, b) {
      if (a.isEditable != b.isEditable) {
        return a.isEditable ? -1 : 1; // Editable first
      }
      return a.employeeCode.compareTo(b.employeeCode);
    });
  }

  // ==================== EMPLOYEE STATUS UPDATES ====================

  /// Update employee status
  void updateEmployeeStatus(int employeeId, String status) {
    final index = _employeeAttendanceList.indexWhere((emp) => emp.employeeId == employeeId);
    if (index == -1) return;

    final employee = _employeeAttendanceList[index];
    if (!employee.isEditable) return; // Cannot edit non-editable items

    _employeeAttendanceList[index] = employee.copyWith(selectedStatus: status);
    
    debugPrint('✏️ Updated employee ${employee.employeeCode} status: $status');
    notifyListeners();
  }

  /// Update employee custom check-in time (for LATE status)
  void updateEmployeeCheckInTime(int employeeId, TimeOfDay? time) {
    final index = _employeeAttendanceList.indexWhere((emp) => emp.employeeId == employeeId);
    if (index == -1) return;

    final employee = _employeeAttendanceList[index];
    if (!employee.isEditable) return;

    _employeeAttendanceList[index] = employee.copyWith(customCheckInTime: time);
    
    debugPrint('🕐 Updated employee ${employee.employeeCode} check-in time: ${time?.format24Hour()}');
    notifyListeners();
  }

  /// Update employee custom check-out time (for HALF_DAY status)
  void updateEmployeeCheckOutTime(int employeeId, TimeOfDay? time) {
    final index = _employeeAttendanceList.indexWhere((emp) => emp.employeeId == employeeId);
    if (index == -1) return;

    final employee = _employeeAttendanceList[index];
    if (!employee.isEditable) return;

    _employeeAttendanceList[index] = employee.copyWith(customCheckOutTime: time);
    
    debugPrint('🕕 Updated employee ${employee.employeeCode} check-out time: ${time?.format24Hour()}');
    notifyListeners();
  }

  /// Update employee notes
  void updateEmployeeNotes(int employeeId, String notes) {
    final index = _employeeAttendanceList.indexWhere((emp) => emp.employeeId == employeeId);
    if (index == -1) return;

    final employee = _employeeAttendanceList[index];
    if (!employee.isEditable) return;

    _employeeAttendanceList[index] = employee.copyWith(notes: notes);
    notifyListeners();
  }

  /// Update employee override setting
  void updateEmployeeOverride(int employeeId, bool override) {
    final index = _employeeAttendanceList.indexWhere((emp) => emp.employeeId == employeeId);
    if (index == -1) return;

    final employee = _employeeAttendanceList[index];
    _employeeAttendanceList[index] = employee.copyWith(overrideExisting: override);
    
    debugPrint('🔄 Updated employee ${employee.employeeCode} override: $override');
    notifyListeners();
  }



  // ==================== BATCH PROCESSING ====================

  /// Preview batch before processing
  Future<bool> previewBatch() async {
    if (!canProcess) {
      _errorMessage = 'Chưa đủ thông tin để xử lý';
      notifyListeners();
      return false;
    }

    _isPreviewMode = true;
    _errorMessage = null;
    _lastPreviewResult = null;
    notifyListeners();

    try {
      final request = _buildBatchRequest();
      debugPrint('👁️ Previewing batch: ${request.records.length} records');

      _lastPreviewResult = await _attendanceService.previewManualBatchAttendance(request);
      debugPrint('✅ Preview completed successfully');
      
      return true;
    } catch (e) {
      debugPrint('❌ Preview error: $e');
      _errorMessage = 'Lỗi preview: $e';
      return false;
    } finally {
      _isPreviewMode = false;
      notifyListeners();
    }
  }

  /// Process batch attendance
  Future<bool> processBatch() async {
    if (!canProcess) {
      _errorMessage = 'Chưa đủ thông tin để xử lý';
      notifyListeners();
      return false;
    }

    _isProcessingBatch = true;
    _errorMessage = null;
    _lastProcessResult = null;
    notifyListeners();

    try {
      final request = _buildBatchRequest();
      debugPrint('💼 Processing batch: ${request.records.length} records');

      _lastProcessResult = await _attendanceService.processManualBatchAttendance(request);
      debugPrint('✅ Batch processed: ${_lastProcessResult!.summaryMessage}');

      // If successful, reload employee data to reflect changes
      if (_lastProcessResult!.success && _selectedDepartmentId != null) {
        await loadEmployeesForDepartment(_selectedDepartmentId!);
      }
      
      return _lastProcessResult!.success;
    } catch (e) {
      debugPrint('❌ Processing error: $e');
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        _errorMessage = 'Không có quyền thực hiện chấm công thủ công.';
      } else if (e.toString().contains('Network') || e.toString().contains('Connection')) {
        _errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet.';
      } else {
        _errorMessage = 'Lỗi xử lý: ${e.toString().replaceAll('Exception: ', '')}';
      }
      return false;
    } finally {
      _isProcessingBatch = false;
      notifyListeners();
    }
  }

  /// Build batch request from current state
  ManualBatchAttendanceRequest _buildBatchRequest() {
    final records = modifiedEmployees
        .map((emp) => emp.toManualAttendanceRecord())
        .whereType<ManualAttendanceRecord>()
        .toList();

    return ManualBatchAttendanceRequest(
      date: _selectedDate,
      records: records,
      reason: _reason.trim(),
    );
  }

  // ==================== UTILITY METHODS ====================

  /// Clear all data
  void clearAll() {
    _selectedDate = DateTime.now();
    _selectedDepartmentId = null;
    _allEmployees.clear();
    _todayAttendances.clear();
    _employeeAttendanceList.clear();
    _reason = '';
    _lastProcessResult = null;
    _lastPreviewResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh current data
  Future<void> refresh() async {
    if (_selectedDepartmentId != null) {
      await loadEmployeesForDepartment(_selectedDepartmentId!);
    }
  }

  /// Clear errors
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get department name by ID
  String getDepartmentName(int departmentId) {
    final dept = _departments.where((d) => d.id == departmentId).firstOrNull;
    return dept?.name ?? 'Unknown';
  }

  @override
  void dispose() {
    debugPrint('🗑️ ManualAttendanceProvider: Disposing...');
    super.dispose();
  }
}
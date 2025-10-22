import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/employee.dart';
import '../../models/dto/payroll_dtos.dart';
import '../../models/dto/attendance_dtos.dart';
import '../../models/dto/today_attendance_dto.dart';
import '../../models/dto/working_hours_dtos.dart';
import '../../services/employee_api_service.dart';
import '../../services/payroll_api_service.dart';
import '../../services/attendance_api_service.dart';
import '../../services/working_hours_api_service.dart';
import '../../config/app_theme.dart';
import '../payroll/widgets/edit_adjustment_dialog.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final int employeeId;

  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  final EmployeeApiService _employeeService = EmployeeApiService();
  final PayrollApiService _payrollService = PayrollApiService();
  final AttendanceApiService _attendanceService = AttendanceApiService();
  final WorkingHoursApiService _workingHoursService = WorkingHoursApiService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  
  Employee? _employee;
  List<SalaryAdjustmentResponse> _salaryAdjustments = [];
  PayrollRecordResponse? _currentPayroll;
  List<PayrollRecordResponse> _salaryHistory = [];
  List<AttendanceRecordResponse> _recentAttendance = [];
  TodayAttendanceApiResponse? _todayAttendance;
  AttendanceStatsData? _attendanceStats;
  WorkingHoursPeriodSummary? _workingHoursSummary;
  bool _isLoading = true;
  bool _isLoadingSecondaryData = false;
  bool _isLoadingAdjustments = false;
  bool _isLoadingPayroll = false;
  bool _isLoadingSalaryHistory = false;
  bool _isLoadingAttendance = false;
  bool _isLoadingWorkingHours = false;
  String? _error;

  /// Safe currency formatting với error handling
  String _safeCurrencyFormat(dynamic value) {
    try {
      if (value == null) return '₫0';
      
      final double amount = value is double ? value : double.tryParse(value.toString()) ?? 0.0;
      return _currencyFormat.format(amount);
    } catch (e) {
      debugPrint('Currency format error: $e');
      return '₫0';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadEmployeeDetails();
  }

  Future<void> _loadEmployeeDetails() async {
    // Reset state properly
    if (!mounted) return;
    debugPrint(">>> Starting _loadEmployeeDetails for employee ID: ${widget.employeeId}");
    
    setState(() {
      _isLoading = true; // Start main loading
      _error = null;
      _employee = null;
      _salaryAdjustments = []; // Reset secondary data
      _currentPayroll = null;
    });

    try {
      // --- STEP 1: Load EMPLOYEE DATA ---
      debugPrint(">>> Calling API to get employee by ID: ${widget.employeeId}");
      final employeeResponse = await _employeeService.getEmployeeById(widget.employeeId);
      if (!mounted) return; // Check after await

      debugPrint(">>> API Response: success=${employeeResponse.success}, data=${employeeResponse.data != null ? 'not null' : 'null'}");
      
      if (employeeResponse.success && employeeResponse.data != null) {
        // --- SUCCESS: Employee data loaded ---
        debugPrint(">>> SUCCESS: Employee data received: ${employeeResponse.data!.fullName}");
        debugPrint(">>> Setting employee state and turning off loading...");
        
        setState(() {
          _employee = employeeResponse.data!;
          _isLoading = false; // <<< TURN OFF MAIN LOADING as soon as we have employee
        });

        debugPrint(">>> Employee state set successfully. Now loading secondary data...");

        // --- STEP 2: Load SECONDARY DATA (Salary, Adjustments & Attendance) ---
        setState(() {
          _isLoadingSecondaryData = true;
        });

        await _loadSalaryAdjustments();   // Load salary adjustments
        await _loadCurrentPayroll();      // Load current payroll
        await _loadSalaryHistory();       // Load salary history
        await _loadAttendanceData();      // Load attendance data
        await _loadWorkingHoursSummary(); // Load working hours summary

        if (mounted) {
          setState(() {
            _isLoadingSecondaryData = false;
          });
        }

        debugPrint(">>> All data loading completed successfully!");

      } else {
        // --- FAILURE: Employee data failed to load ---
        debugPrint(">>> FAILURE: Employee API failed - ${employeeResponse.message}");
        setState(() {
          _error = employeeResponse.message ?? 'Không thể tải thông tin nhân viên';
          _isLoading = false; // Turn off main loading when there's employee loading error
        });
      }
    } catch (e) {
      // --- CRITICAL ERROR: Employee loading failed ---
      debugPrint(">>> CRITICAL ERROR: Exception in _loadEmployeeDetails - $e");
      if (!mounted) return;
      setState(() {
        _error = 'Lỗi tải thông tin nhân viên: ${e.toString()}';
        _isLoading = false; // Turn off main loading when there's critical error
      });
    }
    // No finally block needed anymore
  }

  Future<void> _deleteEmployee() async {
    if (_employee == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.errorColor, size: 28),
            const SizedBox(width: 12),
            const Text('Xác nhận xóa nhân viên'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nhân viên: ${_employee!.fullName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Mã NV: ${_employee!.employeeCode}'),
                  Text('Phòng ban: ${_employee!.departmentName ?? "Chưa xác định"}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Nhân viên sẽ chuyển sang trạng thái "Tạm dừng" và có thể khôi phục sau.',
              style: TextStyle(fontSize: 14, color: Colors.orange),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dữ liệu chấm công và lương sẽ được giữ nguyên.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa nhân viên'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response = await _employeeService.deleteEmployee(widget.employeeId);
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Đã xóa nhân viên "${_employee!.fullName}" thành công'),
              ],
            ),
            backgroundColor: AppColors.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Navigate back to employee list
        Navigator.pop(context, true); // Return true to indicate deletion success
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${response.message ?? "Không thể xóa nhân viên"}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _updateFaceId() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật Face ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _employee!.isFaceRegistered
                  ? 'Nhân viên đã có Face ID đăng ký.\nBạn muốn đăng ký lại khuôn mặt mới?'
                  : 'Nhân viên chưa có Face ID.\nBạn muốn đăng ký khuôn mặt?',
            ),
            if (_employee!.isFaceRegistered) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ảnh cũ sẽ bị xóa và thay bằng ảnh mới',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _employee!.isFaceRegistered
                  ? Colors.orange
                  : AppColors.primaryBlue,
            ),
            child: Text(
              _employee!.isFaceRegistered ? 'Đăng ký lại' : 'Đăng ký',
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Navigate to Face Registration with employee info
    final result = await Navigator.pushNamed(
      context,
      '/face/register',
      arguments: {
        'employee': _employee,
        'isReRegister': _employee!.isFaceRegistered,
      },
    );

    // Reload employee data if face was registered/re-registered
    if (result == true) {
      _loadEmployeeDetails();
    }
  }

  Future<void> _loadSalaryAdjustments() async {
    if (_employee == null) return;
    
    setState(() {
      _isLoadingAdjustments = true;
    });

    try {
      final response = await _payrollService.getEmployeeAdjustments(widget.employeeId);
      
      if (response.success && response.data != null) {
        setState(() {
          _salaryAdjustments = response.data!;
        });
      }
    } catch (e) {
      // Silent error for adjustments - không ảnh hưởng đến thông tin chính
      debugPrint('Failed to load salary adjustments: $e');
    } finally {
      setState(() {
        _isLoadingAdjustments = false;
      });
    }
  }

  Future<void> _loadCurrentPayroll() async {
    if (_employee == null || !mounted) return;

    setState(() {
      _isLoadingPayroll = true;
      // Don't reset _currentPayroll here if you want to keep old value during refresh
    });

    try {
      final response = await _payrollService.getEmployeePayroll(1, widget.employeeId); // TODO: Get periodId dynamically
      if (!mounted) return; // Check after await

      if (response.success && response.data != null) {
        setState(() {
          _currentPayroll = response.data!;
        });
      } else {
        // API success but success=false or 404 returned like this
        setState(() {
          _currentPayroll = null; // <<< Important: Set to null when not found
        });
        debugPrint('Failed to load payroll: ${response.message}');
      }
    } catch (e, stackTrace) {
       if (!mounted) return; // Check after await
       setState(() {
         _currentPayroll = null; // <<< Important: Set to null when error occurs
       });
       debugPrint('Failed to load current payroll: $e');
       debugPrint('Stack trace: $stackTrace');
       // Can show SnackBar if desired, but don't set _error globally
       // ScaffoldMessenger.of(context).showSnackBar(...);
    } finally {
      if (!mounted) return; // Check after await
      setState(() {
        _isLoadingPayroll = false;
      });
    }
  }

  Future<void> _loadSalaryHistory() async {
    if (_employee == null || !mounted) return;

    setState(() {
      _isLoadingSalaryHistory = true;
    });

    try {
      // TODO: Implement getEmployeePayrollHistory API when backend is ready
      // For now, we'll use a placeholder or load multiple periods
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading
      
      if (!mounted) return;
      setState(() {
        _salaryHistory = []; // Empty for now until API is implemented
      });
      
      debugPrint('Salary history loading completed (placeholder)');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _salaryHistory = [];
      });
      debugPrint('Failed to load salary history: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingSalaryHistory = false;
      });
    }
  }

  /// Load attendance data (today's attendance, recent history, and stats)
  Future<void> _loadAttendanceData() async {
    if (_employee == null || !mounted) return;

    setState(() {
      _isLoadingAttendance = true;
    });

    // Load today's attendance - independent error handling
    try {
      final todayResponse = await _attendanceService.getEmployeeTodayAttendance(widget.employeeId);
      if (mounted && todayResponse.success) {
        setState(() {
          _todayAttendance = todayResponse;
        });
      } else if (mounted) {
        // API returned success=false or 404 - this is normal for new employees
        debugPrint('Today attendance not found for employee ${widget.employeeId}: ${todayResponse.message}');
        setState(() {
          _todayAttendance = null;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to load today attendance for employee ${widget.employeeId}: $e');
      debugPrint('Stack trace: ${stackTrace.toString()}');
      // Set null state to show "no data" UI instead of error
      if (mounted) {
        setState(() {
          _todayAttendance = null;
        });
      }
    }

    // Load recent attendance history - independent error handling
    try {
      final historyRequest = AttendanceHistoryRequest(
        employeeId: widget.employeeId,
        fromDate: DateTime.now().subtract(const Duration(days: 7)),
        toDate: DateTime.now(),
        pageSize: 10,
        sortBy: 'date',
        sortOrder: 'desc',
      );
      
      final historyResponse = await _attendanceService.getEmployeeAttendanceHistory(
        widget.employeeId,
        historyRequest,
      );
      
      if (mounted && historyResponse.success) {
        setState(() {
          _recentAttendance = historyResponse.records;
        });
      } else if (mounted) {
        // API returned success=false or 404 - normal for employees with no attendance history
        debugPrint('Attendance history not found for employee ${widget.employeeId}: ${historyResponse.message}');
        setState(() {
          _recentAttendance = [];
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to load attendance history for employee ${widget.employeeId}: $e');
      debugPrint('Stack trace: ${stackTrace.toString()}');
      // Set empty list to show "no data" UI instead of error
      if (mounted) {
        setState(() {
          _recentAttendance = [];
        });
      }
    }

    // Load attendance statistics - independent error handling
    try {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final statsRequest = AttendanceStatsRequest(
        employeeId: widget.employeeId,
        fromDate: firstDayOfMonth,
        toDate: now,
        period: 'monthly',
      );
      
      final statsResponse = await _attendanceService.getEmployeeAttendanceStatistics(
        widget.employeeId,
        statsRequest,
      );
      
      if (mounted && statsResponse.success && statsResponse.stats != null) {
        setState(() {
          _attendanceStats = statsResponse.stats!;
        });
      } else if (mounted) {
        // API returned success=false or no stats - normal for new employees
        debugPrint('Attendance statistics not found for employee ${widget.employeeId}: ${statsResponse.message}');
        setState(() {
          _attendanceStats = null;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to load attendance statistics for employee ${widget.employeeId}: $e');
      debugPrint('Stack trace: ${stackTrace.toString()}');
      // Set null to show "no data" UI instead of error
      if (mounted) {
        setState(() {
          _attendanceStats = null;
        });
      }
    }

    // Always complete loading regardless of individual API failures
    if (mounted) {
      setState(() {
        _isLoadingAttendance = false;
      });
    }
  }

  /// 🕐 Load Working Hours Summary (from October to now)
  Future<void> _loadWorkingHoursSummary() async {
    if (_employee == null) return;
    
    if (!mounted) return;
    setState(() {
      _isLoadingWorkingHours = true;
    });

    try {
      debugPrint("🕐 Loading working hours summary for employee ${_employee!.id}");
      
      // Calculate from October 2025 to current month
      final fromYear = 2025;
      final fromMonth = 10;
      
      final summary = await _workingHoursService.getWorkingHoursSummaryFromMonth(
        _employee!.id,
        _employee!.fullName,
        fromYear,
        fromMonth,
      );
      
      if (mounted) {
        setState(() {
          _workingHoursSummary = summary;
        });
        debugPrint("✅ Working hours summary loaded: ${summary.formattedTotalHours}, ${summary.formattedTotalWorkingDays}");
      }
    } catch (e) {
      debugPrint("❌ Failed to load working hours summary: $e");
      if (mounted) {
        setState(() {
          _workingHoursSummary = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWorkingHours = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: const Text('Chi Tiết Nhân Viên'),
        actions: [
          if (_employee != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    Navigator.pushNamed(
                      context,
                      '/employee/edit',
                      arguments: {'employee': _employee},
                    ).then((_) => _loadEmployeeDetails());
                    break;
                  case 'update_face':
                    _updateFaceId();
                    break;
                  case 'delete':
                    _deleteEmployee();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 12),
                      Text('Chỉnh sửa'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'update_face',
                  child: Row(
                    children: [
                      Icon(Icons.face, size: 20),
                      SizedBox(width: 12),
                      Text('Cập nhật Face ID'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Xóa nhân viên',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildSafeBody(),
      bottomNavigationBar: _employee != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/employee/edit',
                            arguments: {'employee': _employee},
                          ).then((_) => _loadEmployeeDetails());
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Chỉnh sửa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _updateFaceId,
                        icon: const Icon(Icons.face),
                        label: const Text('Face ID'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  /// Safe wrapper cho body với error boundary
  Widget _buildSafeBody() {
    try {
      return _buildBody();
    } catch (e, stackTrace) {
      debugPrint('Error building body: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Đã xảy ra lỗi khi hiển thị thông tin',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Lỗi: $e',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                  _loadEmployeeDetails();
                },
                child: const Text('Thử lại'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildBody() {
    // Primary loading - loading employee basic information
    if (_isLoading && _employee == null) {
      debugPrint(">>> Employee Detail Screen: Loading primary data...");
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Đang tải thông tin nhân viên...',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      );
    }

    // Primary error - employee data failed to load
    if (_error != null && _employee == null) {
      debugPrint(">>> Employee Detail Screen: Primary error state - $_error");
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
            const SizedBox(height: 16),
            Text(_error!, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEmployeeDetails,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    // Employee data not found
    if (_employee == null) {
      debugPrint(">>> Employee Detail Screen: Employee is null");
      return const Center(child: Text('Không tìm thấy thông tin nhân viên'));
    }

    // Add debug print to confirm we have employee data
    debugPrint(">>> Building employee UI. Employee: ${_employee!.fullName} (ID: ${_employee!.id})");
    debugPrint(">>> Employee data: departmentName=${_employee!.departmentName}, email=${_employee!.email}");

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar & Name Card
          _buildProfileCard(),
          const SizedBox(height: AppSpacing.lg),

          // Information Sections
          _buildSection(
            title: 'Thông tin cơ bản',
            children: [
              _buildInfoRow('Mã nhân viên', '#${_employee!.id}'),
              _buildInfoRow('Họ tên', _employee!.fullName.isNotEmpty ? _employee!.fullName : 'Chưa có tên'),
              _buildInfoRow('Email', _employee!.email?.isNotEmpty == true ? _employee!.email! : 'Chưa có'),
              _buildInfoRow(
                'Số điện thoại',
                _employee!.phoneNumber?.isNotEmpty == true ? _employee!.phoneNumber! : 'Chưa có',
              ),
              _buildInfoRow('Chức vụ', _employee!.position?.isNotEmpty == true ? _employee!.position! : 'Chưa có'),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          _buildSection(
            title: 'Phòng ban & Vai trò',
            children: [
              _buildInfoRow('Phòng ban', _employee!.departmentName ?? 'Chưa xác định'),
              if (_employee!.departmentCode != null)
                _buildInfoRow('Mã phòng ban', _employee!.departmentCode!),
              _buildInfoRow('Vai trò', _employee!.roleName ?? 'Chưa có'),
              if (_employee!.roleLevel != null)
                _buildInfoRow('Cấp độ', _employee!.roleLevel.toString()),
              _buildInfoRow(
                'Tài khoản hệ thống',
                _employee!.hasAccount ? 'Đã cấp' : 'Chưa cấp',
                valueColor: _employee!.hasAccount 
                    ? AppColors.successColor 
                    : AppColors.textSecondary,
              ),
              if (_employee!.accountProvisionedAt != null)
                _buildInfoRow(
                  'Ngày cấp tài khoản',
                  _formatDate(_employee!.accountProvisionedAt!),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          _buildSection(
            title: 'Face ID',
            children: [
              _buildInfoRow(
                'Trạng thái',
                _employee!.isFaceRegistered ? 'Đã đăng ký' : 'Chưa đăng ký',
                valueColor: _employee!.isFaceRegistered
                    ? AppColors.successColor
                    : AppColors.errorColor,
              ),
              if (_employee!.faceImageUrl != null)
                _buildInfoRow('Face URL', _employee!.faceImageUrl!),
              if (_employee!.faceRegisteredAt != null)
                _buildInfoRow(
                  'Ngày đăng ký',
                  _formatDate(_employee!.faceRegisteredAt!),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // � Activity Status Section
          _buildSection(
            title: 'Trạng thái Hoạt động',
            children: [
              _buildInfoRow(
                'Trạng thái', 
                _employee!.currentStatus ?? 'Offline',
                valueColor: _employee!.currentStatus == "Working" 
                            ? AppColors.successColor 
                            : AppColors.textSecondary,
              ),
              // Chỉ hiển thị thời gian check-in nếu có
              if (_employee!.lastCheckInToday != null)
                _buildInfoRow(
                  'Check-in lần cuối (hôm nay)', 
                  _formatDate(_employee!.lastCheckInToday!)
                ),
              // Chỉ hiển thị thời gian cập nhật nếu có
              if (_employee!.statusUpdatedAt != null)
                _buildInfoRow(
                  'Cập nhật lúc', 
                  _formatDate(_employee!.statusUpdatedAt!)
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // �💰 Basic Salary Information Section
          // Loading indicator for secondary data
          if (_isLoadingSecondaryData)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Đang tải thông tin lương & chấm công...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          _buildBasicSalarySection(),

          const SizedBox(height: AppSpacing.lg),

          // 💰 Current Salary Information Section
          _buildCurrentSalarySection(),
          
          const SizedBox(height: AppSpacing.lg),

          // 💰 Salary Adjustments Section  
          _buildSalaryAdjustmentsSection(),
          
          const SizedBox(height: AppSpacing.lg),

          // � Salary History Section
          _buildSalaryHistorySection(),
          
          const SizedBox(height: AppSpacing.lg),

          // �📊 Attendance Section
          _buildAttendanceSection(),
          
          const SizedBox(height: AppSpacing.lg),

          // 🕐 Working Hours Summary Section
          _buildWorkingHoursSummarySection(),
          
          const SizedBox(height: AppSpacing.lg),

          _buildSection(
            title: 'Thông tin khác',
            children: [
              _buildInfoRow(
                'Trạng thái',
                _employee!.isActive ? 'Đang làm việc' : 'Đã nghỉ',
                valueColor: _employee!.isActive
                    ? AppColors.successColor
                    : AppColors.textSecondary,
              ),
              _buildInfoRow('Ngày vào làm', _formatDate(_employee!.joinDate)),
              _buildInfoRow(
                'Ngày tạo hồ sơ',
                _formatDate(_employee!.createdAt),
              ),
            ],
          ),

          const SizedBox(height: 100), // Space for bottom buttons
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _employee!.isActive ? AppColors.primaryBlue : Colors.grey.shade600,
            _employee!.isActive ? AppColors.primaryDark : Colors.grey.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        boxShadow: [
          BoxShadow(
            color: (_employee!.isActive ? AppColors.primaryBlue : Colors.grey)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with badge
          Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _employee!.isFaceRegistered
                      ? Icons.face_retouching_natural
                      : Icons.person_outline,
                  size: 55,
                  color: Colors.white,
                ),
              ),
              if (_employee!.isFaceRegistered)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.successColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Name
          Text(
            _employee!.fullName.isNotEmpty ? _employee!.fullName : 'Chưa có tên',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Employee Code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _employee!.employeeCode.isNotEmpty ? _employee!.employeeCode : 'EMP${_employee!.id}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Position
          Text(
            _employee!.position ?? 'Chưa có chức vụ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: _employee!.isActive
                  ? Colors.white.withOpacity(0.25)
                  : Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _employee!.isActive
                        ? Colors.greenAccent.shade200
                        : Colors.red.shade200,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _employee!.isActive ? 'Đang làm việc' : 'Đã nghỉ việc',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                // Current Status Indicator
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _employee!.currentStatus == "Working"
                        ? Colors.greenAccent.shade400
                        : Colors.grey,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_employee!.currentStatus == "Working"
                                ? Colors.greenAccent.shade400
                                : Colors.grey)
                            .withOpacity(0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.h5.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.bgColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 💰 BASIC SALARY INFORMATION SECTION
  Widget _buildBasicSalarySection() {
    return _buildSection(
      title: 'Thông tin lương cơ bản',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade50,
                Colors.blue.shade100,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,  
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.monetization_on,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Lương cơ bản theo vị trí',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Basic salary info based on position and department
              _buildBasicSalaryInfoRow(
                'Vị trí',
                _employee?.position ?? 'Chưa xác định',
                icon: Icons.work,
              ),
              _buildBasicSalaryInfoRow(
                'Phòng ban',
                _employee?.departmentName ?? 'Chưa xác định',
                icon: Icons.business,
              ),
              
              const Divider(height: 20),
              
              // Current payroll status
              if (_isLoadingPayroll)
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Đang tải thông tin lương hiện tại...',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_currentPayroll != null)
                Column(
                  children: [
                    _buildBasicSalaryInfoRow(
                      'Lương cơ bản hiện tại',
                      _safeCurrencyFormat(_currentPayroll!.baseSalaryActual),
                      icon: Icons.payments,
                      valueColor: Colors.green.shade700,
                      isBold: true,
                    ),
                    _buildBasicSalaryInfoRow(
                      'Kỳ lương',
                      'Kỳ ${_currentPayroll!.payrollPeriodId}',
                      icon: Icons.calendar_month,
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Chưa có thông tin lương cho kỳ hiện tại',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicSalaryInfoRow(
    String label, 
    String value, {
    IconData? icon,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: Colors.blue.shade600,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// 💰 CURRENT SALARY INFORMATION SECTION  
  Widget _buildCurrentSalarySection() {
    return _buildSection(
      title: '💰 Thông tin lương hiện tại',
      children: [
        if (_isLoadingPayroll) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ] else if (_currentPayroll == null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chưa có dữ liệu lương cho kỳ hiện tại.',
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhân viên này có thể chưa được tính lương hoặc chưa có trong kỳ lương hiện tại.',
                  style: TextStyle(color: Colors.orange.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons for salary management
          _buildSalaryActionButtons(),
        ] else ...[
          // Salary overview card
          _buildSalaryOverviewCard(),
          const SizedBox(height: 16),
          // Salary breakdown
          _buildSalaryBreakdown(),
          const SizedBox(height: 16),
          // Action buttons
          _buildSalaryActionButtons(),
        ],
      ],
    );
  }

  /// 📊 Salary Overview Card
  Widget _buildSalaryOverviewCard() {
    if (_currentPayroll == null) return const SizedBox();
    
    final isNegative = _currentPayroll!.netSalary < 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNegative 
            ? [Colors.red.shade400, Colors.red.shade600]
            : [AppColors.primaryBlue, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isNegative ? Colors.red : AppColors.primaryBlue).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isNegative) ...[
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 8),
              ],
              const Text(
                'LƯƠNG THỰC NHẬN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _safeCurrencyFormat(_currentPayroll!.netSalary),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                'Kỳ lương hiện tại',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📋 Salary Breakdown
  Widget _buildSalaryBreakdown() {
    if (_currentPayroll == null) return const SizedBox();
    
    return Column(
      children: [
        // Income section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.add_circle, color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Thu nhập',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSalaryInfoRow('Lương cơ bản', _currentPayroll!.baseSalaryActual),
              _buildSalaryInfoRow('Thu nhập OT', _currentPayroll!.totalOTPayment),
              _buildSalaryInfoRow('Phụ cấp', _currentPayroll!.totalAllowances),
              _buildSalaryInfoRow('Thưởng', _currentPayroll!.bonus),
              const Divider(),
              _buildSalaryInfoRow(
                'Tổng thu nhập', 
                _currentPayroll!.adjustedGrossIncome,
                isBold: true,
                color: Colors.green.shade700,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Deduction section  
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.remove_circle, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Khấu trừ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSalaryInfoRow('Bảo hiểm XH/YT/TN', _currentPayroll!.insuranceDeduction),
              _buildSalaryInfoRow('Thuế TNCN', _currentPayroll!.pitDeduction),
              _buildSalaryInfoRow('Khấu trừ khác', _currentPayroll!.otherDeductions),
              const Divider(),
              _buildSalaryInfoRow(
                'Tổng khấu trừ', 
                _currentPayroll!.insuranceDeduction + _currentPayroll!.pitDeduction + _currentPayroll!.otherDeductions,
                isBold: true,
                color: Colors.red.shade700,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalaryInfoRow(String label, double value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
          Text(
            _safeCurrencyFormat(value),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Salary Action Buttons
  Widget _buildSalaryActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Nếu màn hình nhỏ, hiển thị theo cột
        if (constraints.maxWidth < 500) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddAdjustmentDialog(type: 'BONUS'),
                      icon: const Icon(Icons.star_rounded, color: Colors.green, size: 16),
                      label: const Text(
                        'Thưởng',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddAdjustmentDialog(type: 'PENALTY'),
                      icon: const Icon(Icons.warning_rounded, color: Colors.red, size: 16),
                      label: const Text(
                        'Phạt',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditBaseSalaryDialog(),
                      icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 16),
                      label: const Text(
                        'Sửa lương',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to full salary detail screen
                        Navigator.pushNamed(
                          context,
                          '/payroll/employee-detail',
                          arguments: {
                            'periodId': 1, // TODO: Get current period ID
                            'employeeId': widget.employeeId,
                            'employeeName': _employee?.fullName ?? 'Chưa có tên',
                            'employeeCode': _employee?.employeeCode,
                            'department': 'ID: ${_employee?.departmentId ?? ''}',
                            'position': _employee?.position,
                          },
                        );
                      },
                      icon: const Icon(Icons.visibility_rounded, size: 16),
                      label: const Text('Chi tiết', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        
        // Màn hình lớn, hiển thị theo hàng
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showAddAdjustmentDialog(type: 'BONUS'),
                icon: const Icon(Icons.star_rounded, color: Colors.green),
                label: const Text(
                  'Thêm thưởng',
                  style: TextStyle(color: Colors.green),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showAddAdjustmentDialog(type: 'PENALTY'),
                icon: const Icon(Icons.warning_rounded, color: Colors.red),
                label: const Text(
                  'Thêm phạt',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showEditBaseSalaryDialog(),
                icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                label: const Text(
                  'Sửa lương',
                  style: TextStyle(color: Colors.blue),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to full salary detail screen
                  Navigator.pushNamed(
                    context,
                    '/payroll/employee-detail',
                    arguments: {
                      'periodId': 1, // TODO: Get current period ID
                      'employeeId': widget.employeeId,
                      'employeeName': _employee?.fullName ?? 'Chưa có tên',
                      'employeeCode': _employee?.employeeCode,
                      'department': 'ID: ${_employee?.departmentId ?? ''}',
                      'position': _employee?.position,
                    },
                  );
                },
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Xem chi tiết'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 💰 SALARY ADJUSTMENTS SECTION WITH EDIT FUNCTIONALITY
  Widget _buildSalaryAdjustmentsSection() {
    return _buildSection(
      title: '💰 Điều chỉnh lương',
      children: [
        if (_isLoadingAdjustments) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ] else if (_salaryAdjustments.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Chưa có khoản điều chỉnh lương nào',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        ] else ...[
          // Adjustments List
          ...(_salaryAdjustments.take(5).map((adjustment) => 
            _buildAdjustmentCard(adjustment))),
          
          if (_salaryAdjustments.length > 5) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                // TODO: Navigate to full adjustments list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Showing ${_salaryAdjustments.length} adjustments'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.expand_more, size: 18),
              label: Text('Xem tất cả (${_salaryAdjustments.length} khoản)'),
            ),
          ],
        ],
      ],
    );
  }

  /// 🎯 Individual Adjustment Card with Edit Button
  Widget _buildAdjustmentCard(SalaryAdjustmentResponse adjustment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: adjustment.getTypeColor().withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: adjustment.getTypeColor().withAlpha(50)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: adjustment.getTypeColor().withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getAdjustmentIcon(adjustment.adjustmentType),
                color: adjustment.getTypeColor(),
                size: 16,
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Content - Flexible để tránh overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Type và Amount - Flexible row
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          adjustment.getTypeLabel(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: adjustment.getTypeColor(),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _safeCurrencyFormat(adjustment.amount.abs()),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: adjustment.getTypeColor(),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Description
                  Text(
                    adjustment.description.isNotEmpty ? adjustment.description : 'Không có mô tả',
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Date và Status
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(adjustment.effectiveDate),
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!adjustment.canEdit) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'Đã xử lý',
                            style: TextStyle(fontSize: 8, color: Colors.black54),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Edit Button - Fixed width
            if (adjustment.canEdit) ...[
              const SizedBox(width: 4),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  onPressed: () => _editAdjustment(adjustment),
                  icon: const Icon(Icons.edit_rounded),
                  iconSize: 16,
                  color: adjustment.getTypeColor(),
                  tooltip: 'Sửa',
                  style: IconButton.styleFrom(
                    backgroundColor: adjustment.getTypeColor().withAlpha(25),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(width: 4),
              SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getAdjustmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bonus':
        return Icons.star_rounded;
      case 'penalty':
        return Icons.warning_rounded;
      case 'correction':
        return Icons.tune_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  /// 🎯 EDIT ADJUSTMENT ACTION
  void _editAdjustment(SalaryAdjustmentResponse adjustment) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditAdjustmentDialog(
        adjustment: adjustment,
        periodId: 1, // TODO: Get current period ID
        onUpdated: () {
          // Reload both employee data and adjustments
          _loadEmployeeDetails();
        },
      ),
    );

    if (result == true) {
      // Additional actions if needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Điều chỉnh lương đã được cập nhật thành công!'),
          backgroundColor: Color(0xFF34C759),
        ),
      );
    }
  }

  /// 💰 Show Edit Base Salary Dialog
  void _showEditBaseSalaryDialog() async {
    if (_employee == null) return;

    final result = await Navigator.pushNamed(
      context,
      '/payroll/edit-base-salary',
      arguments: {
        'employee': _employee!,
        'currentRule': null, // Will be loaded by the screen
      },
    );

    if (result is Map<String, dynamic> && result['success'] == true) {
      // Reload employee data to reflect changes
      _loadEmployeeDetails();
      
      // Show success message with details
      if (mounted) {
        final newSalary = result['newSalary'] as double?;
        final previousSalary = result['previousSalary'] as double?;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✅ Cập nhật lương thành công!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (previousSalary != null && newSalary != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Lương cũ: ${_safeCurrencyFormat(previousSalary)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Lương mới: ${_safeCurrencyFormat(newSalary)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
            backgroundColor: AppColors.successColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// 💰 Show Add Adjustment Dialog
  void _showAddAdjustmentDialog({String type = 'BONUS'}) {
    final reasonController = TextEditingController();
    final amountController = TextEditingController();
    
    final isBonus = type.toUpperCase() == 'BONUS';
    final typeName = isBonus ? 'thưởng' : 'phạt';
    final typeColor = isBonus ? Colors.green : Colors.red;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isBonus ? Icons.star_rounded : Icons.warning_rounded, 
              color: typeColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text('Thêm $typeName'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do',
                border: OutlineInputBorder(),
                hintText: 'Nhập lý do điều chỉnh...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Số tiền',
                border: OutlineInputBorder(),
                suffixText: '₫',
                hintText: '0',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.replaceAll(',', '')) ?? 0;
              if (reasonController.text.isEmpty || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập đầy đủ thông tin hợp lệ'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                final request = CreateSalaryAdjustmentRequest(
                  employeeId: widget.employeeId,
                  adjustmentType: type,
                  amount: type.toUpperCase() == 'PENALTY' ? -amount : amount,
                  effectiveDate: DateTime.now(),
                  description: reasonController.text,
                  createdBy: 'HR Admin', // TODO: Get from auth service
                );

                final response = await _payrollService.createSalaryAdjustment(request);

                // Close loading
                if (mounted) Navigator.pop(context);

                if (response.success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Đã thêm $typeName thành công!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  
                  // Reload data
                  _loadEmployeeDetails();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: ${response.message ?? "Không thể thêm $typeName"}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                // Close loading
                if (mounted) Navigator.pop(context);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: typeColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Thêm $typeName'),
          ),
        ],
      ),
    );
  }

  /// � SALARY HISTORY SECTION
  Widget _buildSalaryHistorySection() {
    return _buildSection(
      title: '💰 Lịch sử lương',
      children: [
        if (_isLoadingSalaryHistory) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ] else if (_salaryHistory.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade50,
                  Colors.orange.shade100,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Chưa có lịch sử lương',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Lịch sử lương sẽ hiển thị sau khi có kỳ lương đầu tiên được tính toán.',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 14,
                  ),
                ),
                if (_currentPayroll != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.payment,
                              color: Colors.green.shade600,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Lương hiện tại (Kỳ ${_currentPayroll!.payrollPeriodId})',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lương thực nhận:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              _safeCurrencyFormat(_currentPayroll!.netSalary),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ngày tính lương:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              _formatDate(_currentPayroll!.calculatedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ] else ...[
          // Future: Display salary history when API is implemented
          Column(
            children: _salaryHistory.take(5).map((record) => 
              _buildSalaryHistoryCard(record)
            ).toList(),
          ),
          
          if (_salaryHistory.length > 5) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Navigate to full salary history screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Xem lịch sử lương chi tiết (Coming soon)'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.history, size: 16),
              label: Text('Xem tất cả ${_salaryHistory.length} kỳ lương'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: BorderSide(color: AppColors.primaryBlue),
              ),
            ),
          ],
        ],
        
        const SizedBox(height: 16),
        
        // Salary statistics summary
        _buildSalarySummaryStats(),
      ],
    );
  }

  Widget _buildSalaryHistoryCard(PayrollRecordResponse record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kỳ lương ${record.payrollPeriodId}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                _safeCurrencyFormat(record.netSalary),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lương cơ bản',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                _safeCurrencyFormat(record.baseSalaryActual),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ngày tính lương',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                _formatDate(record.calculatedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalarySummaryStats() {
    if (_currentPayroll == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade500, size: 20),
            const SizedBox(width: 8),
            Text(
              'Không có dữ liệu thống kê lương',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Thống kê lương',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Số ngày làm việc',
                  '${_currentPayroll!.totalWorkingDays.toInt()} ngày',
                  Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Giờ OT',
                  '${_currentPayroll!.totalOTHours.toStringAsFixed(1)}h',
                  Icons.access_time,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Tổng thu nhập',
                  _safeCurrencyFormat(_currentPayroll!.adjustedGrossIncome),
                  Icons.trending_up,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Tổng khấu trừ',
                  _safeCurrencyFormat(
                    _currentPayroll!.insuranceDeduction + 
                    _currentPayroll!.pitDeduction + 
                    _currentPayroll!.otherDeductions
                  ),
                  Icons.trending_down,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: color ?? Colors.blue.shade600,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  /// �📊 ATTENDANCE SECTION
  Widget _buildAttendanceSection() {
    return _buildSection(
      title: '📊 Thông tin chấm công',
      children: [
        if (_isLoadingAttendance) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ] else ...[
          // Today's attendance card
          if (_todayAttendance != null) _buildTodayAttendanceCard(),
          
          const SizedBox(height: 16),
          
          // Attendance statistics
          if (_attendanceStats != null) _buildAttendanceStatsCard(),
          
          const SizedBox(height: 16),
          
          // Recent attendance history
          _buildRecentAttendanceList(),
          
          const SizedBox(height: 16),
          
          // View full attendance history button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/attendance/employee-history',
                arguments: {
                  'employeeId': widget.employeeId,
                  'employeeName': _employee?.fullName ?? 'Chưa có tên',
                  'employeeCode': _employee?.employeeCode,
                },
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('Xem lịch sử chấm công đầy đủ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  /// Today's attendance card
  Widget _buildTodayAttendanceCard() {
    if (_todayAttendance == null || (!_todayAttendance!.hasCheckedIn && !_todayAttendance!.hasCheckedOut)) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            const Text('Chưa có dữ liệu chấm công hôm nay'),
          ],
        ),
      );
    }

    final attendance = _todayAttendance!;
    final statusColor = attendance.getStatusColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Chấm công hôm nay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  attendance.statusDisplay,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeInfo(
                  'Giờ vào',
                  attendance.checkIn?.checkTime,
                  Icons.login,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeInfo(
                  'Giờ ra',
                  attendance.checkOut?.checkTime,
                  Icons.logout,
                  Colors.orange,
                ),
              ),
            ],
          ),
          if (attendance.workingHoursDisplay != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.blue.shade600),
                const SizedBox(width: 4),
                Text(
                  'Giờ làm việc: ${attendance.workingHoursDisplay}',
                  style: TextStyle(fontSize: 14, color: Colors.blue.shade600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build time info widget
  Widget _buildTimeInfo(String label, DateTime? time, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time != null 
            ? DateFormat('HH:mm').format(time)
            : '--:--',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Attendance statistics card
  Widget _buildAttendanceStatsCard() {
    if (_attendanceStats == null) return const SizedBox();

    final stats = _attendanceStats!;
    final attendanceRate = stats.attendanceRate;
    final rateColor = AttendanceApiService.getAttendanceRateColor(attendanceRate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: rateColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Thống kê tháng này',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rateColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${attendanceRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Tổng ngày',
                  stats.totalDays.toString(),
                  Icons.calendar_month,
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Có mặt',
                  stats.presentDays.toString(),
                  Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Vắng',
                  stats.absentDays.toString(),
                  Icons.cancel,
                  color: Colors.red,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Đi muộn',
                  stats.lateDays.toString(),
                  Icons.access_time,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Recent attendance list
  Widget _buildRecentAttendanceList() {
    if (_recentAttendance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            const Text('Chưa có lịch sử chấm công'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, size: 18, color: Colors.blue),
            const SizedBox(width: 6),
            const Text(
              'Lịch sử gần đây (7 ngày)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...(_recentAttendance.take(5).map((record) => _buildAttendanceItem(record))),
      ],
    );
  }

  /// Build attendance item
  Widget _buildAttendanceItem(AttendanceRecordResponse record) {
    final statusColor = record.getStatusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              _getAttendanceIcon(record.status),
              color: statusColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(record.date),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        record.getStatusDisplayText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (record.checkInTime != null) ...[
                      Icon(Icons.login, size: 12, color: Colors.green.shade600),
                      const SizedBox(width: 2),
                      Text(
                        DateFormat('HH:mm').format(record.checkInTime!),
                        style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (record.checkOutTime != null) ...[
                      Icon(Icons.logout, size: 12, color: Colors.orange.shade600),
                      const SizedBox(width: 2),
                      Text(
                        DateFormat('HH:mm').format(record.checkOutTime!),
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade600),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (record.workHours != null) ...[
                      Icon(Icons.access_time, size: 12, color: Colors.blue.shade600),
                      const SizedBox(width: 2),
                      Text(
                        AttendanceApiService.formatWorkHours(record.workHours),
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAttendanceIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
      case 'completed':
        return Icons.check_circle;
      case 'late':
        return Icons.access_time;
      case 'absent':
        return Icons.cancel;
      case 'early_leave':
        return Icons.exit_to_app;
      case 'working':
        return Icons.work;
      default:
        return Icons.help_outline;
    }
  }

  /// 🕐 Build Working Hours Summary Section
  Widget _buildWorkingHoursSummarySection() {
    return _buildSection(
      title: '🕐 Thống Kê Giờ Làm Việc (Từ tháng 10/2025)',
      children: [
        if (_isLoadingWorkingHours)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Đang tính toán giờ làm việc...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else if (_workingHoursSummary != null)
          _buildWorkingHoursSummaryCard()
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.textSecondary, size: 16),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Chưa có dữ liệu giờ làm việc',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 🕐 Build Working Hours Summary Card
  Widget _buildWorkingHoursSummaryCard() {
    if (_workingHoursSummary == null) return const SizedBox.shrink();
    
    final summary = _workingHoursSummary!;
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(0.1),
            AppColors.primaryBlue.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with period info
          Row(
            children: [
              Icon(Icons.schedule, color: AppColors.primaryBlue, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                summary.periodDescription,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${summary.monthlySummaries.length} tháng',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Total summary cards
          Row(
            children: [
              Expanded(
                child: _buildWorkingHoursMetricCard(
                  '⏰ Tổng Giờ Làm',
                  summary.formattedTotalHours,
                  '≈ ${summary.averageHoursPerMonth.toStringAsFixed(1)}h/tháng',
                  AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildWorkingHoursMetricCard(
                  '📅 Tổng Ngày Công',
                  summary.formattedTotalWorkingDays,
                  '≈ ${summary.averageWorkingDaysPerMonth.toStringAsFixed(1)} ngày/tháng',
                  AppColors.successColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Monthly breakdown title
          Text(
            'Chi tiết theo tháng:',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // Monthly breakdown list
          ...summary.monthlySummaries.map((monthSummary) {
            final isCurrentMonth = monthSummary.month == currentMonth && 
                                   monthSummary.year == currentYear;
            
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isCurrentMonth 
                    ? AppColors.primaryBlue.withOpacity(0.08)
                    : Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
                border: isCurrentMonth 
                    ? Border.all(color: AppColors.primaryBlue.withOpacity(0.3))
                    : null,
              ),
              child: Row(
                children: [
                  // Month indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isCurrentMonth 
                          ? AppColors.primaryBlue
                          : AppColors.textSecondary.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  
                  // Month name
                  Expanded(
                    flex: 2,
                    child: Text(
                      monthSummary.monthName,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: isCurrentMonth ? FontWeight.w600 : FontWeight.w500,
                        color: isCurrentMonth ? AppColors.primaryBlue : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  
                  // Hours
                  Expanded(
                    flex: 2,
                    child: Text(
                      monthSummary.formattedTotalHours,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Working days
                  Expanded(
                    flex: 2,
                    child: Text(
                      monthSummary.formattedWorkingDays,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Attendance rate
                  Expanded(
                    flex: 1,
                    child: Text(
                      monthSummary.formattedAttendanceRate,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: monthSummary.attendanceRate >= 90
                            ? AppColors.successColor
                            : monthSummary.attendanceRate >= 80
                                ? AppColors.warningColor
                                : AppColors.errorColor,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          const SizedBox(height: AppSpacing.sm),
          
          // Footer note
          Text(
            'Cập nhật lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(summary.calculatedAt)}',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// 🕐 Build Working Hours Metric Card
  Widget _buildWorkingHoursMetricCard(
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

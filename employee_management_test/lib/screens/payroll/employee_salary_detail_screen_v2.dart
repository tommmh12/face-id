import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/dto/payroll_dtos.dart';
import '../../services/payroll_api_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/pdf_generator.dart';
import '../../utils/permission_helper.dart';
import '../../config/app_theme.dart';
import 'audit_log_screen.dart';
import 'widgets/edit_adjustment_dialog.dart';

/// 💰 Employee Salary Detail Screen - Real Data from API
/// 
/// Features:
/// - Hiển thị chi tiết lương nhân viên (REAL DATA)
/// - Cho phép thêm thưởng/phạt (POST /adjustments)
/// - Cho phép sửa công (POST /attendance/correct)
/// - Xem lịch sử điều chỉnh
/// - Tính lại lương (POST /recalculate)
/// - Permission check (HR/Admin only)
class EmployeeSalaryDetailScreenV2 extends StatefulWidget {
  final int periodId;
  final int employeeId;

  const EmployeeSalaryDetailScreenV2({
    super.key,
    required this.periodId,
    required this.employeeId,
  });

  @override
  State<EmployeeSalaryDetailScreenV2> createState() => _EmployeeSalaryDetailScreenV2State();
}

class _EmployeeSalaryDetailScreenV2State extends State<EmployeeSalaryDetailScreenV2> {
  final PayrollApiService _payrollService = PayrollApiService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  PayrollRecordResponse? _payrollData;
  List<SalaryAdjustmentResponse> _adjustments = [];
  List<AllowanceResponse> _allowances = [];
  
  bool _isLoading = true;
  String? _error;

  // ✅ Permission System Integration
  User? _currentUser;
  bool get _canEdit => PermissionHelper.canEditPayroll(_currentUser);

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _loadData();
  }

  /// Initialize current user
  /// TODO: Replace with actual auth service
  void _initializeUser() {
    // DEMO: Mock user for testing
    // Replace with: _currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
    _currentUser = User(
      id: 1,
      username: 'admin',
      role: PermissionHelper.roleHR, // Change to test different roles
      employeeId: 1,
      fullName: 'HR Manager',
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      AppLogger.startOperation('Load Employee Salary Detail');

      // 1. Load payroll record
      final payrollResponse = await _payrollService.getEmployeePayroll(
        widget.periodId,
        widget.employeeId,
      );

      if (!payrollResponse.success || payrollResponse.data == null) {
        throw Exception(payrollResponse.message ?? 'Không tải được dữ liệu lương');
      }

      // 2. Load adjustments
      final adjustmentsResponse = await _payrollService.getEmployeeAdjustments(widget.employeeId);
      
      // 3. Load allowances
      final allowancesResponse = await _payrollService.getEmployeeAllowances(widget.employeeId);

      setState(() {
        _payrollData = payrollResponse.data;
        _adjustments = adjustmentsResponse.data ?? [];
        _allowances = allowancesResponse.data ?? [];
        _isLoading = false;
      });

      AppLogger.endOperation('Load Employee Salary Detail');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load salary detail', error: e, stackTrace: stackTrace, tag: 'SalaryDetail');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Chi tiết lương nhân viên'),
        actions: [
          // 📜 Audit Log - View employee-specific history
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuditLogScreen(),
                ),
              );
              // TODO: After screen loads, auto-filter by employee ID
              // Can be done by passing employeeId to AuditLogScreen constructor
            },
            tooltip: 'Lịch sử thay đổi',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
            tooltip: 'Xuất PDF',
          ),
          if (_canEdit) // ✅ Permission check
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showAdjustmentMenu(context),
              tooltip: 'Chỉnh sửa',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_payrollData == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmployeeHeader(),
            const SizedBox(height: 16),
            
            // ⚠️ Cảnh báo lương âm (nếu có)
            if (_payrollData!.netSalary < 0)
              _buildNegativeSalaryWarningBanner(),
            if (_payrollData!.netSalary < 0)
              const SizedBox(height: 16),
            
            // 📊 Dashboard Summary Card (nổi bật)
            _buildDashboardSummaryCard(),
            const SizedBox(height: 20),
            
            // 💰 Section I: Thu nhập
            _buildIncomeSection(),
            const SizedBox(height: 16),
            
            // 📉 Section II: Khấu trừ
            _buildDeductionSection(),
            const SizedBox(height: 16),
            
            // 💵 Lương thực nhận (Net Salary)
            _buildNetSalaryCard(),
            const SizedBox(height: 24),
            
            // 🎁 Phụ cấp & lịch sử điều chỉnh
            _buildAllowancesSection(),
            const SizedBox(height: 16),
            _buildAdjustmentsSection(),
            const SizedBox(height: 16),
            
            // 💰 TÙY CHỈNH LƯƠNG NHÂN VIÊN (NEW FEATURE)
            _buildSalaryCustomizationSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: PayrollColors.primary.withOpacity(0.1),
              child: Text(
                _payrollData!.employeeName.isNotEmpty 
                  ? _payrollData!.employeeName[0].toUpperCase()
                  : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: PayrollColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _payrollData!.employeeName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MSNV: ${_payrollData!.employeeId}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.business, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Phòng IT', // TODO: Get from employee data
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.work, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Senior Developer', // TODO: Get from employee data
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⚠️ Banner cảnh báo lương âm
  Widget _buildNegativeSalaryWarningBanner() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ CẢNH BÁO: LƯƠNG ÂM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tổng khấu trừ vượt quá thu nhập. Vui lòng kiểm tra lại các khoản BHXH, thuế, hoặc phạt.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Dashboard Summary Card - Hiển thị các chỉ số chính
  Widget _buildDashboardSummaryCard() {
    final isNegative = _payrollData!.netSalary < 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              PayrollColors.primary.withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📊 TỔNG QUAN BẢ LƯƠNG',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                // Period status chip removed - needs backend implementation
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            
            // Lương Ròng (Net Salary) - Chỉ số chính
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LƯƠNG THỰC NHẬN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(_payrollData!.netSalary),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isNegative ? Colors.red.shade700 : PayrollColors.success,
                      ),
                    ),
                  ],
                ),
                // Icon trạng thái
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isNegative ? Colors.red : PayrollColors.success).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isNegative ? Icons.trending_down : Icons.trending_up,
                    color: isNegative ? Colors.red.shade700 : PayrollColors.success,
                    size: 32,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            
            // Các chỉ số phụ (Grid layout 2x2)
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    icon: Icons.calendar_today,
                    label: 'Ngày công',
                    value: '${_payrollData!.totalWorkingDays} / 22',
                    color: PayrollColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryMetric(
                    icon: Icons.access_time,
                    label: 'Giờ OT',
                    value: '${_payrollData!.totalOTHours}h',
                    color: PayrollColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    icon: Icons.add_circle,
                    label: 'Thu nhập',
                    value: _currencyFormat.format(_payrollData!.adjustedGrossIncome),
                    color: PayrollColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryMetric(
                    icon: Icons.remove_circle,
                    label: 'Khấu trừ',
                    value: _currencyFormat.format(
                      _payrollData!.insuranceDeduction + 
                      _payrollData!.pitDeduction + 
                      _payrollData!.otherDeductions
                    ),
                    color: PayrollColors.error,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Thời gian tính lương
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Tính lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(_payrollData!.calculatedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget cho Summary Metric (chỉ số nhỏ trong Dashboard)
  Widget _buildSummaryMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeSection() {
    final income = _payrollData!.adjustedGrossIncome;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: PayrollColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_circle, color: PayrollColors.success, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  '💰 TỔNG THU NHẬP (A)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            _buildInfoRow('Lương Cơ bản', _currencyFormat.format(_payrollData!.baseSalaryActual)),
            _buildInfoRow('Thu nhập OT', _currencyFormat.format(_payrollData!.totalOTPayment)),
            _buildInfoRow('Tổng Phụ cấp', _currencyFormat.format(_payrollData!.totalAllowances)),
            _buildInfoRow(
              '🎁 THƯỞNG',
              _currencyFormat.format(_payrollData!.bonus),
              color: _payrollData!.bonus > 0 ? PayrollColors.success : null,
              isBold: _payrollData!.bonus > 0,
            ),
            const Divider(thickness: 2),
            _buildInfoRow(
              '� TỔNG GROSS (A)',
              _currencyFormat.format(income),
              isBold: true,
              color: PayrollColors.success,
              fontSize: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeductionSection() {
    final totalDeduction = _payrollData!.insuranceDeduction + 
                          _payrollData!.pitDeduction + 
                          _payrollData!.otherDeductions;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: PayrollColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.remove_circle, color: PayrollColors.error, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  '📉 TỔNG KHẤU TRỪ (B)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            _buildInfoRow('Bảo hiểm (XH/YT/TN)', _currencyFormat.format(_payrollData!.insuranceDeduction)),
            _buildInfoRow('Thuế TNCN', _currencyFormat.format(_payrollData!.pitDeduction)),
            
            // Khấu trừ khác với chú thích
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  '⚠️ Khấu trừ khác',
                  _currencyFormat.format(_payrollData!.otherDeductions),
                  color: _payrollData!.otherDeductions > 0 ? PayrollColors.error : null,
                  isBold: _payrollData!.otherDeductions > 0,
                ),
                if (_payrollData!.otherDeductions > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      '* Bao gồm cả tiền phạt (Penalty)',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
            
            const Divider(thickness: 2),
            _buildInfoRow(
              '� TỔNG KHẤU TRỪ (B)',
              _currencyFormat.format(totalDeduction),
              isBold: true,
              color: PayrollColors.error,
              fontSize: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetSalaryCard() {
    final isNegative = _payrollData!.netSalary < 0;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNegative 
            ? [Colors.red.shade700, Colors.red.shade900]
            : PayrollColors.gradientSuccess,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isNegative ? Colors.red : PayrollColors.success).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isNegative) ...[
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
              ],
              const Text(
                '💵 LƯƠNG THỰC NHẬN (A - B)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currencyFormat.format(_payrollData!.netSalary),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (isNegative) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '⚠️ LƯƠNG ÂM - Vui lòng kiểm tra lại',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Tính lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(_payrollData!.calculatedAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white60,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllowancesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.card_giftcard, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Phụ cấp hiện tại',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '(${_allowances.length})',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const Divider(),
            if (_allowances.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('Chưa có phụ cấp'),
                ),
              )
            else
              ..._allowances.map((allowance) => ListTile(
                leading: Icon(_getAllowanceIcon(allowance.allowanceType), color: PayrollColors.primary),
                title: Text(allowance.allowanceType),
                trailing: Text(
                  _currencyFormat.format(allowance.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: PayrollColors.success,
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Lịch sử điều chỉnh',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '(${_adjustments.length})',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (_canEdit) // ✅ Permission check
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddAdjustmentDialog(),
                    tooltip: 'Thêm điều chỉnh',
                  ),
              ],
            ),
            const Divider(),
            if (_adjustments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('Chưa có điều chỉnh')),
              )
            else
              ..._adjustments.take(5).map((adj) => ListTile(
                leading: Icon(
                  _getAdjustmentIcon(adj.adjustmentType),
                  color: _getAdjustmentColor(adj.adjustmentType),
                ),
                title: Text(adj.description),
                subtitle: Text(
                  '${DateFormat('dd/MM/yyyy').format(adj.effectiveDate)} • ${adj.getTypeLabel()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: Text(
                  _currencyFormat.format(adj.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: adj.amount >= 0 ? PayrollColors.success : PayrollColors.error,
                  ),
                ),
              )),
            if (_adjustments.length > 5)
              TextButton(
                onPressed: () {
                  // Show all adjustments dialog
                },
                child: const Text('Xem tất cả →'),
              ),
          ],
        ),
      ),
    );
  }

  /// 💰 TÙY CHỈNH LƯƠNG NHÂN VIÊN - Edit Salary Adjustments
  Widget _buildSalaryCustomizationSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              PayrollColors.primary.withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với icon nổi bật
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PayrollColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.tune_rounded, 
                      color: PayrollColors.primary, 
                      size: 28
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💰 TÙY CHỈNH LƯƠNG NHÂN VIÊN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Chỉnh sửa thưởng, phạt và điều chỉnh lương',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              
              // Danh sách adjustments có thể chỉnh sửa
              if (_adjustments.isEmpty)
                _buildEmptyAdjustmentsState()
              else
                _buildEditableAdjustmentsList(),
              
              const SizedBox(height: 20),
              
              // Action buttons
              if (_canEdit)
                _buildCustomizationActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty state khi chưa có adjustments
  Widget _buildEmptyAdjustmentsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.money_off_rounded,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'Chưa có khoản điều chỉnh lương nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Thêm thưởng, phạt hoặc điều chỉnh để tùy chỉnh lương nhân viên',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Danh sách adjustments có thể chỉnh sửa
  Widget _buildEditableAdjustmentsList() {
    return Column(
      children: _adjustments.map((adjustment) => 
        _buildEditableAdjustmentCard(adjustment)
      ).toList(),
    );
  }

  /// Card cho từng adjustment có thể chỉnh sửa
  Widget _buildEditableAdjustmentCard(SalaryAdjustmentResponse adjustment) {
    final canEdit = adjustment.canEdit; // Chỉ edit được nếu chưa processed
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: adjustment.getTypeColor().withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: adjustment.getTypeColor().withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: adjustment.getTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: adjustment.getTypeColor().withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getAdjustmentIcon(adjustment.adjustmentType),
                        size: 14,
                        color: adjustment.getTypeColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        adjustment.getTypeLabel(),
                        style: TextStyle(
                          color: adjustment.getTypeColor(),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                
                // Amount
                Text(
                  _currencyFormat.format(adjustment.amount),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: adjustment.getTypeColor(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              adjustment.description,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            // Details row
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(adjustment.effectiveDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  adjustment.lastUpdatedBy ?? adjustment.createdBy,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                
                // Status và Edit button
                if (!canEdit) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Đã xử lý',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_canEdit) ...[
                  ElevatedButton.icon(
                    onPressed: () => _editAdjustment(adjustment),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Sửa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: adjustment.getTypeColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Action buttons cho tùy chỉnh lương
  Widget _buildCustomizationActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showAddAdjustmentDialog(type: 'BONUS'),
            icon: const Icon(Icons.add_circle, color: PayrollColors.success),
            label: const Text(
              'Thêm thưởng',
              style: TextStyle(color: PayrollColors.success),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: PayrollColors.success),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showAddAdjustmentDialog(type: 'PENALTY'),
            icon: const Icon(Icons.remove_circle, color: PayrollColors.error),
            label: const Text(
              'Thêm phạt',
              style: TextStyle(color: PayrollColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: PayrollColors.error),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _recalculateSalary,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tính lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PayrollColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// Chỉnh sửa adjustment (mở EditAdjustmentDialog)
  void _editAdjustment(SalaryAdjustmentResponse adjustment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditAdjustmentDialog(
        adjustment: adjustment,
        periodId: widget.periodId,
        onUpdated: () {
          // Reload data sau khi cập nhật
          _loadData();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã cập nhật thành công ${adjustment.getTypeLabel().toLowerCase()} #${adjustment.id}!',
                    ),
                  ),
                ],
              ),
              backgroundColor: PayrollColors.success,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Xem',
                textColor: Colors.white,
                onPressed: () {
                  // Scroll to adjustments section or navigate
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? color, double? fontSize}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize ?? 14,
              color: Colors.grey[700],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize ?? 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjustmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_circle, color: PayrollColors.success),
            title: const Text('Thêm thưởng'),
            onTap: () {
              Navigator.pop(context);
              _showAddAdjustmentDialog(type: 'BONUS');
            },
          ),
          ListTile(
            leading: const Icon(Icons.remove_circle, color: PayrollColors.error),
            title: const Text('Thêm phạt'),
            onTap: () {
              Navigator.pop(context);
              _showAddAdjustmentDialog(type: 'PENALTY');
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time, color: PayrollColors.warning),
            title: const Text('Sửa chấm công'),
            onTap: () {
              Navigator.pop(context);
              _showCorrectAttendanceDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh, color: PayrollColors.primary),
            title: const Text('Tính lại lương'),
            onTap: () {
              Navigator.pop(context);
              _recalculateSalary();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAddAdjustmentDialog({String type = 'BONUS'}) {
    final reasonController = TextEditingController();
    final amountController = TextEditingController();
    
    final isBonus = type.toUpperCase() == 'BONUS';
    final typeName = isBonus ? 'thưởng' : 'phạt';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('➕ Thêm $typeName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Số tiền',
                border: OutlineInputBorder(),
                suffixText: '₫',
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
              final amount = double.tryParse(amountController.text) ?? 0;
              if (reasonController.text.isEmpty || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
                );
                return;
              }

              Navigator.pop(context);

              final request = CreateSalaryAdjustmentRequest(
                employeeId: widget.employeeId,
                adjustmentType: type,
                amount: type.toUpperCase() == 'PENALTY' ? -amount : amount,
                effectiveDate: DateTime.now(),
                description: reasonController.text,
                createdBy: 'HR Admin', // TODO: Get from auth service
              );

              final response = await _payrollService.createSalaryAdjustment(request);

              if (response.success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Đã thêm điều chỉnh thành công')),
                );
                _loadData();
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showCorrectAttendanceDialog() {
    final workingDaysController = TextEditingController(text: _payrollData!.totalWorkingDays.toString());
    final otHoursController = TextEditingController(text: _payrollData!.totalOTHours.toString());
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🕐 Chỉnh sửa chấm công'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: workingDaysController,
              decoration: const InputDecoration(
                labelText: 'Số ngày làm',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otHoursController,
              decoration: const InputDecoration(
                labelText: 'Giờ OT',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do chỉnh sửa',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
              Navigator.pop(context);

              final request = CorrectAttendanceRequest(
                employeeId: widget.employeeId,
                periodId: widget.periodId,
                date: DateTime.now(),
                workingDays: int.tryParse(workingDaysController.text),
                overtimeHours: double.tryParse(otHoursController.text),
                reason: reasonController.text,
                correctedBy: 'HR', // TODO: Get from auth
              );

              final response = await _payrollService.correctAttendance(request);

              if (response.success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Đã sửa chấm công thành công')),
                );
                _loadData();
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _recalculateSalary() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔄 Tính lại lương'),
        content: const Text('Bạn có chắc muốn tính lại lương cho kỳ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tính lại'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await _payrollService.recalculatePayroll(widget.periodId);
      
      if (response.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã tính lại lương thành công')),
        );
        _loadData();
      }
    }
  }

  IconData _getAllowanceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'lunch':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'phone':
        return Icons.phone;
      case 'housing':
        return Icons.home;
      case 'position':
        return Icons.work;
      default:
        return Icons.card_giftcard;
    }
  }

  IconData _getAdjustmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bonus':
        return Icons.card_giftcard;
      case 'penalty':
        return Icons.warning;
      default:
        return Icons.edit;
    }
  }

  Color _getAdjustmentColor(String type) {
    switch (type.toLowerCase()) {
      case 'bonus':
        return PayrollColors.success;
      case 'penalty':
        return PayrollColors.error;
      default:
        return PayrollColors.warning;
    }
  }

  // ============ PDF EXPORT ============

  Future<void> _exportToPdf() async {
    if (_payrollData == null) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tạo PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Generate PDF
      final pdf = await PayrollPdfGenerator.generatePayslip(
        record: _payrollData!,
        periodName: 'Kỳ lương #${widget.periodId}', // TODO: Get real period name
        companyName: 'CÔNG TY CỔ PHẦN XYZ',
        companyAddress: 'Hà Nội, Việt Nam',
      );

      // Close loading
      if (mounted) Navigator.pop(context);

      // Show action menu
      if (mounted) {
        showModalBottomSheet(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility, color: PayrollColors.primary),
                title: const Text('Xem trước'),
                onTap: () async {
                  Navigator.pop(context);
                  await PayrollPdfGenerator.previewPdf(pdf);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: PayrollColors.success),
                title: const Text('Tải xuống'),
                onTap: () async {
                  Navigator.pop(context);
                  final fileName = 'phieu_luong_${_payrollData!.employeeId}_${DateTime.now().millisecondsSinceEpoch}';
                  final filePath = await PayrollPdfGenerator.savePdf(
                    pdf: pdf,
                    fileName: fileName,
                  );
                  
                  if (mounted && filePath != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ Đã lưu: $filePath')),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Lỗi khi lưu PDF')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: PayrollColors.warning),
                title: const Text('Chia sẻ'),
                onTap: () async {
                  Navigator.pop(context);
                  final fileName = 'phieu_luong_${_payrollData!.employeeName}';
                  await PayrollPdfGenerator.sharePdf(pdf: pdf, fileName: fileName);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading if still open
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi tạo PDF: $e')),
        );
      }
    }
  }
}

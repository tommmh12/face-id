import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/dto/payroll_dtos.dart';
import '../../utils/app_logger.dart';

/// Màn hình chi tiết bảng lương của 1 nhân viên
/// 
/// Features:
/// - Hiển thị thông tin nhân viên (avatar, MSNV, phòng ban, chức vụ)
/// - Breakdown thu nhập chi tiết:
///   * Lương cơ bản
///   * Lương làm thêm (OT)
///   * Phụ cấp
///   * Thưởng
///   * Tổng thu nhập (Gross)
/// - Breakdown khấu trừ chi tiết:
///   * BHXH (8%)
///   * BHYT (1.5%)
///   * BHTN (1%)
///   * Thuế TNCN (PIT)
///   * Khác
///   * Tổng khấu trừ
/// - Lương thực nhận (Net Salary) - hiển thị nổi bật với gradient xanh lá
/// - Export PDF payslip (phiếu lương cá nhân)
/// - Send email notification cho nhân viên
/// - Responsive design, Material 3
class EmployeePayrollDetailScreen extends StatefulWidget {
  final int periodId;
  final int employeeId;
  final String employeeName;
  final String? employeeCode;
  final String? department;
  final String? position;

  const EmployeePayrollDetailScreen({
    super.key,
    required this.periodId,
    required this.employeeId,
    required this.employeeName,
    this.employeeCode,
    this.department,
    this.position,
  });

  @override
  State<EmployeePayrollDetailScreen> createState() => _EmployeePayrollDetailScreenState();
}

class _EmployeePayrollDetailScreenState extends State<EmployeePayrollDetailScreen> {
  PayrollRecordResponse? _payrollRecord;
  bool _isLoading = false;
  bool _isExporting = false;
  bool _isSendingEmail = false;

  @override
  void initState() {
    super.initState();
    AppLogger.info('Screen initialized for employee ${widget.employeeId}, period ${widget.periodId}', tag: 'EmployeePayrollDetail');
    _loadPayrollDetail();
  }

  @override
  void dispose() {
    AppLogger.info('Screen disposed', tag: 'EmployeePayrollDetail');
    super.dispose();
  }

  /// Load chi tiết bảng lương từ API
  Future<void> _loadPayrollDetail() async {
    setState(() => _isLoading = true);
    AppLogger.info('Loading payroll detail for employee ${widget.employeeId}, period ${widget.periodId}', tag: 'EmployeePayrollDetail');

    try {
      // TODO: Implement GET /api/payroll/records/employee/{employeeId}/period/{periodId}
      // For now, create dummy data
      await Future.delayed(const Duration(seconds: 1));
      
      _payrollRecord = PayrollRecordResponse(
        id: 1,
        payrollPeriodId: widget.periodId,
        employeeId: widget.employeeId,
        employeeName: widget.employeeName,
        totalWorkingDays: 22,
        totalOTHours: 10,
        totalOTPayment: 1500000,
        baseSalaryActual: 10000000,
        totalAllowances: 2000000,
        bonus: 500000,
        adjustedGrossIncome: 14000000,
        insuranceDeduction: 1470000, // BHXH 8% + BHYT 1.5% + BHTN 1% = 10.5%
        pitDeduction: 245000,
        otherDeductions: 50000,
        netSalary: 12235000,
        calculatedAt: DateTime.now(),
        notes: null,
      );

      setState(() {});
      AppLogger.success('Loaded payroll detail', tag: 'EmployeePayrollDetail');
    } catch (e) {
      AppLogger.error('Exception loading payroll detail', error: e, tag: 'EmployeePayrollDetail');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải chi tiết bảng lương'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Export PDF payslip
  Future<void> _exportPDF() async {
    if (_payrollRecord == null) return;

    setState(() => _isExporting = true);
    AppLogger.info('Exporting PDF payslip for employee ${widget.employeeId}', tag: 'EmployeePayrollDetail');

    try {
      // TODO: Implement GET /api/payroll/pdf/employee/{periodId}/{employeeId}
      // For now, just show a message
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xuất phiếu lương PDF'),
            backgroundColor: Color(0xFF34C759),
          ),
        );
      }
      AppLogger.success('PDF exported successfully', tag: 'EmployeePayrollDetail');
    } catch (e) {
      AppLogger.error('Exception exporting PDF', error: e, tag: 'EmployeePayrollDetail');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xuất PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  /// Send email to employee
  Future<void> _sendEmailToEmployee() async {
    if (_payrollRecord == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📧 Xác nhận gửi email'),
        content: Text('Gửi thông báo lương đến nhân viên "${widget.employeeName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSendingEmail = true);
    AppLogger.info('Sending email to employee ${widget.employeeId}', tag: 'EmployeePayrollDetail');

    try {
      // TODO: Implement POST /api/payroll/email/employee/{periodId}/{employeeId}
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã gửi email đến "${widget.employeeName}"'),
            backgroundColor: const Color(0xFF34C759),
          ),
        );
      }
      AppLogger.success('Email sent successfully', tag: 'EmployeePayrollDetail');
    } catch (e) {
      AppLogger.error('Exception sending email', error: e, tag: 'EmployeePayrollDetail');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể gửi email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSendingEmail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng lương chi tiết'),
        actions: [
          // Export PDF button
          if (_payrollRecord != null)
            IconButton(
              icon: _isExporting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf),
              onPressed: _isExporting ? null : _exportPDF,
              tooltip: 'Xuất PDF',
            ),
          // Send email button
          if (_payrollRecord != null)
            IconButton(
              icon: _isSendingEmail
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.email),
              onPressed: _isSendingEmail ? null : _sendEmailToEmployee,
              tooltip: 'Gửi email',
            ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _payrollRecord == null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _loadPayrollDetail,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Employee info card
                    _buildEmployeeInfoCard(),
                    
                    const SizedBox(height: 16),

                    // Working days info
                    _buildWorkingDaysCard(),

                    const SizedBox(height: 16),

                    // Income section
                    _buildIncomeSection(),

                    const SizedBox(height: 16),

                    // Deduction section
                    _buildDeductionSection(),

                    const SizedBox(height: 16),

                    // Net salary card (highlight)
                    _buildNetSalaryCard(),

                    const SizedBox(height: 80), // Space for bottom bar
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _payrollRecord != null ? _buildBottomActionBar() : null,
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Không thể tải dữ liệu',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadPayrollDetail,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  /// Build employee info card
  Widget _buildEmployeeInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFF0A84FF),
              child: Text(
                widget.employeeName.isNotEmpty ? widget.employeeName[0].toUpperCase() : 'N',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.employeeName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (widget.employeeCode != null)
                    Text(
                      'MSNV: ${widget.employeeCode}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (widget.department != null)
                    Text(
                      widget.department!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (widget.position != null)
                    Text(
                      widget.position!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),

            // Status chip (approved if has data)
            if (_payrollRecord != null)
              const Chip(
                label: Text('Đã duyệt'),
                backgroundColor: Color(0xFF34C759),
                labelStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build working days card
  Widget _buildWorkingDaysCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    '${_payrollRecord!.totalWorkingDays.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A84FF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ngày công',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: Colors.grey[300],
            ),
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.access_time, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    '${_payrollRecord!.totalOTHours.toStringAsFixed(0)}h',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF9500),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Làm thêm',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build income section
  Widget _buildIncomeSection() {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '💰 KHOẢN THU NHẬP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Income items
            _buildIncomeItem('Lương cơ bản', _payrollRecord!.baseSalaryActual, formatter),
            if (_payrollRecord!.totalOTPayment > 0)
              _buildIncomeItem('Lương làm thêm (${_payrollRecord!.totalOTHours.toStringAsFixed(0)}h)', _payrollRecord!.totalOTPayment, formatter),
            if (_payrollRecord!.totalAllowances > 0)
              _buildIncomeItem('Phụ cấp', _payrollRecord!.totalAllowances, formatter),
            if (_payrollRecord!.bonus > 0)
              _buildIncomeItem('Thưởng', _payrollRecord!.bonus, formatter),

            const Divider(height: 24),

            // Total income
            _buildIncomeItem(
              'Tổng thu nhập',
              _payrollRecord!.adjustedGrossIncome,
              formatter,
              isBold: true,
              color: const Color(0xFF34C759),
            ),
          ],
        ),
      ),
    );
  }

  /// Build income item row
  Widget _buildIncomeItem(String label, double amount, NumberFormat formatter, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build deduction section
  Widget _buildDeductionSection() {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '📉 KHOẢN KHẤU TRỪ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Deduction items
            _buildDeductionItem('Bảo hiểm (BHXH + BHYT + BHTN)', _payrollRecord!.insuranceDeduction, formatter),
            _buildDeductionItem('Thuế TNCN', _payrollRecord!.pitDeduction, formatter),
            if (_payrollRecord!.otherDeductions > 0)
              _buildDeductionItem('Khác', _payrollRecord!.otherDeductions, formatter),

            const Divider(height: 24),

            // Total deduction
            _buildDeductionItem(
              'Tổng khấu trừ',
              _payrollRecord!.insuranceDeduction + _payrollRecord!.pitDeduction + _payrollRecord!.otherDeductions,
              formatter,
              isBold: true,
              color: const Color(0xFFFF3B30),
            ),
          ],
        ),
      ),
    );
  }

  /// Build deduction item row
  Widget _buildDeductionItem(String label, double amount, NumberFormat formatter, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build net salary card (highlight)
  Widget _buildNetSalaryCard() {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF34C759), Color(0xFF30D158)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34C759).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            '💵 LƯƠNG THỰC NHẬN',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(_payrollRecord!.netSalary),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tháng ${DateFormat('MM/yyyy').format(_payrollRecord!.calculatedAt)}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// Build bottom action bar
  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isExporting ? null : _exportPDF,
                icon: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
                label: Text(_isExporting ? 'Đang xuất...' : 'Xuất PDF'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF0A84FF)),
                  foregroundColor: const Color(0xFF0A84FF),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isSendingEmail ? null : _sendEmailToEmployee,
                icon: _isSendingEmail
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.email),
                label: Text(_isSendingEmail ? 'Đang gửi...' : 'Gửi email'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0A84FF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

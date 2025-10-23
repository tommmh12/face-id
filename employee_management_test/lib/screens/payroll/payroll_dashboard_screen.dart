import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/dto/payroll_dtos.dart';
import '../../services/payroll_api_service.dart';
import '../../config/app_theme.dart';

class PayrollDashboardScreen extends StatefulWidget {
  const PayrollDashboardScreen({super.key});

  @override
  State<PayrollDashboardScreen> createState() => _PayrollDashboardScreenState();
}

class _PayrollDashboardScreenState extends State<PayrollDashboardScreen> {
  final PayrollApiService _payrollService = PayrollApiService();

  List<PayrollPeriodResponse> _periods = [];
  PayrollSummaryResponse? _currentSummary;
  bool _isLoading = true;
  String? _error;
  int? _selectedPeriodId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // -------------------------- LOAD DATA --------------------------
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final periodsResponse = await _payrollService.getPayrollPeriods();
      if (periodsResponse.success && periodsResponse.data != null) {
        _periods = periodsResponse.data!;
        if (_periods.isNotEmpty && _selectedPeriodId == null) {
          _selectedPeriodId = _periods.first.id;
        }
        if (_selectedPeriodId != null) {
          await _loadSummary(_selectedPeriodId!);
        }
      } else {
        _error = periodsResponse.message ?? 'Không thể tải dữ liệu kỳ lương.';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSummary(int periodId) async {
    try {
      final summaryResponse = await _payrollService.getPayrollSummary(periodId);
      if (summaryResponse.success && summaryResponse.data != null) {
        if (mounted) setState(() => _currentSummary = summaryResponse.data!);
      } else {
        if (mounted) setState(() => _currentSummary = null);
      }
    } catch (e) {
      debugPrint('Error loading summary: $e');
    }
  }

  // -------------------------- GENERATE PAYROLL --------------------------
  Future<void> _generatePayroll() async {
    if (_selectedPeriodId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận tính lương'),
        content: const Text(
          'Bạn có chắc chắn muốn tính lương cho kỳ này?\n'
          'Hệ thống sẽ xử lý toàn bộ dữ liệu lương của nhân viên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.calculate),
            label: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Đang tính lương...'),
          ],
        ),
      ),
    );

    try {
      final response = await _payrollService.generatePayroll(_selectedPeriodId!);
      if (mounted) Navigator.pop(context); // Close loading

      if (response.success && response.data != null) {
        if (mounted) _showGenerateResultDialog(response.data!);
        await _loadSummary(_selectedPeriodId!);
      } else {
        _showErrorSnackBar(response.message ?? 'Lỗi khi tính lương.');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorSnackBar('Lỗi: $e');
    }
  }

  void _showGenerateResultDialog(GeneratePayrollResponse result) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(
          result.success ? Icons.check_circle : Icons.error,
          color: result.success ? Colors.green : Colors.red,
          size: 48,
        ),
        title: Text(result.success ? 'Tính Lương Thành Công' : 'Có lỗi xảy ra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tổng nhân viên: ${result.totalEmployees}'),
            Text('Thành công: ${result.successCount}'),
            if (result.failedCount > 0) ...[
              Text('Thất bại: ${result.failedCount}'),
              const SizedBox(height: 8),
              const Text('Chi tiết lỗi:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.errors.take(3).map((e) => Text('• $e')),
              if (result.errors.length > 3)
                Text('• ... và ${result.errors.length - 3} lỗi khác'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  String _formatCurrency(double value) =>
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(value);

  // -------------------------- UI --------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: const Text('Quản Lý Lương', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Tải lại dữ liệu',
          )
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to create new payroll period
        },
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Kỳ mới'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 64),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildPeriodSelector(),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _currentSummary != null
                ? _buildSummaryView()
                : _selectedPeriodId != null
                    ? _buildEmptySummary()
                    : _buildNoPeriodSelected(),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.calendar_month, color: AppColors.primaryBlue),
              SizedBox(width: AppSpacing.sm),
              Text('Chọn kỳ lương', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey(_selectedPeriodId),
            value: _selectedPeriodId,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                borderSide: BorderSide.none,
              ),
            ),
            items: _periods
                .map(
                  (p) => DropdownMenuItem<int>(
                    value: p.id,
                    child: Text(p.periodName),
                  ),
                )
                .toList(),
            onChanged: (id) {
              setState(() {
                _selectedPeriodId = id;
                _currentSummary = null;
              });
              if (id != null) _loadSummary(id);
            },
          ),
          if (_selectedPeriodId != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${DateFormat('dd/MM/yyyy').format(_periods.firstWhere((p) => p.id == _selectedPeriodId!).startDate)} - '
                '${DateFormat('dd/MM/yyyy').format(_periods.firstWhere((p) => p.id == _selectedPeriodId!).endDate)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryView() {
    final s = _currentSummary!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          _buildInfoHeader(s),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildSummaryCard('Tổng Gross', _formatCurrency(s.totalGrossSalary),
                  Icons.attach_money, Colors.blue),
              _buildSummaryCard('Tổng Net', _formatCurrency(s.totalNetSalary),
                  Icons.money, Colors.green),
              _buildSummaryCard('Bảo hiểm', _formatCurrency(s.totalInsuranceDeduction),
                  Icons.security, Colors.orange),
              _buildSummaryCard('Thuế TNCN', _formatCurrency(s.totalPITDeduction),
                  Icons.account_balance, Colors.red),
              _buildSummaryCard('Tiền OT', _formatCurrency(s.totalOvertimePay),
                  Icons.access_time, Colors.purple),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generatePayroll,
                  icon: const Icon(Icons.calculate),
                  label: const Text('Tính Lương'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to payroll detail
                  },
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Chi Tiết'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoHeader(PayrollSummaryResponse s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            s.periodName,
            style: AppTextStyles.h3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhân viên: ${s.totalEmployees}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySummary() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Chưa có dữ liệu lương cho kỳ này'),
            SizedBox(height: 4),
            Text('Nhấn "Tính Lương" để bắt đầu', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );

  Widget _buildNoPeriodSelected() => const Center(
        child: Text('Vui lòng chọn kỳ lương', style: TextStyle(color: Colors.grey)),
      );

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        boxShadow: AppShadows.small,
        border: Border.all(color: color.withOpacity(0.2), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

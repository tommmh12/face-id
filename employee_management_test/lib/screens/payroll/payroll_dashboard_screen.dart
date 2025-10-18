import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/dto/payroll_dtos.dart';
import '../../services/payroll_api_service.dart';

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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final periodsResponse = await _payrollService.getPayrollPeriods();
      if (periodsResponse.success && periodsResponse.data != null) {
        setState(() {
          _periods = periodsResponse.data!;
          if (_periods.isNotEmpty && _selectedPeriodId == null) {
            _selectedPeriodId = _periods.first.id;
          }
        });
        
        if (_selectedPeriodId != null) {
          await _loadSummary(_selectedPeriodId!);
        }
      } else {
        setState(() {
          _error = periodsResponse.message ?? 'Lỗi tải dữ liệu';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSummary(int periodId) async {
    try {
      final summaryResponse = await _payrollService.getPayrollSummary(periodId);
      if (summaryResponse.success && summaryResponse.data != null) {
        setState(() {
          _currentSummary = summaryResponse.data!;
        });
      }
    } catch (e) {
      debugPrint('Error loading summary: $e');
    }
  }

  Future<void> _generatePayroll() async {
    if (_selectedPeriodId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text(
          'Bạn có chắc chắn muốn tính lương cho kỳ này?\n'
          'Quá trình này sẽ tính toán lương cho tất cả nhân viên.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Đang tính lương...'),
            ],
          ),
        ),
      );

      final response = await _payrollService.generatePayroll(_selectedPeriodId!);
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (response.success && response.data != null) {
        if (mounted) _showGenerateResultDialog(response.data!);
        // Reload summary
        await _loadSummary(_selectedPeriodId!);
      } else {
        if (mounted) _showErrorSnackBar(response.message ?? 'Lỗi tính lương');
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      if (mounted) _showErrorSnackBar('Lỗi: ${e.toString()}');
    }
  }

  void _showGenerateResultDialog(GeneratePayrollResponse result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          result.success ? Icons.check_circle : Icons.error,
          color: result.success ? Colors.green : Colors.red,
          size: 48,
        ),
        title: Text(result.success ? 'Tính Lương Thành Công' : 'Có Lỗi Xảy Ra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tổng nhân viên: ${result.totalEmployees}'),
            Text('Thành công: ${result.successCount}'),
            if (result.failedCount > 0) ...[
              Text('Thất bại: ${result.failedCount}'),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Lỗi:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...result.errors.take(3).map((error) => Text('• $error')),
                if (result.errors.length > 3)
                  Text('• Và ${result.errors.length - 3} lỗi khác...'),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý Lương'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Period Selection
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<int>(
                        key: ValueKey(_selectedPeriodId),
                        value: _selectedPeriodId,
                        decoration: const InputDecoration(
                          labelText: 'Chọn kỳ lương',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                        items: _periods.map((period) => DropdownMenuItem<int>(
                          value: period.id,
                          child: Text('${period.periodName} (${DateFormat('dd/MM/yyyy').format(period.startDate)} - ${DateFormat('dd/MM/yyyy').format(period.endDate)})'),
                        )).toList(),
                        onChanged: (periodId) {
                          if (mounted) {
                            setState(() {
                              _selectedPeriodId = periodId;
                              _currentSummary = null;
                            });
                            if (periodId != null) {
                              _loadSummary(periodId);
                            }
                          }
                        },
                      ),
                    ),

                    // Summary Cards
                    if (_currentSummary != null)
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Period Info
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.info, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Thông Tin Kỳ Lương',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Kỳ: ${_currentSummary!.periodName}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      Text(
                                        'Tổng nhân viên: ${_currentSummary!.totalEmployees}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Financial Summary
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.2,
                                children: [
                                  _buildSummaryCard(
                                    'Tổng Lương Gross',
                                    _formatCurrency(_currentSummary!.totalGrossSalary),
                                    Icons.attach_money,
                                    Colors.blue,
                                  ),
                                  _buildSummaryCard(
                                    'Tổng Lương Net',
                                    _formatCurrency(_currentSummary!.totalNetSalary),
                                    Icons.money,
                                    Colors.green,
                                  ),
                                  _buildSummaryCard(
                                    'Tổng Bảo Hiểm',
                                    _formatCurrency(_currentSummary!.totalInsuranceDeduction),
                                    Icons.security,
                                    Colors.orange,
                                  ),
                                  _buildSummaryCard(
                                    'Tổng Thuế TNCN',
                                    _formatCurrency(_currentSummary!.totalPITDeduction),
                                    Icons.account_balance,
                                    Colors.red,
                                  ),
                                  _buildSummaryCard(
                                    'Tổng Tiền OT',
                                    _formatCurrency(_currentSummary!.totalOvertimePay),
                                    Icons.access_time,
                                    Colors.purple,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Action Buttons
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
                                        // TODO: Navigate to detailed payroll records
                                      },
                                      icon: const Icon(Icons.list),
                                      label: const Text('Chi Tiết'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_selectedPeriodId != null)
                      const Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.hourglass_empty,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Chưa có dữ liệu lương cho kỳ này',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Hãy nhấn "Tính Lương" để bắt đầu',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Vui lòng chọn kỳ lương',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create new payroll period
        },
        tooltip: 'Tạo kỳ lương mới',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
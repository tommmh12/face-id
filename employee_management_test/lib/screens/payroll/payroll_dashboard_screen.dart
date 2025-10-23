import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/dto/payroll_dtos.dart';
import '../../services/payroll_api_service.dart';
import '../../utils/app_logger.dart';
import 'audit_log_screen.dart';

/// 💰 Payroll Dashboard - Material 3 Design
///
/// Features:
/// - 3 Summary Statistics Cards
/// - Payroll Period List with Status Chips
/// - Floating Action Button (Create New Period)
/// - Pull to Refresh
/// - Navigation to Detail Screens
class PayrollDashboardScreen extends StatefulWidget {
  const PayrollDashboardScreen({super.key});

  @override
  State<PayrollDashboardScreen> createState() => _PayrollDashboardScreenState();
}

class _PayrollDashboardScreenState extends State<PayrollDashboardScreen> {
  final PayrollApiService _payrollService = PayrollApiService();
  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

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
      AppLogger.startOperation('Load Payroll Dashboard Data');

      // Load periods
      final periodsResponse = await _payrollService.getPayrollPeriods();

      if (periodsResponse.success && periodsResponse.data != null) {
        setState(() {
          _periods = periodsResponse.data!;
          // Select latest period by default
          if (_periods.isNotEmpty && _selectedPeriodId == null) {
            _selectedPeriodId = _periods.first.id;
          }
        });

        AppLogger.success(
          'Loaded ${_periods.length} payroll periods',
          tag: 'PayrollDashboard',
        );

        // Load summary for selected period
        if (_selectedPeriodId != null) {
          await _loadSummary(_selectedPeriodId!);
        }
      } else {
        setState(() {
          _error = periodsResponse.message ?? 'Không thể tải dữ liệu';
        });
        AppLogger.warning(
          'Failed to load periods: ${periodsResponse.message}',
          tag: 'PayrollDashboard',
        );
      }

      AppLogger.endOperation(
        'Load Payroll Dashboard Data',
        success: _error == null,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Dashboard load error',
        error: e,
        stackTrace: stackTrace,
        tag: 'PayrollDashboard',
      );
      setState(() {
        _error = 'Lỗi kết nối: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSummary(int periodId) async {
    try {
      AppLogger.data(
        'Loading summary for period $periodId',
        tag: 'PayrollDashboard',
      );

      final summaryResponse = await _payrollService.getPayrollSummary(periodId);

      if (summaryResponse.success && summaryResponse.data != null) {
        setState(() {
          _currentSummary = summaryResponse.data;
        });
        AppLogger.success(
          'Summary loaded: ${_currentSummary!.totalEmployees} employees',
          tag: 'PayrollDashboard',
        );
      }
    } catch (e) {
      AppLogger.warning('Failed to load summary: $e', tag: 'PayrollDashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet, size: 28),
            const SizedBox(width: 12),
            Flexible(
              child: const Text(
                '💰 Bảng lương nhân viên',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        actions: [
          // 📜 Audit Log Button
          IconButton(
            onPressed: () {
              AppLogger.navigation('PayrollDashboard', 'AuditLogScreen');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuditLogScreen()),
              );
            },
            icon: const Icon(Icons.history),
            tooltip: 'Lịch sử thay đổi',
          ),
          // Filter Button
          IconButton(
            onPressed: () {
              AppLogger.ui('Opening filter dialog', tag: 'PayrollDashboard');
              // TODO: Show filter dialog
            },
            icon: const Icon(Icons.filter_list),
            tooltip: 'Bộ lọc',
          ),
          // Analytics Button
          IconButton(
            onPressed: () {
              AppLogger.navigation('PayrollDashboard', 'PayrollChartScreen');
              Navigator.pushNamed(context, '/payroll/chart');
            },
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Biểu đồ',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context, theme, colorScheme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePeriodDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tạo kỳ lương'),
        tooltip: 'Tạo kỳ lương mới',
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải dữ liệu...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: colorScheme.error)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Summary Statistics Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildStatisticsCards(theme, colorScheme),
            ),
          ),

          // Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Danh sách kỳ lương',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      AppLogger.ui('View all periods', tag: 'PayrollDashboard');
                      // TODO: Navigate to full list
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text(
                      'Xem tất cả',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Payroll Periods List
          _periods.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có kỳ lương nào',
                          style: TextStyle(color: colorScheme.outline),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _showCreatePeriodDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Tạo kỳ lương đầu tiên'),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final period = _periods[index];
                      return _buildPeriodCard(
                        context,
                        period,
                        theme,
                        colorScheme,
                      );
                    }, childCount: _periods.length),
                  ),
                ),
        ],
      ),
    );
  }

  /// 📊 Statistics Summary Cards
  Widget _buildStatisticsCards(ThemeData theme, ColorScheme colorScheme) {
    final summary = _currentSummary;

    return Column(
      children: [
        // Row 1: Total Employees + Total Cost
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.people,
                title: 'Tổng nhân viên',
                value: summary?.totalEmployees.toString() ?? '--',
                subtitle: 'Có bảng lương',
                color: const Color(0xFF0A84FF), // Primary blue
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.account_balance_wallet,
                title: 'Tổng chi phí',
                value: summary != null
                    ? _currencyFormat
                          .format(summary.totalNetSalary)
                          .replaceAll('₫', '')
                    : '--',
                subtitle: '₫ Net Salary',
                color: const Color(0xFF34C759), // Success green
                theme: theme,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Row 2: Current Period (Full Width)
        _buildStatCard(
          icon: Icons.calendar_today,
          title: 'Kỳ lương hiện tại',
          value: summary?.periodName ?? 'Chưa chọn',
          subtitle: _selectedPeriodId != null
              ? _formatPeriodDate()
              : 'Chọn kỳ lương để xem',
          color: const Color(0xFFFF9500), // Warning orange
          theme: theme,
          isFullWidth: true,
        ),
      ],
    );
  }

  String _formatPeriodDate() {
    final period = _periods.firstWhere((p) => p.id == _selectedPeriodId);
    final formatter = DateFormat('dd/MM/yyyy');
    return '${formatter.format(period.startDate)} - ${formatter.format(period.endDate)}';
  }

  /// ✅ RESOLVED: _buildStatCard Method (Login Branch Implementation)
  /// Keeps statistics display logic with theme-based styling
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required ThemeData theme,
    bool isFullWidth = false,
  }) {
    return Card(
      elevation: 0,
      color: color.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withAlpha(180),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 Payroll Period Card
  Widget _buildPeriodCard(
    BuildContext context,
    PayrollPeriodResponse period,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final formatter = DateFormat('dd/MM/yyyy');
    final isSelected = _selectedPeriodId == period.id;

    return Card(
      elevation: isSelected ? 2 : 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF0A84FF)
              : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPeriodId = period.id;
          });
          _loadSummary(period.id);
          AppLogger.ui(
            'Selected period: ${period.periodName}',
            tag: 'PayrollDashboard',
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          period.periodName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatter.format(period.startDate)} - ${formatter.format(period.endDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Chip
                  Chip(
                    label: Text(period.isClosed ? 'Đã đóng' : 'Đang mở'),
                    labelStyle: theme.textTheme.bodySmall?.copyWith(
                      color: period.isClosed
                          ? colorScheme.onSurfaceVariant
                          : const Color(0xFF34C759),
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: period.isClosed
                        ? colorScheme.surfaceContainerHighest
                        : const Color(0xFF34C759).withAlpha(25),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  if (!period.isClosed) ...[
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => _generatePayroll(context, period.id),
                        icon: const Icon(Icons.calculate, size: 16),
                        label: const Text(
                          'Tính lương',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF0A84FF,
                          ).withAlpha(25),
                          foregroundColor: const Color(0xFF0A84FF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewReport(context, period.id),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text(
                        'Xem báo cáo',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== ACTIONS ====================

  void _showCreatePeriodDialog(BuildContext context) {
    AppLogger.ui('Opening create period dialog', tag: 'PayrollDashboard');

    final now = DateTime.now();
    final periodNameController = TextEditingController(
      text: 'Kỳ lương ${DateFormat('MM/yyyy').format(now)}',
    );

    DateTime startDate = DateTime(now.year, now.month, 1);
    DateTime endDate = DateTime(now.year, now.month + 1, 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline),
              SizedBox(width: 12),
              Text('Tạo kỳ lương mới'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: periodNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên kỳ lương',
                    hintText: 'VD: Kỳ lương 10/2025',
                    prefixIcon: Icon(Icons.label),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Start Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Ngày bắt đầu'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        startDate = picked;
                      });
                    }
                  },
                ),

                // End Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: const Text('Ngày kết thúc'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(endDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: startDate,
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        endDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: () async {
                if (periodNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên kỳ lương')),
                  );
                  return;
                }

                Navigator.pop(context);
                await _createPeriod(
                  periodNameController.text.trim(),
                  startDate,
                  endDate,
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPeriod(
    String name,
    DateTime startDate,
    DateTime endDate,
  ) async {
    AppLogger.startOperation('Create Payroll Period');
    AppLogger.data(
      'Period: $name ($startDate - $endDate)',
      tag: 'PayrollDashboard',
    );

    try {
      final request = CreatePayrollPeriodRequest(
        periodName: name,
        startDate: startDate,
        endDate: endDate,
      );

      final response = await _payrollService.createPayrollPeriod(request);

      if (response.success) {
        AppLogger.success(
          'Period created successfully',
          tag: 'PayrollDashboard',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Tạo kỳ lương thành công!'),
                ],
              ),
              backgroundColor: Color(0xFF34C759),
            ),
          );
        }

        await _loadData();
        AppLogger.endOperation('Create Payroll Period', success: true);
      } else {
        throw Exception(response.message);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to create period',
        error: e,
        stackTrace: stackTrace,
        tag: 'PayrollDashboard',
      );
      AppLogger.endOperation('Create Payroll Period', success: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Lỗi: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generatePayroll(BuildContext context, int periodId) async {
    AppLogger.business(
      'User requested payroll generation for period $periodId',
      tag: 'PayrollDashboard',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text('Xác nhận tính lương'),
        content: const Text(
          'Bạn có chắc chắn muốn tính lương cho tất cả nhân viên trong kỳ này?\n\n'
          'Lưu ý: Thao tác này sẽ tính toán dựa trên dữ liệu chấm công và quy tắc lương hiện tại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tính lương'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      AppLogger.startOperation('Generate Payroll');

      // Show progress dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tính lương...'),
              ],
            ),
          ),
        );
      }

      try {
        final response = await _payrollService.generatePayroll(periodId);

        if (context.mounted) {
          Navigator.pop(context); // Close progress dialog
        }

        if (response.success) {
          AppLogger.success(
            'Payroll generated: ${response.data?.successCount}/${response.data?.totalEmployees} employees',
            tag: 'PayrollDashboard',
          );
          AppLogger.endOperation('Generate Payroll', success: true);

          if (context.mounted) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                icon: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF34C759),
                  size: 48,
                ),
                title: const Text('Tính lương thành công!'),
                content: Text(
                  'Đã tính lương cho ${response.data?.successCount ?? 0} nhân viên.\n'
                  '${response.data?.failedCount ?? 0} lỗi.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _viewReport(context, periodId);
                    },
                    child: const Text('Xem báo cáo'),
                  ),
                ],
              ),
            );
          }

          await _loadSummary(periodId);
        } else {
          throw Exception(response.message);
        }
      } catch (e, stackTrace) {
        AppLogger.error(
          'Payroll generation failed',
          error: e,
          stackTrace: stackTrace,
          tag: 'PayrollDashboard',
        );
        AppLogger.endOperation('Generate Payroll', success: false);

        if (context.mounted) {
          Navigator.pop(context); // Close progress dialog

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi tính lương: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _viewReport(BuildContext context, int periodId) {
    AppLogger.navigation(
      'PayrollDashboard',
      'PayrollReportScreen',
      arguments: {'periodId': periodId},
    );

    Navigator.pushNamed(
      context,
      '/payroll/report',
      arguments: {'periodId': periodId},
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/dto/payroll_dtos.dart';
import '../../models/employee.dart';
import '../../services/payroll_api_service.dart';
import '../../services/employee_api_service.dart';
import '../../utils/app_logger.dart';
import '../../config/app_theme.dart';
import 'payroll_rule_setup_screen.dart';

/// 👤 Employee HR Profile Screen - Unified Employee Payroll Management
/// 
/// **Navigation**:
/// - From Dashboard: Click employee name
/// - From Audit Log: Click "Xem NV" button
/// 
/// **Features** (4 Tabs):
/// - Tab I: Payroll Rules (Quy tắc lương)
/// - Tab II: Allowances & Adjustments (Phụ cấp & Điều chỉnh)
/// - Tab III: Salary History (Lịch sử lương)
/// - Tab IV: Rules History (Lịch sử quy tắc - Versioning)
class EmployeeHRProfileScreen extends StatefulWidget {
  final int employeeId;
  final String? employeeName; // Optional - will fetch if not provided

  const EmployeeHRProfileScreen({
    super.key,
    required this.employeeId,
    this.employeeName,
  });

  @override
  State<EmployeeHRProfileScreen> createState() => _EmployeeHRProfileScreenState();
}

class _EmployeeHRProfileScreenState extends State<EmployeeHRProfileScreen> with SingleTickerProviderStateMixin {
  final PayrollApiService _payrollService = PayrollApiService();
  final EmployeeApiService _employeeService = EmployeeApiService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  late TabController _tabController;
  
  Employee? _employee;
  PayrollRuleResponse? _currentRule;
  List<AllowanceResponse> _allowances = [];
  List<SalaryAdjustmentResponse> _adjustments = [];
  List<PayrollRecordResponse> _salaryHistory = [];
  List<PayrollRuleResponse> _rulesHistory = []; // TODO: Backend needs to implement versioning
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      AppLogger.startOperation('Load Employee HR Profile');

      // 1. Load Employee Info
      final employeeResponse = await _employeeService.getEmployeeById(widget.employeeId);
      if (employeeResponse.success && employeeResponse.data != null) {
        _employee = employeeResponse.data;
      }

      // 2. Load Payroll Rule
      final ruleResponse = await _payrollService.getPayrollRuleByEmployeeId(widget.employeeId);
      if (ruleResponse.success) {
        _currentRule = ruleResponse.data;
      }

      // 3. Load Allowances
      final allowancesResponse = await _payrollService.getEmployeeAllowances(widget.employeeId);
      if (allowancesResponse.success) {
        _allowances = allowancesResponse.data ?? [];
      }

      // 4. Load Adjustments
      final adjustmentsResponse = await _payrollService.getEmployeeAdjustments(widget.employeeId);
      if (adjustmentsResponse.success) {
        _adjustments = adjustmentsResponse.data ?? [];
      }

      // 5. Load Salary History (across all periods)
      await _loadSalaryHistory();

      setState(() {
        _isLoading = false;
      });

      AppLogger.endOperation('Load Employee HR Profile', success: true);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load HR profile', error: e, stackTrace: stackTrace);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSalaryHistory() async {
    try {
      // Get all periods first
      final periodsResponse = await _payrollService.getPayrollPeriods();
      if (!periodsResponse.success || periodsResponse.data == null) return;

      final periods = periodsResponse.data!;
      final List<PayrollRecordResponse> allRecords = [];

      // Load records for each period
      for (final period in periods) {
        try {
          final recordResponse = await _payrollService.getEmployeePayroll(
            period.id,
            widget.employeeId,
          );
          
          if (recordResponse.success && recordResponse.data != null) {
            allRecords.add(recordResponse.data!);
          }
        } catch (e) {
          AppLogger.warning('Failed to load record for period ${period.id}: $e');
        }
      }

      setState(() {
        _salaryHistory = allRecords;
      });
    } catch (e) {
      AppLogger.warning('Failed to load salary history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('👤 Hồ sơ nhân viên', style: TextStyle(fontSize: 18)),
            if (_employee != null)
              Text(
                _employee!.fullName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.rule), text: 'Quy tắc'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'Phụ cấp/Điều chỉnh'),
            Tab(icon: Icon(Icons.history), text: 'Lịch sử lương'),
            Tab(icon: Icon(Icons.history_edu), text: 'Lịch sử quy tắc'),
          ],
        ),
        actions: [
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

    return TabBarView(
      controller: _tabController,
      children: [
        _buildPayrollRuleTab(),
        _buildAllowancesAdjustmentsTab(),
        _buildSalaryHistoryTab(),
        _buildRulesHistoryTab(),
      ],
    );
  }

  // ==================== TAB I: PAYROLL RULES ====================

  Widget _buildPayrollRuleTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PayrollColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.rule, size: 32, color: PayrollColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quy tắc lương hiện tại',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentRule != null
                                ? 'Cập nhật: ${DateFormat('dd/MM/yyyy').format(_currentRule!.updatedAt ?? _currentRule!.createdAt)}'
                                : 'Chưa có quy tắc',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rules Details
            if (_currentRule == null)
              _buildEmptyState(
                icon: Icons.rule,
                title: 'Chưa có quy tắc lương',
                subtitle: 'Vui lòng thiết lập quy tắc tính lương cho nhân viên này',
                actionLabel: 'Thiết lập ngay',
                onAction: () => _navigateToRuleSetup(null),
              )
            else ...[
              _buildRuleCard(
                title: '💰 Lương cơ bản',
                icon: Icons.monetization_on,
                color: PayrollColors.primary,
                items: [
                  _buildInfoRow('Lương cơ bản', _currencyFormat.format(_currentRule!.baseSalary)),
                  _buildInfoRow('Số ngày công chuẩn', '${_currentRule!.standardWorkingDays} ngày'),
                ],
              ),
              const SizedBox(height: 12),
              _buildRuleCard(
                title: '🛡️ Bảo hiểm',
                icon: Icons.security,
                color: PayrollColors.info,
                items: [
                  _buildInfoRow('BHXH', '${_currentRule!.socialInsuranceRate}%'),
                  _buildInfoRow('BHYT', '${_currentRule!.healthInsuranceRate}%'),
                  _buildInfoRow('BHTN', '${_currentRule!.unemploymentInsuranceRate}%'),
                  const Divider(),
                  _buildInfoRow(
                    'Tổng khấu trừ BHXH',
                    _currencyFormat.format(_currentRule!.baseSalary * 
                      (_currentRule!.socialInsuranceRate + 
                       _currentRule!.healthInsuranceRate + 
                       _currentRule!.unemploymentInsuranceRate) / 100),
                    isBold: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRuleCard(
                title: '📊 Khấu trừ thuế',
                icon: Icons.account_balance,
                color: PayrollColors.warning,
                items: [
                  _buildInfoRow('Giảm trừ bản thân', _currencyFormat.format(_currentRule!.personalDeduction)),
                  _buildInfoRow('Số người phụ thuộc', '${_currentRule!.numberOfDependents} người'),
                  _buildInfoRow('Giảm trừ/người', _currencyFormat.format(_currentRule!.dependentDeduction)),
                  const Divider(),
                  _buildInfoRow(
                    'Tổng giảm trừ',
                    _currencyFormat.format(_currentRule!.personalDeduction + 
                      (_currentRule!.numberOfDependents * _currentRule!.dependentDeduction)),
                    isBold: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRuleDetails(_currentRule!),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Xem chi tiết'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToRuleSetup(_currentRule),
                      icon: const Icon(Icons.edit),
                      label: const Text('Chỉnh sửa'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> items,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            ...items,
          ],
        ),
      ),
    );
  }

  void _showRuleDetails(PayrollRuleResponse rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📋 Chi tiết quy tắc'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Trạng thái: ${rule.isActive ? "✅ Đang áp dụng" : "⏸️ Tạm dừng"}'),
              const SizedBox(height: 8),
              Text('Tạo lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(rule.createdAt)}'),
              if (rule.updatedAt != null) ...[
                const SizedBox(height: 4),
                Text('Cập nhật: ${DateFormat('dd/MM/yyyy HH:mm').format(rule.updatedAt!)}'),
              ],
            ],
          ),
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

  Future<void> _navigateToRuleSetup(PayrollRuleResponse? existingRule) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PayrollRuleSetupScreen(
          employeeId: widget.employeeId,
          employeeName: _employee?.fullName ?? widget.employeeName ?? 'Nhân viên',
          existingRule: existingRule,
        ),
      ),
    );

    if (result == true) {
      _loadData(); // Reload after save
    }
  }

  // ==================== TAB II: ALLOWANCES & ADJUSTMENTS ====================

  Widget _buildAllowancesAdjustmentsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Allowances Section
            Card(
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
                          child: const Icon(Icons.card_giftcard, color: PayrollColors.success, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '🎁 Phụ cấp định kỳ',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: PayrollColors.success),
                          onPressed: _showAddAllowanceDialog,
                          tooltip: 'Thêm phụ cấp',
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_allowances.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('Chưa có phụ cấp')),
                      )
                    else
                      ..._allowances.map((allowance) => ListTile(
                        leading: Icon(_getAllowanceIcon(allowance.allowanceType), color: PayrollColors.success),
                        title: Text(allowance.allowanceType),
                        subtitle: Text('Hiệu lực: ${DateFormat('dd/MM/yyyy').format(allowance.effectiveDate)}'),
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
            ),
            const SizedBox(height: 16),

            // Adjustments Section
            Card(
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
                            color: PayrollColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.edit, color: PayrollColors.warning, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '⚡ Thưởng/Phạt (Adjustments)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.add_circle, color: PayrollColors.warning),
                          tooltip: 'Thêm điều chỉnh',
                          onSelected: (type) => _showAddAdjustmentDialog(type),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'Bonus',
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle, color: PayrollColors.success),
                                  SizedBox(width: 12),
                                  Text('Thêm thưởng'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'Penalty',
                              child: Row(
                                children: [
                                  Icon(Icons.remove_circle, color: PayrollColors.error),
                                  SizedBox(width: 12),
                                  Text('Thêm phạt'),
                                ],
                              ),
                            ),
                          ],
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
                      ..._adjustments.take(10).map((adj) => ListTile(
                        leading: Icon(
                          adj.adjustmentType == 'Bonus' ? Icons.trending_up : Icons.trending_down,
                          color: adj.amount >= 0 ? PayrollColors.success : PayrollColors.error,
                        ),
                        title: Text(adj.reason),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy').format(adj.adjustmentDate)} • ${adj.adjustmentType}',
                        ),
                        trailing: Text(
                          _currencyFormat.format(adj.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: adj.amount >= 0 ? PayrollColors.success : PayrollColors.error,
                          ),
                        ),
                      )),
                  ],
                ),
              ),
            ),

            // Warning Banner
            if (_adjustments.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PayrollColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PayrollColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: PayrollColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sau khi thêm điều chỉnh, vui lòng chạy "Tính lại lương" cho kỳ hiện tại để áp dụng.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[800]),
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

  void _showAddAllowanceDialog() {
    final typeController = TextEditingController();
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('➕ Thêm phụ cấp định kỳ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(
                labelText: 'Loại phụ cấp',
                hintText: 'VD: Lunch, Transport, Housing',
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
              if (typeController.text.isEmpty || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
                );
                return;
              }

              Navigator.pop(context);

              final request = CreateAllowanceRequest(
                employeeId: widget.employeeId,
                allowanceType: typeController.text,
                amount: amount,
                effectiveDate: DateTime.now(),
              );

              final response = await _payrollService.createAllowance(request);
              if (response.success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Đã thêm phụ cấp')),
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

  void _showAddAdjustmentDialog(String type) {
    final reasonController = TextEditingController();
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('➕ Thêm ${type == 'Bonus' ? 'thưởng' : 'phạt'}'),
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

              // TODO: Need to get current periodId
              final periodsResponse = await _payrollService.getPayrollPeriods();
              if (!periodsResponse.success || periodsResponse.data == null || periodsResponse.data!.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không tìm thấy kỳ lương')),
                  );
                }
                return;
              }

              final currentPeriod = periodsResponse.data!.first;

              final request = CreateSalaryAdjustmentRequest(
                employeeId: widget.employeeId,
                periodId: currentPeriod.id,
                adjustmentType: type,
                reason: reasonController.text,
                amount: type == 'Penalty' ? -amount : amount,
                adjustmentDate: DateTime.now(),
                approvedBy: 'HR', // TODO: Get from auth
              );

              final response = await _payrollService.createSalaryAdjustment(request);
              if (response.success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Đã thêm ${type == 'Bonus' ? 'thưởng' : 'phạt'}')),
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

  // ==================== TAB III: SALARY HISTORY ====================

  Widget _buildSalaryHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _salaryHistory.isEmpty
        ? _buildEmptyState(
            icon: Icons.history,
            title: 'Chưa có lịch sử lương',
            subtitle: 'Lịch sử lương sẽ xuất hiện sau khi chạy tính lương',
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _salaryHistory.length,
            itemBuilder: (context, index) {
              final record = _salaryHistory[index];
              final isNegative = record.netSalary < 0;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isNegative ? PayrollColors.error : PayrollColors.success).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isNegative ? Icons.trending_down : Icons.trending_up,
                      color: isNegative ? PayrollColors.error : PayrollColors.success,
                    ),
                  ),
                  title: Text(
                    'Kỳ lương #${record.payrollPeriodId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Ngày công: ${record.totalWorkingDays}  |  OT: ${record.totalOTHours}h'),
                      Text('Tính lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(record.calculatedAt)}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFormat.format(record.netSalary),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isNegative ? PayrollColors.error : PayrollColors.success,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isNegative ? PayrollColors.error : PayrollColors.success).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isNegative ? 'CẢNH BÁO' : 'HOÀN THÀNH',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isNegative ? PayrollColors.error : PayrollColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to detailed salary view
                    // Navigator.push(context, MaterialPageRoute(...));
                  },
                ),
              );
            },
          ),
    );
  }

  // ==================== TAB IV: RULES HISTORY (VERSIONING) ====================

  Widget _buildRulesHistoryTab() {
    // TODO: Backend needs to implement GET /api/payroll/rules/versions/employee/{id}
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _buildEmptyState(
        icon: Icons.history_edu,
        title: 'Lịch sử quy tắc (Versioning)',
        subtitle: 'Tính năng đang phát triển.\nBackend cần implement: GET /api/payroll/rules/versions/employee/{id}',
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
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
}

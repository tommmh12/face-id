import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../utils/formatters.dart';
import '../data/payroll_service.dart';
import '../data/models/payroll_model.dart';

class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key});

  @override
  State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage>
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late final PayrollService _payrollService;
  late final TabController _tabController;

  List<PayrollPeriod> _periods = [];
  List<PayrollRule> _rules = [];
  
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _payrollService = PayrollService(_apiClient);
    _tabController = TabController(length: 2, vsync: this);
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
      final results = await Future.wait([
        _payrollService.getAllPeriods(),
        _payrollService.getAllRules(),
      ]);

      setState(() {
        _periods = results[0] as List<PayrollPeriod>;
        _rules = results[1] as List<PayrollRule>;
        _isLoading = false;
      });
    } catch (e) {
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
        title: const Text('Quản lý bảng lương'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Kỳ lương', icon: Icon(Icons.calendar_today)),
            Tab(text: 'Quy tắc', icon: Icon(Icons.rule)),
          ],
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePeriodDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tạo kỳ lương'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Đang tải dữ liệu...');
    }

    if (_error != null) {
      return ErrorStateWidget(
        message: _error!,
        onRetry: _loadData,
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildPeriodsTab(),
        _buildRulesTab(),
      ],
    );
  }

  Widget _buildPeriodsTab() {
    if (_periods.isEmpty) {
      return const EmptyWidget(
        icon: Icons.calendar_today_outlined,
        message: 'Chưa có kỳ lương nào',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _periods.length,
        itemBuilder: (context, index) {
          final period = _periods[index];
          return _buildPeriodCard(period);
        },
      ),
    );
  }

  Widget _buildPeriodCard(PayrollPeriod period) {
    final isActive = period.status.toLowerCase() == 'active';
    final isProcessed = period.processedDate != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.successGreen.withOpacity(0.1)
                : AppTheme.mediumGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_month,
            color: isActive ? AppTheme.successGreen : AppTheme.darkGray,
          ),
        ),
        title: Text(
          period.periodName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${Formatters.formatDate(period.startDate)} - ${Formatters.formatDate(period.endDate)}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.successGreen.withOpacity(0.1)
                    : AppTheme.mediumGray,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? AppTheme.successGreen : AppTheme.darkGray,
                ),
              ),
              child: Text(
                period.status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? AppTheme.successGreen : AppTheme.darkGray,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isProcessed) ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: AppTheme.successGreen),
                      const SizedBox(width: 4),
                      Text(
                        'Đã xử lý: ${Formatters.formatDateTime(period.processedDate)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _viewPayrollSummary(period),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Xem tổng hợp lương'),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () => _generatePayroll(period),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Tạo bảng lương'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesTab() {
    if (_rules.isEmpty) {
      return const EmptyWidget(
        icon: Icons.rule_outlined,
        message: 'Chưa có quy tắc lương nào',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rules.length,
        itemBuilder: (context, index) {
          final rule = _rules[index];
          return _buildRuleCard(rule);
        },
      ),
    );
  }

  Widget _buildRuleCard(PayrollRule rule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rule.employeeName ?? 'Employee #${rule.employeeId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (rule.effectiveTo == null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.successGreen),
                    ),
                    child: const Text(
                      'Hiện tại',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            _buildRuleRow('Lương cơ bản', Formatters.formatCurrency(rule.baseSalary)),
            _buildRuleRow('Tỷ lệ OT', Formatters.formatPercentage(rule.overtimeRate)),
            _buildRuleRow('Bảo hiểm', Formatters.formatPercentage(rule.insuranceRate)),
            _buildRuleRow('Thuế', Formatters.formatPercentage(rule.taxRate)),
            _buildRuleRow('Có hiệu lực từ', Formatters.formatDate(rule.effectiveFrom)),
            if (rule.effectiveTo != null)
              _buildRuleRow('Hết hiệu lực', Formatters.formatDate(rule.effectiveTo)),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.darkGray,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePeriodDialog() {
    showDialog(
      context: context,
      builder: (context) => CreatePeriodDialog(
        onSuccess: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  Future<void> _generatePayroll(PayrollPeriod period) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text(
          'Bạn có chắc muốn tạo bảng lương cho kỳ "${period.periodName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _payrollService.generatePayroll(period.id);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo bảng lương thành công!')),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _viewPayrollSummary(PayrollPeriod period) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final records = await _payrollService.getPayrollSummary(period.id);

      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Tổng hợp lương - ${period.periodName}'),
          content: SizedBox(
            width: double.maxFinite,
            child: records.isEmpty
                ? const Center(child: Text('Chưa có dữ liệu lương'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return Card(
                        child: ListTile(
                          title: Text(record.employeeName ?? 'Employee #${record.employeeId}'),
                          subtitle: Text(
                            'Lương net: ${Formatters.formatCurrency(record.netSalary)}',
                          ),
                          trailing: Text(
                            record.status,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.successGreen,
                            ),
                          ),
                        ),
                      );
                    },
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
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
}

class CreatePeriodDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const CreatePeriodDialog({super.key, required this.onSuccess});

  @override
  State<CreatePeriodDialog> createState() => _CreatePeriodDialogState();
}

class _CreatePeriodDialogState extends State<CreatePeriodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _periodNameController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isSubmitting = false;

  @override
  void dispose() {
    _periodNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày kết thúc phải sau ngày bắt đầu')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ApiClient();
      final payrollService = PayrollService(apiClient);

      final request = CreatePayrollPeriodRequest(
        periodName: _periodNameController.text,
        startDate: _startDate,
        endDate: _endDate,
      );

      await payrollService.createPeriod(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo kỳ lương thành công!')),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo kỳ lương mới'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _periodNameController,
              decoration: const InputDecoration(
                labelText: 'Tên kỳ lương *',
                border: OutlineInputBorder(),
                hintText: 'Ví dụ: Tháng 10/2025',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Vui lòng nhập tên kỳ lương' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Ngày bắt đầu'),
              subtitle: Text(Formatters.formatDate(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectStartDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.mediumGray),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Ngày kết thúc'),
              subtitle: Text(Formatters.formatDate(_endDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectEndDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.mediumGray),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Tạo mới'),
        ),
      ],
    );
  }
}

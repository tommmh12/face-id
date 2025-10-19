import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/dto/payroll_dtos.dart';
import '../../services/payroll_api_service.dart';
import '../../utils/app_logger.dart';

/// ⚙️ Payroll Rule Setup Screen - Configure Salary Rules
/// 
/// Features:
/// - Form to set base salary, working days, insurance rates
/// - Personal Income Tax (PIT) deduction settings
/// - Dependent deduction configuration
/// - Save/Update rule for employee
/// - Real-time net salary preview
class PayrollRuleSetupScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  final PayrollRuleResponse? existingRule;
  
  const PayrollRuleSetupScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
    this.existingRule,
  });

  @override
  State<PayrollRuleSetupScreen> createState() => _PayrollRuleSetupScreenState();
}

class _PayrollRuleSetupScreenState extends State<PayrollRuleSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final PayrollApiService _payrollService = PayrollApiService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  
  // Form Controllers
  late TextEditingController _baseSalaryController;
  late TextEditingController _workingDaysController;
  late TextEditingController _socialInsuranceController;
  late TextEditingController _healthInsuranceController;
  late TextEditingController _unemploymentInsuranceController;
  late TextEditingController _personalDeductionController;
  late TextEditingController _dependentsController;
  late TextEditingController _dependentDeductionController;
  
  bool _isSaving = false;
  
  // Calculated values
  double _grossSalary = 0;
  double _totalInsurance = 0;
  double _taxableIncome = 0;
  double _estimatedPIT = 0;
  double _netSalary = 0;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data or defaults
    final rule = widget.existingRule;
    
    _baseSalaryController = TextEditingController(
      text: rule?.baseSalary.toStringAsFixed(0) ?? '10000000',
    );
    _workingDaysController = TextEditingController(
      text: rule?.standardWorkingDays.toString() ?? '22',
    );
    _socialInsuranceController = TextEditingController(
      text: rule?.socialInsuranceRate.toStringAsFixed(1) ?? '8.0',
    );
    _healthInsuranceController = TextEditingController(
      text: rule?.healthInsuranceRate.toStringAsFixed(1) ?? '1.5',
    );
    _unemploymentInsuranceController = TextEditingController(
      text: rule?.unemploymentInsuranceRate.toStringAsFixed(1) ?? '1.0',
    );
    _personalDeductionController = TextEditingController(
      text: rule?.personalDeduction.toStringAsFixed(0) ?? '11000000',
    );
    _dependentsController = TextEditingController(
      text: rule?.numberOfDependents.toString() ?? '0',
    );
    _dependentDeductionController = TextEditingController(
      text: rule?.dependentDeduction.toStringAsFixed(0) ?? '4400000',
    );
    
    // Add listeners for real-time calculation
    _baseSalaryController.addListener(_calculateSalary);
    _socialInsuranceController.addListener(_calculateSalary);
    _healthInsuranceController.addListener(_calculateSalary);
    _unemploymentInsuranceController.addListener(_calculateSalary);
    _personalDeductionController.addListener(_calculateSalary);
    _dependentsController.addListener(_calculateSalary);
    _dependentDeductionController.addListener(_calculateSalary);
    
    // Initial calculation
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateSalary());
  }

  @override
  void dispose() {
    _baseSalaryController.dispose();
    _workingDaysController.dispose();
    _socialInsuranceController.dispose();
    _healthInsuranceController.dispose();
    _unemploymentInsuranceController.dispose();
    _personalDeductionController.dispose();
    _dependentsController.dispose();
    _dependentDeductionController.dispose();
    super.dispose();
  }

  void _calculateSalary() {
    try {
      final baseSalary = double.tryParse(_baseSalaryController.text.replaceAll(',', '')) ?? 0;
      final socialRate = double.tryParse(_socialInsuranceController.text) ?? 0;
      final healthRate = double.tryParse(_healthInsuranceController.text) ?? 0;
      final unemploymentRate = double.tryParse(_unemploymentInsuranceController.text) ?? 0;
      final personalDeduction = double.tryParse(_personalDeductionController.text.replaceAll(',', '')) ?? 0;
      final dependents = int.tryParse(_dependentsController.text) ?? 0;
      final dependentDeduction = double.tryParse(_dependentDeductionController.text.replaceAll(',', '')) ?? 0;
      
      setState(() {
        _grossSalary = baseSalary;
        
        // Insurance deduction (on gross salary)
        _totalInsurance = baseSalary * (socialRate + healthRate + unemploymentRate) / 100;
        
        // Taxable income = Gross - Insurance - Personal Deduction - Dependent Deduction
        final totalDependentDeduction = dependents * dependentDeduction;
        _taxableIncome = baseSalary - _totalInsurance - personalDeduction - totalDependentDeduction;
        
        // PIT calculation (progressive tax brackets)
        _estimatedPIT = _calculatePIT(_taxableIncome);
        
        // Net salary = Gross - Insurance - PIT
        _netSalary = _grossSalary - _totalInsurance - _estimatedPIT;
      });
    } catch (e) {
      AppLogger.warning('Salary calculation error: $e', tag: 'PayrollRuleSetup');
    }
  }

  double _calculatePIT(double taxableIncome) {
    if (taxableIncome <= 0) return 0;
    
    // Vietnam PIT progressive tax brackets (2024)
    double pit = 0;
    
    if (taxableIncome <= 5000000) {
      pit = taxableIncome * 0.05;
    } else if (taxableIncome <= 10000000) {
      pit = 5000000 * 0.05 + (taxableIncome - 5000000) * 0.10;
    } else if (taxableIncome <= 18000000) {
      pit = 5000000 * 0.05 + 5000000 * 0.10 + (taxableIncome - 10000000) * 0.15;
    } else if (taxableIncome <= 32000000) {
      pit = 5000000 * 0.05 + 5000000 * 0.10 + 8000000 * 0.15 + (taxableIncome - 18000000) * 0.20;
    } else if (taxableIncome <= 52000000) {
      pit = 5000000 * 0.05 + 5000000 * 0.10 + 8000000 * 0.15 + 14000000 * 0.20 + (taxableIncome - 32000000) * 0.25;
    } else if (taxableIncome <= 80000000) {
      pit = 5000000 * 0.05 + 5000000 * 0.10 + 8000000 * 0.15 + 14000000 * 0.20 + 20000000 * 0.25 + (taxableIncome - 52000000) * 0.30;
    } else {
      pit = 5000000 * 0.05 + 5000000 * 0.10 + 8000000 * 0.15 + 14000000 * 0.20 + 20000000 * 0.25 + 28000000 * 0.30 + (taxableIncome - 80000000) * 0.35;
    }
    
    return pit;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚙️ Cài đặt quy tắc lương'),
            Text(
              widget.employeeName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.existingRule != null)
            IconButton(
              onPressed: _showRuleInfo,
              icon: const Icon(Icons.info_outline),
              tooltip: 'Thông tin quy tắc',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Form Fields (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Base Salary
                    _buildSectionHeader('💰 Lương cơ bản', theme),
                    _buildSalaryCard(theme, colorScheme),
                    
                    const SizedBox(height: 24),
                    
                    // Section 2: Working Days
                    _buildSectionHeader('📅 Ngày công chuẩn', theme),
                    _buildWorkingDaysCard(theme, colorScheme),
                    
                    const SizedBox(height: 24),
                    
                    // Section 3: Insurance Rates
                    _buildSectionHeader('🏥 Tỷ lệ bảo hiểm', theme),
                    _buildInsuranceCard(theme, colorScheme),
                    
                    const SizedBox(height: 24),
                    
                    // Section 4: Tax Deductions
                    _buildSectionHeader('📊 Giảm trừ thuế', theme),
                    _buildTaxDeductionCard(theme, colorScheme),
                    
                    const SizedBox(height: 24),
                    
                    // Section 5: Salary Preview
                    _buildSectionHeader('💵 Dự tính lương thực nhận', theme),
                    _buildSalaryPreviewCard(theme, colorScheme),
                    
                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),
            ),
            
            // Bottom Action Bar
            _buildBottomBar(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSalaryCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _baseSalaryController,
              decoration: InputDecoration(
                labelText: 'Lương cơ bản (₫/tháng)',
                hintText: 'VD: 10,000,000',
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: '₫',
                border: const OutlineInputBorder(),
                helperText: 'Lương cơ bản theo hợp đồng lao động',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsSeparatorInputFormatter(),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập lương cơ bản';
                }
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return 'Lương phải lớn hơn 0';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingDaysCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _workingDaysController,
          decoration: const InputDecoration(
            labelText: 'Số ngày công chuẩn/tháng',
            hintText: 'VD: 22',
            prefixIcon: Icon(Icons.calendar_today),
            suffixText: 'ngày',
            border: OutlineInputBorder(),
            helperText: 'Số ngày làm việc tiêu chuẩn trong tháng',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập số ngày công';
            }
            final days = int.tryParse(value);
            if (days == null || days < 1 || days > 31) {
              return 'Số ngày từ 1-31';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildInsuranceCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Social Insurance
            TextFormField(
              controller: _socialInsuranceController,
              decoration: const InputDecoration(
                labelText: 'Bảo hiểm xã hội (BHXH)',
                hintText: 'VD: 8.0',
                prefixIcon: Icon(Icons.health_and_safety),
                suffixText: '%',
                border: OutlineInputBorder(),
                helperText: 'Mức đóng BHXH theo quy định (8%)',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Nhập tỷ lệ BHXH';
                final rate = double.tryParse(value);
                if (rate == null || rate < 0 || rate > 100) return 'Tỷ lệ 0-100%';
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Health Insurance
            TextFormField(
              controller: _healthInsuranceController,
              decoration: const InputDecoration(
                labelText: 'Bảo hiểm y tế (BHYT)',
                hintText: 'VD: 1.5',
                prefixIcon: Icon(Icons.medical_services),
                suffixText: '%',
                border: OutlineInputBorder(),
                helperText: 'Mức đóng BHYT theo quy định (1.5%)',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Nhập tỷ lệ BHYT';
                final rate = double.tryParse(value);
                if (rate == null || rate < 0 || rate > 100) return 'Tỷ lệ 0-100%';
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Unemployment Insurance
            TextFormField(
              controller: _unemploymentInsuranceController,
              decoration: const InputDecoration(
                labelText: 'Bảo hiểm thất nghiệp (BHTN)',
                hintText: 'VD: 1.0',
                prefixIcon: Icon(Icons.work_off),
                suffixText: '%',
                border: OutlineInputBorder(),
                helperText: 'Mức đóng BHTN theo quy định (1%)',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Nhập tỷ lệ BHTN';
                final rate = double.tryParse(value);
                if (rate == null || rate < 0 || rate > 100) return 'Tỷ lệ 0-100%';
                return null;
              },
            ),
            
            const SizedBox(height: 12),
            
            // Insurance Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A84FF).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate, color: Color(0xFF0A84FF), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tổng khấu trừ BH: ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _currencyFormat.format(_totalInsurance),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0A84FF),
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

  Widget _buildTaxDeductionCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Personal Deduction
            TextFormField(
              controller: _personalDeductionController,
              decoration: const InputDecoration(
                labelText: 'Giảm trừ bản thân',
                hintText: 'VD: 11,000,000',
                prefixIcon: Icon(Icons.person),
                suffixText: '₫',
                border: OutlineInputBorder(),
                helperText: 'Mức giảm trừ cá nhân theo luật (11 triệu)',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsSeparatorInputFormatter(),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Nhập mức giảm trừ';
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Number of Dependents
            TextFormField(
              controller: _dependentsController,
              decoration: const InputDecoration(
                labelText: 'Số người phụ thuộc',
                hintText: 'VD: 2',
                prefixIcon: Icon(Icons.family_restroom),
                suffixText: 'người',
                border: OutlineInputBorder(),
                helperText: 'Số người phụ thuộc (con, cha mẹ...)',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Nhập số người phụ thuộc';
                final num = int.tryParse(value);
                if (num == null || num < 0) return 'Số người >= 0';
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Dependent Deduction
            TextFormField(
              controller: _dependentDeductionController,
              decoration: const InputDecoration(
                labelText: 'Giảm trừ/người phụ thuộc',
                hintText: 'VD: 4,400,000',
                prefixIcon: Icon(Icons.groups),
                suffixText: '₫',
                border: OutlineInputBorder(),
                helperText: 'Mức giảm trừ mỗi người (4.4 triệu)',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsSeparatorInputFormatter(),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Nhập mức giảm trừ';
                return null;
              },
            ),
            
            const SizedBox(height: 12),
            
            // Tax Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9500).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Thu nhập tính thuế:',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        _currencyFormat.format(_taxableIncome > 0 ? _taxableIncome : 0),
                        style: theme.textTheme.bodySmall?.copyWith(
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
                        'Thuế TNCN dự kiến:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _currencyFormat.format(_estimatedPIT),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF9500),
                        ),
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

  Widget _buildSalaryPreviewCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF34C759), Color(0xFF28A745)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lương cơ bản:',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  _currencyFormat.format(_grossSalary),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '- Bảo hiểm:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  _currencyFormat.format(_totalInsurance),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '- Thuế TNCN:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  _currencyFormat.format(_estimatedPIT),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white30, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lương thực nhận:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _currencyFormat.format(_netSalary > 0 ? _netSalary : 0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveRule,
                icon: _isSaving 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Đang lưu...' : 'Lưu quy tắc'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRuleInfo() {
    final rule = widget.existingRule!;
    final createdDate = DateFormat('dd/MM/yyyy HH:mm').format(rule.createdAt);
    final updatedDate = rule.updatedAt != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(rule.updatedAt!)
        : 'Chưa cập nhật';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info),
            SizedBox(width: 12),
            Text('Thông tin quy tắc'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${rule.id}'),
            const SizedBox(height: 8),
            Text('Nhân viên: ${widget.employeeName}'),
            const SizedBox(height: 8),
            Text('Ngày tạo: $createdDate'),
            const SizedBox(height: 8),
            Text('Cập nhật lần cuối: $updatedDate'),
            const SizedBox(height: 8),
            Text('Trạng thái: ${rule.isActive ? "Đang áp dụng" : "Tạm dừng"}'),
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

  Future<void> _saveRule() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng kiểm tra lại thông tin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    AppLogger.startOperation('Save Payroll Rule');
    
    try {
      final request = CreatePayrollRuleRequest(
        employeeId: widget.employeeId,
        baseSalary: double.parse(_baseSalaryController.text.replaceAll(',', '')),
        standardWorkingDays: int.parse(_workingDaysController.text),
        socialInsuranceRate: double.parse(_socialInsuranceController.text),
        healthInsuranceRate: double.parse(_healthInsuranceController.text),
        unemploymentInsuranceRate: double.parse(_unemploymentInsuranceController.text),
        personalDeduction: double.parse(_personalDeductionController.text.replaceAll(',', '')),
        numberOfDependents: int.parse(_dependentsController.text),
        dependentDeduction: double.parse(_dependentDeductionController.text.replaceAll(',', '')),
      );
      
      AppLogger.data('Saving rule for employee ${widget.employeeId}', tag: 'PayrollRuleSetup');
      
      final response = await _payrollService.createOrUpdatePayrollRule(request);
      
      if (response.success) {
        AppLogger.success('Rule saved successfully', tag: 'PayrollRuleSetup');
        AppLogger.endOperation('Save Payroll Rule', success: true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Lưu quy tắc lương thành công!'),
                ],
              ),
              backgroundColor: Color(0xFF34C759),
            ),
          );
          
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(response.message);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save rule', error: e, stackTrace: stackTrace, tag: 'PayrollRuleSetup');
      AppLogger.endOperation('Save Payroll Rule', success: false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

/// Custom input formatter for thousands separator
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final number = int.tryParse(newValue.text.replaceAll(',', ''));
    if (number == null) {
      return oldValue;
    }

    final formatter = NumberFormat('#,###', 'en_US');
    final newText = formatter.format(number);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

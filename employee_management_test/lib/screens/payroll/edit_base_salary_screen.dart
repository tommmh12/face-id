import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/dto/payroll_dtos.dart';
import '../../models/employee.dart';
import '../../services/payroll_api_service.dart';
import '../../config/app_theme.dart';
import '../../utils/app_logger.dart';
import '../../utils/user_helper.dart';

/// Màn hình sửa lương cơ bản (Base Salary) của nhân viên
/// 
/// Features:
/// - Hiển thị thông tin nhân viên và lương hiện tại
/// - Form nhập lương mới với validation
/// - Lý do thay đổi (bắt buộc)
/// - Ngày hiệu lực
/// - Tạo version mới của PayrollRule (không ghi đè rule cũ)
/// - Audit trail với lý do thay đổi
class EditBaseSalaryScreen extends StatefulWidget {
  final Employee employee;
  final PayrollRuleResponse? currentRule;

  const EditBaseSalaryScreen({
    super.key,
    required this.employee,
    this.currentRule,
  });

  @override
  State<EditBaseSalaryScreen> createState() => _EditBaseSalaryScreenState();
}

class _EditBaseSalaryScreenState extends State<EditBaseSalaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseSalaryController = TextEditingController();
  final _reasonController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  
  final PayrollApiService _payrollService = PayrollApiService();
  
  DateTime _effectiveDate = DateTime.now();
  bool _isLoading = false;
  bool _isLoadingCurrentRule = false;
  PayrollRuleResponse? _currentRule;
  
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
    _currentRule = widget.currentRule;
    
    if (_currentRule == null) {
      _loadCurrentPayrollRule();
    } else {
      _initializeForm();
    }
  }

  @override
  void dispose() {
    _baseSalaryController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  /// Load current payroll rule nếu chưa có
  Future<void> _loadCurrentPayrollRule() async {
    setState(() => _isLoadingCurrentRule = true);
    
    try {
      final response = await _payrollService.getPayrollRuleByEmployeeId(widget.employee.id);
      
      if (response.success && response.data != null) {
        setState(() {
          _currentRule = response.data!;
        });
        _initializeForm();
      } else {
        // Nhân viên chưa có payroll rule - cho phép tạo mới
        setState(() {
          _currentRule = null;
        });
        _initializeForm();
        AppLogger.info('Employee ${widget.employee.id} has no payroll rule yet - will create new', tag: 'EditBaseSalary');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ Nhân viên này chưa có quy tắc lương. Bạn có thể tạo mới.'),
              backgroundColor: Color(0xFF0A84FF),
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error loading payroll rule', error: e, tag: 'EditBaseSalary');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải thông tin lương: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingCurrentRule = false);
    }
  }

  /// Initialize form với dữ liệu hiện tại
  void _initializeForm() {
    if (_currentRule != null) {
      _baseSalaryController.text = _currentRule!.baseSalary.toStringAsFixed(0);
    } else {
      // Chưa có rule - để form trống để user nhập
      _baseSalaryController.clear();
    }
  }

  /// Validate và save lương mới
  Future<void> _saveSalaryChange() async {
    if (!_formKey.currentState!.validate()) return;
    
    final newBaseSalary = double.tryParse(_baseSalaryController.text.replaceAll(',', ''));
    if (newBaseSalary == null || newBaseSalary <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập lương cơ bản hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Kiểm tra xem có thay đổi không (chỉ khi đã có rule)
    if (_currentRule != null && newBaseSalary == _currentRule!.baseSalary) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lương mới phải khác với lương hiện tại'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Lấy thông tin người dùng hiện tại
      final currentUser = await UserHelper.getCurrentUserName();
      
      if (_currentRule != null) {
        // TRƯỜNG HỢP 1: Đã có rule → Tạo version mới (cập nhật)
        AppLogger.info('Updating existing salary rule: ${widget.employee.fullName} - ${_safeCurrencyFormat(newBaseSalary)}', tag: 'EditBaseSalary');
        
        final request = CreatePayrollRuleVersionRequest(
          employeeId: widget.employee.id,
          baseSalary: newBaseSalary,
          effectiveDate: _effectiveDate,
          reason: _reasonController.text.trim(),
          // Giữ nguyên các thông số khác từ rule hiện tại
          standardWorkingDays: _currentRule!.standardWorkingDays,
          socialInsuranceRate: _currentRule!.socialInsuranceRate,
          healthInsuranceRate: _currentRule!.healthInsuranceRate,
          unemploymentInsuranceRate: _currentRule!.unemploymentInsuranceRate,
          personalDeduction: _currentRule!.personalDeduction,
          numberOfDependents: _currentRule!.numberOfDependents,
          dependentDeduction: _currentRule!.dependentDeduction,
          createdBy: currentUser,
        );

        final response = await _payrollService.createPayrollRuleVersion(request);
        
        if (response.success && response.data != null) {
          AppLogger.success('Salary rule updated successfully: ${widget.employee.fullName}', tag: 'EditBaseSalary');
          _handleUpdateSuccess(response.data!, newBaseSalary);
        } else {
          throw Exception(response.message ?? 'Không thể cập nhật lương');
        }
      } else {
        // TRƯỜNG HỢP 2: Chưa có rule → Tạo mới hoàn toàn
        AppLogger.info('Creating new salary rule: ${widget.employee.fullName} - ${_safeCurrencyFormat(newBaseSalary)}', tag: 'EditBaseSalary');
        
        final request = CreatePayrollRuleRequest(
          employeeId: widget.employee.id,
          baseSalary: newBaseSalary,
          // Sử dụng giá trị default
          standardWorkingDays: 22,
          socialInsuranceRate: 8.0,
          healthInsuranceRate: 1.5,
          unemploymentInsuranceRate: 1.0,
          personalDeduction: 11000000,
          numberOfDependents: 0,
          dependentDeduction: 4400000,
        );

        final response = await _payrollService.createOrUpdatePayrollRule(request);
        
        if (response.success && response.data != null) {
          AppLogger.success('Salary rule created successfully: ${widget.employee.fullName}', tag: 'EditBaseSalary');
          _handleCreateSuccess(response.data!, newBaseSalary);
        } else {
          throw Exception(response.message ?? 'Không thể tạo quy tắc lương');
        }
      }
    } catch (e) {
      AppLogger.error('Error updating salary', error: e, tag: 'EditBaseSalary');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi cập nhật lương: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Xử lý thành công khi cập nhật rule có sẵn
  void _handleUpdateSuccess(PayrollRuleVersionResponse newVersion, double newBaseSalary) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã cập nhật lương thành công: ${_safeCurrencyFormat(newBaseSalary)}'),
          backgroundColor: AppColors.successColor,
        ),
      );
      
      // Trả về thông tin đã cập nhật
      Navigator.of(context).pop({
        'success': true,
        'newVersion': newVersion,
        'previousSalary': _currentRule?.baseSalary ?? 0,
        'newSalary': newBaseSalary,
        'reason': _reasonController.text.trim(),
        'effectiveDate': _effectiveDate,
      });
    }
  }

  /// Xử lý thành công khi tạo rule mới
  void _handleCreateSuccess(PayrollRuleResponse newRule, double newBaseSalary) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã tạo quy tắc lương thành công: ${_safeCurrencyFormat(newBaseSalary)}'),
          backgroundColor: AppColors.successColor,
        ),
      );
      
      // Trả về thông tin đã tạo
      Navigator.of(context).pop({
        'success': true,
        'newRule': newRule,
        'previousSalary': 0, // Chưa có lương trước đó
        'newSalary': newBaseSalary,
        'isNewRule': true,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: Text(_currentRule != null ? 'Sửa lương cơ bản' : 'Tạo quy tắc lương mới'),
        elevation: 0,
        backgroundColor: AppColors.bgColor,
      ),
      body: _isLoadingCurrentRule 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Employee info card
                  _buildEmployeeInfoCard(),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Current salary info
                  if (_currentRule != null) _buildCurrentSalaryCard(),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // New salary form
                  _buildSalaryForm(),
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // Action buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
    );
  }

  /// Employee info card
  Widget _buildEmployeeInfoCard() {
    return Container(
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
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              widget.employee.fullName.isNotEmpty 
                ? widget.employee.fullName[0].toUpperCase() 
                : 'N',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.employee.fullName,
                  style: AppTextStyles.h5.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'MSNV: ${widget.employee.employeeCode.isNotEmpty ? widget.employee.employeeCode : 'EMP${widget.employee.id}'}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (widget.employee.position != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.employee.position!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
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

  /// Current salary card
  Widget _buildCurrentSalaryCard() {
    return Container(
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
                'Lương hiện tại',
                style: AppTextStyles.h6.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lương cơ bản:',
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                _safeCurrencyFormat(_currentRule!.baseSalary),
                style: AppTextStyles.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ngày công chuẩn:',
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                '${_currentRule!.standardWorkingDays} ngày/tháng',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ngày tạo:',
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                '${_currentRule!.createdAt.day}/${_currentRule!.createdAt.month}/${_currentRule!.createdAt.year}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Salary form
  Widget _buildSalaryForm() {
    return Container(
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
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _currentRule != null ? 'Thông tin lương mới' : 'Thông tin quy tắc lương',
                style: AppTextStyles.h6.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // New base salary input
          Text(
            _currentRule != null ? 'Lương cơ bản mới *' : 'Lương cơ bản *',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _baseSalaryController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TextInputFormatter.withFunction((oldValue, newValue) {
                // Format number với dấu phẩy
                if (newValue.text.isEmpty) return newValue;
                final number = int.tryParse(newValue.text.replaceAll(',', ''));
                if (number == null) return oldValue;
                final formatted = NumberFormat('#,###').format(number);
                return TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }),
            ],
            decoration: InputDecoration(
              hintText: _currentRule != null ? 'Nhập lương cơ bản mới' : 'Nhập lương cơ bản',
              prefixText: '₫ ',
              suffixText: 'VND',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập lương cơ bản';
              }
              final amount = double.tryParse(value.replaceAll(',', ''));
              if (amount == null || amount <= 0) {
                return 'Lương cơ bản phải lớn hơn 0';
              }
              if (amount < 1000000) {
                return 'Lương cơ bản tối thiểu 1,000,000₫';
              }
              if (amount > 100000000) {
                return 'Lương cơ bản tối đa 100,000,000₫';
              }
              return null;
            },
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Effective date
          Text(
            'Ngày hiệu lực *',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: _selectEffectiveDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md + 2,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_effectiveDate.day}/${_effectiveDate.month}/${_effectiveDate.year}',
                    style: AppTextStyles.bodyMedium,
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Reason input
          Text(
            _currentRule != null ? 'Lý do thay đổi *' : 'Ghi chú *',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: _currentRule != null ? 'Nhập lý do điều chỉnh lương...' : 'Nhập ghi chú cho quy tắc lương...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return _currentRule != null ? 'Vui lòng nhập lý do thay đổi lương' : 'Vui lòng nhập ghi chú';
              }
              if (value.trim().length < 10) {
                return 'Nội dung phải có ít nhất 10 ký tự';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// Action buttons
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.primaryBlue),
            ),
            child: Text(
              'Hủy',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveSalaryChange,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _currentRule != null ? 'Cập nhật lương' : 'Tạo quy tắc lương',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
      ],
    );
  }

  /// Date picker
  Future<void> _selectEffectiveDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _effectiveDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)), // Cho phép backdate 30 ngày
      lastDate: DateTime.now().add(const Duration(days: 365)), // Cho phép schedule 1 năm tới
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _effectiveDate) {
      setState(() {
        _effectiveDate = picked;
      });
    }
  }
}
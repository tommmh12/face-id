import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/dto/payroll_dtos.dart';
import '../../../services/payroll_api_service.dart';
import '../../../utils/app_logger.dart';

/// 🎯 EDIT SALARY ADJUSTMENT DIALOG (V2.1)
/// 
/// Features:
/// - Pre-filled data from existing adjustment
/// - Validation with business rules
/// - Update reason field (CRITICAL for audit)
/// - Transaction flow: Update → Recalculate
/// - Professional Material 3 design
class EditAdjustmentDialog extends StatefulWidget {
  final SalaryAdjustmentResponse adjustment;
  final int periodId;
  final VoidCallback? onUpdated; // Callback để reload data

  const EditAdjustmentDialog({
    super.key,
    required this.adjustment,
    required this.periodId,
    this.onUpdated,
  });

  @override
  State<EditAdjustmentDialog> createState() => _EditAdjustmentDialogState();
}

class _EditAdjustmentDialogState extends State<EditAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _payrollService = PayrollApiService();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  // Controllers with pre-filled data
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _updateReasonController;
  
  // Form state
  String _selectedType = 'BONUS';
  DateTime _effectiveDate = DateTime.now();
  bool _isLoading = false;

  // Adjustment types
  final List<Map<String, dynamic>> _adjustmentTypes = [
    {'value': 'BONUS', 'label': '🎁 Thưởng', 'color': Color(0xFF34C759)},
    {'value': 'PENALTY', 'label': '⚠️ Phạt', 'color': Color(0xFFFF3B30)},
    {'value': 'CORRECTION', 'label': '⚖️ Điều chỉnh', 'color': Color(0xFFFF9500)},
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Pre-fill với dữ liệu gốc của adjustment
    _amountController = TextEditingController(
      text: widget.adjustment.amount.abs().toStringAsFixed(0), // Không hiển thị số âm trong input
    );
    _descriptionController = TextEditingController(
      text: widget.adjustment.description,
    );
    _updateReasonController = TextEditingController();
    
    _selectedType = widget.adjustment.adjustmentType.toUpperCase();
    _effectiveDate = widget.adjustment.effectiveDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _updateReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.adjustment.getTypeColor().withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.edit_rounded,
              color: widget.adjustment.getTypeColor(),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chỉnh sửa điều chỉnh lương',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'ID: ${widget.adjustment.id} • ${widget.adjustment.employeeName ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ⚠️ Warning nếu adjustment đã processed
                if (!widget.adjustment.canEdit) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withAlpha(50)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Không thể chỉnh sửa: Adjustment đã được xử lý trong bảng lương',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 1. Adjustment Type Dropdown
                _buildTypeDropdown(),
                const SizedBox(height: 16),

                // 2. Amount Input
                _buildAmountInput(),
                const SizedBox(height: 16),

                // 3. Description Input
                _buildDescriptionInput(),
                const SizedBox(height: 16),

                // 4. Effective Date Picker
                _buildDatePicker(),
                const SizedBox(height: 16),

                // 5. Update Reason Input (CRITICAL)
                _buildUpdateReasonInput(),
                const SizedBox(height: 16),

                // 📊 Original vs New Comparison
                _buildComparisonCard(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Cancel Button
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        
        // Save & Recalculate Button
        FilledButton.icon(
          onPressed: _isLoading || !widget.adjustment.canEdit 
            ? null 
            : _updateAndRecalculate,
          icon: _isLoading 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_alt_rounded),
          label: Text(_isLoading 
            ? 'Đang xử lý...' 
            : 'Lưu & Tính lại lương'),
          style: FilledButton.styleFrom(
            backgroundColor: widget.adjustment.canEdit 
              ? colorScheme.primary 
              : colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: InputDecoration(
        labelText: 'Loại điều chỉnh',
        prefixIcon: Icon(
          Icons.category_rounded,
          color: _getSelectedTypeColor(),
        ),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: _getSelectedTypeColor().withAlpha(10),
      ),
      items: _adjustmentTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type['value'],
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: type['color'],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 8),
              Text(type['label']),
            ],
          ),
        );
      }).toList(),
      onChanged: widget.adjustment.canEdit 
        ? (value) {
            if (value != null) {
              setState(() {
                _selectedType = value;
              });
            }
          }
        : null,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng chọn loại điều chỉnh';
        }
        return null;
      },
    );
  }

  Widget _buildAmountInput() {
    return TextFormField(
      controller: _amountController,
      enabled: widget.adjustment.canEdit,
      decoration: InputDecoration(
        labelText: 'Số tiền',
        hintText: 'VD: 5000000',
        prefixIcon: Icon(
          Icons.payments_rounded,
          color: _getSelectedTypeColor(),
        ),
        suffixText: 'VNĐ',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: _getSelectedTypeColor().withAlpha(10),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        TextInputFormatter.withFunction((oldValue, newValue) {
          if (newValue.text.isEmpty) return newValue;
          final number = int.tryParse(newValue.text);
          if (number != null) {
            final formatted = NumberFormat('#,###').format(number);
            return TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
          return oldValue;
        }),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập số tiền';
        }
        final cleanValue = value.replaceAll(',', '');
        final amount = double.tryParse(cleanValue);
        if (amount == null || amount <= 0) {
          return 'Số tiền phải lớn hơn 0';
        }
        if (amount > 999999999) {
          return 'Số tiền không được vượt quá 999,999,999 VNĐ';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionInput() {
    return TextFormField(
      controller: _descriptionController,
      enabled: widget.adjustment.canEdit,
      decoration: const InputDecoration(
        labelText: 'Mô tả/Lý do',
        hintText: 'VD: Thưởng hoàn thành dự án Q4/2024',
        prefixIcon: Icon(Icons.description_rounded),
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
      maxLength: 500,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Vui lòng nhập mô tả';
        }
        if (value.trim().length < 10) {
          return 'Mô tả phải có ít nhất 10 ký tự';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: widget.adjustment.canEdit ? _selectDate : null,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Ngày hiệu lực',
          prefixIcon: Icon(Icons.calendar_today_rounded),
          border: OutlineInputBorder(),
        ),
        child: Text(
          DateFormat('dd/MM/yyyy').format(_effectiveDate),
          style: TextStyle(
            color: widget.adjustment.canEdit 
              ? null 
              : Theme.of(context).disabledColor,
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateReasonInput() {
    return TextFormField(
      controller: _updateReasonController,
      enabled: widget.adjustment.canEdit,
      decoration: InputDecoration(
        labelText: 'Lý do cập nhật *',
        hintText: 'VD: Điều chỉnh theo quyết định HĐQT ngày 15/10/2025',
        prefixIcon: const Icon(Icons.edit_note_rounded, color: Colors.orange),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.orange.withAlpha(10),
        helperText: '⚠️ Bắt buộc để ghi nhận vào audit log',
        helperStyle: const TextStyle(color: Colors.orange, fontSize: 11),
      ),
      maxLines: 3,
      maxLength: 500,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Lý do cập nhật là bắt buộc (để audit)';
        }
        if (value.trim().length < 15) {
          return 'Lý do cập nhật phải có ít nhất 15 ký tự';
        }
        return null;
      },
    );
  }

  Widget _buildComparisonCard() {
    final originalAmount = widget.adjustment.amount;
    final newAmount = _getNewAmount();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows_rounded, size: 16),
              const SizedBox(width: 4),
              Text(
                'So sánh thay đổi',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trước:', style: TextStyle(fontSize: 12)),
                    Text(
                      '${widget.adjustment.getTypeLabel()}: ${_currencyFormat.format(originalAmount.abs())}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, size: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Sau:', style: TextStyle(fontSize: 12)),
                    Text(
                      '${_getTypeLabel(_selectedType)}: ${_currencyFormat.format(newAmount.abs())}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _getSelectedTypeColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (originalAmount != newAmount) ...[
            const SizedBox(height: 4),
            Text(
              'Chênh lệch: ${_currencyFormat.format((newAmount - originalAmount).abs())}',
              style: TextStyle(
                fontSize: 11,
                color: newAmount > originalAmount ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getSelectedTypeColor() {
    final type = _adjustmentTypes.firstWhere(
      (t) => t['value'] == _selectedType,
      orElse: () => _adjustmentTypes.first,
    );
    return type['color'];
  }

  String _getTypeLabel(String type) {
    final typeMap = _adjustmentTypes.firstWhere(
      (t) => t['value'] == type,
      orElse: () => _adjustmentTypes.first,
    );
    return typeMap['label'];
  }

  double _getNewAmount() {
    final cleanValue = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(cleanValue) ?? 0;
    // Apply sign based on type
    return _selectedType == 'PENALTY' ? -amount : amount;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _effectiveDate = picked;
      });
    }
  }

  /// 🔥 MAIN TRANSACTION FLOW: Update → Recalculate
  Future<void> _updateAndRecalculate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      AppLogger.startOperation('Update and Recalculate Salary Adjustment');

      // Step 1: Update Salary Adjustment
      final updateRequest = UpdateSalaryAdjustmentRequest(
        adjustmentType: _selectedType,
        amount: _getNewAmount(),
        effectiveDate: _effectiveDate,
        description: _descriptionController.text.trim(),
        updatedBy: 'HR001', // TODO: Get from current user
        updateReason: _updateReasonController.text.trim(),
      );

      AppLogger.info('Updating adjustment ${widget.adjustment.id}: ${updateRequest.updateReason}');

      final updateResponse = await _payrollService.updateSalaryAdjustment(
        widget.adjustment.id,
        updateRequest,
      );

      if (!updateResponse.success) {
        throw Exception(updateResponse.message);
      }

      AppLogger.success('Adjustment updated successfully');

      // Step 2: Recalculate Payroll
      AppLogger.data('Recalculating payroll for period ${widget.periodId}');

      final recalcResponse = await _payrollService.recalculatePayroll(widget.periodId);

      if (!recalcResponse.success) {
        throw Exception(recalcResponse.message);
      }

      AppLogger.success('Payroll recalculated successfully');
      AppLogger.endOperation('Update and Recalculate Salary Adjustment', success: true);

      // Success feedback
      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Cập nhật thành công!',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Đã tính lại lương cho ${recalcResponse.data?.recalculatedCount ?? 0} nhân viên',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF34C759),
            duration: const Duration(seconds: 4),
          ),
        );

        // Trigger callback to reload data
        widget.onUpdated?.call();
      }

    } catch (e, stackTrace) {
      AppLogger.error('Failed to update and recalculate', error: e, stackTrace: stackTrace);
      AppLogger.endOperation('Update and Recalculate Salary Adjustment', success: false);

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
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
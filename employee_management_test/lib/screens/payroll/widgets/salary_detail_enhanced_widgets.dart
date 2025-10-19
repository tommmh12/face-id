import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/dto/payroll_dtos.dart';
import '../../../config/app_theme.dart';

/// 💰 Employee Salary Detail - Enhanced UI Widgets
/// 
/// Các widget nâng cấp cho màn hình chi tiết lương:
/// - Warning Banner cho lương âm
/// - Dashboard Summary Card
/// - Income/Deduction sections với công thức chi tiết
class SalaryDetailEnhancedWidgets {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  /// ⚠️ Banner cảnh báo lương âm
  static Widget buildNegativeSalaryWarningBanner() {
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

  /// 📊 Dashboard Summary Card
  static Widget buildDashboardSummaryCard({
    required PayrollRecordResponse payrollData,
    required bool isPeriodClosed,
  }) {
    final isNegative = payrollData.netSalary < 0;
    final totalDeduction = payrollData.insuranceDeduction +
        payrollData.pitDeduction +
        payrollData.otherDeductions;

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
                  '📊 TỔNG QUAN BẢNG LƯƠNG',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                // Chip trạng thái kỳ lương
                Chip(
                  label: Text(
                    isPeriodClosed ? 'Đã Chốt' : 'Đang Mở',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor:
                      isPeriodClosed ? Colors.grey : PayrollColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
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
                      _currencyFormat.format(payrollData.netSalary),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isNegative
                            ? Colors.red.shade700
                            : PayrollColors.success,
                      ),
                    ),
                  ],
                ),
                // Icon trạng thái
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isNegative ? Colors.red : PayrollColors.success)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isNegative ? Icons.trending_down : Icons.trending_up,
                    color: isNegative
                        ? Colors.red.shade700
                        : PayrollColors.success,
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
                    value: '${payrollData.totalWorkingDays} / 22',
                    color: PayrollColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryMetric(
                    icon: Icons.access_time,
                    label: 'Giờ OT',
                    value: '${payrollData.totalOTHours}h',
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
                    value: _currencyFormat.format(payrollData.adjustedGrossIncome),
                    color: PayrollColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryMetric(
                    icon: Icons.remove_circle,
                    label: 'Khấu trừ',
                    value: _currencyFormat.format(totalDeduction),
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
                  'Tính lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(payrollData.calculatedAt)}',
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

  /// Helper widget cho Summary Metric
  static Widget _buildSummaryMetric({
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

  /// 🔍 Widget hiển thị công thức tính toán
  static Widget buildFormulaText(String formula) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 4, bottom: 8),
      child: Text(
        formula,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  /// ⚠️ Widget cảnh báo nhỏ (cho lương gross thấp)
  static Widget buildMiniWarning(String message) {
    return Container(
      margin: const EdgeInsets.only(left: 24, bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎁 Container đặc biệt cho Bonus (highlighted)
  static Widget buildBonusContainer({
    required String label,
    required double amount,
    required NumberFormat currencyFormat,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: amount > 0
            ? PayrollColors.success.withOpacity(0.08)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: amount > 0
              ? PayrollColors.success.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: amount > 0 ? FontWeight.bold : FontWeight.normal,
              color: amount > 0 ? PayrollColors.success : Colors.grey[600],
            ),
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: amount > 0 ? FontWeight.bold : FontWeight.w500,
              color: amount > 0 ? PayrollColors.success : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dto/payroll_dtos.dart';

/// Reusable widgets for Payroll Management Module
/// 
/// Contains common widgets used across payroll screens:
/// - StatCard: Summary statistics with icon and gradient
/// - PeriodCard: Payroll period list item
/// - EmployeePayrollCard: Employee payroll summary card
/// - FilterChipGroup: Multi-select filter chips
/// - ExportButton: PDF/Email export button
/// - GradientCard: Card with gradient background
/// - SectionHeader: Section title with icon
/// - EmptyStateWidget: Empty state placeholder
/// - PayrollStatusChip: Status indicator chip

// ============================================================================
// STAT CARD
// ============================================================================

/// Statistics card with icon, title, value, and optional gradient
class PayrollStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;

  const PayrollStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
    this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: gradientColors != null
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors!,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: gradientColors != null
                          ? Colors.white.withOpacity(0.2)
                          : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: gradientColors != null ? Colors.white : color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: gradientColors != null
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: gradientColors != null
                      ? Colors.white.withOpacity(0.9)
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: gradientColors != null ? Colors.white : color,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11,
                    color: gradientColors != null
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PERIOD CARD
// ============================================================================

/// Payroll period card for dashboard list
class PayrollPeriodCard extends StatelessWidget {
  final PayrollPeriodResponse period;
  final VoidCallback onTap;
  final VoidCallback? onGeneratePayroll;
  final VoidCallback? onViewReport;
  final VoidCallback? onClose;

  const PayrollPeriodCard({
    super.key,
    required this.period,
    required this.onTap,
    this.onGeneratePayroll,
    this.onViewReport,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = period.isClosed ? const Color(0xFF34C759) : const Color(0xFFFF9500);
    final statusText = period.isClosed ? 'Đã đóng' : 'Đang xử lý';
    final statusIcon = period.isClosed ? Icons.check_circle : Icons.pending;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      period.periodName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PayrollStatusChip(
                    status: period.isClosed ? 'Closed' : 'Processing',
                    color: statusColor,
                    label: statusText,
                    icon: statusIcon,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(period.startDate)} - ${DateFormat('dd/MM/yyyy').format(period.endDate)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!period.isClosed && onGeneratePayroll != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onGeneratePayroll,
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Tạo lương'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0A84FF),
                        ),
                      ),
                    ),
                  if (!period.isClosed && onViewReport != null) ...[
                    if (onGeneratePayroll != null)
                      const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onViewReport,
                        icon: const Icon(Icons.bar_chart, size: 18),
                        label: const Text('Xem báo cáo'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0A84FF),
                        ),
                      ),
                    ),
                  ],
                  if (!period.isClosed && onClose != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onClose,
                      icon: const Icon(Icons.lock, size: 18),
                      label: const Text('Đóng kỳ'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF9500),
                      ),
                    ),
                  ],
                  if (period.isClosed && onViewReport != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onViewReport,
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Xem chi tiết'),
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
}

// ============================================================================
// EMPLOYEE PAYROLL CARD
// ============================================================================

/// Employee payroll summary card for report screen
class EmployeePayrollCard extends StatelessWidget {
  final String employeeId;
  final String employeeName;
  final String? employeeCode;
  final String? department;
  final String? position;
  final double netSalary;
  final double? grossSalary;
  final double? totalDeductions;
  final int? workingDays;
  final VoidCallback onTap;
  final bool showActions;
  final VoidCallback? onExportPdf;
  final VoidCallback? onSendEmail;

  const EmployeePayrollCard({
    super.key,
    required this.employeeId,
    required this.employeeName,
    this.employeeCode,
    this.department,
    this.position,
    required this.netSalary,
    this.grossSalary,
    this.totalDeductions,
    this.workingDays,
    required this.onTap,
    this.showActions = false,
    this.onExportPdf,
    this.onSendEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF0A84FF).withOpacity(0.1),
                    child: Text(
                      employeeName.isNotEmpty ? employeeName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Color(0xFF0A84FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employeeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (employeeCode != null)
                          Text(
                            'MSNV: $employeeCode',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                            .format(netSalary),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF34C759),
                        ),
                      ),
                      Text(
                        'Thực nhận',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (department != null || position != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (department != null) ...[
                      Icon(Icons.business, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        department!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                    if (department != null && position != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('•', style: TextStyle(color: Colors.grey[600])),
                      ),
                    if (position != null) ...[
                      Icon(Icons.work, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        position!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ],
              if (grossSalary != null || totalDeductions != null || workingDays != null) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    if (workingDays != null)
                      Expanded(
                        child: _buildInfoItem(
                          Icons.calendar_today,
                          'Ngày công',
                          '$workingDays ngày',
                        ),
                      ),
                    if (grossSalary != null)
                      Expanded(
                        child: _buildInfoItem(
                          Icons.monetization_on,
                          'Tổng thu nhập',
                          NumberFormat.compact(locale: 'vi_VN').format(grossSalary),
                        ),
                      ),
                    if (totalDeductions != null)
                      Expanded(
                        child: _buildInfoItem(
                          Icons.remove_circle_outline,
                          'Khấu trừ',
                          NumberFormat.compact(locale: 'vi_VN').format(totalDeductions),
                        ),
                      ),
                  ],
                ),
              ],
              if (showActions && (onExportPdf != null || onSendEmail != null)) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    if (onExportPdf != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onExportPdf,
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text('PDF'),
                        ),
                      ),
                    if (onExportPdf != null && onSendEmail != null)
                      const SizedBox(width: 8),
                    if (onSendEmail != null)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onSendEmail,
                          icon: const Icon(Icons.email, size: 18),
                          label: const Text('Email'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0A84FF),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// FILTER CHIP GROUP
// ============================================================================

/// Multi-select filter chip group
class PayrollFilterChipGroup extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selectedOption;
  final bool multiSelect;
  final Function(String) onSelected;
  final IconData? icon;

  const PayrollFilterChipGroup({
    super.key,
    required this.label,
    required this.options,
    this.selectedOption,
    this.multiSelect = false,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedOption == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                onSelected(option);
              },
              selectedColor: const Color(0xFF0A84FF).withOpacity(0.2),
              checkmarkColor: const Color(0xFF0A84FF),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ============================================================================
// EXPORT BUTTON
// ============================================================================

/// Export button with loading state
class PayrollExportButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String label;
  final IconData icon;
  final bool isPrimary;
  final Color? color;

  const PayrollExportButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    required this.label,
    this.icon = Icons.download,
    this.isPrimary = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color ?? const Color(0xFF0A84FF),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color ?? const Color(0xFF0A84FF),
                  ),
                ),
              )
            : Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color ?? const Color(0xFF0A84FF),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      );
    }
  }
}

// ============================================================================
// GRADIENT CARD
// ============================================================================

/// Card with gradient background
class PayrollGradientCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const PayrollGradientCard({
    super.key,
    required this.colors,
    required this.child,
    this.borderRadius,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius ?? 12),
          ),
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION HEADER
// ============================================================================

/// Section header with icon and optional action
class PayrollSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? subtitle;
  final Widget? action;
  final Color? color;

  const PayrollSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.action,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: color ?? const Color(0xFF0A84FF),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color ?? Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE WIDGET
// ============================================================================

/// Empty state placeholder
class PayrollEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PayrollEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 20),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STATUS CHIP
// ============================================================================

/// Status indicator chip
class PayrollStatusChip extends StatelessWidget {
  final String status;
  final Color color;
  final String label;
  final IconData? icon;

  const PayrollStatusChip({
    super.key,
    required this.status,
    required this.color,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INFO ROW
// ============================================================================

/// Information row with label and value
class PayrollInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final FontWeight? valueFontWeight;

  const PayrollInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.valueFontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: valueFontWeight ?? FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// LOADING SHIMMER
// ============================================================================

/// Shimmer loading effect for cards
class PayrollShimmerCard extends StatelessWidget {
  final double height;
  final double? width;

  const PayrollShimmerCard({
    super.key,
    this.height = 100,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey[300]!,
              Colors.grey[100]!,
              Colors.grey[300]!,
            ],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

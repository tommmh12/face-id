import 'package:flutter/material.dart';
import '../../core/theme.dart';

class StatusBadge extends StatelessWidget {
  final bool isActive;
  final String? activeText;
  final String? inactiveText;

  const StatusBadge({
    super.key,
    required this.isActive,
    this.activeText,
    this.inactiveText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive 
            ? AppTheme.successGreen.withOpacity(0.1)
            : AppTheme.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppTheme.successGreen : AppTheme.errorRed,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: isActive ? AppTheme.successGreen : AppTheme.errorRed,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? (activeText ?? 'Hoạt động') : (inactiveText ?? 'Ngưng'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? AppTheme.successGreen : AppTheme.errorRed,
            ),
          ),
        ],
      ),
    );
  }
}

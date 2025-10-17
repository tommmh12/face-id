import 'package:flutter/material.dart';

class AttendanceResult {
  const AttendanceResult({
    required this.actionLabel,
    required this.success,
    required this.status,
    required this.message,
    this.employeeName,
    this.confidence,
  });

  final String actionLabel;
  final bool success;
  final String status;
  final String message;
  final String? employeeName;
  final double? confidence;
}

class ResultCard extends StatelessWidget {
  const ResultCard({super.key, required this.result});

  final AttendanceResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final successColor = colors.primary;
    final failureColor = colors.error;
    final tone = result.success ? successColor : failureColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.withOpacity(0.4), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                result.success ? Icons.verified : Icons.warning_amber_rounded,
                color: tone,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${result.actionLabel} • ${result.status.isEmpty ? 'Status Unknown' : result.status}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onBackground,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (result.employeeName != null && result.employeeName!.isNotEmpty)
            Text(
              '👤 ${result.employeeName}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onBackground,
              ),
            ),
          if (result.confidence != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '🎯 Confidence: ${result.confidence!.toStringAsFixed(2)}%',
                style: theme.textTheme.bodyMedium?.copyWith(color: colors.onBackground.withOpacity(0.9)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '🕒 Status: ${result.message}',
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onBackground.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

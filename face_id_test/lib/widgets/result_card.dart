import 'package:flutter/material.dart';

class AttendanceResult {
  const AttendanceResult({
    required this.actionLabel,
    required this.success,
    required this.status,
    required this.message,
    this.employeeName,
    this.confidence,
    this.timestamp,
  });

  final String actionLabel;
  final bool success;
  final String status;
  final String message;
  final String? employeeName;
  final double? confidence;
  final DateTime? timestamp;
}

class ResultCard extends StatelessWidget {
  const ResultCard({super.key, required this.result});

  final AttendanceResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final successColor = Colors.green.shade600;
    final failureColor = Colors.red.shade600;
    final tone = result.success ? successColor : failureColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone.withOpacity(0.1),
            tone.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tone.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: tone.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tone.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tone.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    result.success 
                        ? Icons.check_circle_outline 
                        : Icons.error_outline,
                    color: tone,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.actionLabel,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tone,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.success ? 'Success' : 'Failed',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tone.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (result.timestamp != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.outline.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${result.timestamp!.hour.toString().padLeft(2, '0')}:${result.timestamp!.minute.toString().padLeft(2, '0')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.employeeName != null && result.employeeName!.isNotEmpty) ...[
                  _InfoRow(
                    icon: Icons.person,
                    label: 'Employee',
                    value: result.employeeName!,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (result.confidence != null) ...[
                  _InfoRow(
                    icon: Icons.analytics,
                    label: 'Confidence',
                    value: '${result.confidence!.toStringAsFixed(1)}%',
                    color: _getConfidenceColor(result.confidence!),
                  ),
                  const SizedBox(height: 16),
                ],
                
                _InfoRow(
                  icon: Icons.info,
                  label: 'Message',
                  value: result.message,
                  color: colors.onSurface.withOpacity(0.7),
                ),
                
                if (result.timestamp != null) ...[
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.schedule,
                    label: 'Time',
                    value: '${result.timestamp!.day}/${result.timestamp!.month}/${result.timestamp!.year} ${result.timestamp!.hour.toString().padLeft(2, '0')}:${result.timestamp!.minute.toString().padLeft(2, '0')}:${result.timestamp!.second.toString().padLeft(2, '0')}',
                    color: colors.onSurface.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 90) return Colors.green;
    if (confidence >= 80) return Colors.orange;
    return Colors.red;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

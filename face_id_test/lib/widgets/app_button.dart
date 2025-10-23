import 'package:flutter/material.dart';

enum AttendanceAction { checkIn, checkOut }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.type,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;
  final AttendanceAction? type;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    
    // Determine colors based on button type
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;
    
    if (!enabled) {
      backgroundColor = colorScheme.surfaceContainerHighest.withOpacity(0.3);
      foregroundColor = colorScheme.onSurfaceVariant.withOpacity(0.6);
      borderColor = colorScheme.outline.withOpacity(0.2);
    } else if (type == AttendanceAction.checkIn) {
      backgroundColor = Colors.green.withOpacity(0.1);
      foregroundColor = Colors.green.shade700;
      borderColor = Colors.green.withOpacity(0.3);
    } else if (type == AttendanceAction.checkOut) {
      backgroundColor = Colors.orange.withOpacity(0.1);
      foregroundColor = Colors.orange.shade700;
      borderColor = Colors.orange.withOpacity(0.3);
    } else {
      backgroundColor = colorScheme.primary.withOpacity(0.1);
      foregroundColor = colorScheme.primary;
      borderColor = colorScheme.primary.withOpacity(0.3);
    }

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: enabled ? [
          BoxShadow(
            color: foregroundColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: foregroundColor,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: foregroundColor.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

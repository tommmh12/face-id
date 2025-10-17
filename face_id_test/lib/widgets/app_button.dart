import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = enabled ? colorScheme.primary : colorScheme.surfaceVariant.withOpacity(0.3);
    final foreground = enabled ? colorScheme.onPrimary : colorScheme.onSurfaceVariant.withOpacity(0.6);

    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
      ),
      icon: Icon(icon, size: 24),
      label: Text(label),
    );
  }
}

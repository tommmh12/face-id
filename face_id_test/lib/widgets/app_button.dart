import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.gradient,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    // Determine which gradient to use based on label
    List<Color> buttonGradient;
    if (label.contains('Check In')) {
      buttonGradient = AppColors.gradientSoftGreen;
    } else if (label.contains('Check Out')) {
      buttonGradient = AppColors.gradientSoftOrange;
    } else {
      buttonGradient = gradient ?? AppColors.gradientSoftBlue;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: enabled
            ? LinearGradient(
                colors: buttonGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: enabled ? null : AppColors.bgColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: buttonGradient[0].withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.xl,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: enabled ? Colors.white : AppColors.textDisabled,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: enabled ? Colors.white : AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

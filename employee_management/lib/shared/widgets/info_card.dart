import 'package:flutter/material.dart';
import '../../core/theme.dart';

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (backgroundColor ?? iconColor ?? AppTheme.primaryBlue)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor ?? AppTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.darkGray,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

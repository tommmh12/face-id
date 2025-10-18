import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const primaryBlue = Color(0xFF2196F3);
  static const primaryDark = Color(0xFF1976D2);
  static const primaryLight = Color(0xFF64B5F6);
  
  // Secondary
  static const secondaryGreen = Color(0xFF4CAF50);
  static const secondaryGreenDark = Color(0xFF388E3C);
  static const secondaryOrange = Color(0xFFFF9800);
  static const secondaryOrangeDark = Color(0xFFF57C00);
  static const secondaryPurple = Color(0xFF9C27B0);
  static const secondaryPurpleDark = Color(0xFF7B1FA2);
  
  // Status
  static const successColor = Color(0xFF4CAF50);
  static const errorColor = Color(0xFFF44336);
  static const warningColor = Color(0xFFFF9800);
  static const infoColor = Color(0xFF2196F3);
  
  // Neutrals
  static const bgColor = Color(0xFFF8F9FA);
  static const cardColor = Colors.white;
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const dividerColor = Color(0xFFE0E0E0);
  static const borderColor = Color(0xFFEEEEEE);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

class AppTextStyles {
  // Headings
  static const h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  // Body
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  // Button
  static const buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  // Caption
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
}

class AppBorderRadius {
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double extraLarge = 20.0;
}

class AppShadows {
  static List<BoxShadow> get small => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get large => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}

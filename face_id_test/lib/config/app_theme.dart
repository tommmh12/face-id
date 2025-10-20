import 'package:flutter/material.dart';

class AppColors {
  // Modern Primary Colors - Professional Blue
  static const primaryBlue = Color(0xFF1E88E5);
  static const primaryDark = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF42A5F5);
  static const primaryLighter = Color(0xFFE3F2FD);

  // Secondary Colors - Fresh & Modern
  static const secondaryGreen = Color(0xFF43A047);
  static const secondaryGreenDark = Color(0xFF2E7D32);
  static const secondaryGreenLight = Color(0xFFE8F5E9);

  static const secondaryOrange = Color(0xFFFF6F00);
  static const secondaryOrangeDark = Color(0xFFE65100);
  static const secondaryOrangeLight = Color(0xFFFFF3E0);

  static const secondaryPurple = Color(0xFF8E24AA);
  static const secondaryPurpleDark = Color(0xFF6A1B9A);
  static const secondaryPurpleLight = Color(0xFFF3E5F5);

  static const secondaryTeal = Color(0xFF00897B);
  static const secondaryTealLight = Color(0xFFE0F2F1);

  // Status Colors
  static const successColor = Color(0xFF43A047);
  static const successLight = Color(0xFFE8F5E9);
  static const errorColor = Color(0xFFE53935);
  static const errorLight = Color(0xFFFFEBEE);
  static const warningColor = Color(0xFFFB8C00);
  static const warningLight = Color(0xFFFFF3E0);
  static const infoColor = Color(0xFF1E88E5);
  static const infoLight = Color(0xFFE3F2FD);

  // Neutrals - Modern & Clean
  static const bgColor = Color(0xFFF5F7FA);
  static const bgSecondary = Color(0xFFFFFFFF);
  static const cardColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFFAFBFC);

  // Text Colors
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);
  static const textTertiary = Color(0xFF999999);
  static const textDisabled = Color(0xFFBDBDBD);

  // Border & Divider
  static const dividerColor = Color(0xFFE5E7EB);
  static const borderColor = Color(0xFFE0E0E0);
  static const borderLight = Color(0xFFF0F0F0);

  // Vibrant Gradients - Modern & Eye-catching
  static const gradientBlue = [Color(0xFF667eea), Color(0xFF764ba2)];
  static const gradientPurple = [Color(0xFFa8edea), Color(0xFFfed6e3)];
  static const gradientOrange = [Color(0xFFff9a56), Color(0xFFff6a88)];
  static const gradientGreen = [Color(0xFF0ba360), Color(0xFF3cba92)];
  static const gradientPink = [Color(0xFFf093fb), Color(0xFFf5576c)];
  static const gradientSunset = [Color(0xFFfa709a), Color(0xFFfee140)];
  static const gradientOcean = [Color(0xFF00d2ff), Color(0xFF3a7bd5)];
  static const gradientFirework = [Color(0xFFff6b6b), Color(0xFFfeca57)];
  static const gradientNorthern = [Color(0xFF00f260), Color(0xFF0575e6)];
  static const gradientTwilight = [
    Color(0xFF7303c0),
    Color(0xFFec38bc),
    Color(0xFFfdeff9),
  ];

  // Soft Gradients - Gentle & Professional
  static const gradientSoftBlue = [Color(0xFF5B8FD8), Color(0xFF7AA8E5)];
  static const gradientSoftGreen = [Color(0xFF52B558), Color(0xFF6FCC75)];
  static const gradientSoftOrange = [Color(0xFFFF8A5B), Color(0xFFFF9D73)];
  static const gradientSoftPurple = [Color(0xFF8B68CD), Color(0xFFA88DD9)];
  static const gradientSoftTeal = [Color(0xFF3FA89D), Color(0xFF5EBDB3)];
  static const gradientSoftPink = [Color(0xFFE37B9E), Color(0xFFF095B3)];
  static const gradientSoftCyan = [Color(0xFF3EC4D8), Color(0xFF5DD4E8)];
  static const gradientSoftLavender = [Color(0xFFA88DD9), Color(0xFFC3B1E1)];

  // Overlay & Shadow
  static const overlayDark = Color(0x80000000);
  static const overlayLight = Color(0x33000000);
}

class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  static const double massive = 48.0;
}

class AppTextStyles {
  // Headings - Modern Typography
  static const h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const h5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const h6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Body Text
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Button Text
  static const buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const buttonMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  // Label & Caption
  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  static const captionBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  // Overline
  static const overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    letterSpacing: 1.0,
    height: 1.3,
  );
}

class AppBorderRadius {
  static const double xs = 4.0;
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double rounded = 100.0; // For circular buttons
}

class AppShadows {
  static List<BoxShadow> get subtle => [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get small => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get large => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get xl => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Colored shadows for specific use cases
  static List<BoxShadow> primaryShadow({double opacity = 0.2}) => [
    BoxShadow(
      color: AppColors.primaryBlue.withOpacity(opacity),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> successShadow({double opacity = 0.2}) => [
    BoxShadow(
      color: AppColors.successColor.withOpacity(opacity),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> errorShadow({double opacity = 0.2}) => [
    BoxShadow(
      color: AppColors.errorColor.withOpacity(opacity),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

// Animation Durations
class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 350);
  static const verySlow = Duration(milliseconds: 500);
}

// Animation Curves
class AppCurves {
  static const easeIn = Curves.easeIn;
  static const easeOut = Curves.easeOut;
  static const easeInOut = Curves.easeInOut;
  static const smooth = Curves.easeInOutCubic;
  static const bounce = Curves.bounceOut;
}

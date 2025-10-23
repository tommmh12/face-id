import 'package:flutter/material.dart';

import 'screens/home_screen_new.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FaceRecognitionApp());
}

class FaceRecognitionApp extends StatelessWidget {
  const FaceRecognitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Professional corporate color scheme
    const primaryColor = Color(0xFF1565C0); // Corporate Blue
    const secondaryColor = Color(0xFF0D47A1); // Deep Blue
    const surfaceColor = Color(0xFFF8F9FA); // Light Gray
    const cardColor = Color(0xFFFFFFFF); // Pure White
    
    final colorScheme = ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      onSurface: const Color(0xFF212529), // Dark Gray Text
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      background: surfaceColor,
      onBackground: const Color(0xFF212529),
      error: const Color(0xFFD32F2F), // Professional Red
      onError: Colors.white,
    );

    return MaterialApp(
      title: 'Hệ thống Chấm công Nhận diện Khuôn mặt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: surfaceColor,
        cardColor: cardColor,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
          shadowColor: Colors.black26,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            elevation: 3,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: cardColor,
          elevation: 3,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Color(0xFF212529),
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: Color(0xFF212529),
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF495057),
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF6C757D),
            fontSize: 14,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

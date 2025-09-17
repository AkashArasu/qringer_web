import 'package:flutter/material.dart';

/// Centralized app theme settings and gradients
class AppTheme {
  // Primary green background gradient used across screens
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0B2E0B),
      Color(0xFF1A3A1A),
      Color(0xFF2D5A2D),
    ],
  );

  // Title text gradient
  static const LinearGradient titleGradient = LinearGradient(
    colors: [
      Colors.green,
      Colors.lightGreen,
      Colors.teal,
    ],
  );

  // Accent button gradient (e.g., primary CTAs)
  static LinearGradient accentGradient({double alpha = 0.8}) => LinearGradient(
        colors: [
          Colors.cyan.withValues(alpha: alpha),
          Colors.blue.withValues(alpha: alpha),
        ],
      );

  // Theme data for the app with custom colors matching the gradient theme
  static ThemeData get theme {
    return ThemeData(
      primarySwatch: Colors.green,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2D5A2D),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0B2E0B),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF2D5A2D),
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D5A2D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white),
        displayMedium: TextStyle(color: Colors.white),
        displaySmall: TextStyle(color: Colors.white),
        headlineLarge: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: Colors.white),
        labelSmall: TextStyle(color: Colors.white),
      ),
    );
  }
}
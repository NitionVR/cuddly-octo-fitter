import 'package:flutter/material.dart';

class AppColors {
  // Base Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color cardDark = Color(0xFF2A2A2A);
  static const Color accentGreen = Color(0xFF4CAF50);

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB3B3B3);

  // Accent Colors
  static const Color successGreen = Color(0xFF43A047);
  static const Color errorRed = Color(0xFFE53935);
  static const Color warningOrange = Color(0xFFFFA726);

  static const progressBackground = Color(0xFF424242);
  static const progressBar = accentGreen;
}


class AppTheme{

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.darkBackground,
    primaryColor: AppColors.accentGreen,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentGreen,
      secondary: AppColors.accentGreen,
      surface: AppColors.cardDark,
    ),

    // Card Theme
    cardTheme: CardTheme(
      color: AppColors.cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),

    // Text Theme
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color:AppColors.textPrimary,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
    ),

    bottomAppBarTheme: const BottomAppBarTheme(
      color: AppColors.cardDark,
      elevation: 8,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.progressBar,
      linearTrackColor: AppColors.progressBackground,
    ),

    // Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentGreen,
      foregroundColor: Colors.white,
      elevation: 6,
    ),


    iconTheme: const IconThemeData(
      color: AppColors.textSecondary,
    ),

  );
}
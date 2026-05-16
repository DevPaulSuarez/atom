import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6C63FF);
  static const primarySoft = Color(0xFFEDECFF);
  static const breakColor = Color(0xFFFF8C6B);
  static const breakSoft = Color(0xFFFFEDE8);
  static const success = Color(0xFF34C759);
  static const successSoft = Color(0xFFE8F9EE);
  static const longBreakColor = Color(0xFF3B82F6);
  static const longBreakSoft = Color(0xFFEBF2FF);

  // Light
  static const bgLight = Color(0xFFE4E4ED);
  static const cardLight = Color(0xFFF2F2F8);
  static const textPrimaryLight = Color(0xFF1C1C2E);
  static const textSecondaryLight = Color(0xFF9B9BB5);
  static const borderLight = Color(0xFFD4D4E0);
  static const trackLight = Color(0xFFD8D8E6);

  // Dark
  static const bgDark = Color(0xFF0F0F1A);
  static const cardDark = Color(0xFF1E1E30);
  static const textPrimaryDark = Color(0xFFF0F0FA);
  static const textSecondaryDark = Color(0xFF6A6A85);
  static const borderDark = Color(0xFF2A2A40);
  static const trackDark = Color(0xFF2A2A40);
}

class AppTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bgLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardLight,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.borderLight),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgLight,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardDark,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.borderDark),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bgDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
        ),
      );
}

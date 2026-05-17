import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF7B6FFF);
  static const primarySoft = Color(0xFF2A2850);
  static const primaryGlow = Color(0x337B6FFF);

  static const breakColor = Color(0xFFFF8C6B);
  static const breakSoft = Color(0xFF3A2218);
  static const breakGlow = Color(0x33FF8C6B);

  static const success = Color(0xFF34C759);
  static const successSoft = Color(0xFF1A3A25);

  static const longBreakColor = Color(0xFF4F9EF8);
  static const longBreakSoft = Color(0xFF162038);
  static const longBreakGlow = Color(0x334F9EF8);

  static const warning = Color(0xFFFFB340);

  // Light
  static const bgLight = Color(0xFFEAEAF4);
  static const cardLight = Color(0xFFF5F5FC);
  static const card2Light = Color(0xFFFFFFFF);
  static const textPrimaryLight = Color(0xFF12122A);
  static const textSecondaryLight = Color(0xFF8888AA);
  static const borderLight = Color(0xFFD8D8EC);
  static const trackLight = Color(0xFFD0D0E8);

  // Dark
  static const bgDark = Color(0xFF0C0C18);
  static const cardDark = Color(0xFF181828);
  static const card2Dark = Color(0xFF1F1F35);
  static const textPrimaryDark = Color(0xFFF0F0FA);
  static const textSecondaryDark = Color(0xFF5A5A7A);
  static const borderDark = Color(0xFF252540);
  static const trackDark = Color(0xFF222238);

  static Color card(bool isDark) => isDark ? cardDark : cardLight;
  static Color card2(bool isDark) => isDark ? card2Dark : card2Light;
  static Color bg(bool isDark) => isDark ? bgDark : bgLight;
  static Color textPrimary(bool isDark) =>
      isDark ? textPrimaryDark : textPrimaryLight;
  static Color textSecondary(bool isDark) =>
      isDark ? textSecondaryDark : textSecondaryLight;
  static Color border(bool isDark) => isDark ? borderDark : borderLight;
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
            letterSpacing: -0.4,
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
            letterSpacing: -0.4,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
        ),
      );
}

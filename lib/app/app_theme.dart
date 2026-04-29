import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const navy = Color(0xFF123047);
  static const teal = Color(0xFF2B8C82);
  static const sky = Color(0xFFE7F2F4);
  static const peach = Color(0xFFFFF5EB);
  static const sand = Color(0xFFF5F0E8);
  static const ink = Color(0xFF1C2631);
  static const muted = Color(0xFF728196);
  static const success = Color(0xFF2F9E67);
  static const warning = Color(0xFFDF8A2E);
  static const danger = Color(0xFFD85B61);
}

ThemeData buildAppTheme() {
  final baseTextTheme = GoogleFonts.manropeTextTheme();

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF7F8FA),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      primary: AppColors.teal,
      secondary: AppColors.navy,
      surface: Colors.white,
      error: AppColors.danger,
      brightness: Brightness.light,
    ),
    textTheme: baseTextTheme.copyWith(
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: AppColors.ink,
        height: 1.45,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: AppColors.muted,
        height: 1.45,
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE6EAEE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.teal, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.sky,
      labelStyle: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
  );
}

import 'package:flutter/material.dart';

/// Centralised colors, fonts and shared styling for the AdiVaani app.
class AppColors {
  // ============================================================
  // MAIN APP COLORS
  // ============================================================

  static const background = Color(0xFFF4EFE3);
  static const green = Color(0xFF1B5E3C);
  static const greenDark = Color(0xFF14432C);

  // ============================================================
  // TEXT COLORS
  // ============================================================

  static const textDark = Color(0xFF1F1F1F);
  static const textMuted = Color(0xFF6B6B6B);

  // Text/accent used on dark green backgrounds
  static const accentOnDark = Color(0xFFFFD39A);

  // Divider color
  static const divider = Color(0xFFE0E0E0);

  // ============================================================
  // FEATURE CARD COLORS
  // ============================================================

  static const cardMint = Color(0xFFD9EBDD);
  static const cardPeach = Color(0xFFF7DCD2);
  static const cardSand = Color(0xFFF3E1B8);
  static const cardLilac = Color(0xFFE1DCF2);

  // ============================================================
  // FEATURE ICON COLORS
  // ============================================================

  static const iconMintText = Color(0xFF2E7D4F);
  static const iconPeachText = Color(0xFFB5502E);
  static const iconSandText = Color(0xFF8A6A1E);
  static const iconLilacText = Color(0xFF4B3F8A);
}


/// Main application theme.
class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,

      scaffoldBackgroundColor: AppColors.background,

      fontFamily: 'Roboto',

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.green,
        surface: AppColors.background,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
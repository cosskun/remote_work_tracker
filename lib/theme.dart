import 'package:flutter/material.dart';

class AppColors {
  // Pastel Core Palette
  static const Color background = Color(0xFFF4F7FC); // Soft Slate Light Grey/Blue
  static const Color primary = Color(0xFF7C92FF);    // Soft Lavender Blue
  static const Color primaryLight = Color(0xFFEBEFFF); // Soft blue bubble
  static const Color accent = Color(0xFFFFB4B4);     // Soft Peach/Rose
  static const Color accentLight = Color(0xFFFFF0F0); // Soft Rose bubble
  static const Color success = Color(0xFFB5EAD7);    // Soft Mint Green
  static const Color successLight = Color(0xFFEAF9F3); // Soft Mint bubble
  static const Color successText = Color(0xFF2E8B57); // Green text color
  static const Color warning = Color(0xFFFFDAC1);    // Soft Apricot Yellow
  
  // Neutral Colors
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D3748);  // Slate Black
  static const Color textSecondary = Color(0xFF718096); // Cool Grey
  static const Color textLight = Color(0xFFA0AEC0);     // Light Grey
  static const Color border = Color(0xFFE2E8F0);        // Light Border Grey
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        background: AppColors.background,
        surface: AppColors.cardBg,
        onPrimary: Colors.white,
        onSecondary: AppColors.textPrimary,
      ),
      fontFamily: 'Roboto', // Default standard font
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Soft glassmorphism/card decoration helper
  static BoxDecoration cardDecoration({
    Color color = AppColors.cardBg,
    double borderRadius = 20,
    bool hasShadow = true,
    bool hasBorder = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      border: hasBorder ? Border.all(color: AppColors.border, width: 1) : null,
      boxShadow: hasShadow
          ? [
              BoxShadow(
                color: AppColors.textPrimary.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ]
          : null,
    );
  }
}

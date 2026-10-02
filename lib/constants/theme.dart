import 'package:flutter/material.dart';

class AgriColors {
  // Brand Green (Agrocom)
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF2E7D32);
  static const Color primaryAccent = Color(0xFF4CAF50);
  static const Color primarySubtle = Color(0xFFE8F5E9);
  
  // Chili Red Accent
  static const Color chiliRed = Color(0xFFD32F2F);
  static const Color chiliRedLight = Color(0xFFFFEBEE);

  // Status Colors
  static const Color warning = Color(0xFFFFA000);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color danger = Color(0xFFE53935);
  static const Color dangerLight = Color(0xFFFFEBEE);
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);

  // Neutral Colors
  static const Color bg = Color(0xFFF7FAF7);
  static const Color card = Colors.white;
  static const Color textDark = Color(0xFF1C281F);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
}

class AgriTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AgriColors.primary,
        primary: AgriColors.primary,
        secondary: AgriColors.chiliRed,
        surface: AgriColors.bg,
      ),
      scaffoldBackgroundColor: AgriColors.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AgriColors.textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AgriColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AgriColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AgriColors.card,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AgriColors.border, width: 0.8),
        ),
      ),
    );
  }
}

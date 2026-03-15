import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color darkBg = Color(0xFF050A18);
  static const Color darkSurface = Color(0xFF0C1223);
  static const Color darkPrimary = Color(0xFF3B82F6);
  static const Color darkSecondary = Color(0xFF8B5CF6);
  static const Color darkAccent = Color(0xFF10B981);
  static const Color darkText = Color(0xFFE2E8F0);
  static const Color darkTextDim = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0x14FFFFFF);
  static const Color darkCardBg = Color(0x08FFFFFF);

  static const Color lightBg = Color(0xFFFAF0E6);
  static const Color lightSurface = Color(0xFFFFFAF0);
  static const Color lightPrimary = Color(0xFF2563EB);
  static const Color lightSecondary = Color(0xFF7C3AED);
  static const Color lightAccent = Color(0xFF059669);
  static const Color lightText = Color(0xFF334155);
  static const Color lightTextDim = Color(0xFF64748B);
  static const Color lightBorder = Color(0x14000000);
  static const Color lightCardBg = Color(0x08000000);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: darkPrimary,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        tertiary: darkAccent,
        surface: darkSurface,
        onSurface: darkText,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: lightPrimary,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        tertiary: lightAccent,
        surface: lightSurface,
        onSurface: lightText,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }
}

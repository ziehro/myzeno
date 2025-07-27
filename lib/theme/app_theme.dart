import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Define our calm colors
  static const Color primaryColor = Color(0xFF3B8E7E); // A soft teal/green
  static const Color accentColor = Color(0xFFF4A261);  // A warm, motivating coral/orange
  static const Color backgroundColor = Color(0xFFF7F9F9);
  static const Color textColor = Color(0xFF2D3A3A);

  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: accentColor,
      primary: primaryColor,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.manrope(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: textColor),
    ),
    textTheme: TextTheme(
      headlineSmall: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: textColor),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: textColor.withOpacity(0.8)),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: textColor.withOpacity(0.7)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    ),
  );
}
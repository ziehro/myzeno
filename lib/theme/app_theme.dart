import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- COLOR PALETTE ---
  static const Color primaryColor = Color(0xFF3B8E7E); // Teal Green
  static const Color accentColor = Color(0xFFF4A261);  // Warm Orange

  // Light Theme Colors
  static const Color lightBackgroundColor = Color(0xFFF7F9F9);
  static const Color lightSurfaceColor = Colors.white;
  static const Color lightTextColor = Color(0xFF1A2025);

  // Dark Theme Colors
  static const Color darkBackgroundColor = Color(0xFF1A2025); // Deep Slate Gray
  static const Color darkSurfaceColor = Color(0xFF2D3A3A);
  static const Color darkTextColor = Color(0xFFF0F2F2);


  // --- THEMES ---

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackgroundColor,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      background: lightBackgroundColor,
      surface: lightSurfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onBackground: lightTextColor,
      onSurface: lightTextColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.manrope(
        color: lightTextColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: lightTextColor),
    ),
    // --- FIX IS HERE: Use CardTheme, not CardThemeData ---
    cardTheme: CardThemeData(
      elevation: 2,
      color: lightSurfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(bodyColor: lightTextColor),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackgroundColor,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      background: darkBackgroundColor,
      surface: darkSurfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onBackground: darkTextColor,
      onSurface: darkTextColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.manrope(
        color: darkTextColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: darkTextColor),
    ),
    // --- FIX IS HERE: Use CardTheme, not CardThemeData ---
    cardTheme: CardThemeData(
      elevation: 4,
      color: darkSurfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(bodyColor: darkTextColor),
  );
}
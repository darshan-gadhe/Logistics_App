// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    const Color darkBackgroundColor = Color(0xFF121212);
    const Color darkSurfaceColor = Color(0xFF1E1E1E);   // A slightly lighter grey for surfaces
    const Color darkAccentColor = Color(0xFF03DAC6);
    const Color primaryTextColor = Color(0xFFEAEAEA);
    const Color secondaryTextColor = Color(0xFFB0B0B0);

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: darkAccentColor,
      scaffoldBackgroundColor: darkBackgroundColor,

      colorScheme: const ColorScheme.dark(
        primary: darkAccentColor,
        secondary: darkAccentColor,
        background: darkBackgroundColor,
        surface: darkSurfaceColor,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onBackground: primaryTextColor,
        onSurface: primaryTextColor,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurfaceColor,
        elevation: 1,
        titleTextStyle: TextStyle(
          color: primaryTextColor,
          fontSize: 21,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: darkSurfaceColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      // --- THIS IS THE FIX ---
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        // 1. Set a different background color from the main scaffold
        backgroundColor: darkSurfaceColor,

        // 2. Add elevation to give it a shadow and "lift" it off the page
        elevation: 10.0,

        // These properties were already correct but are kept for completeness
        selectedItemColor: darkAccentColor,
        unselectedItemColor: secondaryTextColor,
        type: BottomNavigationBarType.fixed,
      ),
      // --- END OF FIX ---

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAccentColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      textTheme: const TextTheme(
        headlineSmall: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold, fontSize: 22),
        titleLarge: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: primaryTextColor, fontSize: 16),
        bodyMedium: TextStyle(color: secondaryTextColor, fontSize: 14),
      ),
    );
  }

  // Your light theme can remain here if you have one
  static ThemeData get lightTheme {
    return ThemeData(); // Placeholder
  }
}
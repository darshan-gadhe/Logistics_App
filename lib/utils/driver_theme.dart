// lib/utils/driver_theme.dart
import 'package:flutter/material.dart';

class DriverAppTheme {
  // --- DEFINE THE DRIVER'S BRAND COLORS ---

  // Light Theme Colors
  static const Color lightPrimaryColor = Color(0xFF005A9C); // A strong, Royal Blue
  static const Color lightAccentColor = Color(0xFFF26419);   // A vibrant, action-oriented Orange
  static const Color lightBackgroundColor = Color(0xFFF8F9FA);
  static const Color lightCardColor = Colors.white;

  // Dark Theme Colors
  static const Color darkPrimaryColor = Color(0xFF4FC3F7);    // A brighter Sky Blue for contrast
  static const Color darkAccentColor = Color(0xFFF26419);     // The same vibrant Orange
  static const Color darkBackgroundColor = Color(0xFF263238);  // Professional Dark Slate Grey
  static const Color darkCardColor = Color(0xFF37474F);        // A slightly lighter shade for cards

  /// Returns a complete, distinct theme for the Driver's UI in LIGHT mode.
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: lightPrimaryColor,
      scaffoldBackgroundColor: lightBackgroundColor,
      cardColor: lightCardColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lightPrimaryColor,
        primary: lightPrimaryColor,
        secondary: lightAccentColor,
        brightness: Brightness.light,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: lightPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: lightPrimaryColor,
        unselectedItemColor: Colors.grey,
        elevation: 10,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lightAccentColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Returns a complete, distinct theme for the Driver's UI in DARK mode.
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: darkPrimaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      cardColor: darkCardColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimaryColor,
        primary: darkPrimaryColor,
        secondary: darkAccentColor,
        brightness: Brightness.dark,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkCardColor,
        foregroundColor: Colors.white,
        elevation: 1,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCardColor,
        selectedItemColor: darkPrimaryColor,
        unselectedItemColor: Colors.white70,
        elevation: 10,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryColor,
          foregroundColor: darkBackgroundColor, // Dark text on light blue button
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkAccentColor,
        foregroundColor: Colors.white,
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: darkPrimaryColor,
            side: const BorderSide(color: darkPrimaryColor),
          )
      ),
    );
  }
}
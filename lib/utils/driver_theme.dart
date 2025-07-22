// lib/utils/driver_theme.dart
import 'package:flutter/material.dart';

class DriverAppTheme {
  // --- DEFINE THE DRIVER'S CUSTOM COLORS ---
  static const Color driverBackgroundColor = Color(0xFF263238); // A professional, dark slate grey
  static const Color driverCardColor = Color(0xFF37474F);      // A slightly lighter shade for cards
  static const Color driverAccentColor = Color(0xFF19CAF2);      // A vibrant, action-oriented orange for key buttons

  /// This function takes the app's default dark theme and applies specific overrides
  /// to create a unique look and feel for the driver's UI.
  static ThemeData getThemeOverride(BuildContext context) {
    // Start with the base dark theme so we inherit most of its properties
    final baseTheme = Theme.of(context);

    // Use .copyWith() to change only the properties we care about
    return baseTheme.copyWith(

      // --- BACKGROUND AND SURFACE COLOR OVERRIDE ---
      scaffoldBackgroundColor: driverBackgroundColor,

      cardTheme: baseTheme.cardTheme.copyWith(
        color: driverCardColor, // Change card background color
        elevation: 1,
      ),

      // --- BOTTOM NAVIGATION BAR OVERRIDE ---
      bottomNavigationBarTheme: baseTheme.bottomNavigationBarTheme.copyWith(
        backgroundColor: driverCardColor, // Match the card color for a cohesive look
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
      ),

      // --- BUTTONS AND ACCENTS OVERRIDE ---
      colorScheme: baseTheme.colorScheme.copyWith(
        // This makes sure buttons and other accents use our new colors
        primary: driverAccentColor,      // Primary actions now use orange
        secondary: driverAccentColor,    // Secondary actions also use orange
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: driverAccentColor, // Default buttons are now orange
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      floatingActionButtonTheme: baseTheme.floatingActionButtonTheme.copyWith(
        backgroundColor: driverAccentColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
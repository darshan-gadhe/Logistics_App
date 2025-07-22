// lib/services/theme_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService with ChangeNotifier {
  static const _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark theme

  ThemeMode get themeMode => _themeMode;

  ThemeService() {
    _loadTheme();
  }

  // Load the saved theme preference from the device
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system; // or default to dark
    }
    notifyListeners();
  }

  // Set and save the new theme preference
  Future<void> setAndSaveTheme(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners(); // Notify listeners to rebuild the UI

    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) {
      prefs.setString(_themeKey, 'light');
    } else if (mode == ThemeMode.dark) {
      prefs.setString(_themeKey, 'dark');
    } else {
      prefs.setString(_themeKey, 'system');
    }
  }
}
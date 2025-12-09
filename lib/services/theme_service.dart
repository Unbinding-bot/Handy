// lib/services/theme_service.dartimport 'package:flutter/material.dart';

class ThemeService extends ChangeNotifier {
  // --- Available Colors ---
  static const List<Color> colorOptions = [
    Colors.deepPurple,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.orange,
    Colors.green,
  ];

  // --- Theme State ---
  ThemeMode _themeMode = ThemeMode.system;
  Color _themeColor = Colors.deepPurple;

  // Getters
  ThemeMode get themeMode => _themeMode;
  Color get themeColor => _themeColor;

  // Actions
  void updateThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void updateThemeColor(Color color) {
    _themeColor = color;
    notifyListeners();
  }

  // --- Theme Generators ---
  
  // Creates the Light Theme data based on the selected accent color
  static ThemeData getLightTheme(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      // ColorSchemeSeed generates a full color palette (primary, secondary, etc.)
      // based on a single seed color.
      colorSchemeSeed: accentColor,
      brightness: Brightness.light,
      appBarTheme: AppBarTheme(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      // Custom styling for the main control button look
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(backgroundColor: accentColor),
      ),
    );
  }

  // Creates the Dark Theme data based on the selected accent color
  static ThemeData getDarkTheme(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: accentColor,
      brightness: Brightness.dark,
      // Custom dark theme background colors for better contrast
      scaffoldBackgroundColor: Colors.black,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.dark,
        surface: Colors.grey[900], // Darker background for surfaces
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
    );
  }
}
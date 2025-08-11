import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ThemeConfig {
  // Primary Color Configuration
  static Color get primaryColor {
    final colorString = dotenv.env['PRIMARY_COLOR'] ?? '255,158,19,17';
    final colorValues = colorString.split(',').map(int.parse).toList();
    return Color.fromARGB(colorValues[0], colorValues[1], colorValues[2], colorValues[3]);
  }
  
  // Background Color Configuration
  static Color get backgroundColor {
    final colorString = dotenv.env['BACKGROUND_COLOR'] ?? '255,249,249,249';
    final colorValues = colorString.split(',').map(int.parse).toList();
    return Color.fromARGB(colorValues[0], colorValues[1], colorValues[2], colorValues[3]);
  }
  
  // Build Material Theme
  static ThemeData buildTheme() {
    final primaryRed = primaryColor;
    final background = backgroundColor;

    return ThemeData(
      // Use Material 3 design
      useMaterial3: true,
      
      // Define the color scheme based on primary color
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        primary: primaryRed,
        brightness: Brightness.light,
        background: background,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ElevatedButton Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      // InputDecoration Theme (for TextFields)
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryRed, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.black54),
      ),
    );
  }
}
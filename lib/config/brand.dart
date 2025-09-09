// lib/config/brand.dart
import 'package:flutter/material.dart';

class Brand {
  // App display name (used in AppBar / title)
  static const String appName = 'Aktivstall Hochbuch';

  // Primary brand colors (change to alter colors globally)
  static const Color primary = Color(0xFF8F7C74); // #8f7c74
  static const Color accent  = Color(0xFFB7A5A5); // #b7a5a5

  // Assets (replace the files in /assets to change logo/icon)
  static const String logoAsset = 'assets/logo.png';
  static const String iconAsset = 'assets/icon.png';

  // App theme derived from the above
  static ThemeData themeData() {
    return ThemeData(
      primaryColor: primary,
      colorScheme: ColorScheme.fromSwatch(primarySwatch: _createMaterialColor(primary))
          .copyWith(secondary: accent),
      appBarTheme: AppBarTheme(backgroundColor: primary, foregroundColor: Colors.white),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: accent),
    );
  }

  // Helper to make a MaterialColor for primarySwatch
  static MaterialColor _createMaterialColor(Color color) {
    final strengths = <double>[.05];
    final swatch = <int, Color>{};
    final r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) strengths.add(0.1 * i);
    for (final s in strengths) {
      final ds = 0.5 - s;
      swatch[(s * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}
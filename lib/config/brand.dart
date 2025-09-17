import 'package:flutter/material.dart';

class Brand {
  // Primary brand colors (as requested)
  static const Color primary = Color(0xFF8f7c74); // darker
  static const Color secondary = Color(0xFFb7a5a5); // lighter

  // App name
  static const String appName = 'Aktivstall Hochbuch';

  // Use this TextTheme if you want a consistent look
  static TextTheme textTheme(TextTheme base) => base.copyWith(
        headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: base.bodyLarge?.copyWith(height: 1.4),
        bodyMedium: base.bodyMedium?.copyWith(height: 1.4),
      );
}
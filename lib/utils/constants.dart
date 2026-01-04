import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Bubblegum romantic theme
  static const Color primary = Color(0xFFEE5A7B); // Hot pink
  static const Color secondary = Color(0xFFFFC0CB); // Light pink
  static const Color accent = Color(0xFFFFE5D9); // Cream/peach
  
  // Neutrals
  static const Color darkText = Color(0xFF1A1A1A); // Almost black
  static const Color mediumText = Color(0xFF8B8B8B); // Gray
  static const Color lightText = Color(0xFFC8C8C8); // Light gray
  static const Color background = Color(0xFFFAF8F7); // Off-white
  static const Color cardBackground = Color(0xFFFFFFFF); // White
  
  // Functional colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEE5A7B);
  static const Color warning = Color(0xFFFFC107);
  
  // Light backgrounds
  static const Color lightPink = Color(0xFFFFF0F5);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color lightOrange = Color(0xFFFFE5D9);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double full = 999.0;
}

class AppShadows {
  static const BoxShadow subtle = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );
  
  static const BoxShadow medium = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 12,
    offset: Offset(0, 4),
  );
  
  static const BoxShadow elevated = BoxShadow(
    color: Color(0x33000000),
    blurRadius: 16,
    offset: Offset(0, 8),
  );
}

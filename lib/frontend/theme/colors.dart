import 'package:flutter/material.dart';

class AppColors {
  // Design system color palette
  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF030213);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF030213);

  static const Color primary = Color(0xFF030213);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFFF3F3F5);
  static const Color secondaryForeground = Color(0xFF030213);

  static const Color muted = Color(0xFFECECF0);
  static const Color mutedForeground = Color(0xFF717182);

  static const Color accent = Color(0xFFE9EBEF);
  static const Color accentForeground = Color(0xFF030213);

  static const Color destructive = Color(0xFFD4183D);
  static const Color destructiveForeground = Color(0xFFFFFFFF);

  static const Color border = Color(0x1A000000); // rgba(0, 0, 0, 0.1)
  static const Color input = Colors.transparent;
  static const Color inputBackground = Color(0xFFF3F3F5);
  static const Color switchBackground = Color(0xFFCBCED4);

  // Legacy compatibility
  static const Color text = foreground;
  static const Color textSecondary = mutedForeground;
  static const Color secondaryBackground = Color(0xFFF7F6F3);
  static const Color hover = Color(0xFFF1F1EF);
  static const Color subtle = Color(0xFFEDECE8);
}

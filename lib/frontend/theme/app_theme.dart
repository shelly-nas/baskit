import 'package:flutter/material.dart';

/// App Theme Configuration
/// This file contains all styling configurations for the app.
/// Modify colors, fonts, and other style properties here to change the app's appearance.
class AppTheme {
  // ========== COLORS ==========
  // Primary colors - main brand colors
  static const Color primaryColor = Color(0xFF2E7D32); // Green
  static const Color primaryLightColor = Color(0xFF60AD5E);
  static const Color primaryDarkColor = Color(0xFF005005);

  // Secondary colors - accent colors
  static const Color secondaryColor = Color(0xFFFF6F00); // Orange
  static const Color secondaryLightColor = Color(0xFFFF9E40);
  static const Color secondaryDarkColor = Color(0xFFC43E00);

  // Background colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color textDisabledColor = Color(0xFFBDBDBD);

  // Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFE53935);
  static const Color infoColor = Color(0xFF2196F3);

  // Border colors
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color dividerColor = Color(0xFFBDBDBD);

  // ========== FONTS ==========
  // Font families
  static const String primaryFontFamily = 'Roboto';
  static const String headingFontFamily = 'Roboto';

  // Font sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeXXLarge = 24.0;
  static const double fontSizeTitle = 28.0;

  // Font weights
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // ========== SPACING ==========
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // ========== BORDER RADIUS ==========
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;

  // ========== ELEVATION ==========
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // ========== THEME DATA ==========
  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Color scheme
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryColor,
        onError: Colors.white,
      ),

      // Scaffold
      scaffoldBackgroundColor: backgroundColor,

      // App bar
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: elevationLow,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: fontSizeXLarge,
          fontWeight: fontWeightSemiBold,
          color: Colors.white,
          fontFamily: headingFontFamily,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingSmall,
        ),
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeTitle,
          fontWeight: fontWeightBold,
          color: textPrimaryColor,
          fontFamily: headingFontFamily,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeXXLarge,
          fontWeight: fontWeightSemiBold,
          color: textPrimaryColor,
          fontFamily: headingFontFamily,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeXLarge,
          fontWeight: fontWeightSemiBold,
          color: textPrimaryColor,
          fontFamily: headingFontFamily,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: fontWeightMedium,
          color: textPrimaryColor,
          fontFamily: primaryFontFamily,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: fontWeightRegular,
          color: textPrimaryColor,
          fontFamily: primaryFontFamily,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: fontWeightRegular,
          color: textPrimaryColor,
          fontFamily: primaryFontFamily,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeSmall,
          fontWeight: fontWeightRegular,
          color: textSecondaryColor,
          fontFamily: primaryFontFamily,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: textPrimaryColor, size: 24.0),

      // Floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: elevationMedium,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1.0,
        space: spacingMedium,
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingMedium,
        ),
      ),
    );
  }

  /// Dark theme configuration (optional - can be customized later)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.dark(
        primary: primaryLightColor,
        secondary: secondaryLightColor,
        surface: const Color(0xFF1E1E1E),
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: const Color(0xFF121212),
    );
  }
}

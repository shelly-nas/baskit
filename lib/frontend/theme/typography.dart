import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTypography {
  // Font weights matching design system
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight normal = FontWeight.w400;

  static final TextTheme textTheme = TextTheme(
    // Display styles
    displayLarge: GoogleFonts.inter(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: AppColors.foreground,
      height: 1.5,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: medium,
      color: AppColors.foreground,
      height: 1.5,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: medium,
      color: AppColors.foreground,
      height: 1.5,
    ),
    // Headline styles (h1, h2, h3)
    headlineLarge: GoogleFonts.inter(
      fontSize: 24, // text-2xl
      fontWeight: medium,
      color: AppColors.foreground,
      height: 1.5,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20, // text-xl
      fontWeight: medium,
      color: AppColors.foreground,
      height: 1.5,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 18, // text-lg
      fontWeight: medium,
      color: AppColors.foreground,
      height: 1.5,
    ),
    // Title styles (h4)
    titleLarge: GoogleFonts.inter(
      fontSize: 16, // text-base
      fontWeight: medium,
      color: AppColors.foreground,
      height: 1.5,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: medium,
      color: AppColors.foreground,
      height: 1.5,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: medium,
      color: AppColors.foreground,
      height: 1.5,
    ),
    // Label styles (buttons, labels)
    labelLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: medium,
      color: AppColors.foreground,
      height: 1.5,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: medium,
      color: AppColors.mutedForeground,
      height: 1.5,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: medium,
      color: AppColors.mutedForeground,
      height: 1.5,
    ),
    // Body text (paragraphs)
    bodyLarge: GoogleFonts.inter(
      fontSize: 16, // text-base
      fontWeight: normal,
      color: AppColors.foreground,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: normal,
      color: AppColors.foreground,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: normal,
      color: AppColors.mutedForeground,
      height: 1.5,
    ),
  );
}

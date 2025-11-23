import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';

/// Atomic text component for consistent typography
class AppText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const AppText(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    // Use AppTypography's bodyMedium as the base style
    final baseStyle = AppTypography.textTheme.bodyMedium;

    return Text(
      text,
      style:
          style?.copyWith(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ) ??
          baseStyle?.copyWith(
            color: color ?? AppColors.foreground,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

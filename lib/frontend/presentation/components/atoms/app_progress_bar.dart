import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';

/// Atomic progress bar component
class AppProgressBar extends StatelessWidget {
  final double value;
  final Color? backgroundColor;
  final Color? valueColor;
  final double? height;
  final double? borderRadius;

  const AppProgressBar({
    super.key,
    required this.value,
    this.backgroundColor,
    this.valueColor,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        borderRadius ?? DesignTokens.radiusMedium,
      ),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height ?? 6,
        backgroundColor: backgroundColor ?? AppColors.secondary,
        valueColor: AlwaysStoppedAnimation<Color>(
          valueColor ?? AppColors.primary,
        ),
      ),
    );
  }
}

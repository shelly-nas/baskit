import 'package:flutter/material.dart';
import '../../../theme/design_tokens.dart';
import 'app_text.dart';

/// Atomic badge component for labels and indicators
class AppBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const AppBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceMedium,
            vertical: DesignTokens.spaceSmall,
          ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          borderRadius ?? DesignTokens.radiusLarge,
        ),
      ),
      child: AppText(text, fontSize: 12, color: textColor),
    );
  }
}

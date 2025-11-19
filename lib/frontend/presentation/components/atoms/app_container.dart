import 'package:flutter/material.dart';
import '../../../theme/design_tokens.dart';

/// Atomic container component with consistent styling
class AppContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? borderColor;
  final double? borderWidth;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? decoration;

  const AppContainer({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.margin,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      margin: margin,
      decoration:
          decoration ??
          BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(
              borderRadius ?? DesignTokens.radiusMedium,
            ),
            border: borderColor != null
                ? Border.all(
                    color: borderColor!,
                    width: borderWidth ?? DesignTokens.borderThin,
                  )
                : null,
          ),
      child: child,
    );
  }
}

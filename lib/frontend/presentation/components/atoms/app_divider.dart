import 'package:flutter/material.dart';
import '../../../theme/design_tokens.dart';

/// Atomic divider component
class AppDivider extends StatelessWidget {
  final Color color;
  final double height;
  final double thickness;

  const AppDivider({
    super.key,
    required this.color,
    this.height = 1,
    this.thickness = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(height: height, thickness: thickness, color: color);
  }
}

/// Horizontal border divider
class AppBorderDivider extends StatelessWidget {
  final Color color;
  final double width;

  const AppBorderDivider({
    super.key,
    required this.color,
    this.width = DesignTokens.borderThin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: color, width: width),
        ),
      ),
    );
  }
}

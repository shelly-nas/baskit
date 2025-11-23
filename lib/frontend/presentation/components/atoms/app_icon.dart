import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';

/// Atomic icon component for consistent iconography
class AppIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;

  const AppIcon(this.icon, {super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size ?? DesignTokens.iconMedium,
      color: color ?? AppColors.foreground,
    );
  }
}

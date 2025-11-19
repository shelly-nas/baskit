import 'package:flutter/material.dart';
import '../../../theme/design_tokens.dart';
import 'app_icon.dart';

/// Atomic avatar component
class AppAvatar extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final double iconSize;

  const AppAvatar({
    super.key,
    required this.icon,
    this.size = DesignTokens.avatarSize,
    required this.backgroundColor,
    required this.iconColor,
    this.iconSize = DesignTokens.iconXLarge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(DesignTokens.radius3XLarge),
      ),
      child: Center(
        child: AppIcon(icon, size: iconSize, color: iconColor),
      ),
    );
  }
}

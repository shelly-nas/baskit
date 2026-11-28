import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_text.dart';

/// One tab of the glass tab bar: the selected tab sits in a soft capsule
/// with a filled icon.
class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const BottomNavItem({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.mutedForeground;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              vertical: DesignTokens.spaceMedium,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.glassSelected : Colors.transparent,
              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  isSelected ? selectedIcon : icon,
                  size: DesignTokens.iconLarge,
                  color: color,
                ),
                const SizedBox(height: DesignTokens.spaceXSmall),
                AppText(
                  label,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

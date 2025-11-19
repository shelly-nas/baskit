import 'package:flutter/material.dart';
import '../../../theme/design_tokens.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_text.dart';
import '../atoms/spacing.dart';

/// Molecular component for bottom navigation bar items
class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: DesignTokens.spaceXSmall,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  icon,
                  size: DesignTokens.iconLarge,
                  color: isSelected
                      ? const Color(0xFF37352F)
                      : const Color(0xFF787774),
                ),
                const VerticalSpace.small(),
                AppText(
                  label,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF37352F)
                      : const Color(0xFF787774),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

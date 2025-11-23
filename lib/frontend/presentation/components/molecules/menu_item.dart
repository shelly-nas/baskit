import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_text.dart';
import '../atoms/spacing.dart';

/// Molecular component for menu items with icon, label, and chevron
class MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const MenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: AppColors.border,
          width: DesignTokens.borderThin,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceXLarge),
            child: Row(
              children: [
                AppIcon(
                  icon,
                  size: DesignTokens.iconMedium,
                  color: AppColors.mutedForeground,
                ),
                const HorizontalSpace.large(),
                Expanded(
                  child: AppText(
                    label,
                    fontSize: 14,
                    color: AppColors.foreground,
                  ),
                ),
                const AppIcon(
                  CupertinoIcons.chevron_right,
                  size: DesignTokens.iconMedium,
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

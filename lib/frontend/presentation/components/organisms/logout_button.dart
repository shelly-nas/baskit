import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_text.dart';
import '../atoms/spacing.dart';

/// Organism component for logout button
class LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const LogoutButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: AppColors.destructive.withValues(alpha: 0.3),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          child: const Padding(
            padding: EdgeInsets.all(DesignTokens.spaceXLarge),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(
                  CupertinoIcons.square_arrow_right,
                  size: DesignTokens.iconMedium,
                  color: AppColors.destructive,
                ),
                HorizontalSpace.medium(),
                AppText(
                  'Log Out',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.destructive,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

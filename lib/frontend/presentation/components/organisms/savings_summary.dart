import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../atoms/app_text.dart';
import '../atoms/spacing.dart';

/// Organism component for savings summary section
class SavingsSummary extends StatelessWidget {
  final String totalSavings;
  final String membershipDuration;

  const SavingsSummary({
    super.key,
    required this.totalSavings,
    required this.membershipDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceXLarge),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            'Your Total Savings',
            fontSize: 14,
            color: AppColors.mutedForeground,
          ),
          const VerticalSpace(DesignTokens.spaceLarge),
          AppText(
            totalSavings,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
          ),
          const VerticalSpace(DesignTokens.spaceMedium),
          AppText(
            membershipDuration,
            fontSize: 12,
            color: AppColors.mutedForeground,
          ),
        ],
      ),
    );
  }
}

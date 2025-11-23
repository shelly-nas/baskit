import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../../models/shopping_list.dart';
import '../atoms/app_progress_bar.dart';
import '../atoms/spacing.dart';
import '../molecules/list_card_header.dart';
import '../molecules/list_card_info.dart';

/// Organism component for shopping list card
class ShoppingListCardComponent extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback? onTap;

  const ShoppingListCardComponent({super.key, required this.list, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceLarge),
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
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceXLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListCardHeader(name: list.name, isShared: list.isShared),
                const VerticalSpace(DesignTokens.spaceSmall),
                ListCardInfo(
                  completedItems: list.completedItems,
                  totalItems: list.itemCount,
                ),
                const VerticalSpace(DesignTokens.spaceLarge),
                AppProgressBar(
                  value: list.completionPercentage,
                  backgroundColor: AppColors.secondary,
                  valueColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

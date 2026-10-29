import 'package:flutter/material.dart';
import '../../../../backend/models/shopping_list.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../../../utils/formatters.dart';
import '../atoms/app_progress_bar.dart';
import '../atoms/app_text.dart';
import '../atoms/spacing.dart';
import '../molecules/list_card_header.dart';
import '../molecules/list_card_info.dart';

/// Organism component for shopping list card
class ShoppingListCardComponent extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ShoppingListCardComponent({
    super.key,
    required this.list,
    this.onTap,
    this.trailing,
  });

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
          onTap: onTap,
          hoverColor: AppColors.hover,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceXLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ListCardHeader(
                        name: list.name,
                        isShared: list.isShared,
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                const VerticalSpace(DesignTokens.spaceSmall),
                Row(
                  children: [
                    Expanded(
                      child: ListCardInfo(
                        completedItems: list.completedItemsCount,
                        totalItems: list.itemCount,
                      ),
                    ),
                    if (list.offerItems.isNotEmpty)
                      AppText(
                        '${list.offerItems.length} on offer, '
                        '${Formatters.price(list.offerTotal)}',
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                  ],
                ),
                const VerticalSpace(DesignTokens.spaceLarge),
                // The "x/y items completed" text above already says this; as
                // a progress bar it made screen readers announce the whole
                // card as one instead of as a button.
                ExcludeSemantics(
                  child: AppProgressBar(
                    value: list.completionPercentage,
                    backgroundColor: AppColors.secondary,
                    valueColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

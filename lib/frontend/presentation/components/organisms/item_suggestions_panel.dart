import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../backend/models/offer.dart';
import '../../../../backend/services/item_suggestion_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../../../utils/formatters.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_text.dart';

/// Suggestions under the "Add an item" field: items added before, then
/// matching offers. Tapping one adds it to the list.
class ItemSuggestionsPanel extends StatelessWidget {
  final ItemSuggestions suggestions;
  final ValueChanged<String> onName;
  final ValueChanged<Offer> onOffer;

  const ItemSuggestionsPanel({
    super.key,
    required this.suggestions,
    required this.onName,
    required this.onOffer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: DesignTokens.spaceSmall),
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Column(
        children: [
          for (final name in suggestions.names)
            ListTile(
              dense: true,
              leading: const AppIcon(
                CupertinoIcons.clock,
                size: DesignTokens.iconMedium,
                color: AppColors.mutedForeground,
              ),
              title: Text(name),
              onTap: () => onName(name),
            ),
          for (final offer in suggestions.offers)
            ListTile(
              dense: true,
              leading: const AppIcon(
                CupertinoIcons.tag,
                size: DesignTokens.iconMedium,
                color: AppColors.success,
              ),
              title: Text(offer.name),
              subtitle: AppText(
                '${offer.supermarket.name} - '
                '${Formatters.price(offer.discountPrice)}',
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
              onTap: () => onOffer(offer),
            ),
        ],
      ),
    );
  }
}

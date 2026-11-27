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

  /// Whether products are limited to offers; the user can switch it off.
  final bool offersOnly;
  final ValueChanged<bool> onOffersOnlyChanged;

  const ItemSuggestionsPanel({
    super.key,
    required this.suggestions,
    required this.onName,
    required this.onOffer,
    required this.offersOnly,
    required this.onOffersOnlyChanged,
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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceLarge,
              vertical: DesignTokens.spaceSmall,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Only offers'),
                selected: offersOnly,
                onSelected: onOffersOnlyChanged,
              ),
            ),
          ),
          for (final offer in suggestions.offers)
            ListTile(
              dense: true,
              leading: AppIcon(
                offer.isOnOffer ? CupertinoIcons.tag : CupertinoIcons.cart,
                size: DesignTokens.iconMedium,
                color: offer.isOnOffer
                    ? AppColors.success
                    : AppColors.mutedForeground,
              ),
              title: Text(offer.name),
              subtitle: AppText(
                '${offer.supermarket.name} - '
                '${Formatters.price(offer.price)}',
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

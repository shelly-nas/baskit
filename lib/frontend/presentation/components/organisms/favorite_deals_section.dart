import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../backend/models/offer.dart';
import '../../../../backend/services/favorite_deals_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../../../utils/formatters.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_text.dart';

/// "Your favorites on offer" at the top of the Search tab (FR-010): one
/// card per favorite that is on offer now; tapping one opens the offer.
class FavoriteDealsSection extends StatelessWidget {
  final List<FavoriteDeal> deals;
  final ValueChanged<Offer> onOpen;

  const FavoriteDealsSection({
    super.key,
    required this.deals,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceXLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: const AppText(
              'Your favorites on offer',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.spaceMedium),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: deals.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: DesignTokens.spaceMedium),
              itemBuilder: (context, index) =>
                  _DealCard(deal: deals[index], onOpen: onOpen),
            ),
          ),
        ],
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final FavoriteDeal deal;
  final ValueChanged<Offer> onOpen;

  const _DealCard({required this.deal, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final offer = deal.offer;
    return SizedBox(
      width: 200,
      child: Material(
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        child: InkWell(
          key: ValueKey('deal-${deal.favorite.id}'),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          onTap: () => onOpen(offer),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppIcon(
                      CupertinoIcons.star_fill,
                      size: DesignTokens.iconSmall,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: DesignTokens.spaceSmall),
                    Expanded(
                      child: AppText(
                        deal.favorite.name,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spaceSmall),
                AppText(
                  offer.name,
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                AppText(
                  '${offer.supermarket.name} - ${Formatters.price(offer.price)}',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

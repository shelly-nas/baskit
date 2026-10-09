import 'package:flutter/material.dart';
import '../../../../backend/models/offer.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../../../utils/formatters.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_text.dart';

/// Organism component showing a single supermarket offer as a Notion style row
class OfferCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback? onTap;

  const OfferCard({super.key, required this.offer, this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.supermarket(offer.supermarket.key);

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.hover,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.spaceLarge),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            border: Border.all(
              color: AppColors.border,
              width: DesignTokens.borderThin,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceLarge),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      offer.name,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DesignTokens.spaceXSmall),
                    AppText(
                      [
                        offer.supermarket.name,
                        if (offer.category.isNotEmpty) offer.category,
                      ].join('  /  '),
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DesignTokens.spaceMedium),
                    Wrap(
                      spacing: DesignTokens.spaceSmall,
                      runSpacing: DesignTokens.spaceSmall,
                      children: [
                        if (offer.specialDiscount != null)
                          AppBadge(
                            text: offer.specialDiscount!,
                            backgroundColor: AppColors.warningBackground,
                            textColor: AppColors.warning,
                            borderRadius: DesignTokens.radiusSmall,
                          ),
                        AppBadge(
                          text: Formatters.expiry(offer.expireDate),
                          backgroundColor: AppColors.secondary,
                          textColor: AppColors.mutedForeground,
                          borderRadius: DesignTokens.radiusSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.spaceLarge),
              _PriceColumn(offer: offer),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceColumn extends StatelessWidget {
  final Offer offer;

  const _PriceColumn({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AppText(
          Formatters.price(offer.discountPrice),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        if (offer.originalPrice != null &&
            offer.originalPrice! > offer.discountPrice)
          Text(
            Formatters.price(offer.originalPrice!),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        if (offer.discountPercentage != null &&
            offer.discountPercentage! > 0) ...[
          const SizedBox(height: DesignTokens.spaceSmall),
          AppBadge(
            text: '-${offer.discountPercentage}%',
            backgroundColor: AppColors.successBackground,
            textColor: AppColors.success,
            borderRadius: DesignTokens.radiusSmall,
          ),
        ],
      ],
    );
  }
}

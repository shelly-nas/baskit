import 'package:flutter/material.dart';
import '../../../../backend/models/offer.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../../../utils/formatters.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_text.dart';

/// Organism component showing a single supermarket offer as a compact,
/// Notion style row: the deal as a short label (full text in the details).
class OfferCard extends StatelessWidget {
  static const EdgeInsets _badgePadding = EdgeInsets.symmetric(
    horizontal: DesignTokens.spaceMedium,
    vertical: DesignTokens.spaceXSmall,
  );

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
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceLarge,
            vertical: DesignTokens.spaceMedium,
          ),
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
                height: 32,
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
                    const SizedBox(height: DesignTokens.spaceSmall),
                    Wrap(
                      spacing: DesignTokens.spaceSmall,
                      runSpacing: DesignTokens.spaceSmall,
                      children: [
                        if (offer.specialDiscount != null)
                          AppBadge(
                            text: Formatters.dealLabel(offer.specialDiscount!),
                            backgroundColor: AppColors.warningBackground,
                            textColor: AppColors.warning,
                            borderRadius: DesignTokens.radiusSmall,
                            padding: _badgePadding,
                          ),
                        AppBadge(
                          text: offer.expireDate == null
                              ? 'Regular price'
                              : Formatters.expiry(offer.expireDate!),
                          backgroundColor: AppColors.secondary,
                          textColor: AppColors.mutedForeground,
                          borderRadius: DesignTokens.radiusSmall,
                          padding: _badgePadding,
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
          Formatters.price(offer.price),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        // The regular price and the discount side by side, on one line.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (offer.originalPrice != null &&
                offer.originalPrice! > offer.price)
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
              const SizedBox(width: DesignTokens.spaceSmall),
              AppText(
                '-${offer.discountPercentage}%',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

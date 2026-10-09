import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../backend/models/offer.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../../../utils/formatters.dart';
import '../atoms/app_divider.dart';
import '../atoms/app_text.dart';

/// Organism component with the details of one offer, shown in a bottom sheet
class OfferDetailsSheet extends StatelessWidget {
  final Offer offer;

  const OfferDetailsSheet({super.key, required this.offer});

  static Future<void> show(BuildContext context, Offer offer) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      constraints: const BoxConstraints(maxWidth: 640),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusXLarge),
        ),
      ),
      builder: (_) => OfferDetailsSheet(offer: offer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Supermarket', offer.supermarket.name),
      if (offer.category.isNotEmpty) MapEntry('Category', offer.category),
      MapEntry('Offer price', Formatters.price(offer.discountPrice)),
      if (offer.originalPrice != null)
        MapEntry('Regular price', Formatters.price(offer.originalPrice!)),
      if (offer.savings != null)
        MapEntry('You save', Formatters.price(offer.savings!)),
      if (offer.unitPrice != null) MapEntry('Unit price', offer.unitPrice!),
      if (offer.specialDiscount != null)
        MapEntry('Deal', offer.specialDiscount!),
      MapEntry('Valid', Formatters.expiry(offer.expireDate)),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space2XLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(offer.name, fontSize: 20, fontWeight: FontWeight.w700),
            const SizedBox(height: DesignTokens.spaceXLarge),
            for (final row in rows) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: DesignTokens.spaceMedium,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: AppText(
                        row.key,
                        fontSize: 13,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    Expanded(child: AppText(row.value, fontSize: 14)),
                  ],
                ),
              ),
              const AppDivider(color: AppColors.border),
            ],
            if (offer.productUrl != null) ...[
              const SizedBox(height: DesignTokens.space2XLarge),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(CupertinoIcons.arrow_up_right_square),
                  label: Text('View at ${offer.supermarket.name}'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.spaceXLarge,
                    ),
                  ),
                  onPressed: () => launchUrl(
                    Uri.parse(offer.productUrl!),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

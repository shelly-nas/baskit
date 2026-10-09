import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../backend/models/shopping_list.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_tokens.dart';
import '../../../utils/formatters.dart';
import '../atoms/app_icon.dart';
import '../atoms/app_text.dart';

/// Organism component for one item on a shopping list (Notion style to-do row)
class ListItemRow extends StatelessWidget {
  final ListItem item;
  final VoidCallback onToggle;
  final VoidCallback? onTap;

  const ListItemRow({
    super.key,
    required this.item,
    required this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final offer = item.offer;
    final done = item.isCompleted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.hover,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceSmall,
            vertical: DesignTokens.spaceMedium,
          ),
          child: Row(
            children: [
              Semantics(
                checked: done,
                label: done ? 'Mark as not done' : 'Mark as done',
                child: InkResponse(
                  onTap: onToggle,
                  radius: 20,
                  child: AppIcon(
                    done
                        ? CupertinoIcons.checkmark_square_fill
                        : CupertinoIcons.square,
                    size: DesignTokens.iconLarge,
                    color: done ? AppColors.primary : AppColors.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceLarge),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        color: done
                            ? AppColors.mutedForeground
                            : AppColors.foreground,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (offer != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: DesignTokens.spaceXSmall,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: AppColors.supermarket(
                                  offer.supermarketKey,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: DesignTokens.spaceSmall),
                            Flexible(
                              child: AppText(
                                [
                                  offer.supermarketName,
                                  if (offer.specialDiscount != null)
                                    offer.specialDiscount!,
                                  offer.isExpired()
                                      ? 'offer ended'
                                      : Formatters.expiry(
                                          offer.expireDate,
                                        ).toLowerCase(),
                                ].join('  /  '),
                                fontSize: 12,
                                color: offer.isExpired()
                                    ? AppColors.destructive
                                    : AppColors.mutedForeground,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (item.quantity != null && item.quantity!.isNotEmpty) ...[
                const SizedBox(width: DesignTokens.spaceMedium),
                AppText(
                  item.quantity!,
                  fontSize: 13,
                  color: AppColors.mutedForeground,
                ),
              ],
              if (offer != null) ...[
                const SizedBox(width: DesignTokens.spaceLarge),
                AppText(
                  Formatters.price(offer.price),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: done
                      ? AppColors.mutedForeground
                      : AppColors.foreground,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

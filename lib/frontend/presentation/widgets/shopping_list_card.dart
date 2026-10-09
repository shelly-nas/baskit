import 'package:flutter/material.dart';
import '../../../backend/models/shopping_list.dart';
import '../../theme/app_theme.dart';

/// Shopping List Card Widget
/// Displays a shopping list as a card with name, description, and metadata
class ShoppingListCard extends StatelessWidget {
  final ShoppingList shoppingList;
  final VoidCallback? onTap;

  const ShoppingListCard({super.key, required this.shoppingList, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with name and share indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shoppingList.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (shoppingList.isShared)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSmall,
                        vertical: AppTheme.spacingXSmall,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.infoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusSmall,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people,
                            size: 16,
                            color: AppTheme.infoColor,
                          ),
                          const SizedBox(width: AppTheme.spacingXSmall),
                          Text(
                            'Shared',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.infoColor,
                                  fontWeight: AppTheme.fontWeightMedium,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Description (if available)
              if (shoppingList.description != null &&
                  shoppingList.description!.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingSmall),
                Text(
                  shoppingList.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: AppTheme.spacingMedium),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                child: LinearProgressIndicator(
                  value: shoppingList.completionPercentage,
                  backgroundColor: AppTheme.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    shoppingList.isCompleted
                        ? AppTheme.successColor
                        : AppTheme.primaryColor,
                  ),
                  minHeight: 6,
                ),
              ),

              const SizedBox(height: AppTheme.spacingSmall),

              // Footer with item count and completion status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingXSmall),
                      Text(
                        '${shoppingList.completedItemsCount}/${shoppingList.itemCount} items',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (shoppingList.isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSmall,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusSmall,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(width: AppTheme.spacingXSmall),
                          Text(
                            'Completed',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.successColor,
                                  fontWeight: AppTheme.fontWeightMedium,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

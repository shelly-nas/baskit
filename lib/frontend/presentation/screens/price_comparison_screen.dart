import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../backend/models/price_comparison.dart';
import '../../../backend/models/shopping_list.dart';
import '../../../backend/services/price_comparison_service.dart';
import '../../theme/colors.dart';
import '../../theme/design_tokens.dart';
import '../../utils/formatters.dart';
import '../components/atoms/app_badge.dart';
import '../components/atoms/app_icon.dart';
import '../components/atoms/app_text.dart';

/// Shows what a shopping list costs at each supermarket.
class PriceComparisonScreen extends StatefulWidget {
  final ShoppingList list;
  final PriceComparisonService service;

  const PriceComparisonScreen({
    super.key,
    required this.list,
    required this.service,
  });

  @override
  State<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends State<PriceComparisonScreen> {
  static const double _maxContentWidth = 760;

  late Future<PriceComparison> _comparison;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _comparison = widget.service.compareList(widget.list);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.service.itemsToCompare(widget.list);
    final names = {for (final item in items) item.id: item.name};

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: const AppText(
          'Compare prices',
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: FutureBuilder<PriceComparison>(
            future: _comparison,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (snapshot.hasError) {
                return _Message(
                  title: 'Could not compare prices',
                  message: 'Check your connection and try again.',
                  onRetry: () => setState(_load),
                );
              }
              final comparison = snapshot.data!;
              final stores = comparison.storesWithMatches;
              if (stores.isEmpty) {
                return const _Message(
                  title: 'No prices found',
                  message:
                      'None of the supermarkets has products matching '
                      'the items on this list.',
                );
              }
              return ListView(
                padding: const EdgeInsets.all(DesignTokens.spaceXLarge),
                children: [
                  AppText(
                    '${widget.list.name}: ${comparison.itemCount} '
                    '${comparison.itemCount == 1 ? 'item' : 'items'} to buy',
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(height: DesignTokens.spaceSmall),
                  const AppText(
                    'Uses current offers and regular prices. Stores are '
                    'ranked by items found, then by total.',
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(height: DesignTokens.spaceXLarge),
                  for (final store in stores)
                    _StoreCard(
                      store: store,
                      itemCount: comparison.itemCount,
                      isBest: identical(store, comparison.best),
                      itemNames: names,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final StoreComparison store;
  final int itemCount;
  final bool isBest;
  final Map<String, String> itemNames;

  const _StoreCard({
    required this.store,
    required this.itemCount,
    required this.isBest,
    required this.itemNames,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.supermarket(store.supermarket.key);
    final complete = store.matched == itemCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceLarge),
      child: Material(
        color: AppColors.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          side: BorderSide(
            color: isBest ? AppColors.primary : AppColors.border,
            width: isBest ? DesignTokens.borderMedium : DesignTokens.borderThin,
          ),
        ),
        child: Theme(
          // No divider lines from ExpansionTile.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: isBest,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceXLarge,
              vertical: DesignTokens.spaceSmall,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              DesignTokens.spaceXLarge,
              0,
              DesignTokens.spaceXLarge,
              DesignTokens.spaceLarge,
            ),
            leading: Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              ),
            ),
            title: Row(
              children: [
                Flexible(
                  child: AppText(
                    store.supermarket.name,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isBest) ...[
                  const SizedBox(width: DesignTokens.spaceMedium),
                  const AppBadge(
                    text: 'Best choice',
                    backgroundColor: AppColors.successBackground,
                    textColor: AppColors.success,
                    borderRadius: DesignTokens.radiusSmall,
                  ),
                ],
              ],
            ),
            subtitle: AppText(
              complete
                  ? 'All $itemCount items found'
                  : '${store.matched} of $itemCount items found',
              fontSize: 12,
              color: complete ? AppColors.mutedForeground : AppColors.warning,
            ),
            trailing: AppText(
              Formatters.price(store.total),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            children: [
              for (final line in store.lines)
                _LineRow(line: line, itemNames: itemNames),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final ComparisonLine line;
  final Map<String, String> itemNames;

  const _LineRow({required this.line, required this.itemNames});

  @override
  Widget build(BuildContext context) {
    final itemName = itemNames[line.itemId] ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  line.count > 1 ? '${line.count} x $itemName' : itemName,
                  fontSize: 14,
                ),
                AppText(
                  line.isFound ? line.productName! : 'Not found',
                  fontSize: 12,
                  color: line.isFound
                      ? AppColors.mutedForeground
                      : AppColors.destructive,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (line.isOffer) ...[
            const SizedBox(width: DesignTokens.spaceMedium),
            AppBadge(
              text: line.specialDiscount ?? 'Offer',
              backgroundColor: AppColors.warningBackground,
              textColor: AppColors.warning,
              borderRadius: DesignTokens.radiusSmall,
            ),
          ],
          const SizedBox(width: DesignTokens.spaceMedium),
          AppText(
            line.lineTotal == null ? '-' : Formatters.price(line.lineTotal!),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _Message({required this.title, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.space3XLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppIcon(
            CupertinoIcons.chart_bar,
            size: DesignTokens.iconXLarge,
            color: AppColors.mutedForeground,
          ),
          const SizedBox(height: DesignTokens.spaceLarge),
          AppText(title, fontSize: 16, fontWeight: FontWeight.w500),
          const SizedBox(height: DesignTokens.spaceSmall),
          AppText(
            message,
            fontSize: 14,
            color: AppColors.mutedForeground,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: DesignTokens.spaceXLarge),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ],
      ),
    );
  }
}

// Result of pricing a shopping list at every supermarket.

import 'offer.dart';

class ComparisonLine {
  final String itemId;
  final int count;

  /// Matched product name; null when the supermarket has nothing that matches.
  final String? productName;

  /// Price of one unit right now (offer price or regular price).
  final double? unitPrice;
  final double? lineTotal;
  final bool isOffer;
  final String? specialDiscount;
  final String? productUrl;

  const ComparisonLine({
    required this.itemId,
    required this.count,
    this.productName,
    this.unitPrice,
    this.lineTotal,
    this.isOffer = false,
    this.specialDiscount,
    this.productUrl,
  });

  bool get isFound => productName != null;
}

class StoreComparison {
  final Supermarket supermarket;
  final double total;
  final int matched;
  final List<String> missingItemIds;
  final List<ComparisonLine> lines;

  const StoreComparison({
    required this.supermarket,
    required this.total,
    required this.matched,
    required this.missingItemIds,
    required this.lines,
  });

  ComparisonLine? lineFor(String itemId) {
    for (final line in lines) {
      if (line.itemId == itemId) return line;
    }
    return null;
  }
}

class PriceComparison {
  final int itemCount;

  /// Best first: most items found, then the lowest total.
  final List<StoreComparison> stores;

  const PriceComparison({required this.itemCount, required this.stores});

  /// Stores that found at least one item.
  List<StoreComparison> get storesWithMatches =>
      stores.where((s) => s.matched > 0).toList();

  /// The recommended store: most items found, cheapest among those.
  StoreComparison? get best =>
      storesWithMatches.isEmpty ? null : storesWithMatches.first;
}

/// One list item as sent to the comparison.
class CompareRequestItem {
  final String id;
  final String query;
  final int count;
  final int? productId;

  const CompareRequestItem({
    required this.id,
    required this.query,
    this.count = 1,
    this.productId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'query': query,
    'count': count,
    if (productId != null) 'productId': productId,
  };
}

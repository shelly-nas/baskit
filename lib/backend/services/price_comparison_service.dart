import '../models/price_comparison.dart';
import '../models/shopping_list.dart';
import '../../database/repositories/offer_repository.dart';

/// Prices the items of a shopping list at every supermarket.
class PriceComparisonService {
  final OfferRepository _repository;

  PriceComparisonService(this._repository);

  /// Items that are still to be bought are compared; checked items are not.
  List<ListItem> itemsToCompare(ShoppingList list) => list.uncompletedItems;

  Future<PriceComparison> compareList(ShoppingList list) {
    final items = itemsToCompare(list)
        .map(
          (item) => CompareRequestItem(
            id: item.id,
            query: item.name,
            count: countFromQuantity(item.quantity),
            productId: item.offer?.productId,
          ),
        )
        .toList();
    return _repository.compare(items);
  }

  /// "2", "2x" or "3 stuks" is a count; a size such as "500 g" is not.
  static int countFromQuantity(String? quantity) {
    if (quantity == null) return 1;
    final match = RegExp(
      r'^\s*(\d{1,2})\s*(x|st|stuk|stuks|pcs|pieces)?\s*$',
      caseSensitive: false,
    ).firstMatch(quantity);
    if (match == null) return 1;
    final count = int.parse(match.group(1)!);
    return count < 1 ? 1 : count;
  }
}

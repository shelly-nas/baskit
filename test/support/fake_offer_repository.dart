import 'package:baskit/backend/models/offer.dart';
import 'package:baskit/backend/models/price_comparison.dart';
import 'package:baskit/database/repositories/offer_repository.dart';

const dirk = Supermarket(key: 'dirk', name: 'Dirk', activeDiscounts: 2);
const jumbo = Supermarket(key: 'jumbo', name: 'Jumbo', activeDiscounts: 1);
const aldi = Supermarket(key: 'aldi', name: 'Aldi');

final sampleOffers = [
  Offer(
    productId: 1,
    name: 'Halfvolle melk 1L',
    category: 'Zuivel',
    supermarket: dirk,
    originalPrice: 1.09,
    discountPrice: 0.79,
    discountPercentage: 28,
    expireDate: DateTime.now().add(const Duration(days: 3)),
  ),
  Offer(
    productId: 2,
    name: 'Melkchocolade reep',
    category: 'Snoep',
    supermarket: jumbo,
    discountPrice: 1.99,
    specialDiscount: '2 voor 3,50',
    expireDate: DateTime.now().add(const Duration(days: 1)),
  ),
  Offer(
    productId: 3,
    name: 'Kipfilet 500g',
    category: 'Vlees',
    supermarket: dirk,
    originalPrice: 5.99,
    discountPrice: 3.99,
    discountPercentage: 33,
    expireDate: DateTime.now().add(const Duration(days: 5)),
  ),
];

/// In-memory repository that filters [sampleOffers] like the real API does.
class FakeOfferRepository implements OfferRepository {
  final List<OfferQuery> queries = [];
  final List<List<CompareRequestItem>> comparisons = [];
  bool fail = false;

  @override
  Future<List<Supermarket>> getSupermarkets() async => [aldi, jumbo, dirk];

  @override
  Future<List<OfferCategory>> getCategories({
    Set<String> supermarketKeys = const {},
  }) async => const [
    OfferCategory(name: 'Snoep', count: 1),
    OfferCategory(name: 'Zuivel', count: 1),
  ];

  @override
  Future<OfferPage> search(
    OfferQuery query, {
    int limit = 25,
    int offset = 0,
  }) async {
    queries.add(query);
    if (fail) throw Exception('offline');
    final words = query.text
        .toLowerCase()
        .split(' ')
        .where((w) => w.isNotEmpty);
    final matches = sampleOffers.where((o) {
      final name = o.name.toLowerCase();
      return words.every(name.contains) &&
          (query.supermarketKeys.isEmpty ||
              query.supermarketKeys.contains(o.supermarket.key)) &&
          (query.category == null || o.category == query.category);
    }).toList();
    return OfferPage(
      items: matches.skip(offset).take(limit).toList(),
      total: matches.length,
      offset: offset,
    );
  }

  /// Dirk finds every item (0.50 each), Jumbo only the first (1.00).
  @override
  Future<PriceComparison> compare(List<CompareRequestItem> items) async {
    comparisons.add(items);
    if (fail) throw Exception('offline');
    StoreComparison store(Supermarket sm, double price, int found) {
      final lines = [
        for (var i = 0; i < items.length; i++)
          i < found
              ? ComparisonLine(
                  itemId: items[i].id,
                  count: items[i].count,
                  productName: '${sm.name} ${items[i].query}',
                  unitPrice: price,
                  lineTotal: price * items[i].count,
                  isOffer: sm.key == 'dirk',
                )
              : ComparisonLine(itemId: items[i].id, count: items[i].count),
      ];
      return StoreComparison(
        supermarket: sm,
        total: lines.fold(0.0, (sum, l) => sum + (l.lineTotal ?? 0)),
        matched: found,
        missingItemIds: [
          for (final l in lines)
            if (!l.isFound) l.itemId,
        ],
        lines: lines,
      );
    }

    return PriceComparison(
      itemCount: items.length,
      stores: [
        store(dirk, 0.5, items.length),
        store(jumbo, 1.0, items.isEmpty ? 0 : 1),
        store(aldi, 0, 0),
      ],
    );
  }
}

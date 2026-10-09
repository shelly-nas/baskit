import 'package:baskit/backend/models/offer.dart';
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
}

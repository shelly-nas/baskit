import '../models/offer.dart';
import '../../database/repositories/offer_repository.dart';

/// Business logic for searching supermarket offers.
class OfferSearchService {
  static const int pageSize = 25;

  final OfferRepository _repository;

  OfferSearchService(this._repository);

  Future<List<Supermarket>> getSupermarkets() async {
    final supermarkets = await _repository.getSupermarkets();
    // Supermarkets with offers first, then alphabetical.
    supermarkets.sort((a, b) {
      final hasA = a.activeDiscounts > 0 ? 0 : 1;
      final hasB = b.activeDiscounts > 0 ? 0 : 1;
      if (hasA != hasB) return hasA - hasB;
      return a.name.compareTo(b.name);
    });
    return supermarkets;
  }

  Future<List<OfferCategory>> getCategories(Set<String> supermarketKeys) =>
      _repository.getCategories(supermarketKeys: supermarketKeys);

  Future<OfferPage> search(OfferQuery query, {int offset = 0}) =>
      _repository.search(query, limit: pageSize, offset: offset);
}

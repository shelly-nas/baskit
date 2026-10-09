import '../../backend/models/offer.dart';
import '../data_sources/discount_api_data_source.dart';

/// Abstracts where offers come from so the UI and services stay testable.
abstract class OfferRepository {
  Future<List<Supermarket>> getSupermarkets();
  Future<List<OfferCategory>> getCategories({Set<String> supermarketKeys});
  Future<OfferPage> search(OfferQuery query, {int limit, int offset});
}

class ApiOfferRepository implements OfferRepository {
  final DiscountApiDataSource _dataSource;

  ApiOfferRepository(this._dataSource);

  @override
  Future<List<Supermarket>> getSupermarkets() => _dataSource.getSupermarkets();

  @override
  Future<List<OfferCategory>> getCategories({
    Set<String> supermarketKeys = const {},
  }) => _dataSource.getCategories(supermarketKeys: supermarketKeys);

  @override
  Future<OfferPage> search(
    OfferQuery query, {
    int limit = 25,
    int offset = 0,
  }) => _dataSource.search(query, limit: limit, offset: offset);
}

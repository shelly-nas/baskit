import '../models/favorite.dart';
import '../models/offer.dart';
import 'offer_search_service.dart';

/// A favorite that is on offer right now.
class FavoriteDeal {
  final Favorite favorite;
  final Offer offer;

  const FavoriteDeal(this.favorite, this.offer);
}

/// Finds the current offers for the user's favorites (FR-010) through the
/// supermarket-scraper search: per favorite the best match on offer. The
/// answer is kept for [maxAge], as offers change weekly, not by the minute.
/// A favorite whose search fails simply has no deal.
class FavoriteDealsService {
  static const int maxFavorites = 20;

  final OfferSearchService _offers;
  final Duration maxAge;

  List<FavoriteDeal> _deals = const [];
  String? _askedFor;
  DateTime? _askedAt;

  FavoriteDealsService(
    this._offers, {
    this.maxAge = const Duration(minutes: 30),
  });

  Future<List<FavoriteDeal>> dealsFor(
    List<Favorite> favorites, {
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final key = favorites.map((f) => f.name.toLowerCase()).join('|');
    final askedAt = _askedAt;
    if (key == _askedFor &&
        askedAt != null &&
        at.difference(askedAt) < maxAge) {
      return _deals;
    }
    final found = await Future.wait(favorites.take(maxFavorites).map(_dealFor));
    _deals = [for (final deal in found) ?deal];
    _askedFor = key;
    _askedAt = at;
    return _deals;
  }

  Future<FavoriteDeal?> _dealFor(Favorite favorite) async {
    try {
      final page = await _offers.search(
        OfferQuery(text: favorite.name, sort: OfferSort.discount),
      );
      final offer = page.items.where((o) => o.isOnOffer).firstOrNull;
      return offer == null ? null : FavoriteDeal(favorite, offer);
    } catch (_) {
      // The offers come from another service; without them, no deal.
      return null;
    }
  }
}

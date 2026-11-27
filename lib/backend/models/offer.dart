// Domain models for supermarket offers coming from the supermarket-scraper API.

class Supermarket {
  final String key;
  final String name;
  final int activeDiscounts;
  final DateTime? lastUpdated;

  const Supermarket({
    required this.key,
    required this.name,
    this.activeDiscounts = 0,
    this.lastUpdated,
  });
}

class OfferCategory {
  final String name;
  final int count;

  const OfferCategory({required this.name, required this.count});
}

/// A product from the supermarket-scraper: on offer, or (when the search
/// includes the catalog) at its regular price.
class Offer {
  final int productId;
  final String name;
  final String category;
  final Supermarket supermarket;
  final String? productUrl;

  /// The regular price, shown struck through next to an offer price.
  final double? originalPrice;

  /// What it costs now: the offer price, or the regular price when the
  /// product is not on offer.
  final double price;
  final String? unitPrice;
  final String? specialDiscount;
  final int? discountPercentage;

  /// When the offer ends; null for a product that is not on offer.
  final DateTime? expireDate;

  const Offer({
    required this.productId,
    required this.name,
    required this.category,
    required this.supermarket,
    this.productUrl,
    this.originalPrice,
    required this.price,
    this.unitPrice,
    this.specialDiscount,
    this.discountPercentage,
    this.expireDate,
  });

  bool get isOnOffer => expireDate != null;

  /// Amount saved compared to the regular price, when known.
  double? get savings {
    final original = originalPrice;
    if (!isOnOffer || original == null || original <= price) return null;
    return original - price;
  }

  /// Whole days left until the offer expires (0 means it expires today);
  /// null when the product is not on offer.
  int? daysLeft([DateTime? now]) {
    final end = expireDate;
    if (end == null) return null;
    final reference = now ?? DateTime.now();
    return end.difference(reference).inHours ~/ 24;
  }
}

enum OfferSort {
  relevance('relevance', 'Relevance'),
  price('price', 'Lowest price'),
  discount('discount', 'Biggest discount'),
  expiry('expiry', 'Ending soon'),
  name('name', 'Name');

  final String apiValue;
  final String label;

  const OfferSort(this.apiValue, this.label);
}

class OfferQuery {
  final String text;
  final Set<String> supermarketKeys;
  final String? category;
  final OfferSort sort;

  /// Only products on offer (the default), or also the regular catalog.
  final bool offersOnly;

  const OfferQuery({
    this.text = '',
    this.supermarketKeys = const {},
    this.category,
    this.sort = OfferSort.relevance,
    this.offersOnly = true,
  });

  OfferQuery copyWith({
    String? text,
    Set<String>? supermarketKeys,
    String? category,
    bool clearCategory = false,
    OfferSort? sort,
    bool? offersOnly,
  }) {
    return OfferQuery(
      text: text ?? this.text,
      supermarketKeys: supermarketKeys ?? this.supermarketKeys,
      category: clearCategory ? null : (category ?? this.category),
      sort: sort ?? this.sort,
      offersOnly: offersOnly ?? this.offersOnly,
    );
  }
}

class OfferPage {
  final List<Offer> items;
  final int total;
  final int offset;

  const OfferPage({
    required this.items,
    required this.total,
    required this.offset,
  });

  bool get hasMore => offset + items.length < total;
}

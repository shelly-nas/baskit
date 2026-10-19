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

class Offer {
  final int productId;
  final String name;
  final String category;
  final Supermarket supermarket;
  final String? productUrl;
  final double? originalPrice;
  final double discountPrice;
  final String? unitPrice;
  final String? specialDiscount;
  final int? discountPercentage;
  final DateTime expireDate;

  const Offer({
    required this.productId,
    required this.name,
    required this.category,
    required this.supermarket,
    this.productUrl,
    this.originalPrice,
    required this.discountPrice,
    this.unitPrice,
    this.specialDiscount,
    this.discountPercentage,
    required this.expireDate,
  });

  /// Amount saved compared to the regular price, when known.
  double? get savings {
    final original = originalPrice;
    if (original == null || original <= discountPrice) return null;
    return original - discountPrice;
  }

  /// Whole days left until the offer expires (0 means it expires today).
  int daysLeft([DateTime? now]) {
    final reference = now ?? DateTime.now();
    return expireDate.difference(reference).inHours ~/ 24;
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

  const OfferQuery({
    this.text = '',
    this.supermarketKeys = const {},
    this.category,
    this.sort = OfferSort.relevance,
  });

  OfferQuery copyWith({
    String? text,
    Set<String>? supermarketKeys,
    String? category,
    bool clearCategory = false,
    OfferSort? sort,
  }) {
    return OfferQuery(
      text: text ?? this.text,
      supermarketKeys: supermarketKeys ?? this.supermarketKeys,
      category: clearCategory ? null : (category ?? this.category),
      sort: sort ?? this.sort,
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

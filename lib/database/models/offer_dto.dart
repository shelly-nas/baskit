import '../../backend/models/offer.dart';

/// JSON parsing for the discount-scraper public API (`/api/public/v1`).
class OfferDto {
  static Supermarket supermarketFromJson(Map<String, dynamic> json) {
    return Supermarket(
      key: json['key'] as String,
      name: json['name'] as String,
      activeDiscounts: (json['activeDiscounts'] as num?)?.toInt() ?? 0,
      lastUpdated: _parseDate(json['lastUpdated']),
    );
  }

  static OfferCategory categoryFromJson(Map<String, dynamic> json) {
    return OfferCategory(
      name: json['name'] as String,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  static Offer offerFromJson(Map<String, dynamic> json) {
    final discount = json['discount'] as Map<String, dynamic>;
    return Offer(
      productId: (json['id'] as num).toInt(),
      name: json['name'] as String,
      category: json['category'] as String? ?? '',
      supermarket: supermarketFromJson(
        json['supermarket'] as Map<String, dynamic>,
      ),
      productUrl: json['productUrl'] as String?,
      originalPrice: (discount['originalPrice'] as num?)?.toDouble(),
      discountPrice: (discount['discountPrice'] as num).toDouble(),
      unitPrice: discount['unitPrice'] as String?,
      specialDiscount: discount['specialDiscount'] as String?,
      discountPercentage: (discount['discountPercentage'] as num?)?.toInt(),
      expireDate: _parseDate(discount['expireDate']) ?? DateTime.now(),
    );
  }

  static OfferPage pageFromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>)
        .map((item) => offerFromJson(item as Map<String, dynamic>))
        .toList();
    return OfferPage(
      items: items,
      total: (json['total'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}

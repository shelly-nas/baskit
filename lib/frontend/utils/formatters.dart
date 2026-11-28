/// Display formatting helpers (Dutch conventions: comma decimal separator).
class Formatters {
  static String price(double value) {
    final fixed = value.toStringAsFixed(2).replaceAll('.', ',');
    return '€$fixed';
  }

  /// The deal itself ("50% KORTING"), without the explanation supermarkets
  /// put after a bar ("| Alle AH Donuts van de bakkerij"); for small labels.
  static String dealLabel(String deal) {
    String tidy(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final parts = deal.split('|');
    final first = tidy(parts.first);
    return first.isNotEmpty ? first : tidy(parts.skip(1).join('|'));
  }

  static String expiry(DateTime expireDate, [DateTime? now]) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final day = DateTime(expireDate.year, expireDate.month, expireDate.day);
    final days = day.difference(today).inDays;
    if (days <= 0) return 'Ends today';
    if (days == 1) return 'Ends tomorrow';
    if (days < 7) return 'Ends in $days days';
    return 'Until ${expireDate.day}-${expireDate.month}';
  }
}

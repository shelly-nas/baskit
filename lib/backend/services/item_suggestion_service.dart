import '../../database/data_sources/baskit_api_client.dart';
import '../../database/data_sources/item_suggestion_data_source.dart';
import '../models/offer.dart';
import '../models/shopping_list.dart';
import 'offer_search_service.dart';

/// What to suggest while the user types an item.
class ItemSuggestions {
  /// Items the user added before.
  final List<String> names;

  /// Current offers that match the text.
  final List<Offer> offers;

  const ItemSuggestions({this.names = const [], this.offers = const []});

  bool get isEmpty => names.isEmpty && offers.isEmpty;
}

/// Suggestions for adding an item (FR-003): the user's own history from the
/// server and matching offers from the supermarket-scraper. Without a
/// connection the names on the user's lists stand in for the history.
/// Suggestions are a help, so a failure gives fewer suggestions, not an error.
class ItemSuggestionService {
  static const int maxNames = 5;
  static const int maxOffers = 3;

  final ItemSuggestionDataSource? _history;
  final OfferSearchService? _offers;

  ItemSuggestionService({
    ItemSuggestionDataSource? history,
    OfferSearchService? offers,
  }) : _history = history,
       _offers = offers;

  /// [known] are the user's lists (for the offline fallback); items still
  /// open on [openOn] are left out.
  Future<ItemSuggestions> suggest(
    String text, {
    required List<ShoppingList> known,
    ShoppingList? openOn,
  }) async {
    final query = text.trim();
    if (query.isEmpty) return const ItemSuggestions();
    final open = {
      for (final item in openOn?.uncompletedItems ?? const <ListItem>[])
        item.name.trim().toLowerCase(),
    };
    final results = await Future.wait([
      _names(query, known),
      _matchingOffers(query),
    ]);
    final names = (results[0] as List<String>)
        .where((name) => !open.contains(name.trim().toLowerCase()))
        .take(maxNames)
        .toList();
    return ItemSuggestions(names: names, offers: results[1] as List<Offer>);
  }

  Future<List<String>> _names(String query, List<ShoppingList> known) async {
    final history = _history;
    if (history != null) {
      try {
        return await history.suggest(query);
      } on BaskitApiException catch (e) {
        // Only without a connection; other answers mean no suggestions.
        if (e.status != 0 && e.status < 500) return const [];
      }
    }
    return _namesOnLists(query, known);
  }

  static List<String> _namesOnLists(String query, List<ShoppingList> lists) {
    final q = query.toLowerCase();
    final byKey = <String, String>{};
    for (final list in lists) {
      for (final item in list.items) {
        final name = item.name.trim();
        if (name.toLowerCase().contains(q)) byKey[name.toLowerCase()] = name;
      }
    }
    final names = byKey.values.toList()
      ..sort((a, b) {
        final aStarts = a.toLowerCase().startsWith(q) ? 0 : 1;
        final bStarts = b.toLowerCase().startsWith(q) ? 0 : 1;
        return aStarts != bStarts ? aStarts - bStarts : a.compareTo(b);
      });
    return names;
  }

  Future<List<Offer>> _matchingOffers(String query) async {
    final offers = _offers;
    if (offers == null || query.length < 2) return const [];
    try {
      final page = await offers.search(OfferQuery(text: query));
      return page.items.take(maxOffers).toList();
    } catch (_) {
      // Offers come from another service; without them the history remains.
      return const [];
    }
  }
}

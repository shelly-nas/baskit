import 'baskit_api_client.dart';

/// Items the signed-in user added before, from the Baskit server
/// (`GET /api/items/suggestions`): names containing the text, the ones
/// starting with it and the most added first.
class ItemSuggestionDataSource {
  final BaskitApiClient _api;

  ItemSuggestionDataSource(this._api);

  Future<List<String>> suggest(String text, {int limit = 8}) async {
    final query = Uri(queryParameters: {'q': text, 'limit': '$limit'}).query;
    final json = await _api.get('items/suggestions?$query') as List<dynamic>;
    return [
      for (final row in json) (row as Map<String, dynamic>)['name'] as String,
    ];
  }
}

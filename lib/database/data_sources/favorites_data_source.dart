import 'dart:convert';

import '../../backend/models/favorite.dart';
import 'baskit_api_client.dart';
import 'key_value_store.dart';

/// The user's favorites on the Baskit server (`/api/favorites`). The last
/// list fetched is kept on the device, so the favorites can be put on a list
/// without a connection; adding or removing one needs the server.
class FavoritesDataSource {
  static const String cacheKey = 'baskit.favorites.v1';

  final BaskitApiClient _api;
  final KeyValueStore _store;

  FavoritesDataSource(this._api, this._store);

  /// From the server, or the copy on the device when it cannot be reached.
  Future<List<Favorite>> getAll() async {
    try {
      final json = await _api.get('favorites') as List<dynamic>;
      await _store.write(cacheKey, jsonEncode(json));
      return _parse(json);
    } on BaskitApiException catch (e) {
      if (e.status != 0 && e.status < 500) rethrow;
      final kept = await _store.read(cacheKey);
      if (kept == null) rethrow;
      return _parse(jsonDecode(kept) as List<dynamic>);
    }
  }

  Future<Favorite> add(Favorite favorite) async => Favorite.fromJson(
    await _api.post('favorites', favorite.toJson()) as Map<String, dynamic>,
  );

  Future<void> remove(String id) => _api.delete('favorites/$id');

  /// Updates the copy on the device after a change the server accepted.
  Future<void> keep(List<Favorite> favorites) => _store.write(
    cacheKey,
    jsonEncode([for (final favorite in favorites) favorite.toJson()]),
  );

  Future<void> clear() => _store.delete(cacheKey);

  static List<Favorite> _parse(List<dynamic> json) => [
    for (final row in json) Favorite.fromJson(row as Map<String, dynamic>),
  ];
}

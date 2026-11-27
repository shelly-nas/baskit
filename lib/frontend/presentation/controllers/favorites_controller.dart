import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../backend/models/favorite.dart';
import '../../../backend/services/favorite_deals_service.dart';
import '../../../database/data_sources/baskit_api_client.dart';
import '../../../database/data_sources/favorites_data_source.dart';

/// The signed-in user's favorites, for the list screen and the profile.
/// Loaded on sign-in, cleared on sign-out ([AuthController]). Failures are
/// reported through [onMessage] (a snack bar), not thrown.
class FavoritesController extends ChangeNotifier {
  static const _uuid = Uuid();

  final FavoritesDataSource _source;
  final FavoriteDealsService? _dealsService;
  final void Function(String message)? onMessage;

  FavoritesController(
    this._source, {
    this.onMessage,
    FavoriteDealsService? deals,
  }) : _dealsService = deals;

  List<Favorite> _favorites = [];
  List<FavoriteDeal> _deals = [];

  List<Favorite> get favorites => List.unmodifiable(_favorites);

  /// Favorites on offer right now (FR-010); fetched after the favorites, in
  /// the background.
  List<FavoriteDeal> get deals => List.unmodifiable(_deals);

  FavoriteDeal? dealFor(String favoriteId) {
    for (final deal in _deals) {
      if (deal.favorite.id == favoriteId) return deal;
    }
    return null;
  }

  /// Looks up the offers for the favorites again (cached by the service).
  Future<void> refreshDeals() async {
    final service = _dealsService;
    if (service == null) return;
    _deals = await service.dealsFor(_favorites);
    notifyListeners();
  }

  /// The favorite with this name, in any case.
  Favorite? byName(String name) {
    final key = name.trim().toLowerCase();
    for (final favorite in _favorites) {
      if (favorite.name.toLowerCase() == key) return favorite;
    }
    return null;
  }

  Future<void> load() => _guard(() async {
    _favorites = await _source.getAll();
    unawaited(refreshDeals());
  });

  Future<void> add(String name, {String? quantity}) => _guard(() async {
    final added = await _source.add(
      Favorite(id: _uuid.v4(), name: name.trim(), quantity: quantity),
    );
    _favorites = [..._favorites, added]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    await _source.keep(_favorites);
    unawaited(refreshDeals());
  });

  Future<void> remove(String id) => _guard(() async {
    await _source.remove(id);
    _favorites = _favorites.where((f) => f.id != id).toList();
    _deals = _deals.where((d) => d.favorite.id != id).toList();
    await _source.keep(_favorites);
  });

  /// Forgets the favorites of the previous account, also on this device.
  Future<void> reset() async {
    _favorites = [];
    _deals = [];
    notifyListeners();
    await _source.clear();
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on BaskitApiException catch (e) {
      onMessage?.call(e.message);
    }
    notifyListeners();
  }
}

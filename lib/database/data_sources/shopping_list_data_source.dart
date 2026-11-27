import 'dart:convert';

import '../models/shopping_list_entity.dart';
import 'key_value_store.dart';

/// Abstract data source for shopping lists
/// Defines the contract for data operations (local or remote)
abstract class ShoppingListDataSource {
  /// Get all shopping lists
  Future<List<ShoppingListEntity>> getAllLists();

  /// Get a specific shopping list by ID
  Future<ShoppingListEntity?> getListById(String id);

  /// Create a new shopping list
  Future<ShoppingListEntity> createList(ShoppingListEntity list);

  /// Update an existing shopping list
  Future<ShoppingListEntity> updateList(ShoppingListEntity list);

  /// Delete a shopping list
  Future<void> deleteList(String id);

  /// Add an item to a shopping list
  Future<ListItemEntity> addItem(String listId, ListItemEntity item);

  /// Update an item in a shopping list
  Future<ListItemEntity> updateItem(String listId, ListItemEntity item);

  /// Delete an item from a shopping list
  Future<void> deleteItem(String listId, String itemId);
}

/// Data source that keeps all lists as JSON in a [KeyValueStore].
///
/// The app uses it as the device copy of the server lists
/// ([OfflineShoppingListDataSource]); tests also use it as a list backend
/// without a server. Every change writes the full set of lists, which is fine
/// for the size of a household's shopping lists.
class LocalShoppingListDataSource implements ShoppingListDataSource {
  static const String defaultKey = 'baskit.shopping_lists.v1';

  final KeyValueStore _store;
  final String _key;
  List<ShoppingListEntity>? _cache;

  LocalShoppingListDataSource(this._store, {String key = defaultKey})
    : _key = key;

  /// Replaces all lists, e.g. with the latest copy from the server.
  Future<void> replaceAll(List<ShoppingListEntity> lists) => _save(lists);

  Future<void> clear() async {
    _cache = [];
    await _store.delete(_key);
  }

  Future<List<ShoppingListEntity>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await _store.read(_key);
    if (raw == null || raw.isEmpty) {
      _cache = [];
    } else {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _cache = decoded
          .map((e) => ShoppingListEntity.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return _cache!;
  }

  Future<void> _save(List<ShoppingListEntity> lists) async {
    _cache = lists;
    await _store.write(
      _key,
      jsonEncode(lists.map((list) => list.toJson()).toList()),
    );
  }

  Future<ShoppingListEntity> _requireList(String id) async {
    final lists = await _load();
    return lists.firstWhere(
      (list) => list.id == id,
      orElse: () => throw StateError('List $id not found'),
    );
  }

  Future<void> _replaceList(ShoppingListEntity updated) async {
    final lists = await _load();
    await _save([
      for (final list in lists) list.id == updated.id ? updated : list,
    ]);
  }

  @override
  Future<List<ShoppingListEntity>> getAllLists() async {
    final lists = await _load();
    return List.unmodifiable(lists);
  }

  @override
  Future<ShoppingListEntity?> getListById(String id) async {
    final lists = await _load();
    for (final list in lists) {
      if (list.id == id) return list;
    }
    return null;
  }

  @override
  Future<ShoppingListEntity> createList(ShoppingListEntity list) async {
    final lists = await _load();
    await _save([...lists, list]);
    return list;
  }

  @override
  Future<ShoppingListEntity> updateList(ShoppingListEntity list) async {
    await _requireList(list.id);
    await _replaceList(list);
    return list;
  }

  @override
  Future<void> deleteList(String id) async {
    final lists = await _load();
    await _save(lists.where((list) => list.id != id).toList());
  }

  @override
  Future<ListItemEntity> addItem(String listId, ListItemEntity item) async {
    final list = await _requireList(listId);
    await _replaceList(
      list.copyWith(items: [...list.items, item], updatedAt: DateTime.now()),
    );
    return item;
  }

  @override
  Future<ListItemEntity> updateItem(String listId, ListItemEntity item) async {
    final list = await _requireList(listId);
    if (!list.items.any((i) => i.id == item.id)) {
      throw StateError('Item ${item.id} not found');
    }
    await _replaceList(
      list.copyWith(
        items: [for (final i in list.items) i.id == item.id ? item : i],
        updatedAt: DateTime.now(),
      ),
    );
    return item;
  }

  @override
  Future<void> deleteItem(String listId, String itemId) async {
    final list = await _requireList(listId);
    await _replaceList(
      list.copyWith(
        items: list.items.where((i) => i.id != itemId).toList(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}

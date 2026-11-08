import '../models/shopping_list_entity.dart';
import 'baskit_api_client.dart';
import 'shopping_list_data_source.dart';

/// Lists stored on the Baskit server, for signed-in users. Lists shared with
/// the user are included.
class RemoteShoppingListDataSource implements ShoppingListDataSource {
  final BaskitApiClient _api;

  RemoteShoppingListDataSource(this._api);

  static ShoppingListEntity _list(dynamic json) =>
      ShoppingListEntity.fromJson(json as Map<String, dynamic>);

  static ListItemEntity _item(dynamic json) =>
      ListItemEntity.fromJson(json as Map<String, dynamic>);

  @override
  Future<List<ShoppingListEntity>> getAllLists() async {
    final json = await _api.get('lists') as List<dynamic>;
    return json.map(_list).toList();
  }

  @override
  Future<ShoppingListEntity?> getListById(String id) async {
    try {
      return _list(await _api.get('lists/$id'));
    } on BaskitApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  @override
  Future<ShoppingListEntity> createList(ShoppingListEntity list) async =>
      _list(await _api.post('lists', {'id': list.id, 'name': list.name}));

  @override
  Future<ShoppingListEntity> updateList(ShoppingListEntity list) async =>
      _list(await _api.patch('lists/${list.id}', {'name': list.name}));

  @override
  Future<void> deleteList(String id) => _api.delete('lists/$id');

  @override
  Future<ListItemEntity> addItem(String listId, ListItemEntity item) async =>
      _item(await _api.post('lists/$listId/items', item.toJson()));

  @override
  Future<ListItemEntity> updateItem(String listId, ListItemEntity item) async {
    final json = item.toJson()
      ..remove('id')
      ..remove('created_at');
    return _item(await _api.patch('lists/$listId/items/${item.id}', json));
  }

  @override
  Future<void> deleteItem(String listId, String itemId) =>
      _api.delete('lists/$listId/items/$itemId');

  // ---- Sharing ----

  Future<void> addMember(String listId, String email) =>
      _api.post('lists/$listId/members', {'email': email});

  /// Removes a member; pass "me" to leave a list shared with you.
  Future<void> removeMember(String listId, String memberId) =>
      _api.delete('lists/$listId/members/$memberId');
}

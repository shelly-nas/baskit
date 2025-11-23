import '../models/shopping_list_entity.dart';

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

/// Local data source implementation (mock for now)
/// In production, this would interact with SQLite, Hive, or similar
class LocalShoppingListDataSource implements ShoppingListDataSource {
  // Mock in-memory storage
  final List<ShoppingListEntity> _lists = [];

  LocalShoppingListDataSource();

  @override
  Future<List<ShoppingListEntity>> getAllLists() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_lists);
  }

  @override
  Future<ShoppingListEntity?> getListById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _lists.firstWhere((list) => list.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ShoppingListEntity> createList(ShoppingListEntity list) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _lists.add(list);
    return list;
  }

  @override
  Future<ShoppingListEntity> updateList(ShoppingListEntity list) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _lists.indexWhere((l) => l.id == list.id);
    if (index != -1) {
      _lists[index] = list;
      return list;
    }
    throw Exception('List not found');
  }

  @override
  Future<void> deleteList(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _lists.removeWhere((list) => list.id == id);
  }

  @override
  Future<ListItemEntity> addItem(String listId, ListItemEntity item) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final listIndex = _lists.indexWhere((list) => list.id == listId);
    if (listIndex != -1) {
      final updatedItems = [..._lists[listIndex].items, item];
      _lists[listIndex] = _lists[listIndex].copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
      return item;
    }
    throw Exception('List not found');
  }

  @override
  Future<ListItemEntity> updateItem(String listId, ListItemEntity item) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final listIndex = _lists.indexWhere((list) => list.id == listId);
    if (listIndex != -1) {
      final items = _lists[listIndex].items;
      final itemIndex = items.indexWhere((i) => i.id == item.id);
      if (itemIndex != -1) {
        items[itemIndex] = item;
        _lists[listIndex] = _lists[listIndex].copyWith(
          items: items,
          updatedAt: DateTime.now(),
        );
        return item;
      }
    }
    throw Exception('Item not found');
  }

  @override
  Future<void> deleteItem(String listId, String itemId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final listIndex = _lists.indexWhere((list) => list.id == listId);
    if (listIndex != -1) {
      final updatedItems = _lists[listIndex].items
          .where((item) => item.id != itemId)
          .toList();
      _lists[listIndex] = _lists[listIndex].copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );
    }
  }
}

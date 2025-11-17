import '../../backend/models/shopping_list.dart';
import '../data_sources/shopping_list_data_source.dart';
import '../mappers/shopping_list_mapper.dart';

/// Shopping List Repository
/// Abstracts data access and provides domain models to the business logic layer
class ShoppingListRepository {
  final ShoppingListDataSource _dataSource;

  ShoppingListRepository(this._dataSource);

  /// Get all shopping lists
  Future<List<ShoppingList>> getAllLists() async {
    try {
      final entities = await _dataSource.getAllLists();
      return ShoppingListMapper.toDomainList(entities);
    } catch (e) {
      throw RepositoryException('Failed to fetch shopping lists: $e');
    }
  }

  /// Get a specific shopping list by ID
  Future<ShoppingList?> getListById(String id) async {
    try {
      final entity = await _dataSource.getListById(id);
      if (entity == null) return null;
      return ShoppingListMapper.toDomain(entity);
    } catch (e) {
      throw RepositoryException('Failed to fetch shopping list: $e');
    }
  }

  /// Create a new shopping list
  Future<ShoppingList> createList(ShoppingList list) async {
    try {
      final entity = ShoppingListMapper.toEntity(list);
      final created = await _dataSource.createList(entity);
      return ShoppingListMapper.toDomain(created);
    } catch (e) {
      throw RepositoryException('Failed to create shopping list: $e');
    }
  }

  /// Update an existing shopping list
  Future<ShoppingList> updateList(ShoppingList list) async {
    try {
      final entity = ShoppingListMapper.toEntity(list);
      final updated = await _dataSource.updateList(entity);
      return ShoppingListMapper.toDomain(updated);
    } catch (e) {
      throw RepositoryException('Failed to update shopping list: $e');
    }
  }

  /// Delete a shopping list
  Future<void> deleteList(String id) async {
    try {
      await _dataSource.deleteList(id);
    } catch (e) {
      throw RepositoryException('Failed to delete shopping list: $e');
    }
  }

  /// Add an item to a shopping list
  Future<ListItem> addItem(String listId, ListItem item) async {
    try {
      final entity = ListItemMapper.toEntity(item);
      final created = await _dataSource.addItem(listId, entity);
      return ListItemMapper.toDomain(created);
    } catch (e) {
      throw RepositoryException('Failed to add item: $e');
    }
  }

  /// Update an item in a shopping list
  Future<ListItem> updateItem(String listId, ListItem item) async {
    try {
      final entity = ListItemMapper.toEntity(item);
      final updated = await _dataSource.updateItem(listId, entity);
      return ListItemMapper.toDomain(updated);
    } catch (e) {
      throw RepositoryException('Failed to update item: $e');
    }
  }

  /// Delete an item from a shopping list
  Future<void> deleteItem(String listId, String itemId) async {
    try {
      await _dataSource.deleteItem(listId, itemId);
    } catch (e) {
      throw RepositoryException('Failed to delete item: $e');
    }
  }

  /// Toggle item completion status
  Future<ListItem> toggleItemCompletion(String listId, ListItem item) async {
    final toggled = item.toggleCompleted();
    return await updateItem(listId, toggled);
  }
}

/// Repository exception
class RepositoryException implements Exception {
  final String message;

  RepositoryException(this.message);

  @override
  String toString() => 'RepositoryException: $message';
}

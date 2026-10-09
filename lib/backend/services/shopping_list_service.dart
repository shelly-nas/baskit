import '../models/shopping_list.dart';
import '../use_cases/shopping_list_use_cases.dart';

/// Shopping List Service
/// Orchestrates business logic and use cases
class ShoppingListService {
  final GetAllListsUseCase _getAllListsUseCase;
  final GetListByIdUseCase _getListByIdUseCase;
  final CreateListUseCase _createListUseCase;
  final UpdateListUseCase _updateListUseCase;
  final DeleteListUseCase _deleteListUseCase;
  final AddItemUseCase _addItemUseCase;
  final UpdateItemUseCase _updateItemUseCase;
  final DeleteItemUseCase _deleteItemUseCase;
  final ToggleItemCompletionUseCase _toggleItemCompletionUseCase;

  ShoppingListService({
    required GetAllListsUseCase getAllListsUseCase,
    required GetListByIdUseCase getListByIdUseCase,
    required CreateListUseCase createListUseCase,
    required UpdateListUseCase updateListUseCase,
    required DeleteListUseCase deleteListUseCase,
    required AddItemUseCase addItemUseCase,
    required UpdateItemUseCase updateItemUseCase,
    required DeleteItemUseCase deleteItemUseCase,
    required ToggleItemCompletionUseCase toggleItemCompletionUseCase,
  }) : _getAllListsUseCase = getAllListsUseCase,
       _getListByIdUseCase = getListByIdUseCase,
       _createListUseCase = createListUseCase,
       _updateListUseCase = updateListUseCase,
       _deleteListUseCase = deleteListUseCase,
       _addItemUseCase = addItemUseCase,
       _updateItemUseCase = updateItemUseCase,
       _deleteItemUseCase = deleteItemUseCase,
       _toggleItemCompletionUseCase = toggleItemCompletionUseCase;

  /// Get all shopping lists
  Future<List<ShoppingList>> getAllLists() async {
    return await _getAllListsUseCase.execute();
  }

  /// Get a shopping list by ID
  Future<ShoppingList?> getListById(String id) async {
    return await _getListByIdUseCase.execute(id);
  }

  /// Create a new shopping list
  Future<ShoppingList> createList({
    required String name,
    String? description,
    bool isShared = false,
  }) async {
    if (name.trim().isEmpty) {
      throw ServiceException('List name cannot be empty');
    }
    return await _createListUseCase.execute(
      name: name.trim(),
      description: description,
      isShared: isShared,
    );
  }

  /// Update a shopping list
  Future<ShoppingList> updateList(ShoppingList list) async {
    if (list.name.trim().isEmpty) {
      throw ServiceException('List name cannot be empty');
    }
    return await _updateListUseCase.execute(list);
  }

  /// Delete a shopping list
  Future<void> deleteList(String id) async {
    await _deleteListUseCase.execute(id);
  }

  /// Add an item to a shopping list
  Future<ListItem> addItem({
    required String listId,
    required String name,
    String? quantity,
    String? category,
    ListItemOffer? offer,
  }) async {
    if (name.trim().isEmpty) {
      throw ServiceException('Item name cannot be empty');
    }
    return await _addItemUseCase.execute(
      listId: listId,
      name: name.trim(),
      quantity: quantity,
      category: category,
      offer: offer,
    );
  }

  /// Update an item in a shopping list
  Future<ListItem> updateItem(String listId, ListItem item) async {
    if (item.name.trim().isEmpty) {
      throw ServiceException('Item name cannot be empty');
    }
    return await _updateItemUseCase.execute(listId, item);
  }

  /// Delete an item from a shopping list
  Future<void> deleteItem(String listId, String itemId) async {
    await _deleteItemUseCase.execute(listId, itemId);
  }

  /// Toggle item completion status
  Future<ListItem> toggleItemCompletion(String listId, ListItem item) async {
    return await _toggleItemCompletionUseCase.execute(listId, item);
  }

  /// Get lists filtered by completion status
  Future<List<ShoppingList>> getListsByCompletionStatus(
    bool isCompleted,
  ) async {
    final allLists = await getAllLists();
    return allLists.where((list) => list.isCompleted == isCompleted).toList();
  }

  /// Get shared lists
  Future<List<ShoppingList>> getSharedLists() async {
    final allLists = await getAllLists();
    return allLists.where((list) => list.isShared).toList();
  }

  /// Search lists by name
  Future<List<ShoppingList>> searchLists(String query) async {
    if (query.trim().isEmpty) {
      return await getAllLists();
    }

    final allLists = await getAllLists();
    final lowerQuery = query.toLowerCase();

    return allLists.where((list) {
      return list.name.toLowerCase().contains(lowerQuery) ||
          (list.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}

/// Service exception
class ServiceException implements Exception {
  final String message;

  ServiceException(this.message);

  @override
  String toString() => 'ServiceException: $message';
}

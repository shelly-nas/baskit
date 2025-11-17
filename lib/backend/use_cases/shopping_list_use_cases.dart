import '../models/shopping_list.dart';
import '../../database/repositories/shopping_list_repository.dart';

/// Use case for retrieving all shopping lists
class GetAllListsUseCase {
  final ShoppingListRepository _repository;

  GetAllListsUseCase(this._repository);

  Future<List<ShoppingList>> execute() async {
    return await _repository.getAllLists();
  }
}

/// Use case for retrieving a single shopping list by ID
class GetListByIdUseCase {
  final ShoppingListRepository _repository;

  GetListByIdUseCase(this._repository);

  Future<ShoppingList?> execute(String id) async {
    return await _repository.getListById(id);
  }
}

/// Use case for creating a new shopping list
class CreateListUseCase {
  final ShoppingListRepository _repository;

  CreateListUseCase(this._repository);

  Future<ShoppingList> execute({
    required String name,
    String? description,
    bool isShared = false,
  }) async {
    final now = DateTime.now();
    final newList = ShoppingList(
      id: DateTime.now().millisecondsSinceEpoch
          .toString(), // Simple ID generation
      name: name,
      description: description,
      isShared: isShared,
      createdAt: now,
      updatedAt: now,
      items: [],
    );

    return await _repository.createList(newList);
  }
}

/// Use case for updating a shopping list
class UpdateListUseCase {
  final ShoppingListRepository _repository;

  UpdateListUseCase(this._repository);

  Future<ShoppingList> execute(ShoppingList list) async {
    final updatedList = list.copyWith(updatedAt: DateTime.now());
    return await _repository.updateList(updatedList);
  }
}

/// Use case for deleting a shopping list
class DeleteListUseCase {
  final ShoppingListRepository _repository;

  DeleteListUseCase(this._repository);

  Future<void> execute(String id) async {
    await _repository.deleteList(id);
  }
}

/// Use case for adding an item to a shopping list
class AddItemUseCase {
  final ShoppingListRepository _repository;

  AddItemUseCase(this._repository);

  Future<ListItem> execute({
    required String listId,
    required String name,
    String? quantity,
    String? category,
  }) async {
    final newItem = ListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      quantity: quantity,
      category: category,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    return await _repository.addItem(listId, newItem);
  }
}

/// Use case for updating an item in a shopping list
class UpdateItemUseCase {
  final ShoppingListRepository _repository;

  UpdateItemUseCase(this._repository);

  Future<ListItem> execute(String listId, ListItem item) async {
    return await _repository.updateItem(listId, item);
  }
}

/// Use case for deleting an item from a shopping list
class DeleteItemUseCase {
  final ShoppingListRepository _repository;

  DeleteItemUseCase(this._repository);

  Future<void> execute(String listId, String itemId) async {
    await _repository.deleteItem(listId, itemId);
  }
}

/// Use case for toggling item completion status
class ToggleItemCompletionUseCase {
  final ShoppingListRepository _repository;

  ToggleItemCompletionUseCase(this._repository);

  Future<ListItem> execute(String listId, ListItem item) async {
    return await _repository.toggleItemCompletion(listId, item);
  }
}

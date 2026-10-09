import 'package:baskit/backend/services/shopping_list_service.dart';
import 'package:baskit/backend/use_cases/shopping_list_use_cases.dart';
import 'package:baskit/database/data_sources/key_value_store.dart';
import 'package:baskit/database/data_sources/shopping_list_data_source.dart';
import 'package:baskit/database/repositories/shopping_list_repository.dart';
import 'package:baskit/frontend/presentation/controllers/shopping_list_controller.dart';

/// Shopping list stack backed by an in-memory store.
ShoppingListService createShoppingListService([KeyValueStore? store]) {
  final repository = ShoppingListRepository(
    LocalShoppingListDataSource(store ?? InMemoryStore()),
  );
  return ShoppingListService(
    getAllListsUseCase: GetAllListsUseCase(repository),
    getListByIdUseCase: GetListByIdUseCase(repository),
    createListUseCase: CreateListUseCase(repository),
    updateListUseCase: UpdateListUseCase(repository),
    deleteListUseCase: DeleteListUseCase(repository),
    addItemUseCase: AddItemUseCase(repository),
    updateItemUseCase: UpdateItemUseCase(repository),
    deleteItemUseCase: DeleteItemUseCase(repository),
    toggleItemCompletionUseCase: ToggleItemCompletionUseCase(repository),
  );
}

ShoppingListController createShoppingListController([KeyValueStore? store]) =>
    ShoppingListController(createShoppingListService(store));

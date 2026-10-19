import 'package:baskit/backend/services/shopping_list_service.dart';
import 'package:baskit/database/data_sources/key_value_store.dart';
import 'package:baskit/database/data_sources/shopping_list_data_source.dart';
import 'package:baskit/di/dependency_injection.dart';
import 'package:baskit/frontend/presentation/controllers/shopping_list_controller.dart';

/// Shopping list stack backed by an in-memory store.
ShoppingListService createShoppingListService([KeyValueStore? store]) =>
    buildShoppingListService(
      LocalShoppingListDataSource(store ?? InMemoryStore()),
    );

ShoppingListController createShoppingListController([KeyValueStore? store]) =>
    ShoppingListController(createShoppingListService(store));

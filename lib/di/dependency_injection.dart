import '../database/data_sources/key_value_store.dart';
import '../database/data_sources/shopping_list_data_source.dart';
import '../database/repositories/shopping_list_repository.dart';
import '../backend/use_cases/shopping_list_use_cases.dart';
import '../backend/services/shopping_list_service.dart';
import '../backend/services/offer_search_service.dart';
import '../config/app_config.dart';
import '../database/data_sources/discount_api_data_source.dart';
import '../database/repositories/offer_repository.dart';

/// Dependency Injection Container
/// Sets up and provides all dependencies for the application
class DependencyInjection {
  static final DependencyInjection _instance = DependencyInjection._internal();

  factory DependencyInjection() {
    return _instance;
  }

  DependencyInjection._internal();

  // Data Layer
  late final ShoppingListDataSource _dataSource;
  late final ShoppingListRepository _repository;

  // Business Logic Layer
  late final GetAllListsUseCase _getAllListsUseCase;
  late final GetListByIdUseCase _getListByIdUseCase;
  late final CreateListUseCase _createListUseCase;
  late final UpdateListUseCase _updateListUseCase;
  late final DeleteListUseCase _deleteListUseCase;
  late final AddItemUseCase _addItemUseCase;
  late final UpdateItemUseCase _updateItemUseCase;
  late final DeleteItemUseCase _deleteItemUseCase;
  late final ToggleItemCompletionUseCase _toggleItemCompletionUseCase;

  // Services
  late final ShoppingListService _shoppingListService;
  late final OfferSearchService _offerSearchService;

  /// Initialize all dependencies
  ///
  /// [store] defaults to device storage; tests pass an [InMemoryStore].
  void initialize({KeyValueStore? store}) {
    // Initialize data layer
    _dataSource = LocalShoppingListDataSource(
      store ?? SharedPreferencesStore(),
    );
    _repository = ShoppingListRepository(_dataSource);

    // Initialize use cases
    _getAllListsUseCase = GetAllListsUseCase(_repository);
    _getListByIdUseCase = GetListByIdUseCase(_repository);
    _createListUseCase = CreateListUseCase(_repository);
    _updateListUseCase = UpdateListUseCase(_repository);
    _deleteListUseCase = DeleteListUseCase(_repository);
    _addItemUseCase = AddItemUseCase(_repository);
    _updateItemUseCase = UpdateItemUseCase(_repository);
    _deleteItemUseCase = DeleteItemUseCase(_repository);
    _toggleItemCompletionUseCase = ToggleItemCompletionUseCase(_repository);

    // Initialize services
    _shoppingListService = ShoppingListService(
      getAllListsUseCase: _getAllListsUseCase,
      getListByIdUseCase: _getListByIdUseCase,
      createListUseCase: _createListUseCase,
      updateListUseCase: _updateListUseCase,
      deleteListUseCase: _deleteListUseCase,
      addItemUseCase: _addItemUseCase,
      updateItemUseCase: _updateItemUseCase,
      deleteItemUseCase: _deleteItemUseCase,
      toggleItemCompletionUseCase: _toggleItemCompletionUseCase,
    );

    // Offers come from the discount-scraper public API
    _offerSearchService = OfferSearchService(
      ApiOfferRepository(
        DiscountApiDataSource(baseUri: AppConfig.discountApiBaseUri),
      ),
    );
  }

  // Getters for services
  ShoppingListService get shoppingListService => _shoppingListService;
  OfferSearchService get offerSearchService => _offerSearchService;

  // You can add getters for other dependencies if needed directly
  ShoppingListRepository get repository => _repository;
}

import '../backend/services/offer_search_service.dart';
import '../backend/services/price_comparison_service.dart';
import '../backend/services/shopping_list_service.dart';
import '../backend/use_cases/shopping_list_use_cases.dart';
import '../config/app_config.dart';
import '../database/data_sources/baskit_api_client.dart';
import '../database/data_sources/discount_api_data_source.dart';
import '../database/data_sources/key_value_store.dart';
import '../database/data_sources/remote_shopping_list_data_source.dart';
import '../database/data_sources/shopping_list_data_source.dart';
import '../database/repositories/auth_repository.dart';
import '../database/repositories/offer_repository.dart';
import '../database/repositories/shopping_list_repository.dart';
import '../frontend/presentation/controllers/auth_controller.dart';
import '../frontend/presentation/controllers/shopping_list_controller.dart';

/// Builds the shopping list service stack on top of a data source.
ShoppingListService buildShoppingListService(ShoppingListDataSource source) {
  final repository = ShoppingListRepository(source);
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

/// Wires data sources, repositories, services and controllers.
class AppDependencies {
  final OfferSearchService offerSearchService;
  final PriceComparisonService priceComparisonService;
  final ShoppingListController shoppingListController;
  final AuthController authController;

  AppDependencies._({
    required this.offerSearchService,
    required this.priceComparisonService,
    required this.shoppingListController,
    required this.authController,
  });

  /// [store] defaults to device storage; tests pass an [InMemoryStore].
  factory AppDependencies.create({
    KeyValueStore? store,
    BaskitApiClient? baskitApi,
    OfferRepository? offerRepository,
  }) {
    final storage = store ?? SharedPreferencesStore();

    // Offers and prices come from the supermarket-scraper public API.
    final offers =
        offerRepository ??
        ApiOfferRepository(
          DiscountApiDataSource(baseUri: AppConfig.discountApiBaseUri),
        );

    // Lists: on the device when signed out, on the Baskit server when signed in.
    final api =
        baskitApi ?? BaskitApiClient(baseUri: AppConfig.baskitApiBaseUri);
    final deviceStore = LocalShoppingListDataSource(storage);
    final accountStore = RemoteShoppingListDataSource(api);
    final deviceService = buildShoppingListService(deviceStore);
    final lists = ShoppingListController(deviceService);

    return AppDependencies._(
      offerSearchService: OfferSearchService(offers),
      priceComparisonService: PriceComparisonService(offers),
      shoppingListController: lists,
      authController: AuthController(
        repository: AuthRepository(api, storage),
        lists: lists,
        deviceService: deviceService,
        deviceStore: deviceStore,
        accountService: buildShoppingListService(accountStore),
        accountStore: accountStore,
      ),
    );
  }
}

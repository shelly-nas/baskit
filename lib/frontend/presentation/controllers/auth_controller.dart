import 'package:flutter/foundation.dart';

import '../../../backend/models/shopping_list.dart';
import '../../../backend/models/user_account.dart';
import '../../../backend/services/shopping_list_service.dart';
import '../../../database/data_sources/baskit_api_client.dart';
import '../../../database/data_sources/remote_shopping_list_data_source.dart';
import '../../../database/data_sources/shopping_list_data_source.dart';
import '../../../database/mappers/shopping_list_mapper.dart';
import '../../../database/repositories/auth_repository.dart';
import 'shopping_list_controller.dart';

/// The signed-in account, and which lists the app shows.
///
/// Signed out, lists live on the device. Signing in uploads those lists to the
/// account (once) and switches to the lists on the server, including lists
/// shared with the user. Signing out switches back to the (now empty) device.
class AuthController extends ChangeNotifier {
  final AuthRepository _repository;
  final ShoppingListController _lists;
  final ShoppingListService _deviceService;
  final ShoppingListDataSource _deviceStore;
  final ShoppingListService _accountService;
  final RemoteShoppingListDataSource _accountStore;

  AuthController({
    required AuthRepository repository,
    required ShoppingListController lists,
    required ShoppingListService deviceService,
    required ShoppingListDataSource deviceStore,
    required ShoppingListService accountService,
    required RemoteShoppingListDataSource accountStore,
  }) : _repository = repository,
       _lists = lists,
       _deviceService = deviceService,
       _deviceStore = deviceStore,
       _accountService = accountService,
       _accountStore = accountStore;

  UserAccount? _user;
  bool _isBusy = false;

  UserAccount? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isBusy => _isBusy;

  /// Restores the stored session on app start.
  Future<void> restore() async {
    try {
      final user = await _repository.restore();
      if (user != null) await _enterAccount(user);
    } on BaskitApiException {
      // Offline or expired: continue signed out with the device lists.
    }
  }

  /// Throws [BaskitApiException] with a message for the user on failure.
  Future<void> signIn(String email, String password) => _busy(
    () async => _enterAccount(await _repository.signIn(email, password)),
  );

  Future<void> register(String email, String password, String displayName) =>
      _busy(
        () async => _enterAccount(
          await _repository.register(email, password, displayName),
        ),
      );

  Future<void> signOut() => _busy(() async {
    await _repository.signOut();
    _user = null;
    notifyListeners();
    await _lists.useService(_deviceService);
  });

  Future<void> updateProfile({
    String? displayName,
    String? currentPassword,
    String? newPassword,
  }) => _busy(() async {
    _user = await _repository.updateProfile(
      displayName: displayName,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  });

  AuthRepository get repository => _repository;

  Future<void> _enterAccount(UserAccount user) async {
    _user = user;
    notifyListeners();
    await _uploadDeviceLists();
    await _lists.useService(_accountService, remote: _accountStore);
  }

  /// Moves lists made while signed out into the account. They are only
  /// removed from the device after the upload succeeded.
  Future<void> _uploadDeviceLists() async {
    final deviceLists = await _deviceStore.getAllLists();
    if (deviceLists.isEmpty) return;
    try {
      await _accountStore.importLists(deviceLists);
      for (final list in deviceLists) {
        await _deviceStore.deleteList(list.id);
      }
      final names = deviceLists
          .map((l) => ShoppingListMapper.toDomain(l))
          .map((ShoppingList l) => l.name)
          .join(', ');
      _lists.messages.value = 'Moved to your account: $names';
    } on BaskitApiException catch (e) {
      _lists.messages.value =
          'Lists on this device were not uploaded: ${e.message}';
    }
  }

  Future<void> _busy(Future<void> Function() action) async {
    _isBusy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}

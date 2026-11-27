import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../backend/models/offer.dart';
import '../../../backend/models/shopping_list.dart';
import '../../../backend/services/shopping_list_service.dart';
import '../../../database/data_sources/key_value_store.dart';
import '../../../database/data_sources/offline_shopping_list_data_source.dart';
import '../../../database/data_sources/remote_shopping_list_data_source.dart';

/// Holds the user's shopping lists for the UI.
///
/// One instance is shared by the Lists tab and the Search tab, so an offer
/// added from search shows up in the list immediately. The lists live on the
/// Baskit server (own and shared); [AuthController] loads them after signing
/// in and calls [reset] when signing out.
class ShoppingListController extends ChangeNotifier {
  final ShoppingListService _service;
  final RemoteShoppingListDataSource? _remote;
  final OfflineShoppingListDataSource? _offline;

  /// [remote] enables sharing and [offline] the device copy of the lists;
  /// tests without a server leave them out.
  ShoppingListController(
    this._service, {
    RemoteShoppingListDataSource? remote,
    OfflineShoppingListDataSource? offline,
    KeyValueStore? preferences,
  }) : _remote = remote,
       _offline = offline,
       _preferences = preferences;

  final KeyValueStore? _preferences;

  /// Device preference: open items grouped by shop section (FR-006).
  static const String sortByLayoutKey = 'baskit.lists.sort_by_layout';

  bool _sortByLayout = true;

  /// Open items in the order of a walk through the shop (the default), or
  /// in the order they were added.
  bool get sortByLayout => _sortByLayout;

  Future<void> setSortByLayout(bool value) async {
    _sortByLayout = value;
    notifyListeners();
    await _preferences?.write(sortByLayoutKey, '$value');
  }

  static const ValueListenable<SyncStatus> _alwaysOnline =
      _ConstantSyncStatus();

  /// Offline, and how many changes wait to be sent; shown as a banner.
  ValueListenable<SyncStatus> get syncStatus =>
      _offline?.status ?? _alwaysOnline;

  List<ShoppingList> _lists = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  Timer? _autoRefresh;

  /// Counts changes made through this controller, so a background refresh
  /// that read the lists before a change can tell its answer is stale.
  int _changeCount = 0;
  bool _hasLoaded = false;
  String? _error;

  /// Short messages for the user (failed saves); shown as a snack bar.
  final ValueNotifier<String?> messages = ValueNotifier<String?>(null);

  List<ShoppingList> get lists => List.unmodifiable(_lists);
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  ShoppingList? listById(String id) {
    for (final list in _lists) {
      if (list.id == id) return list;
    }
    return null;
  }

  /// Forgets the lists of the previous account, also the copy and unsent
  /// changes on this device.
  Future<void> reset() async {
    stopAutoRefresh();
    _lists = [];
    _hasLoaded = false;
    _error = null;
    notifyListeners();
    await _offline?.clear();
  }

  /// Shows [message] in the snack bar (also for other controllers).
  void showMessage(String message) {
    messages.value = null;
    messages.value = message;
  }

  /// A change made offline that the server refused when it was sent (for
  /// example because the list was deleted meanwhile).
  void reportRejected(String reason) {
    messages.value = null;
    messages.value = 'A change was not saved: $reason';
  }

  Future<void> load() async {
    final sort = await _preferences?.read(sortByLayoutKey);
    if (sort != null) _sortByLayout = sort == 'true';
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _reload();
    } catch (e) {
      _error = 'Could not load your lists.';
    } finally {
      _isLoading = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }

  /// Fetches the lists again to pick up changes made elsewhere: on another
  /// device or by someone the list is shared with. Runs in the background, so
  /// it shows no loader; a failure keeps the last known lists without a
  /// message, as the next refresh tries again.
  Future<void> refresh() async {
    if (_isRefreshing || _isLoading || !_hasLoaded) return;
    _isRefreshing = true;
    final changesBefore = _changeCount;
    try {
      final lists = await _fetch();
      // A change saved meanwhile already reloaded newer lists.
      if (_changeCount != changesBefore) return;
      _lists = lists;
      notifyListeners();
    } catch (_) {
      // Offline or the server is busy: keep showing the last known lists.
    } finally {
      _isRefreshing = false;
    }
  }

  /// Calls [refresh] every [interval] until [stopAutoRefresh]. The app runs it
  /// while it is in the foreground, so shared lists stay current in the shop.
  void startAutoRefresh([Duration interval = const Duration(seconds: 10)]) {
    _autoRefresh?.cancel();
    _autoRefresh = Timer.periodic(interval, (_) => unawaited(refresh()));
  }

  void stopAutoRefresh() {
    _autoRefresh?.cancel();
    _autoRefresh = null;
  }

  /// Ensures the lists are loaded before they are needed (e.g. from search).
  Future<void> ensureLoaded() async {
    if (!_hasLoaded && !_isLoading) await load();
  }

  /// Returns the new list, or null when it could not be saved.
  Future<ShoppingList?> createList(String name) =>
      _guard(() => _service.createList(name: name));

  Future<void> renameList(String listId, String name) => _guard(() async {
    final list = listById(listId);
    if (list == null) return;
    await _service.updateList(list.copyWith(name: name.trim()));
  });

  Future<void> deleteList(String listId) =>
      _guard(() => _service.deleteList(listId));

  Future<void> addItem(String listId, String name, {String? quantity}) =>
      _guard(
        () => _service.addItem(listId: listId, name: name, quantity: quantity),
      );

  /// Adds a supermarket offer as an item, keeping a snapshot of the offer.
  Future<void> addOffer(String listId, Offer offer) => _guard(
    () => _service.addItem(
      listId: listId,
      name: offer.name,
      category: offer.category.isEmpty ? null : offer.category,
      offer: ListItemOffer(
        productId: offer.productId,
        supermarketKey: offer.supermarket.key,
        supermarketName: offer.supermarket.name,
        price: offer.price,
        originalPrice: offer.originalPrice,
        specialDiscount: offer.specialDiscount,
        expireDate: offer.expireDate,
      ),
    ),
  );

  Future<void> toggleItem(String listId, ListItem item) =>
      _guard(() => _service.toggleItemCompletion(listId, item));

  Future<void> updateItem(String listId, ListItem item) =>
      _guard(() => _service.updateItem(listId, item));

  Future<void> deleteItem(String listId, String itemId) =>
      _guard(() => _service.deleteItem(listId, itemId));

  Future<void> clearCompleted(String listId) => _guard(() async {
    final list = listById(listId);
    if (list == null) return;
    for (final item in list.completedItems) {
      await _service.deleteItem(listId, item.id);
    }
  });

  // ---- Sharing (synced lists only) ----

  /// Shares a list with another Baskit account. Returns false on failure;
  /// the reason is posted to [messages].
  Future<bool> shareList(String listId, String email) async =>
      await _guard(() async {
        await _requireRemote().addMember(listId, email.trim());
        return true;
      }) ??
      false;

  Future<void> removeMember(String listId, String memberId) =>
      _guard(() => _requireRemote().removeMember(listId, memberId));

  /// Stops seeing a list someone else shared.
  Future<void> leaveList(String listId) =>
      _guard(() => _requireRemote().removeMember(listId, 'me'));

  RemoteShoppingListDataSource _requireRemote() {
    final remote = _remote;
    if (remote == null) throw StateError('Sharing is not available');
    return remote;
  }

  /// Runs a change, reloads the lists and reports a failure to [messages]
  /// instead of throwing, so screens do not have to handle errors themselves.
  Future<T?> _guard<T>(Future<T> Function() action) async {
    _changeCount++;
    T? result;
    try {
      result = await action();
    } catch (e) {
      // Reset first so the same message twice still notifies.
      messages.value = null;
      messages.value = _describe(e);
    }
    try {
      await _reload();
    } catch (_) {
      // Keep showing the last known lists.
    }
    notifyListeners();
    return result;
  }

  static String _describe(Object error) {
    final text = error.toString();
    for (final prefix in ['ServiceException: ', 'RepositoryException: ']) {
      if (text.startsWith(prefix)) return text.substring(prefix.length);
    }
    if (error is StateError) return error.message;
    return text;
  }

  Future<void> _reload() async {
    _lists = await _fetch();
  }

  Future<List<ShoppingList>> _fetch() async {
    final lists = await _service.getAllLists();
    // Most recently changed first.
    lists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return lists;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    messages.dispose();
    super.dispose();
  }
}

class _ConstantSyncStatus implements ValueListenable<SyncStatus> {
  const _ConstantSyncStatus();

  @override
  SyncStatus get value => const SyncStatus();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

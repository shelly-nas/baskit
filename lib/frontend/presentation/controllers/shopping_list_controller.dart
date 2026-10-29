import 'package:flutter/foundation.dart';

import '../../../backend/models/offer.dart';
import '../../../backend/models/shopping_list.dart';
import '../../../backend/services/shopping_list_service.dart';
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

  /// [remote] enables sharing; tests without a server leave it out.
  ShoppingListController(this._service, {RemoteShoppingListDataSource? remote})
    : _remote = remote;

  List<ShoppingList> _lists = [];
  bool _isLoading = false;
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

  /// Forgets the lists of the previous account.
  void reset() {
    _lists = [];
    _hasLoaded = false;
    _error = null;
    notifyListeners();
  }

  Future<void> load() async {
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
        price: offer.discountPrice,
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
    final lists = await _service.getAllLists();
    // Most recently changed first.
    lists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _lists = lists;
  }

  @override
  void dispose() {
    messages.dispose();
    super.dispose();
  }
}

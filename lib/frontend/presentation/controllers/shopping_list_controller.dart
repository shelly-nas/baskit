import 'package:flutter/foundation.dart';

import '../../../backend/models/offer.dart';
import '../../../backend/models/shopping_list.dart';
import '../../../backend/services/shopping_list_service.dart';

/// Holds the user's shopping lists for the UI.
///
/// One instance is shared by the Lists tab and the Search tab, so an offer
/// added from search shows up in the list immediately.
class ShoppingListController extends ChangeNotifier {
  final ShoppingListService _service;

  ShoppingListController(this._service);

  List<ShoppingList> _lists = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;

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

  Future<ShoppingList> createList(String name) async {
    final list = await _service.createList(name: name);
    await _refresh();
    return list;
  }

  Future<void> renameList(String listId, String name) async {
    final list = listById(listId);
    if (list == null) return;
    await _service.updateList(list.copyWith(name: name.trim()));
    await _refresh();
  }

  Future<void> deleteList(String listId) async {
    await _service.deleteList(listId);
    await _refresh();
  }

  Future<void> addItem(String listId, String name, {String? quantity}) async {
    await _service.addItem(listId: listId, name: name, quantity: quantity);
    await _refresh();
  }

  /// Adds a supermarket offer as an item, keeping a snapshot of the offer.
  Future<void> addOffer(String listId, Offer offer) async {
    await _service.addItem(
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
    );
    await _refresh();
  }

  Future<void> toggleItem(String listId, ListItem item) async {
    await _service.toggleItemCompletion(listId, item);
    await _refresh();
  }

  Future<void> updateItem(String listId, ListItem item) async {
    await _service.updateItem(listId, item);
    await _refresh();
  }

  Future<void> deleteItem(String listId, String itemId) async {
    await _service.deleteItem(listId, itemId);
    await _refresh();
  }

  Future<void> clearCompleted(String listId) async {
    final list = listById(listId);
    if (list == null) return;
    for (final item in list.completedItems) {
      await _service.deleteItem(listId, item.id);
    }
    await _refresh();
  }

  Future<void> _reload() async {
    final lists = await _service.getAllLists();
    // Most recently changed first.
    lists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _lists = lists;
  }

  Future<void> _refresh() async {
    await _reload();
    notifyListeners();
  }
}

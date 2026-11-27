import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/shopping_list_entity.dart';
import 'baskit_api_client.dart';
import 'key_value_store.dart';
import 'shopping_list_data_source.dart';

/// Whether the server can be reached and how many changes wait to be sent.
@immutable
class SyncStatus {
  final bool isOffline;
  final int pending;

  const SyncStatus({this.isOffline = false, this.pending = 0});

  @override
  bool operator ==(Object other) =>
      other is SyncStatus &&
      other.isOffline == isOffline &&
      other.pending == pending;

  @override
  int get hashCode => Object.hash(isOffline, pending);
}

/// The server lists, usable without a connection (FR-007).
///
/// Every list fetched from the server is kept on the device. When the server
/// cannot be reached, lists are read from that copy and changes are applied
/// to it and queued (also on the device, so they survive a restart). The
/// queue is sent in order before the next fetch; list and item ids are made
/// on the device, and the server accepts a repeated create, so sending a
/// change twice is harmless. A queued change the server refuses (the list
/// was deleted meanwhile, access was removed) is dropped and reported through
/// [onRejected]; the rest still goes through.
class OfflineShoppingListDataSource implements ShoppingListDataSource {
  static const String cacheKey = 'baskit.lists.cache.v1';
  static const String outboxKey = 'baskit.lists.outbox.v1';

  final ShoppingListDataSource _remote;
  final KeyValueStore _store;
  final LocalShoppingListDataSource _copy;
  final void Function(String message)? onRejected;

  final ValueNotifier<SyncStatus> status = ValueNotifier(const SyncStatus());

  List<Map<String, dynamic>>? _outbox;

  /// Operations run one after another: the auto refresh and a change by the
  /// user must not send the same queued change twice. Null until the first
  /// operation, so no future is made before the app (or a test) runs.
  Future<void>? _previous;

  Future<T> _oneAtATime<T>(Future<T> Function() operation) {
    final previous = _previous;
    final result = previous == null
        ? operation()
        : previous.then((_) => operation());
    _previous = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  OfflineShoppingListDataSource(this._remote, this._store, {this.onRejected})
    : _copy = LocalShoppingListDataSource(_store, key: cacheKey);

  @override
  Future<List<ShoppingListEntity>> getAllLists() => _oneAtATime(_getAllLists);

  Future<List<ShoppingListEntity>> _getAllLists() async {
    if (await _sendQueued()) {
      try {
        final lists = await _remote.getAllLists();
        await _copy.replaceAll(lists);
        _setOffline(false);
        return lists;
      } on BaskitApiException catch (e) {
        if (!_isUnreachable(e)) rethrow;
        _setOffline(true);
      }
    }
    return _copy.getAllLists();
  }

  @override
  Future<ShoppingListEntity?> getListById(String id) =>
      _oneAtATime(() => _getListById(id));

  Future<ShoppingListEntity?> _getListById(String id) async {
    if ((await _queue()).isEmpty) {
      try {
        final list = await _remote.getListById(id);
        _setOffline(false);
        return list;
      } on BaskitApiException catch (e) {
        if (!_isUnreachable(e)) rethrow;
        _setOffline(true);
      }
    }
    return _copy.getListById(id);
  }

  @override
  Future<ShoppingListEntity> createList(ShoppingListEntity list) => _change(
    {'op': 'createList', 'list': list.toJson()},
    remote: () => _remote.createList(list),
    local: () => _copy.createList(list),
  );

  @override
  Future<ShoppingListEntity> updateList(ShoppingListEntity list) => _change(
    {'op': 'updateList', 'list': list.toJson()},
    remote: () => _remote.updateList(list),
    local: () => _copy.updateList(list),
  );

  @override
  Future<void> deleteList(String id) => _change(
    {'op': 'deleteList', 'listId': id},
    remote: () => _remote.deleteList(id),
    local: () => _copy.deleteList(id),
  );

  @override
  Future<ListItemEntity> addItem(String listId, ListItemEntity item) => _change(
    {'op': 'addItem', 'listId': listId, 'item': item.toJson()},
    remote: () => _remote.addItem(listId, item),
    local: () => _copy.addItem(listId, item),
  );

  @override
  Future<ListItemEntity> updateItem(String listId, ListItemEntity item) =>
      _change(
        {'op': 'updateItem', 'listId': listId, 'item': item.toJson()},
        remote: () => _remote.updateItem(listId, item),
        local: () => _copy.updateItem(listId, item),
      );

  @override
  Future<void> deleteItem(String listId, String itemId) => _change(
    {'op': 'deleteItem', 'listId': listId, 'itemId': itemId},
    remote: () => _remote.deleteItem(listId, itemId),
    local: () => _copy.deleteItem(listId, itemId),
  );

  /// Forgets the device copy and unsent changes; on sign-out, so the next
  /// account on this device starts clean.
  Future<void> clear() => _oneAtATime(_clear);

  Future<void> _clear() async {
    _outbox = [];
    await _store.delete(outboxKey);
    await _copy.clear();
    status.value = const SyncStatus();
  }

  /// Sends a change to the server, or, when it cannot be reached or earlier
  /// changes are still waiting, applies it to the device copy and queues it.
  Future<T> _change<T>(
    Map<String, dynamic> change, {
    required Future<T> Function() remote,
    required Future<T> Function() local,
  }) => _oneAtATime(() => _apply(change, remote: remote, local: local));

  Future<T> _apply<T>(
    Map<String, dynamic> change, {
    required Future<T> Function() remote,
    required Future<T> Function() local,
  }) async {
    if (await _sendQueued()) {
      try {
        final result = await remote();
        _setOffline(false);
        await _updateCopy(local);
        return result;
      } on BaskitApiException catch (e) {
        if (!_isUnreachable(e)) rethrow;
        _setOffline(true);
      }
    }
    final result = await local();
    final queue = await _queue();
    queue.add(change);
    await _saveQueue(queue);
    return result;
  }

  /// Keeps the device copy in step after a change the server accepted. The
  /// copy may not have the list yet (fetched before it was shared); the next
  /// fetch replaces the copy anyway.
  Future<void> _updateCopy(Future<Object?> Function() local) async {
    try {
      await local();
    } on StateError {
      // Not in the device copy yet.
    }
  }

  /// Sends the queued changes in order. Returns true when none are left.
  Future<bool> _sendQueued() async {
    final queue = await _queue();
    while (queue.isNotEmpty) {
      try {
        await _send(queue.first);
      } on BaskitApiException catch (e) {
        if (_isUnreachable(e)) {
          _setOffline(true);
          await _saveQueue(queue);
          return false;
        }
        onRejected?.call(e.message);
      }
      queue.removeAt(0);
      await _saveQueue(queue);
    }
    return true;
  }

  Future<void> _send(Map<String, dynamic> change) async {
    final listId = change['listId'] as String?;
    switch (change['op']) {
      case 'createList':
        await _remote.createList(_list(change));
      case 'updateList':
        await _remote.updateList(_list(change));
      case 'deleteList':
        await _remote.deleteList(listId!);
      case 'addItem':
        await _remote.addItem(listId!, _item(change));
      case 'updateItem':
        await _remote.updateItem(listId!, _item(change));
      case 'deleteItem':
        await _remote.deleteItem(listId!, change['itemId'] as String);
    }
  }

  static ShoppingListEntity _list(Map<String, dynamic> change) =>
      ShoppingListEntity.fromJson(change['list'] as Map<String, dynamic>);

  static ListItemEntity _item(Map<String, dynamic> change) =>
      ListItemEntity.fromJson(change['item'] as Map<String, dynamic>);

  /// No connection, or the server (or nginx in front of it) is down: worth
  /// trying again later. Other errors are answers from the server.
  static bool _isUnreachable(BaskitApiException e) =>
      e.status == 0 || e.status >= 500;

  Future<List<Map<String, dynamic>>> _queue() async {
    if (_outbox == null) {
      final raw = await _store.read(outboxKey);
      _outbox = raw == null || raw.isEmpty
          ? []
          : (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      _setPending(_outbox!.length);
    }
    return _outbox!;
  }

  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    _outbox = queue;
    if (queue.isEmpty) {
      await _store.delete(outboxKey);
    } else {
      await _store.write(outboxKey, jsonEncode(queue));
    }
    _setPending(queue.length);
  }

  void _setOffline(bool offline) => status.value = SyncStatus(
    isOffline: offline,
    pending: status.value.pending,
  );

  void _setPending(int pending) => status.value = SyncStatus(
    isOffline: status.value.isOffline,
    pending: pending,
  );
}

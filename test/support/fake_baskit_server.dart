import 'dart:async';
import 'dart:convert';

import 'package:baskit/database/data_sources/baskit_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Minimal in-memory stand-in for the Baskit server API, enough for the app's
/// auth and list flows.
class FakeBaskitServer {
  final Map<String, Map<String, dynamic>> users = {}; // email -> user
  final Map<String, String> passwords = {};
  final Map<String, Map<String, dynamic>> lists = {}; // id -> list json
  final List<String> requests = [];

  /// How often each item name was added (lower case), like the server's
  /// item history behind `GET items/suggestions`.
  final Map<String, int> history = {};
  final Map<String, String> _spelling = {};

  /// Favorites by id (all users together; tests use one account).
  final Map<String, Map<String, dynamic>> favorites = {};

  /// When true every request fails as if the server cannot be reached.
  bool offline = false;

  /// When set, the next `GET lists` takes its answer at once but only sends
  /// it when this completes, like a slow connection.
  Completer<void>? holdNextListsRead;

  BaskitApiClient client() => BaskitApiClient(
    baseUri: Uri.parse('https://baskit.test/api'),
    client: MockClient(_handle),
  );

  void addUser(String email, String name, {String role = 'user'}) {
    users[email] = {
      'id': 'user-${users.length + 1}',
      'email': email,
      'display_name': name,
      'role': role,
      'is_active': true,
      'created_at': '2026-01-01T00:00:00.000Z',
      'last_login_at': null,
    };
    passwords[email] = 'correct horse';
  }

  http.Response _json(Object? body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  Future<http.Response> _handle(http.Request request) async {
    final path = request.url.path.replaceFirst('/api/', '');
    requests.add('${request.method} $path');
    if (offline) throw http.ClientException('offline', request.url);
    final body = request.body.isEmpty ? null : jsonDecode(request.body);
    final token = request.headers['Authorization']?.replaceFirst('Bearer ', '');

    if (path == 'auth/login') {
      final email = body['email'] as String;
      if (passwords[email] != body['password']) {
        return _json({'error': 'Email or password is incorrect'}, 401);
      }
      return _json({'token': 'token-$email', 'user': users[email]});
    }
    if (path == 'auth/register') {
      final email = body['email'] as String;
      if (users.containsKey(email)) {
        return _json({
          'error': 'An account with this email already exists',
        }, 409);
      }
      addUser(email, body['displayName'] as String);
      return _json({'token': 'token-$email', 'user': users[email]}, 201);
    }

    final email = token?.replaceFirst('token-', '');
    if (email == null || !users.containsKey(email)) {
      return _json({'error': 'Sign in required'}, 401);
    }
    final me = users[email]!;

    if (path == 'auth/me' && request.method == 'DELETE') {
      if (passwords[email] != body['password']) {
        return _json({'error': 'Password is incorrect'}, 400);
      }
      users.remove(email);
      passwords.remove(email);
      return http.Response('', 204);
    }
    if (path == 'auth/me') return _json(me);
    if (path.startsWith('admin/') && me['role'] != 'admin') {
      return _json({'error': 'Admins only'}, 403);
    }
    if (path == 'admin/stats') {
      return _json({
        'users': users.length,
        'active_users': users.values
            .where((u) => u['is_active'] == true)
            .length,
        'users_last_30_days': users.length,
        'lists': lists.length,
        'shared_lists': lists.values
            .where((l) => l['is_shared'] == true)
            .length,
        'items': lists.values.fold<int>(
          0,
          (n, l) => n + (l['items'] as List).length,
        ),
      });
    }
    if (path == 'admin/users') {
      return _json([
        for (final user in users.values) {...user, 'list_count': 0},
      ]);
    }
    final adminUser = RegExp(r'^admin/users/(.+)$').firstMatch(path);
    if (adminUser != null && request.method == 'PATCH') {
      final user = users.values.firstWhere(
        (u) => u['id'] == adminUser.group(1),
      );
      if (body['role'] != null) user['role'] = body['role'];
      if (body['isActive'] != null) user['is_active'] = body['isActive'];
      return _json({...user, 'list_count': 0});
    }
    if (path == 'favorites' && request.method == 'GET') {
      final all = favorites.values.toList()
        ..sort(
          (a, b) => (a['name'] as String).toLowerCase().compareTo(
            (b['name'] as String).toLowerCase(),
          ),
        );
      return _json(all);
    }
    if (path == 'favorites' && request.method == 'POST') {
      final name = (body['name'] as String).trim();
      final same = favorites.values.where(
        (f) => (f['name'] as String).toLowerCase() == name.toLowerCase(),
      );
      if (same.isNotEmpty && same.first['id'] != body['id']) {
        return _json({
          'error': '${same.first['name']} is already a favorite',
        }, 409);
      }
      final favorite = favorites[body['id'] as String] = {
        'id': body['id'],
        'name': name,
        'quantity': body['quantity'],
        'created_at': '2026-11-01T00:00:00.000Z',
      };
      return _json(favorite, 201);
    }
    final favoriteMatch = RegExp(r'^favorites/(.+)$').firstMatch(path);
    if (favoriteMatch != null && request.method == 'DELETE') {
      favorites.remove(favoriteMatch.group(1));
      return http.Response('', 204);
    }
    if (path == 'items/suggestions') {
      final q = (request.url.queryParameters['q'] ?? '').toLowerCase();
      final matches = history.entries.where((e) => e.key.contains(q)).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return _json([
        for (final e in matches)
          {'name': _spelling[e.key], 'times_added': e.value},
      ]);
    }
    if (path == 'lists' && request.method == 'GET') {
      final answer = _json(lists.values.toList());
      final hold = holdNextListsRead;
      holdNextListsRead = null;
      if (hold != null) await hold.future;
      return answer;
    }
    if (path == 'lists' && request.method == 'POST') {
      final now = DateTime.now().toUtc().toIso8601String();
      final list = lists[body['id'] as String] = {
        'id': body['id'],
        'name': body['name'],
        'is_shared': false,
        'created_at': now,
        'updated_at': now,
        'items': <Map<String, dynamic>>[],
        'role': 'owner',
        'owner': {'id': me['id'], 'display_name': me['display_name']},
        'members': <Map<String, dynamic>>[],
      };
      return _json(list, 201);
    }
    final listMatch = RegExp(r'^lists/([^/]+)$').firstMatch(path);
    if (listMatch != null) {
      final list = lists[listMatch.group(1)];
      if (list == null) return _json({'error': 'List not found'}, 404);
      if (request.method == 'PATCH') list['name'] = body['name'];
      if (request.method == 'DELETE') {
        lists.remove(listMatch.group(1));
        return http.Response('', 204);
      }
      return _json(list);
    }
    final itemsMatch = RegExp(
      r'^lists/([^/]+)/items(?:/(.+))?$',
    ).firstMatch(path);
    if (itemsMatch != null) {
      final list = lists[itemsMatch.group(1)];
      if (list == null) return _json({'error': 'List not found'}, 404);
      final items = (list['items'] as List).cast<Map<String, dynamic>>();
      if (request.method == 'POST') {
        final item = Map<String, dynamic>.from(body as Map);
        if (!items.any((i) => i['id'] == item['id'])) {
          final name = (item['name'] as String).trim();
          final key = name.toLowerCase();
          history[key] = (history[key] ?? 0) + 1;
          _spelling[key] = name;
        }
        items.removeWhere((i) => i['id'] == item['id']);
        items.add(item);
        return _json(item, 201);
      }
      final index = items.indexWhere((i) => i['id'] == itemsMatch.group(2));
      if (index < 0) return _json({'error': 'Item not found'}, 404);
      if (request.method == 'DELETE') {
        items.removeAt(index);
        return http.Response('', 204);
      }
      items[index] = {...items[index], ...(body as Map<String, dynamic>)};
      return _json(items[index]);
    }
    final membersMatch = RegExp(
      r'^lists/([^/]+)/members(?:/(.+))?$',
    ).firstMatch(path);
    if (membersMatch != null) {
      final list = lists[membersMatch.group(1)]!;
      final members = (list['members'] as List).cast<Map<String, dynamic>>();
      if (request.method == 'POST') {
        final target = users[body['email']];
        if (target == null) {
          return _json({'error': 'No Baskit account with this email'}, 404);
        }
        members.add({
          'id': target['id'],
          'display_name': target['display_name'],
          'email': target['email'],
        });
        list['is_shared'] = true;
        return _json(list);
      }
      members.removeWhere((m) => m['id'] == membersMatch.group(2));
      return http.Response('', 204);
    }
    return _json({'error': 'Not found'}, 404);
  }
}

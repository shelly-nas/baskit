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
  String? currentEmail;

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

    if (path == 'auth/me') return _json(me);
    if (path == 'lists' && request.method == 'GET') {
      return _json(lists.values.toList());
    }
    if (path == 'lists/import') {
      for (final list in (body['lists'] as List)) {
        lists[list['id'] as String] = {
          ...(list as Map<String, dynamic>),
          'role': 'owner',
          'owner': {'id': me['id'], 'display_name': me['display_name']},
          'members': <Map<String, dynamic>>[],
        };
      }
      return _json({'imported': (body['lists'] as List).length});
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

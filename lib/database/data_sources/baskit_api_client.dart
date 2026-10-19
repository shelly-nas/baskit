import 'dart:convert';

import 'package:http/http.dart' as http;

/// HTTP client for the Baskit server (`/api`): JSON in and out, with the
/// signed-in user's token when there is one.
class BaskitApiClient {
  final Uri _baseUri;
  final http.Client _client;
  final Duration _timeout;

  /// Current sign-in token; set by the auth repository.
  String? token;

  BaskitApiClient({
    required Uri baseUri,
    http.Client? client,
    Duration timeout = const Duration(seconds: 15),
  }) : _baseUri = baseUri.path.endsWith('/')
           ? baseUri
           : baseUri.replace(path: '${baseUri.path}/'),
       _client = client ?? http.Client(),
       _timeout = timeout;

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body);
  Future<dynamic> patch(String path, [Object? body]) =>
      _send('PATCH', path, body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    final request = http.Request(method, _baseUri.resolve(path));
    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(_timeout),
      );
    } catch (e) {
      throw BaskitApiException(
        0,
        'Could not reach Baskit. Check your connection.',
      );
    }

    final text = utf8.decode(response.bodyBytes);
    final decoded = text.isEmpty ? null : _tryDecode(text);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final message = decoded is Map<String, dynamic>
        ? decoded['error'] as String?
        : null;
    throw BaskitApiException(
      response.statusCode,
      message ?? 'Something went wrong (${response.statusCode})',
    );
  }

  static dynamic _tryDecode(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }
}

class BaskitApiException implements Exception {
  /// HTTP status, 0 when the server could not be reached.
  final int status;
  final String message;

  BaskitApiException(this.status, this.message);

  bool get isUnauthorized => status == 401;

  @override
  String toString() => message;
}

import '../../backend/models/user_account.dart';
import '../data_sources/baskit_api_client.dart';
import '../data_sources/key_value_store.dart';

/// Signs in against the Baskit server and keeps the token on the device.
class AuthRepository {
  static const String tokenKey = 'baskit.auth.token';

  final BaskitApiClient _api;
  final KeyValueStore _store;

  AuthRepository(this._api, this._store);

  /// Restores a stored session. Returns null when there is none or when the
  /// server no longer accepts it.
  Future<UserAccount?> restore() async {
    final token = await _store.read(tokenKey);
    if (token == null) return null;
    _api.token = token;
    try {
      return UserAccount.fromJson(
        await _api.get('auth/me') as Map<String, dynamic>,
      );
    } on BaskitApiException catch (e) {
      if (e.isUnauthorized) await signOut();
      rethrow;
    }
  }

  Future<UserAccount> signIn(String email, String password) =>
      _authenticate('auth/login', {'email': email, 'password': password});

  Future<UserAccount> register(
    String email,
    String password,
    String displayName,
  ) => _authenticate('auth/register', {
    'email': email,
    'password': password,
    'displayName': displayName,
  });

  Future<UserAccount> _authenticate(
    String path,
    Map<String, String> body,
  ) async {
    final json = await _api.post(path, body) as Map<String, dynamic>;
    final token = json['token'] as String;
    _api.token = token;
    await _store.write(tokenKey, token);
    return UserAccount.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<UserAccount> updateProfile({
    String? displayName,
    String? currentPassword,
    String? newPassword,
  }) async {
    final json =
        await _api.patch('auth/me', {
              if (displayName != null) 'displayName': displayName,
              if (newPassword != null) 'currentPassword': currentPassword,
              if (newPassword != null) 'newPassword': newPassword,
            })
            as Map<String, dynamic>;
    return UserAccount.fromJson(json);
  }

  /// Deletes the account after the server checked [password].
  Future<void> deleteAccount(String password) async {
    await _api.delete('auth/me', {'password': password});
    await signOut();
  }

  Future<void> signOut() async {
    _api.token = null;
    await _store.delete(tokenKey);
  }

  // ---- Admin ----

  Future<List<UserAccount>> adminUsers() async {
    final json = await _api.get('admin/users') as List<dynamic>;
    return json
        .map((e) => UserAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserAccount> adminUpdateUser(
    String id, {
    String? role,
    bool? isActive,
  }) async {
    final json =
        await _api.patch('admin/users/$id', {
              if (role != null) 'role': role,
              if (isActive != null) 'isActive': isActive,
            })
            as Map<String, dynamic>;
    return UserAccount.fromJson(json);
  }

  Future<Map<String, int>> adminStats() async {
    final json = await _api.get('admin/stats') as Map<String, dynamic>;
    return json.map((key, value) => MapEntry(key, (value as num).toInt()));
  }
}

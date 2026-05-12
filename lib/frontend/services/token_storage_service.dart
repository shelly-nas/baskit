import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure token storage service
/// Persists JWT tokens and basic user info using platform secure storage
class TokenStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userDisplayNameKey = 'user_display_name';

  /// Save access and refresh tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  /// Read the stored access token
  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  /// Read the stored refresh token
  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  /// Save basic user info for quick access
  Future<void> saveUserInfo({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    await Future.wait([
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _userEmailKey, value: email),
      _storage.write(key: _userDisplayNameKey, value: displayName),
    ]);
  }

  /// Read stored user info — returns map with userId, email, displayName keys
  Future<Map<String, String?>> getUserInfo() async {
    final results = await Future.wait([
      _storage.read(key: _userIdKey),
      _storage.read(key: _userEmailKey),
      _storage.read(key: _userDisplayNameKey),
    ]);

    return {
      'userId': results[0],
      'email': results[1],
      'displayName': results[2],
    };
  }

  /// Clear all stored tokens and user info
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Returns true if an access token is present (session exists)
  Future<bool> hasValidSession() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }
}

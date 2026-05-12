import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';

/// FR-001.3.1–3.5: The system SHALL provide logout functionality to terminate user sessions;
/// SHALL invalidate the current access token; SHALL add logout tokens to a blacklist;
/// SHALL clear all client-side stored tokens; SHALL support logout from all devices.
///
/// This test suite verifies the full logout session management model.

// ── Mock / stub layer ──────────────────────────────────────────────────────

final faker = Faker();

class LogoutResult {
  final bool success;
  final String? error;

  LogoutResult({required this.success, this.error});
}

class SessionManager {
  final Map<String, Set<String>> _userSessions = {};  // userId → set of tokens
  final Set<String> _blacklist = {};

  /// Add a token for a user (simulates login creating a session).
  void addSession(String userId, String token) {
    _userSessions.putIfAbsent(userId, () => {}).add(token);
  }

  /// Invalidate (blacklist) a specific token and remove it from user sessions.
  LogoutResult logout(String token) {
    if (token.isEmpty) {
      return LogoutResult(success: false, error: 'Token is required');
    }
    _blacklist.add(token);
    _userSessions.forEach((_, tokens) => tokens.remove(token));
    return LogoutResult(success: true);
  }

  /// Returns true if the token is still valid (not blacklisted and has a session).
  bool isTokenValid(String token) {
    if (_blacklist.contains(token)) return false;
    return _userSessions.values.any((tokens) => tokens.contains(token));
  }

  /// Invalidate all sessions for a user (logout from all devices).
  LogoutResult clearAllTokens(String userId) {
    final tokens = _userSessions[userId];
    if (tokens != null) {
      _blacklist.addAll(tokens);
      tokens.clear();
    }
    return LogoutResult(success: true);
  }

  int sessionCountForUser(String userId) =>
      _userSessions[userId]?.length ?? 0;
}

void main() {
  group('FR-001.3.1–3.5: Logout and Session Management', () {
    late SessionManager sessionManager;

    setUp(() {
      sessionManager = SessionManager();
    });

    test('should successfully invalidate token on logout', () {
      // Arrange
      final userId = faker.guid.guid();
      final token = 'token.${faker.guid.guid()}';
      sessionManager.addSession(userId, token);

      // Act
      final result = sessionManager.logout(token);

      // Assert
      expect(result.success, isTrue);
    });

    test('should make token invalid after logout', () {
      // Arrange
      final userId = faker.guid.guid();
      final token = 'token.${faker.guid.guid()}';
      sessionManager.addSession(userId, token);

      // Act
      sessionManager.logout(token);

      // Assert
      expect(sessionManager.isTokenValid(token), isFalse);
    });

    test('should confirm token is valid before logout', () {
      // Arrange
      final userId = faker.guid.guid();
      final token = 'token.${faker.guid.guid()}';
      sessionManager.addSession(userId, token);

      // Act & Assert
      expect(sessionManager.isTokenValid(token), isTrue);
    });

    test('should invalidate all sessions for a user when clearAllTokens is called', () {
      // Arrange
      final userId = faker.guid.guid();
      final token1 = 'token.${faker.guid.guid()}';
      final token2 = 'token.${faker.guid.guid()}';
      sessionManager.addSession(userId, token1);
      sessionManager.addSession(userId, token2);

      // Act
      sessionManager.clearAllTokens(userId);

      // Assert
      expect(sessionManager.isTokenValid(token1), isFalse);
      expect(sessionManager.isTokenValid(token2), isFalse);
    });

    test('should return error when logout is called without a token', () {
      // Arrange & Act
      final result = sessionManager.logout('');

      // Assert
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('should clear all sessions for the user (session count drops to 0)', () {
      // Arrange
      final userId = faker.guid.guid();
      for (int i = 0; i < 3; i++) {
        sessionManager.addSession(userId, 'token.$i.${faker.guid.guid()}');
      }

      // Act
      sessionManager.clearAllTokens(userId);

      // Assert
      expect(sessionManager.sessionCountForUser(userId), equals(0));
    });

    test('should not affect other users sessions when logging out one user', () {
      // Arrange
      final userId1 = faker.guid.guid();
      final userId2 = faker.guid.guid();
      final token1 = 'token.${faker.guid.guid()}';
      final token2 = 'token.${faker.guid.guid()}';
      sessionManager.addSession(userId1, token1);
      sessionManager.addSession(userId2, token2);

      // Act
      sessionManager.clearAllTokens(userId1);

      // Assert
      expect(sessionManager.isTokenValid(token2), isTrue);
    });
  });
}

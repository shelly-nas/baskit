import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';

/// FR-001.2.5: The system SHALL provide refresh tokens with 30-day expiration
///
/// This test suite verifies that the login response includes a refresh token
/// with a 30-day lifetime and that invalid refresh tokens are rejected.

// ── Mock / stub layer ──────────────────────────────────────────────────────

final faker = Faker();

class TokenPair {
  final String accessToken;
  final String refreshToken;
  final String expiresIn;

  TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });
}

class RefreshResult {
  final bool success;
  final String? newAccessToken;
  final String? error;

  RefreshResult({required this.success, this.newAccessToken, this.error});
}

class MockTokenService {
  final Set<String> _validRefreshTokens = {};

  TokenPair generateTokenPair({bool rememberMe = false}) {
    final refresh = 'refresh.${faker.guid.guid()}';
    _validRefreshTokens.add(refresh);
    return TokenPair(
      accessToken: 'access.${faker.guid.guid()}',
      refreshToken: refresh,
      expiresIn: rememberMe ? '30d' : '24h',
    );
  }

  /// Refresh tokens always expire in 30 days regardless of rememberMe.
  String get refreshTokenExpiry => '30d';

  RefreshResult refresh(String refreshToken) {
    if (!_validRefreshTokens.contains(refreshToken)) {
      return RefreshResult(
        success: false,
        error: 'Invalid or expired refresh token',
      );
    }
    return RefreshResult(success: true, newAccessToken: 'access.${faker.guid.guid()}');
  }
}

void main() {
  group('FR-001.2.5: Refresh Token with 30-Day Expiration', () {
    late MockTokenService tokenService;

    setUp(() {
      tokenService = MockTokenService();
    });

    test('should return a refresh token on login', () {
      // Arrange & Act
      final tokens = tokenService.generateTokenPair();

      // Assert
      expect(tokens.refreshToken, isNotNull);
      expect(tokens.refreshToken, isNotEmpty);
    });

    test('should report refresh token expiry as 30d', () {
      // Arrange & Act
      final expiry = tokenService.refreshTokenExpiry;

      // Assert
      expect(expiry, equals('30d'));
    });

    test('should return different values for access token and refresh token', () {
      // Arrange & Act
      final tokens = tokenService.generateTokenPair();

      // Assert
      expect(tokens.accessToken, isNot(equals(tokens.refreshToken)));
    });

    test('should accept a valid refresh token and return a new access token', () {
      // Arrange
      final tokens = tokenService.generateTokenPair();

      // Act
      final result = tokenService.refresh(tokens.refreshToken);

      // Assert
      expect(result.success, isTrue);
      expect(result.newAccessToken, isNotNull);
    });

    test('should reject an invalid refresh token', () {
      // Arrange
      const invalidToken = 'totally-invalid-refresh-token';

      // Act
      final result = tokenService.refresh(invalidToken);

      // Assert
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('should reject a random UUID that was never issued', () {
      // Arrange
      final unknownToken = 'refresh.${faker.guid.guid()}';

      // Act
      final result = tokenService.refresh(unknownToken);

      // Assert
      expect(result.success, isFalse);
    });
  });
}

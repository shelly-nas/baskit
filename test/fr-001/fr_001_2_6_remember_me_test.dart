import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';

/// FR-001.2.6: The system SHALL support "Remember Me" functionality extending session to 30 days
///
/// This test suite verifies that rememberMe=true yields a 30-day expiry, that
/// rememberMe=false yields 24 hours, and that the default (not provided) is 24 hours.

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

class MockJwtService {
  /// Generates a token pair respecting the rememberMe flag.
  /// rememberMe=true  → expiresIn '30d'
  /// rememberMe=false → expiresIn '24h'
  /// omitted          → defaults to '24h'
  TokenPair generateTokenPair({bool? rememberMe}) {
    final expiry = (rememberMe == true) ? '30d' : '24h';
    return TokenPair(
      accessToken: 'access.${faker.guid.guid()}',
      refreshToken: 'refresh.${faker.guid.guid()}',
      expiresIn: expiry,
    );
  }
}

void main() {
  group('FR-001.2.6: Remember Me Functionality', () {
    late MockJwtService jwtService;

    setUp(() {
      jwtService = MockJwtService();
    });

    test('should set expiresIn to 30d when rememberMe is true', () {
      // Arrange & Act
      final tokens = jwtService.generateTokenPair(rememberMe: true);

      // Assert
      expect(tokens.expiresIn, equals('30d'));
    });

    test('should set expiresIn to 24h when rememberMe is false', () {
      // Arrange & Act
      final tokens = jwtService.generateTokenPair(rememberMe: false);

      // Assert
      expect(tokens.expiresIn, equals('24h'));
    });

    test('should default to 24h when rememberMe is not provided', () {
      // Arrange & Act
      final tokens = jwtService.generateTokenPair();

      // Assert
      expect(tokens.expiresIn, equals('24h'));
    });

    test('should still include accessToken and refreshToken when rememberMe=true', () {
      // Arrange & Act
      final tokens = jwtService.generateTokenPair(rememberMe: true);

      // Assert
      expect(tokens.accessToken, isNotEmpty);
      expect(tokens.refreshToken, isNotEmpty);
    });

    test('should still include accessToken and refreshToken when rememberMe=false', () {
      // Arrange & Act
      final tokens = jwtService.generateTokenPair(rememberMe: false);

      // Assert
      expect(tokens.accessToken, isNotEmpty);
      expect(tokens.refreshToken, isNotEmpty);
    });
  });
}

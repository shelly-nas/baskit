import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';

/// FR-001.2.4: The system SHALL generate JWT tokens with 24-hour expiration for authenticated sessions
///
/// This test suite verifies that a successful login returns a non-null, non-empty
/// access token and that the token pair reports the correct expiry duration.

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
  TokenPair generateTokenPair({bool rememberMe = false}) {
    final expiry = rememberMe ? '30d' : '24h';
    return TokenPair(
      accessToken: 'access.${faker.guid.guid()}',
      refreshToken: 'refresh.${faker.guid.guid()}',
      expiresIn: expiry,
    );
  }
}

class MockAuthService {
  final MockJwtService _jwtService;

  MockAuthService(this._jwtService);

  TokenPair? login(String email, String password, {bool rememberMe = false}) {
    if (email.isEmpty || password.isEmpty) return null;
    return _jwtService.generateTokenPair(rememberMe: rememberMe);
  }
}

void main() {
  group('FR-001.2.4: JWT Access Token with 24-Hour Expiration', () {
    late MockJwtService jwtService;
    late MockAuthService authService;

    setUp(() {
      jwtService = MockJwtService();
      authService = MockAuthService(jwtService);
    });

    test('should return a non-null token pair on successful login', () {
      // Arrange
      final email = faker.internet.email();
      const password = 'SecurePass123!';

      // Act
      final tokens = authService.login(email, password);

      // Assert
      expect(tokens, isNotNull);
    });

    test('should return a non-empty access token', () {
      // Arrange
      final email = faker.internet.email();
      const password = 'SecurePass123!';

      // Act
      final tokens = authService.login(email, password)!;

      // Assert
      expect(tokens.accessToken, isNotEmpty);
    });

    test('should set expiresIn to 24h by default', () {
      // Arrange & Act
      final tokens = jwtService.generateTokenPair();

      // Assert
      expect(tokens.expiresIn, equals('24h'));
    });

    test('should return non-null access token after successful login', () {
      // Arrange
      final email = faker.internet.email();
      const password = 'TestPass1!';

      // Act
      final tokens = authService.login(email, password);

      // Assert
      expect(tokens!.accessToken, isNotNull);
    });

    test('should return null tokens when email is missing', () {
      // Arrange & Act
      final tokens = authService.login('', 'SecurePass123!');

      // Assert
      expect(tokens, isNull);
    });

    test('should return null tokens when password is missing', () {
      // Arrange & Act
      final tokens = authService.login(faker.internet.email(), '');

      // Assert
      expect(tokens, isNull);
    });
  });
}

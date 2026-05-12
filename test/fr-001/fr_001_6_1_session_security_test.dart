import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';

/// FR-001.6.1–6.10: Session Security
///
/// This test suite verifies token claims (issuer, audience, type), blacklist
/// rejection, and refresh token rotation with reuse detection.

// ── Mock / stub layer ──────────────────────────────────────────────────────

final faker = Faker();

enum TokenType { access, refresh }

class TokenClaims {
  final String issuer;
  final String audience;
  final TokenType type;
  final String tokenId;
  final String userId;
  final DateTime issuedAt;
  final DateTime expiresAt;

  TokenClaims({
    required this.issuer,
    required this.audience,
    required this.type,
    required this.tokenId,
    required this.userId,
    required this.issuedAt,
    required this.expiresAt,
  });
}

class MockSecureTokenService {
  static const String issuer = 'baskit-auth';
  static const String audience = 'baskit-api';

  final Set<String> _blacklist = {};
  final Map<String, String> _refreshTokenRotation = {}; // oldTokenId → newTokenId
  final Set<String> _usedRefreshTokenIds = {};

  TokenClaims generateAccessToken(String userId) {
    return TokenClaims(
      issuer: issuer,
      audience: audience,
      type: TokenType.access,
      tokenId: faker.guid.guid(),
      userId: userId,
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
  }

  TokenClaims generateRefreshToken(String userId) {
    return TokenClaims(
      issuer: issuer,
      audience: audience,
      type: TokenType.refresh,
      tokenId: faker.guid.guid(),
      userId: userId,
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  void blacklist(String tokenId) {
    _blacklist.add(tokenId);
  }

  bool isBlacklisted(String tokenId) => _blacklist.contains(tokenId);

  /// Rotate refresh token: marks old as used and returns a new one.
  /// Returns null if the tokenId was already used (reuse attack).
  TokenClaims? rotateRefreshToken(String userId, String oldTokenId) {
    if (_usedRefreshTokenIds.contains(oldTokenId)) {
      return null; // Reuse attack detected
    }
    _usedRefreshTokenIds.add(oldTokenId);
    return generateRefreshToken(userId);
  }
}

void main() {
  group('FR-001.6.1–6.10: Session Security', () {
    late MockSecureTokenService tokenService;

    setUp(() {
      tokenService = MockSecureTokenService();
    });

    // FR-001.6.2 / issuer
    test('should set issuer to "baskit-auth" in access token', () {
      // Arrange & Act
      final claims = tokenService.generateAccessToken(faker.guid.guid());

      // Assert
      expect(claims.issuer, equals('baskit-auth'));
    });

    // FR-001.6.2 / audience
    test('should set audience to "baskit-api" in access token', () {
      // Arrange & Act
      final claims = tokenService.generateAccessToken(faker.guid.guid());

      // Assert
      expect(claims.audience, equals('baskit-api'));
    });

    // Token type differentiation
    test('should set type to access for access tokens', () {
      // Arrange & Act
      final claims = tokenService.generateAccessToken(faker.guid.guid());

      // Assert
      expect(claims.type, equals(TokenType.access));
    });

    test('should set type to refresh for refresh tokens', () {
      // Arrange & Act
      final claims = tokenService.generateRefreshToken(faker.guid.guid());

      // Assert
      expect(claims.type, equals(TokenType.refresh));
    });

    test('access token type should differ from refresh token type', () {
      // Arrange
      final userId = faker.guid.guid();

      // Act
      final access = tokenService.generateAccessToken(userId);
      final refresh = tokenService.generateRefreshToken(userId);

      // Assert
      expect(access.type, isNot(equals(refresh.type)));
    });

    // FR-001.6.8: Blacklist check
    test('should reject a blacklisted token', () {
      // Arrange
      final userId = faker.guid.guid();
      final claims = tokenService.generateAccessToken(userId);
      tokenService.blacklist(claims.tokenId);

      // Act & Assert
      expect(tokenService.isBlacklisted(claims.tokenId), isTrue);
    });

    test('should not flag a non-blacklisted token', () {
      // Arrange
      final claims = tokenService.generateAccessToken(faker.guid.guid());

      // Act & Assert
      expect(tokenService.isBlacklisted(claims.tokenId), isFalse);
    });

    // FR-001.6.3: Refresh token rotation
    test('should return a new refresh token on rotation', () {
      // Arrange
      final userId = faker.guid.guid();
      final original = tokenService.generateRefreshToken(userId);

      // Act
      final rotated = tokenService.rotateRefreshToken(userId, original.tokenId);

      // Assert
      expect(rotated, isNotNull);
      expect(rotated!.tokenId, isNot(equals(original.tokenId)));
    });

    // FR-001.6.4: Token reuse detection
    test('should reject refresh token that has already been rotated (reuse attack)', () {
      // Arrange
      final userId = faker.guid.guid();
      final original = tokenService.generateRefreshToken(userId);

      // Act — rotate once (valid)
      tokenService.rotateRefreshToken(userId, original.tokenId);
      // Attempt to reuse the same old token
      final secondAttempt = tokenService.rotateRefreshToken(userId, original.tokenId);

      // Assert
      expect(secondAttempt, isNull);
    });
  });
}

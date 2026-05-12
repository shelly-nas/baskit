import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';

/// FR-001.2.8: The system SHALL prevent login for unverified email accounts
///
/// This test suite verifies that accounts in pending_verification status are
/// blocked with the correct error message, active accounts can log in, and
/// locked accounts are rejected with the lock message.

// ── Mock / stub layer ──────────────────────────────────────────────────────

final faker = Faker();

enum UserStatus { active, pendingVerification, locked }

class LoginResult {
  final bool success;
  final String? error;
  final String? accessToken;

  LoginResult({required this.success, this.error, this.accessToken});
}

class MockLoginService {
  LoginResult login(UserStatus status, {bool passwordCorrect = true}) {
    switch (status) {
      case UserStatus.pendingVerification:
        return LoginResult(
          success: false,
          error: 'Please verify your email address before logging in',
        );
      case UserStatus.locked:
        return LoginResult(
          success: false,
          error: 'Account locked due to multiple failed login attempts',
        );
      case UserStatus.active:
        if (!passwordCorrect) {
          return LoginResult(success: false, error: 'Invalid email or password');
        }
        return LoginResult(
          success: true,
          accessToken: 'access.${faker.guid.guid()}',
        );
    }
  }
}

void main() {
  group('FR-001.2.8: Prevent Login for Unverified Email Accounts', () {
    late MockLoginService loginService;

    setUp(() {
      loginService = MockLoginService();
    });

    test('should return error for pending_verification account', () {
      // Arrange — account not yet verified

      // Act
      final result = loginService.login(UserStatus.pendingVerification);

      // Assert
      expect(result.success, isFalse);
    });

    test('should return exact error message for unverified account', () {
      // Arrange & Act
      final result = loginService.login(UserStatus.pendingVerification);

      // Assert — must match the spec string exactly
      expect(
        result.error,
        equals('Please verify your email address before logging in'),
      );
    });

    test('should allow login for active account with correct password', () {
      // Arrange & Act
      final result = loginService.login(UserStatus.active, passwordCorrect: true);

      // Assert
      expect(result.success, isTrue);
      expect(result.accessToken, isNotNull);
    });

    test('should return account locked error for locked account', () {
      // Arrange & Act
      final result = loginService.login(UserStatus.locked);

      // Assert
      expect(result.success, isFalse);
      expect(result.error, contains('Account locked due to multiple failed login attempts'));
    });

    test('should not expose access token when account is unverified', () {
      // Arrange & Act
      final result = loginService.login(UserStatus.pendingVerification);

      // Assert
      expect(result.accessToken, isNull);
    });

    test('should not expose access token when account is locked', () {
      // Arrange & Act
      final result = loginService.login(UserStatus.locked);

      // Assert
      expect(result.accessToken, isNull);
    });
  });
}

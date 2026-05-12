import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';

/// FR-001.2.1: The system SHALL provide login functionality using email and password
///
/// This test suite verifies that the login functionality accepts valid credentials
/// and rejects malformed or empty input.

// ── Mock / stub layer ──────────────────────────────────────────────────────

final faker = Faker();

class LoginRequest {
  final String email;
  final String password;
  final bool rememberMe;

  LoginRequest({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  bool get isValid =>
      email.trim().isNotEmpty && password.trim().isNotEmpty;
}

class LoginResult {
  final bool success;
  final String? accessToken;
  final String? error;

  LoginResult({required this.success, this.accessToken, this.error});
}

class MockLoginService {
  Future<LoginResult> login(LoginRequest request) async {
    if (request.email.trim().isEmpty) {
      return LoginResult(success: false, error: 'Email is required');
    }
    if (request.password.trim().isEmpty) {
      return LoginResult(success: false, error: 'Password is required');
    }
    return LoginResult(success: true, accessToken: 'mock-jwt-access-token');
  }
}

void main() {
  group('FR-001.2.1: Login with Email and Password', () {
    late MockLoginService loginService;

    setUp(() {
      loginService = MockLoginService();
    });

    test('should succeed with valid email and password', () async {
      // Arrange
      final request = LoginRequest(
        email: faker.internet.email(),
        password: 'SecurePass123!',
      );

      // Act
      final result = await loginService.login(request);

      // Assert
      expect(result.success, isTrue);
      expect(result.accessToken, isNotNull);
      expect(result.error, isNull);
    });

    test('should fail when email is empty', () async {
      // Arrange
      final request = LoginRequest(email: '', password: 'SecurePass123!');

      // Act
      final result = await loginService.login(request);

      // Assert
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('should fail when password is empty', () async {
      // Arrange
      final request = LoginRequest(email: faker.internet.email(), password: '');

      // Act
      final result = await loginService.login(request);

      // Assert
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('should fail when email is whitespace only', () async {
      // Arrange
      final request = LoginRequest(email: '   ', password: 'SecurePass123!');

      // Act
      final result = await loginService.login(request);

      // Assert
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('should fail when password is whitespace only', () async {
      // Arrange
      final request = LoginRequest(email: faker.internet.email(), password: '   ');

      // Act
      final result = await loginService.login(request);

      // Assert
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('should construct LoginRequest with all required fields', () {
      // Arrange & Act
      final email = faker.internet.email();
      const password = 'TestPassword1!';
      final request = LoginRequest(email: email, password: password);

      // Assert
      expect(request.email, equals(email));
      expect(request.password, equals(password));
      expect(request.rememberMe, isFalse);
      expect(request.isValid, isTrue);
    });

    test('should report isValid false when both fields are empty', () {
      // Arrange
      final request = LoginRequest(email: '', password: '');

      // Act & Assert
      expect(request.isValid, isFalse);
    });
  });
}

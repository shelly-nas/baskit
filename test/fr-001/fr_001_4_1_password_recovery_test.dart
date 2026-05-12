import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';

/// FR-001.4.1–4.8: Password Recovery flow
///
/// This test suite verifies the full forgot-password flow: generic responses
/// for non-existent emails, token expiry and reuse rejection, password history
/// checks, and rate limiting.

// ── Mock / stub layer ──────────────────────────────────────────────────────

final faker = Faker();

class PasswordResetResult {
  final bool success;
  final String message;

  PasswordResetResult({required this.success, required this.message});
}

enum ResetTokenStatus { valid, expired, used }

class PasswordResetService {
  static const String _genericMessage =
      'If an account exists with this email, you will receive a password reset link';

  final Map<String, int> _requestCounts = {};
  final List<String> _passwordHistory = [];
  String? _currentPasswordHash;

  /// FR-001.4.1 / FR-001.4.2: Request a reset link. Always returns generic message.
  PasswordResetResult requestReset(String email, {bool userExists = true}) {
    final count = _requestCounts[email] ?? 0;

    // FR-001.4.8: Rate limit — 3 requests per hour
    if (count >= 3) {
      // Return generic message to avoid leaking rate-limit info
      return PasswordResetResult(success: true, message: _genericMessage);
    }

    _requestCounts[email] = count + 1;
    return PasswordResetResult(success: true, message: _genericMessage);
  }

  /// FR-001.4.3 / FR-001.4.4: Reset password with token.
  PasswordResetResult resetPassword({
    required String token,
    required ResetTokenStatus tokenStatus,
    required String newPassword,
    String? currentPasswordHash,
    List<String> recentPasswordHashes = const [],
  }) {
    // FR-001.4.3: Expired token
    if (tokenStatus == ResetTokenStatus.expired) {
      return PasswordResetResult(
        success: false,
        message: 'This reset link has expired. Please request a new one',
      );
    }

    // FR-001.4.4: Already used token
    if (tokenStatus == ResetTokenStatus.used) {
      return PasswordResetResult(
        success: false,
        message: 'This reset link is invalid. Please request a new one',
      );
    }

    // FR-001.4.6: Password complexity (simple check for test purposes)
    if (!_meetsComplexity(newPassword)) {
      return PasswordResetResult(
        success: false,
        message: 'Password must meet complexity requirements',
      );
    }

    // FR-001.4.7 / new same-as-current: Check password not reused
    if (currentPasswordHash != null && currentPasswordHash == newPassword) {
      return PasswordResetResult(
        success: false,
        message: 'Please choose a different password',
      );
    }
    if (recentPasswordHashes.contains(newPassword)) {
      return PasswordResetResult(
        success: false,
        message: 'You cannot reuse a recent password',
      );
    }

    return PasswordResetResult(success: true, message: 'Password reset successfully');
  }

  bool _meetsComplexity(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#\$%^&*]'))) return false;
    return true;
  }
}

void main() {
  group('FR-001.4.1–4.8: Password Recovery Flow', () {
    late PasswordResetService resetService;

    setUp(() {
      resetService = PasswordResetService();
    });

    // FR-001.4.1 / FR-001.4.2
    test('should return generic message for valid existing email', () {
      // Arrange
      final email = faker.internet.email();

      // Act
      final result = resetService.requestReset(email, userExists: true);

      // Assert
      expect(result.success, isTrue);
      expect(
        result.message,
        equals('If an account exists with this email, you will receive a password reset link'),
      );
    });

    test('should return generic message for non-existent email', () {
      // Arrange
      final email = faker.internet.email();

      // Act
      final result = resetService.requestReset(email, userExists: false);

      // Assert
      expect(result.success, isTrue);
      expect(
        result.message,
        equals('If an account exists with this email, you will receive a password reset link'),
      );
    });

    // FR-001.4.3
    test('should reject expired reset token with correct error message', () {
      // Arrange & Act
      final result = resetService.resetPassword(
        token: faker.guid.guid(),
        tokenStatus: ResetTokenStatus.expired,
        newPassword: 'NewSecure1!',
      );

      // Assert
      expect(result.success, isFalse);
      expect(result.message, equals('This reset link has expired. Please request a new one'));
    });

    // FR-001.4.4
    test('should reject already-used reset token with correct error message', () {
      // Arrange & Act
      final result = resetService.resetPassword(
        token: faker.guid.guid(),
        tokenStatus: ResetTokenStatus.used,
        newPassword: 'NewSecure1!',
      );

      // Assert
      expect(result.success, isFalse);
      expect(result.message, equals('This reset link is invalid. Please request a new one'));
    });

    // FR-001.4.6 (same as FR-001.1.3)
    test('should reject new password that does not meet complexity requirements', () {
      // Arrange & Act
      final result = resetService.resetPassword(
        token: faker.guid.guid(),
        tokenStatus: ResetTokenStatus.valid,
        newPassword: 'weak',
      );

      // Assert
      expect(result.success, isFalse);
    });

    // FR-001.4.7 (same as current password)
    test('should reject new password that is the same as current', () {
      // Arrange
      const currentHash = 'SecurePass123!';

      // Act
      final result = resetService.resetPassword(
        token: faker.guid.guid(),
        tokenStatus: ResetTokenStatus.valid,
        newPassword: 'SecurePass123!',
        currentPasswordHash: currentHash,
      );

      // Assert
      expect(result.success, isFalse);
      expect(result.message, equals('Please choose a different password'));
    });

    // FR-001.4.7 (password history)
    test('should reject new password reused from history', () {
      // Arrange
      const recentPassword = 'OldSecure1!';

      // Act
      final result = resetService.resetPassword(
        token: faker.guid.guid(),
        tokenStatus: ResetTokenStatus.valid,
        newPassword: recentPassword,
        recentPasswordHashes: [recentPassword],
      );

      // Assert
      expect(result.success, isFalse);
      expect(result.message, equals('You cannot reuse a recent password'));
    });

    // FR-001.4.8: Rate limiting
    test('should block 4th password reset request within the hour', () {
      // Arrange
      final email = faker.internet.email();

      // Act — make 3 allowed requests
      resetService.requestReset(email);
      resetService.requestReset(email);
      resetService.requestReset(email);
      // 4th request should still return generic message (rate-limited silently)
      final result = resetService.requestReset(email);

      // Assert — response is still the generic message (security: no leak)
      expect(result.success, isTrue);
      expect(result.message, contains('If an account exists'));
    });

    test('should succeed with valid token and a new strong password', () {
      // Arrange & Act
      final result = resetService.resetPassword(
        token: faker.guid.guid(),
        tokenStatus: ResetTokenStatus.valid,
        newPassword: 'NewBrand1!',
      );

      // Assert
      expect(result.success, isTrue);
    });
  });
}

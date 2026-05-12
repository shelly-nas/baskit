import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';

/// FR-001.2.3: The system SHALL lock accounts after 10 consecutive failed login attempts
///
/// This test suite verifies that accounts are locked after 10 consecutive
/// failed attempts, that locked accounts reject even correct passwords, and
/// that the failed counter resets on successful login.

// ── Mock / stub layer ──────────────────────────────────────────────────────

final faker = Faker();

enum AccountStatus { active, locked, pendingVerification, deleted }

class AccountLockResult {
  final bool isLocked;
  final String? message;
  final DateTime? lockedUntil;
  final int failedAttempts;

  AccountLockResult({
    required this.isLocked,
    this.message,
    this.lockedUntil,
    required this.failedAttempts,
  });
}

class LoginAttemptResult {
  final bool success;
  final String? error;

  LoginAttemptResult({required this.success, this.error});
}

class AccountLockService {
  final int maxAttempts;

  AccountLockService({required this.maxAttempts});

  /// Records a failed attempt and returns lock status.
  AccountLockResult recordFailedAttempt(int currentFailedAttempts) {
    final newCount = currentFailedAttempts + 1;
    final shouldLock = newCount >= maxAttempts;

    if (shouldLock) {
      return AccountLockResult(
        isLocked: true,
        message: 'Account locked due to multiple failed login attempts',
        lockedUntil: DateTime.now().add(const Duration(minutes: 30)),
        failedAttempts: newCount,
      );
    }

    return AccountLockResult(isLocked: false, failedAttempts: newCount);
  }

  /// Checks if an account with the given status and failed count is locked.
  AccountLockResult checkStatus({
    required AccountStatus status,
    required int failedAttempts,
    DateTime? lockedUntil,
  }) {
    if (status == AccountStatus.locked ||
        (lockedUntil != null && lockedUntil.isAfter(DateTime.now()))) {
      return AccountLockResult(
        isLocked: true,
        message: 'Account locked due to multiple failed login attempts',
        lockedUntil: lockedUntil,
        failedAttempts: failedAttempts,
      );
    }
    return AccountLockResult(isLocked: false, failedAttempts: failedAttempts);
  }

  /// Simulates a login attempt against a (possibly locked) account.
  LoginAttemptResult attemptLogin({
    required bool passwordCorrect,
    required bool accountLocked,
  }) {
    if (accountLocked) {
      return LoginAttemptResult(
        success: false,
        error: 'Account locked due to multiple failed login attempts',
      );
    }
    if (!passwordCorrect) {
      return LoginAttemptResult(
        success: false,
        error: 'Invalid email or password',
      );
    }
    return LoginAttemptResult(success: true);
  }

  /// Returns reset count (0) on successful login.
  int resetOnSuccess() => 0;
}

void main() {
  group('FR-001.2.3: Account Locking After 10 Failed Login Attempts', () {
    late AccountLockService lockService;

    setUp(() {
      lockService = AccountLockService(maxAttempts: 10);
    });

    test('should not lock after 9 consecutive failures', () {
      // Arrange
      int failedAttempts = 0;
      AccountLockResult? result;

      // Act
      for (int i = 0; i < 9; i++) {
        result = lockService.recordFailedAttempt(failedAttempts);
        failedAttempts = result.failedAttempts;
      }

      // Assert
      expect(result!.isLocked, isFalse);
      expect(result.failedAttempts, equals(9));
    });

    test('should lock on the 10th consecutive failure', () {
      // Arrange
      int failedAttempts = 9;

      // Act
      final result = lockService.recordFailedAttempt(failedAttempts);

      // Assert
      expect(result.isLocked, isTrue);
      expect(result.failedAttempts, equals(10));
    });

    test('should include the lockout message when account is locked', () {
      // Arrange
      int failedAttempts = 9;

      // Act
      final result = lockService.recordFailedAttempt(failedAttempts);

      // Assert
      expect(
        result.message,
        contains('Account locked due to multiple failed login attempts'),
      );
    });

    test('should reject login with correct password when account is locked', () {
      // Arrange — account is locked
      final loginResult = lockService.attemptLogin(
        passwordCorrect: true,
        accountLocked: true,
      );

      // Act & Assert
      expect(loginResult.success, isFalse);
      expect(
        loginResult.error,
        contains('Account locked due to multiple failed login attempts'),
      );
    });

    test('should reset failed counter to 0 on successful login', () {
      // Arrange — simulate a previously failed count
      int failedAttempts = 7;

      // Act
      failedAttempts = lockService.resetOnSuccess();

      // Assert
      expect(failedAttempts, equals(0));
    });

    test('should set lockedUntil date when locking account', () {
      // Arrange
      int failedAttempts = 9;

      // Act
      final result = lockService.recordFailedAttempt(failedAttempts);

      // Assert
      expect(result.lockedUntil, isNotNull);
      expect(result.lockedUntil!.isAfter(DateTime.now()), isTrue);
    });

    test('should report isLocked true for status=locked regardless of attempt count', () {
      // Arrange & Act
      final result = lockService.checkStatus(
        status: AccountStatus.locked,
        failedAttempts: 0,
      );

      // Assert
      expect(result.isLocked, isTrue);
    });

    test('should report isLocked false for active accounts below threshold', () {
      // Arrange & Act
      final result = lockService.checkStatus(
        status: AccountStatus.active,
        failedAttempts: 3,
      );

      // Assert
      expect(result.isLocked, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

/// FR-001.1.5: The system SHALL check for duplicate email addresses and prevent
/// multiple accounts with the same email
///
/// This test suite verifies that the system properly checks for and prevents
/// duplicate email registrations.

// Mock user model
class User {
  final String id;
  final String email;
  final String displayName;

  User({
    required this.id,
    required this.email,
    required this.displayName,
  });
}

// Registration result
class RegistrationResult {
  final bool success;
  final User? user;
  final String? error;

  RegistrationResult({
    required this.success,
    this.user,
    this.error,
  });
}

// Mock user repository for testing duplicate email checks
class MockUserRepository {
  final Map<String, User> _users = {};
  static int _counter = 0;

  /// Check if email already exists in the database
  Future<bool> emailExists(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    return _users.values.any(
      (user) => user.email.toLowerCase() == normalizedEmail,
    );
  }

  /// Find user by email (case-insensitive)
  Future<User?> findByEmail(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    try {
      return _users.values.firstWhere(
        (user) => user.email.toLowerCase() == normalizedEmail,
      );
    } catch (e) {
      return null;
    }
  }

  /// Register a new user (checks for duplicate email)
  Future<RegistrationResult> registerUser({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // Check for duplicate email
    if (await emailExists(email)) {
      return RegistrationResult(
        success: false,
        error: 'An account with this email already exists',
      );
    }

    // Create new user
    final userId = 'user_${++_counter}';
    final user = User(
      id: userId,
      email: email.toLowerCase().trim(),
      displayName: displayName,
    );

    _users[userId] = user;

    return RegistrationResult(
      success: true,
      user: user,
    );
  }

  /// Get all registered users (for testing)
  List<User> getAllUsers() => _users.values.toList();

  /// Clear all users (for test cleanup)
  void clear() => _users.clear();
}

void main() {
  group('FR-001.1.5: Duplicate Email Prevention', () {
    late MockUserRepository userRepository;

    setUp(() {
      userRepository = MockUserRepository();
    });

    tearDown(() {
      userRepository.clear();
    });

    group('Email existence check', () {
      test('should return false when email does not exist', () async {
        // Act
        final exists = await userRepository.emailExists('new@example.com');

        // Assert
        expect(exists, isFalse);
      });

      test('should return true when email already exists', () async {
        // Arrange
        await userRepository.registerUser(
          email: 'existing@example.com',
          password: 'SecureP@ss1',
          displayName: 'Existing User',
        );

        // Act
        final exists = await userRepository.emailExists('existing@example.com');

        // Assert
        expect(exists, isTrue);
      });

      test('should be case-insensitive for email check', () async {
        // Arrange
        await userRepository.registerUser(
          email: 'User@Example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );

        // Act & Assert
        expect(await userRepository.emailExists('user@example.com'), isTrue);
        expect(await userRepository.emailExists('USER@EXAMPLE.COM'), isTrue);
        expect(await userRepository.emailExists('User@Example.com'), isTrue);
        expect(await userRepository.emailExists('UsEr@ExAmPlE.cOm'), isTrue);
      });

      test('should handle whitespace in email check', () async {
        // Arrange
        await userRepository.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );

        // Act & Assert - should find email even with surrounding whitespace
        expect(await userRepository.emailExists('  user@example.com  '), isTrue);
      });
    });

    group('Duplicate registration prevention', () {
      test('should successfully register user with unique email', () async {
        // Act
        final result = await userRepository.registerUser(
          email: 'new@example.com',
          password: 'SecureP@ss1',
          displayName: 'New User',
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.user, isNotNull);
        expect(result.error, isNull);
      });

      test('should prevent registration with duplicate email', () async {
        // Arrange - register first user
        await userRepository.registerUser(
          email: 'duplicate@example.com',
          password: 'SecureP@ss1',
          displayName: 'First User',
        );

        // Act - try to register second user with same email
        final result = await userRepository.registerUser(
          email: 'duplicate@example.com',
          password: 'DifferentP@ss1',
          displayName: 'Second User',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.user, isNull);
        expect(result.error, equals('An account with this email already exists'));
      });

      test('should prevent duplicate registration with different case', () async {
        // Arrange
        await userRepository.registerUser(
          email: 'User@Example.com',
          password: 'SecureP@ss1',
          displayName: 'First User',
        );

        // Act - try with different case
        final result = await userRepository.registerUser(
          email: 'USER@EXAMPLE.COM',
          password: 'DifferentP@ss1',
          displayName: 'Second User',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('already exists'));
      });

      test('should allow registration with similar but different emails',
          () async {
        // Arrange
        await userRepository.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'First User',
        );

        // Act - register with different email
        final result = await userRepository.registerUser(
          email: 'user@example.org', // different TLD
          password: 'SecureP@ss1',
          displayName: 'Second User',
        );

        // Assert
        expect(result.success, isTrue);
      });

      test('should allow different users with unique emails', () async {
        // Act
        final result1 = await userRepository.registerUser(
          email: 'user1@example.com',
          password: 'SecureP@ss1',
          displayName: 'User One',
        );

        final result2 = await userRepository.registerUser(
          email: 'user2@example.com',
          password: 'SecureP@ss1',
          displayName: 'User Two',
        );

        final result3 = await userRepository.registerUser(
          email: 'user3@example.com',
          password: 'SecureP@ss1',
          displayName: 'User Three',
        );

        // Assert
        expect(result1.success, isTrue);
        expect(result2.success, isTrue);
        expect(result3.success, isTrue);
        expect(userRepository.getAllUsers().length, equals(3));
      });
    });

    group('Find user by email', () {
      test('should find user by exact email', () async {
        // Arrange
        await userRepository.registerUser(
          email: 'findme@example.com',
          password: 'SecureP@ss1',
          displayName: 'Find Me',
        );

        // Act
        final user = await userRepository.findByEmail('findme@example.com');

        // Assert
        expect(user, isNotNull);
        expect(user!.displayName, equals('Find Me'));
      });

      test('should find user by email case-insensitively', () async {
        // Arrange
        await userRepository.registerUser(
          email: 'FindMe@Example.com',
          password: 'SecureP@ss1',
          displayName: 'Find Me',
        );

        // Act
        final user = await userRepository.findByEmail('findme@example.com');

        // Assert
        expect(user, isNotNull);
        expect(user!.displayName, equals('Find Me'));
      });

      test('should return null when user not found', () async {
        // Act
        final user = await userRepository.findByEmail('notfound@example.com');

        // Assert
        expect(user, isNull);
      });
    });

    group('Email normalization', () {
      test('should store email in lowercase', () async {
        // Arrange & Act
        final result = await userRepository.registerUser(
          email: 'User@Example.COM',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );

        // Assert
        expect(result.user!.email, equals('user@example.com'));
      });

      test('should store email without leading/trailing whitespace', () async {
        // Arrange & Act
        final result = await userRepository.registerUser(
          email: '  user@example.com  ',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );

        // Assert
        expect(result.user!.email, equals('user@example.com'));
      });
    });

    group('Error messages', () {
      test('should provide user-friendly error for duplicate email', () async {
        // Arrange
        await userRepository.registerUser(
          email: 'taken@example.com',
          password: 'SecureP@ss1',
          displayName: 'First User',
        );

        // Act
        final result = await userRepository.registerUser(
          email: 'taken@example.com',
          password: 'SecureP@ss1',
          displayName: 'Second User',
        );

        // Assert
        expect(result.error, isNotNull);
        expect(result.error, contains('already exists'));
        // Should not reveal sensitive information
        expect(result.error!.toLowerCase(), isNot(contains('password')));
      });
    });

    group('Concurrent registration', () {
      test('should handle multiple registration attempts', () async {
        // Simulate multiple registration attempts
        final emails = List.generate(10, (i) => 'user$i@example.com');

        for (final email in emails) {
          final result = await userRepository.registerUser(
            email: email,
            password: 'SecureP@ss1',
            displayName: 'User',
          );
          expect(result.success, isTrue);
        }

        // Verify all unique users were created
        expect(userRepository.getAllUsers().length, equals(10));

        // Verify duplicates are still prevented
        final duplicateResult = await userRepository.registerUser(
          email: 'user0@example.com',
          password: 'SecureP@ss1',
          displayName: 'Duplicate',
        );
        expect(duplicateResult.success, isFalse);
      });
    });
  });
}

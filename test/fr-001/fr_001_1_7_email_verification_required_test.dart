import 'package:flutter_test/flutter_test.dart';

/// FR-001.1.7: The system SHALL require email verification before allowing full account access
///
/// This test suite verifies that unverified accounts have restricted access
/// and that verified accounts can access full functionality.

// User account status enum
enum AccountStatus {
  pendingVerification,
  active,
  locked,
  deleted,
}

// User model with verification status
class User {
  final String id;
  final String email;
  final String displayName;
  final bool emailVerified;
  final AccountStatus status;
  final DateTime createdAt;
  final DateTime? emailVerifiedAt;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    this.emailVerified = false,
    this.status = AccountStatus.pendingVerification,
    DateTime? createdAt,
    this.emailVerifiedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? emailVerified,
    AccountStatus? status,
    DateTime? createdAt,
    DateTime? emailVerifiedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      emailVerified: emailVerified ?? this.emailVerified,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
    );
  }

  bool get canAccessFullFeatures => emailVerified && status == AccountStatus.active;
}

// Access control result
class AccessControlResult {
  final bool allowed;
  final String? reason;

  AccessControlResult({
    required this.allowed,
    this.reason,
  });
}

// Mock authentication service
class MockAuthService {
  final Map<String, User> _users = {};
  final Map<String, String> _verificationTokens = {}; // token -> userId

  /// Register a new user (initially unverified)
  User registerUser({
    required String email,
    required String password,
    required String displayName,
  }) {
    final user = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName,
      emailVerified: false,
      status: AccountStatus.pendingVerification,
    );

    _users[user.id] = user;

    // Create verification token
    final token = 'verify_${user.id}';
    _verificationTokens[token] = user.id;

    return user;
  }

  /// Verify user's email
  VerificationResult verifyEmail(String token) {
    final userId = _verificationTokens[token];
    if (userId == null) {
      return VerificationResult(
        success: false,
        error: 'Invalid verification token',
      );
    }

    final user = _users[userId];
    if (user == null) {
      return VerificationResult(
        success: false,
        error: 'User not found',
      );
    }

    if (user.emailVerified) {
      return VerificationResult(
        success: false,
        error: 'Email already verified',
      );
    }

    // Update user as verified
    _users[userId] = user.copyWith(
      emailVerified: true,
      status: AccountStatus.active,
      emailVerifiedAt: DateTime.now(),
    );

    // Remove used token
    _verificationTokens.remove(token);

    return VerificationResult(
      success: true,
      user: _users[userId],
    );
  }

  /// Attempt login
  LoginResult login({
    required String email,
    required String password,
  }) {
    final user = _users.values.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => throw Exception('User not found'),
    );

    // Check if email is verified
    if (!user.emailVerified) {
      return LoginResult(
        success: false,
        error: 'Please verify your email address before logging in',
        requiresVerification: true,
      );
    }

    // Check account status
    if (user.status != AccountStatus.active) {
      return LoginResult(
        success: false,
        error: 'Account is not active',
      );
    }

    return LoginResult(
      success: true,
      user: user,
    );
  }

  /// Get user by ID
  User? getUser(String userId) => _users[userId];

  void clear() {
    _users.clear();
    _verificationTokens.clear();
  }
}

// Login result
class LoginResult {
  final bool success;
  final User? user;
  final String? error;
  final bool requiresVerification;

  LoginResult({
    required this.success,
    this.user,
    this.error,
    this.requiresVerification = false,
  });
}

// Verification result
class VerificationResult {
  final bool success;
  final User? user;
  final String? error;

  VerificationResult({
    required this.success,
    this.user,
    this.error,
  });
}

// Feature access controller
class FeatureAccessController {
  /// Check if user can access a protected feature
  static AccessControlResult canAccessFeature(User? user, String feature) {
    if (user == null) {
      return AccessControlResult(
        allowed: false,
        reason: 'Authentication required',
      );
    }

    if (!user.emailVerified) {
      return AccessControlResult(
        allowed: false,
        reason: 'Please verify your email to access this feature',
      );
    }

    if (user.status != AccountStatus.active) {
      return AccessControlResult(
        allowed: false,
        reason: 'Account is not active',
      );
    }

    return AccessControlResult(allowed: true);
  }

  /// Check if user can create shopping lists
  static AccessControlResult canCreateShoppingList(User? user) {
    return canAccessFeature(user, 'create_shopping_list');
  }

  /// Check if user can share lists
  static AccessControlResult canShareList(User? user) {
    return canAccessFeature(user, 'share_list');
  }

  /// Check if user can access premium features
  static AccessControlResult canAccessPremium(User? user) {
    return canAccessFeature(user, 'premium_features');
  }

  /// Check if user can update profile
  static AccessControlResult canUpdateProfile(User? user) {
    return canAccessFeature(user, 'update_profile');
  }
}

void main() {
  group('FR-001.1.7: Email Verification Required for Full Account Access', () {
    late MockAuthService authService;

    setUp(() {
      authService = MockAuthService();
    });

    tearDown(() {
      authService.clear();
    });

    group('User registration creates unverified account', () {
      test('should create user with emailVerified = false', () {
        // Act
        final user = authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );

        // Assert
        expect(user.emailVerified, isFalse);
      });

      test('should create user with pending_verification status', () {
        // Act
        final user = authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );

        // Assert
        expect(user.status, equals(AccountStatus.pendingVerification));
      });

      test('should not allow full feature access for new user', () {
        // Arrange
        final user = authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );

        // Assert
        expect(user.canAccessFullFeatures, isFalse);
      });
    });

    group('Login prevention for unverified accounts', () {
      test('should prevent login for unverified email', () {
        // Arrange
        authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );

        // Act
        final result = authService.login(
          email: 'user@example.com',
          password: 'SecureP@ss1',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.requiresVerification, isTrue);
      });

      test('should provide appropriate error message for unverified account', () {
        // Arrange
        authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );

        // Act
        final result = authService.login(
          email: 'user@example.com',
          password: 'SecureP@ss1',
        );

        // Assert
        expect(result.error, contains('verify'));
        expect(result.error!.toLowerCase(), contains('email'));
      });
    });

    group('Feature access restrictions for unverified users', () {
      test('should deny shopping list creation for unverified user', () {
        // Arrange
        final user = authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );

        // Act
        final result = FeatureAccessController.canCreateShoppingList(user);

        // Assert
        expect(result.allowed, isFalse);
        expect(result.reason, contains('verify'));
      });

      test('should deny list sharing for unverified user', () {
        // Arrange
        final user = authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );

        // Act
        final result = FeatureAccessController.canShareList(user);

        // Assert
        expect(result.allowed, isFalse);
      });

      test('should deny premium features for unverified user', () {
        // Arrange
        final user = authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );

        // Act
        final result = FeatureAccessController.canAccessPremium(user);

        // Assert
        expect(result.allowed, isFalse);
      });

      test('should deny profile updates for unverified user', () {
        // Arrange
        final user = authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );

        // Act
        final result = FeatureAccessController.canUpdateProfile(user);

        // Assert
        expect(result.allowed, isFalse);
      });
    });

    group('Email verification process', () {
      test('should successfully verify email with valid token', () {
        // Arrange
        final user = authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );
        final token = 'verify_${user.id}';

        // Act
        final result = authService.verifyEmail(token);

        // Assert
        expect(result.success, isTrue);
        expect(result.user!.emailVerified, isTrue);
      });

      test('should update account status to active after verification', () {
        // Arrange
        final user = authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );
        final token = 'verify_${user.id}';

        // Act
        final result = authService.verifyEmail(token);

        // Assert
        expect(result.user!.status, equals(AccountStatus.active));
      });

      test('should set emailVerifiedAt timestamp after verification', () {
        // Arrange
        final user = authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );
        final token = 'verify_${user.id}';

        // Act
        final result = authService.verifyEmail(token);

        // Assert
        expect(result.user!.emailVerifiedAt, isNotNull);
      });

      test('should fail verification with invalid token', () {
        // Act
        final result = authService.verifyEmail('invalid_token');

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Invalid'));
      });

      test('should prevent double verification', () {
        // Arrange
        final user = authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );
        final token = 'verify_${user.id}';

        // Act
        authService.verifyEmail(token); // First verification
        final secondResult = authService.verifyEmail(token); // Second attempt

        // Assert
        expect(secondResult.success, isFalse);
      });
    });

    group('Full access after verification', () {
      test('should allow login after email verification', () {
        // Arrange
        final user = authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );
        authService.verifyEmail('verify_${user.id}');

        // Act
        final result = authService.login(
          email: 'user@example.com',
          password: 'SecureP@ss1',
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.user, isNotNull);
      });

      test('should allow full feature access after verification', () {
        // Arrange
        final user = authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );
        authService.verifyEmail('verify_${user.id}');
        final verifiedUser = authService.getUser(user.id);

        // Assert
        expect(verifiedUser!.canAccessFullFeatures, isTrue);
      });

      test('should allow shopping list creation after verification', () {
        // Arrange
        final user = authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );
        authService.verifyEmail('verify_${user.id}');
        final verifiedUser = authService.getUser(user.id);

        // Act
        final result = FeatureAccessController.canCreateShoppingList(verifiedUser);

        // Assert
        expect(result.allowed, isTrue);
      });

      test('should allow list sharing after verification', () {
        // Arrange
        final user = authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );
        authService.verifyEmail('verify_${user.id}');
        final verifiedUser = authService.getUser(user.id);

        // Act
        final result = FeatureAccessController.canShareList(verifiedUser);

        // Assert
        expect(result.allowed, isTrue);
      });

      test('should allow profile updates after verification', () {
        // Arrange
        final user = authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );
        authService.verifyEmail('verify_${user.id}');
        final verifiedUser = authService.getUser(user.id);

        // Act
        final result = FeatureAccessController.canUpdateProfile(verifiedUser);

        // Assert
        expect(result.allowed, isTrue);
      });
    });

    group('Access control error messages', () {
      test('should require authentication for null user', () {
        // Act
        final result = FeatureAccessController.canAccessFeature(null, 'any_feature');

        // Assert
        expect(result.allowed, isFalse);
        expect(result.reason, contains('Authentication'));
      });

      test('should request verification for unverified user', () {
        // Arrange
        final user = authService.registerUser(
          email: 'user@example.com',
          password: 'SecureP@ss1',
          displayName: 'Test User',
        );

        // Act
        final result = FeatureAccessController.canAccessFeature(user, 'any_feature');

        // Assert
        expect(result.allowed, isFalse);
        expect(result.reason!.toLowerCase(), contains('verify'));
      });
    });

    group('Account status checks', () {
      test('should deny access for locked account even if verified', () {
        // Arrange
        final verifiedButLockedUser = User(
          id: 'user_123',
          email: 'user@example.com',
          displayName: 'Test User',
          emailVerified: true,
          status: AccountStatus.locked,
        );

        // Act
        final result = FeatureAccessController.canAccessFeature(
          verifiedButLockedUser,
          'any_feature',
        );

        // Assert
        expect(result.allowed, isFalse);
        expect(result.reason, contains('not active'));
      });

      test('should deny access for deleted account even if verified', () {
        // Arrange
        final verifiedButDeletedUser = User(
          id: 'user_123',
          email: 'user@example.com',
          displayName: 'Test User',
          emailVerified: true,
          status: AccountStatus.deleted,
        );

        // Act
        final result = FeatureAccessController.canAccessFeature(
          verifiedButDeletedUser,
          'any_feature',
        );

        // Assert
        expect(result.allowed, isFalse);
      });
    });
  });
}

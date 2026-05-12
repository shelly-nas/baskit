import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';

/// FR-001.5.1–5.6: Profile & Personal Information Management
///
/// This test suite verifies that users can update their display name (with
/// length validation), that email changes require the current password, and
/// that dietary preferences are accepted.

// ── Mock / stub layer ──────────────────────────────────────────────────────

final faker = Faker();

class UserProfile {
  String displayName;
  String email;
  String? profilePictureUrl;
  List<String> dietaryPreferences;
  List<String> shoppingPreferences;

  UserProfile({
    required this.displayName,
    required this.email,
    this.profilePictureUrl,
    this.dietaryPreferences = const [],
    this.shoppingPreferences = const [],
  });
}

class ProfileUpdateResult {
  final bool success;
  final String? error;
  final UserProfile? profile;

  ProfileUpdateResult({required this.success, this.error, this.profile});
}

class MockProfileService {
  UserProfile _profile;
  String _currentPasswordHash;

  MockProfileService({required UserProfile profile, required String currentPassword})
      : _profile = profile,
        _currentPasswordHash = currentPassword;

  ProfileUpdateResult updateDisplayName(String newName) {
    final trimmed = newName.trim();
    if (trimmed.length < 2 || trimmed.length > 50) {
      return ProfileUpdateResult(
        success: false,
        error: 'Name must be between 2 and 50 characters',
      );
    }
    _profile.displayName = trimmed;
    return ProfileUpdateResult(success: true, profile: _profile);
  }

  ProfileUpdateResult changeEmail(String newEmail, String providedPassword) {
    if (providedPassword != _currentPasswordHash) {
      return ProfileUpdateResult(
        success: false,
        error: 'Current password is incorrect',
      );
    }
    _profile.email = newEmail;
    return ProfileUpdateResult(success: true, profile: _profile);
  }

  ProfileUpdateResult saveDietaryPreferences(List<String> prefs) {
    _profile.dietaryPreferences = prefs;
    return ProfileUpdateResult(success: true, profile: _profile);
  }
}

void main() {
  group('FR-001.5.1–5.6: Profile Update', () {
    late MockProfileService profileService;

    setUp(() {
      profileService = MockProfileService(
        profile: UserProfile(
          displayName: faker.person.name(),
          email: faker.internet.email(),
        ),
        currentPassword: 'CurrentPass1!',
      );
    });

    // FR-001.5.1
    test('should successfully update displayName with a valid name', () {
      // Arrange
      final newName = faker.person.name();

      // Act
      final result = profileService.updateDisplayName(newName);

      // Assert
      expect(result.success, isTrue);
      expect(result.profile!.displayName, equals(newName.trim()));
    });

    test('should reject displayName shorter than 2 characters', () {
      // Arrange & Act
      final result = profileService.updateDisplayName('A');

      // Assert
      expect(result.success, isFalse);
      expect(result.error, contains('2 and 50 characters'));
    });

    test('should reject displayName longer than 50 characters', () {
      // Arrange
      final longName = 'A' * 51;

      // Act
      final result = profileService.updateDisplayName(longName);

      // Assert
      expect(result.success, isFalse);
      expect(result.error, contains('2 and 50 characters'));
    });

    test('should accept displayName at exactly 2 characters (lower boundary)', () {
      // Arrange & Act
      final result = profileService.updateDisplayName('Jo');

      // Assert
      expect(result.success, isTrue);
    });

    test('should accept displayName at exactly 50 characters (upper boundary)', () {
      // Arrange
      final maxName = 'A' * 50;

      // Act
      final result = profileService.updateDisplayName(maxName);

      // Assert
      expect(result.success, isTrue);
    });

    test('should reject empty displayName', () {
      // Arrange & Act
      final result = profileService.updateDisplayName('');

      // Assert
      expect(result.success, isFalse);
    });

    // FR-001.5.2
    test('should require current password to change email address', () {
      // Arrange
      final newEmail = faker.internet.email();

      // Act — wrong password
      final result = profileService.changeEmail(newEmail, 'WrongPassword!');

      // Assert
      expect(result.success, isFalse);
      expect(result.error, contains('incorrect'));
    });

    test('should allow email change when correct password is provided', () {
      // Arrange
      final newEmail = faker.internet.email();

      // Act
      final result = profileService.changeEmail(newEmail, 'CurrentPass1!');

      // Assert
      expect(result.success, isTrue);
      expect(result.profile!.email, equals(newEmail));
    });

    // FR-001.5.5
    test('should save valid dietary preferences', () {
      // Arrange
      final prefs = ['vegetarian', 'gluten-free'];

      // Act
      final result = profileService.saveDietaryPreferences(prefs);

      // Assert
      expect(result.success, isTrue);
      expect(result.profile!.dietaryPreferences, equals(prefs));
    });
  });
}

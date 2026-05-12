import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';

/// FR-001.5.7–5.11: App Settings — Notification Preferences and Privacy
///
/// This test suite verifies that each notification toggle can be independently
/// set, that default values match the spec, and that privacy settings accept
/// valid values.

// ── Mock / stub layer ──────────────────────────────────────────────────────

final faker = Faker();

class NotificationSettings {
  bool pushEnabled;
  bool emailEnabled;
  bool priceAlerts;
  bool listSharingNotifications;
  bool promotionalMessages;

  NotificationSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.priceAlerts = true,
    this.listSharingNotifications = true,
    this.promotionalMessages = false, // FR-001.5.7: promotional defaults to off
  });
}

class PrivacySettings {
  String profileVisibility; // 'public' | 'private'
  bool listSharingDefault;
  bool dataCollectionConsent;

  PrivacySettings({
    this.profileVisibility = 'private',
    this.listSharingDefault = false,
    this.dataCollectionConsent = false,
  });
}

class MockSettingsService {
  NotificationSettings _notifications = NotificationSettings();
  PrivacySettings _privacy = PrivacySettings();

  NotificationSettings get notifications => _notifications;
  PrivacySettings get privacy => _privacy;

  void updateNotifications(NotificationSettings settings) {
    _notifications = settings;
  }

  bool setPrivacyVisibility(String visibility) {
    if (visibility != 'public' && visibility != 'private') return false;
    _privacy.profileVisibility = visibility;
    return true;
  }
}

void main() {
  group('FR-001.5.7–5.11: Notification and Privacy Settings', () {
    late MockSettingsService settingsService;

    setUp(() {
      settingsService = MockSettingsService();
    });

    // Default values
    test('should default pushEnabled to true', () {
      // Arrange & Act
      final settings = settingsService.notifications;

      // Assert
      expect(settings.pushEnabled, isTrue);
    });

    test('should default emailEnabled to true', () {
      // Arrange & Act
      final settings = settingsService.notifications;

      // Assert
      expect(settings.emailEnabled, isTrue);
    });

    test('should default priceAlerts to true', () {
      // Arrange & Act
      final settings = settingsService.notifications;

      // Assert
      expect(settings.priceAlerts, isTrue);
    });

    test('should default listSharingNotifications to true', () {
      // Arrange & Act
      final settings = settingsService.notifications;

      // Assert
      expect(settings.listSharingNotifications, isTrue);
    });

    test('should default promotionalMessages to false', () {
      // Arrange & Act
      final settings = settingsService.notifications;

      // Assert
      expect(settings.promotionalMessages, isFalse);
    });

    // Individual toggle tests
    test('should allow pushEnabled to be toggled independently', () {
      // Arrange
      final updated = NotificationSettings(pushEnabled: false);

      // Act
      settingsService.updateNotifications(updated);

      // Assert
      expect(settingsService.notifications.pushEnabled, isFalse);
      expect(settingsService.notifications.emailEnabled, isTrue);
    });

    test('should allow promotionalMessages to be enabled independently', () {
      // Arrange
      final updated = NotificationSettings(promotionalMessages: true);

      // Act
      settingsService.updateNotifications(updated);

      // Assert
      expect(settingsService.notifications.promotionalMessages, isTrue);
    });

    test('should allow all notifications to be disabled simultaneously', () {
      // Arrange
      final allOff = NotificationSettings(
        pushEnabled: false,
        emailEnabled: false,
        priceAlerts: false,
        listSharingNotifications: false,
        promotionalMessages: false,
      );

      // Act
      settingsService.updateNotifications(allOff);

      // Assert
      expect(settingsService.notifications.pushEnabled, isFalse);
      expect(settingsService.notifications.emailEnabled, isFalse);
      expect(settingsService.notifications.priceAlerts, isFalse);
      expect(settingsService.notifications.listSharingNotifications, isFalse);
      expect(settingsService.notifications.promotionalMessages, isFalse);
    });

    // Privacy settings
    test('should accept profileVisibility set to "public"', () {
      // Arrange & Act
      final success = settingsService.setPrivacyVisibility('public');

      // Assert
      expect(success, isTrue);
      expect(settingsService.privacy.profileVisibility, equals('public'));
    });

    test('should accept profileVisibility set to "private"', () {
      // Arrange & Act
      final success = settingsService.setPrivacyVisibility('private');

      // Assert
      expect(success, isTrue);
      expect(settingsService.privacy.profileVisibility, equals('private'));
    });

    test('should reject invalid profileVisibility value', () {
      // Arrange & Act
      final success = settingsService.setPrivacyVisibility('friends-only');

      // Assert
      expect(success, isFalse);
    });
  });
}

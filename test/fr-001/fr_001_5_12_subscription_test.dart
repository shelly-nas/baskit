import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';

/// FR-001.5.12–5.17: Subscription Details
///
/// This test suite verifies that the default subscription tier is 'free',
/// that premium tier exposes a renewal date, that billing history is a list,
/// and that cancellation resets the tier to 'free'.

// ── Mock / stub layer ──────────────────────────────────────────────────────

final faker = Faker();

class BillingRecord {
  final String id;
  final double amount;
  final DateTime date;
  final String description;

  BillingRecord({
    required this.id,
    required this.amount,
    required this.date,
    required this.description,
  });
}

class Subscription {
  String tier; // 'free' | 'premium'
  DateTime? renewalDate;
  List<BillingRecord> billingHistory;

  Subscription({
    this.tier = 'free',
    this.renewalDate,
    this.billingHistory = const [],
  });
}

class MockSubscriptionService {
  Subscription _subscription = Subscription();

  Subscription get current => _subscription;

  void upgradeToPremium() {
    _subscription = Subscription(
      tier: 'premium',
      renewalDate: DateTime.now().add(const Duration(days: 30)),
      billingHistory: _subscription.billingHistory,
    );
  }

  void addBillingRecord(BillingRecord record) {
    _subscription.billingHistory = [..._subscription.billingHistory, record];
  }

  void cancel() {
    _subscription = Subscription(
      tier: 'free',
      renewalDate: null,
      billingHistory: _subscription.billingHistory,
    );
  }
}

void main() {
  group('FR-001.5.12–5.17: Subscription Management', () {
    late MockSubscriptionService subscriptionService;

    setUp(() {
      subscriptionService = MockSubscriptionService();
    });

    test('should default subscription tier to "free"', () {
      // Arrange & Act
      final subscription = subscriptionService.current;

      // Assert
      expect(subscription.tier, equals('free'));
    });

    test('should show renewal date after upgrading to premium', () {
      // Arrange & Act
      subscriptionService.upgradeToPremium();

      // Assert
      expect(subscriptionService.current.renewalDate, isNotNull);
    });

    test('should set tier to "premium" after upgrade', () {
      // Arrange & Act
      subscriptionService.upgradeToPremium();

      // Assert
      expect(subscriptionService.current.tier, equals('premium'));
    });

    test('should have an empty billing history initially', () {
      // Arrange & Act
      final history = subscriptionService.current.billingHistory;

      // Assert
      expect(history, isA<List>());
      expect(history, isEmpty);
    });

    test('should add billing records to the history', () {
      // Arrange
      final record = BillingRecord(
        id: faker.guid.guid(),
        amount: 9.99,
        date: DateTime.now(),
        description: 'Premium monthly',
      );

      // Act
      subscriptionService.addBillingRecord(record);

      // Assert
      expect(subscriptionService.current.billingHistory, hasLength(1));
      expect(subscriptionService.current.billingHistory.first.amount, equals(9.99));
    });

    test('should reset tier to "free" on cancellation', () {
      // Arrange
      subscriptionService.upgradeToPremium();

      // Act
      subscriptionService.cancel();

      // Assert
      expect(subscriptionService.current.tier, equals('free'));
    });

    test('should clear renewal date on cancellation', () {
      // Arrange
      subscriptionService.upgradeToPremium();

      // Act
      subscriptionService.cancel();

      // Assert
      expect(subscriptionService.current.renewalDate, isNull);
    });

    test('should preserve billing history after cancellation', () {
      // Arrange
      subscriptionService.upgradeToPremium();
      subscriptionService.addBillingRecord(BillingRecord(
        id: faker.guid.guid(),
        amount: 9.99,
        date: DateTime.now(),
        description: 'Premium monthly',
      ));

      // Act
      subscriptionService.cancel();

      // Assert — history is retained for record-keeping
      expect(subscriptionService.current.billingHistory, hasLength(1));
    });
  });
}

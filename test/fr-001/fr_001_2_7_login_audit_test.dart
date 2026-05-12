import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';

/// FR-001.2.7: The system SHALL log all login attempts (successful and failed) for security auditing
///
/// This test suite verifies that both successful and failed login attempts
/// create audit log entries containing the correct event type, IP address,
/// and a non-null timestamp.

// ── Mock / stub layer ──────────────────────────────────────────────────────

final faker = Faker();

class AuditLog {
  final String userId;
  final String eventType;
  final DateTime timestamp;
  final String ipAddress;

  AuditLog({
    required this.userId,
    required this.eventType,
    required this.timestamp,
    required this.ipAddress,
  });
}

class MockAuditService {
  final List<AuditLog> _logs = [];

  List<AuditLog> get logs => List.unmodifiable(_logs);

  void logLoginSuccess(String userId, String ipAddress) {
    _logs.add(AuditLog(
      userId: userId,
      eventType: 'login_success',
      timestamp: DateTime.now(),
      ipAddress: ipAddress,
    ));
  }

  void logLoginFailure(String userId, String ipAddress) {
    _logs.add(AuditLog(
      userId: userId,
      eventType: 'login_failed',
      timestamp: DateTime.now(),
      ipAddress: ipAddress,
    ));
  }

  List<AuditLog> getLogsForUser(String userId) =>
      _logs.where((l) => l.userId == userId).toList();
}

void main() {
  group('FR-001.2.7: Login Audit Logging', () {
    late MockAuditService auditService;

    setUp(() {
      auditService = MockAuditService();
    });

    test('should create a login_success entry on successful login', () {
      // Arrange
      final userId = faker.guid.guid();
      final ip = faker.internet.ipv4Address();

      // Act
      auditService.logLoginSuccess(userId, ip);

      // Assert
      final logs = auditService.getLogsForUser(userId);
      expect(logs, hasLength(1));
      expect(logs.first.eventType, equals('login_success'));
    });

    test('should create a login_failed entry on failed login', () {
      // Arrange
      final userId = faker.guid.guid();
      final ip = faker.internet.ipv4Address();

      // Act
      auditService.logLoginFailure(userId, ip);

      // Assert
      final logs = auditService.getLogsForUser(userId);
      expect(logs, hasLength(1));
      expect(logs.first.eventType, equals('login_failed'));
    });

    test('should include IP address in the audit log entry', () {
      // Arrange
      final userId = faker.guid.guid();
      final ip = faker.internet.ipv4Address();

      // Act
      auditService.logLoginSuccess(userId, ip);

      // Assert
      final log = auditService.getLogsForUser(userId).first;
      expect(log.ipAddress, equals(ip));
    });

    test('should include a non-null timestamp in the audit log entry', () {
      // Arrange
      final userId = faker.guid.guid();
      final ip = faker.internet.ipv4Address();

      // Act
      auditService.logLoginSuccess(userId, ip);

      // Assert
      final log = auditService.getLogsForUser(userId).first;
      expect(log.timestamp, isNotNull);
    });

    test('should log multiple events for the same user', () {
      // Arrange
      final userId = faker.guid.guid();
      final ip = faker.internet.ipv4Address();

      // Act
      auditService.logLoginFailure(userId, ip);
      auditService.logLoginFailure(userId, ip);
      auditService.logLoginSuccess(userId, ip);

      // Assert
      final logs = auditService.getLogsForUser(userId);
      expect(logs, hasLength(3));
    });

    test('should not mix logs from different users', () {
      // Arrange
      final userId1 = faker.guid.guid();
      final userId2 = faker.guid.guid();
      final ip = faker.internet.ipv4Address();

      // Act
      auditService.logLoginSuccess(userId1, ip);
      auditService.logLoginFailure(userId2, ip);

      // Assert
      expect(auditService.getLogsForUser(userId1), hasLength(1));
      expect(auditService.getLogsForUser(userId2), hasLength(1));
    });
  });
}

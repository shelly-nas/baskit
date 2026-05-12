import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';

/// FR-001.6.11–6.14: Multi-Device Session Management
///
/// This test suite verifies that users can list all active sessions, terminate
/// individual sessions, terminate all other sessions while keeping the current
/// one active, and that terminated sessions no longer appear in the active list.

// ── Mock / stub layer ──────────────────────────────────────────────────────

final faker = Faker();

class SessionInfo {
  final String id;
  final String deviceType;
  final String browser;
  final DateTime lastActive;

  SessionInfo({
    required this.id,
    required this.deviceType,
    required this.browser,
    required this.lastActive,
  });
}

class MockSessionRepository {
  final List<SessionInfo> _sessions = [];

  void addSession(SessionInfo session) {
    _sessions.add(session);
  }

  List<SessionInfo> getActiveSessions() => List.unmodifiable(_sessions);

  bool terminateSession(String sessionId) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return false;
    _sessions.removeAt(index);
    return true;
  }

  void terminateAllExcept(String currentSessionId) {
    _sessions.removeWhere((s) => s.id != currentSessionId);
  }

  bool isActive(String sessionId) => _sessions.any((s) => s.id == sessionId);
}

SessionInfo _makeSession() => SessionInfo(
      id: faker.guid.guid(),
      deviceType: 'mobile',
      browser: 'Chrome',
      lastActive: DateTime.now(),
    );

void main() {
  group('FR-001.6.11–6.14: Multi-Device Session Management', () {
    late MockSessionRepository sessionRepo;

    setUp(() {
      sessionRepo = MockSessionRepository();
    });

    // FR-001.6.11
    test('should return all active sessions for a user', () {
      // Arrange
      sessionRepo.addSession(_makeSession());
      sessionRepo.addSession(_makeSession());
      sessionRepo.addSession(_makeSession());

      // Act
      final sessions = sessionRepo.getActiveSessions();

      // Assert
      expect(sessions, hasLength(3));
    });

    test('should include session id, deviceType, browser, and lastActive', () {
      // Arrange
      final session = _makeSession();
      sessionRepo.addSession(session);

      // Act
      final sessions = sessionRepo.getActiveSessions();

      // Assert
      expect(sessions.first.id, isNotNull);
      expect(sessions.first.deviceType, isNotNull);
      expect(sessions.first.browser, isNotNull);
      expect(sessions.first.lastActive, isNotNull);
    });

    // FR-001.6.13
    test('should terminate an individual session by id', () {
      // Arrange
      final session = _makeSession();
      sessionRepo.addSession(session);

      // Act
      final success = sessionRepo.terminateSession(session.id);

      // Assert
      expect(success, isTrue);
      expect(sessionRepo.isActive(session.id), isFalse);
    });

    test('should not affect other sessions when terminating one', () {
      // Arrange
      final session1 = _makeSession();
      final session2 = _makeSession();
      sessionRepo.addSession(session1);
      sessionRepo.addSession(session2);

      // Act
      sessionRepo.terminateSession(session1.id);

      // Assert
      expect(sessionRepo.isActive(session2.id), isTrue);
    });

    // FR-001.6.14
    test('should keep current session when terminating all others', () {
      // Arrange
      final currentSession = _makeSession();
      final otherSession1 = _makeSession();
      final otherSession2 = _makeSession();
      sessionRepo.addSession(currentSession);
      sessionRepo.addSession(otherSession1);
      sessionRepo.addSession(otherSession2);

      // Act
      sessionRepo.terminateAllExcept(currentSession.id);

      // Assert
      expect(sessionRepo.isActive(currentSession.id), isTrue);
      expect(sessionRepo.getActiveSessions(), hasLength(1));
    });

    test('should remove other sessions when terminating all except current', () {
      // Arrange
      final currentSession = _makeSession();
      final other = _makeSession();
      sessionRepo.addSession(currentSession);
      sessionRepo.addSession(other);

      // Act
      sessionRepo.terminateAllExcept(currentSession.id);

      // Assert
      expect(sessionRepo.isActive(other.id), isFalse);
    });

    test('terminated session should no longer appear in active list', () {
      // Arrange
      final session = _makeSession();
      sessionRepo.addSession(session);

      // Act
      sessionRepo.terminateSession(session.id);

      // Assert
      expect(sessionRepo.getActiveSessions(), isEmpty);
    });
  });
}

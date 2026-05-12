import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';

/// FR-001.2.2: The system SHALL implement rate limiting (5 failed attempts per 15 minutes per IP address)
///
/// This test suite verifies that rate limiting blocks excess login attempts per IP
/// and resets correctly after the window expires.

// ── Mock / stub layer ──────────────────────────────────────────────────────

final faker = Faker();

class RateLimitResult {
  final bool allowed;
  final int remaining;
  final String? message;
  final int? waitMinutes;

  RateLimitResult({
    required this.allowed,
    required this.remaining,
    this.message,
    this.waitMinutes,
  });
}

class RateLimiter {
  final int maxAttempts;
  final int windowMinutes;

  final Map<String, _IpRecord> _store = {};

  RateLimiter({required this.maxAttempts, required this.windowMinutes});

  RateLimitResult check(String ipAddress) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final record = _store[ipAddress];

    if (record == null || now > record.resetAt) {
      return RateLimitResult(allowed: true, remaining: maxAttempts - 1);
    }

    final allowed = record.attempts < maxAttempts;
    final remaining = (maxAttempts - record.attempts).clamp(0, maxAttempts);
    final waitMinutes = allowed
        ? null
        : ((record.resetAt - now) / 60000).ceil();

    return RateLimitResult(
      allowed: allowed,
      remaining: remaining,
      message: allowed
          ? null
          : 'Too many login attempts. Please try again in $waitMinutes minutes',
      waitMinutes: waitMinutes,
    );
  }

  void record(String ipAddress) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowMs = windowMinutes * 60 * 1000;
    final existing = _store[ipAddress];

    if (existing == null || now > existing.resetAt) {
      _store[ipAddress] = _IpRecord(attempts: 1, resetAt: now + windowMs);
    } else {
      _store[ipAddress] = _IpRecord(
        attempts: existing.attempts + 1,
        resetAt: existing.resetAt,
      );
    }
  }

  void reset(String ipAddress) {
    _store.remove(ipAddress);
  }

  void simulateWindowExpiry(String ipAddress) {
    _store.remove(ipAddress);
  }
}

class _IpRecord {
  final int attempts;
  final int resetAt;

  _IpRecord({required this.attempts, required this.resetAt});
}

void main() {
  group('FR-001.2.2: Rate Limiting — 5 Failed Attempts per 15 Minutes per IP', () {
    late RateLimiter rateLimiter;

    setUp(() {
      rateLimiter = RateLimiter(maxAttempts: 5, windowMinutes: 15);
    });

    test('should allow the first attempt for a new IP', () {
      // Arrange
      final ip = faker.internet.ipv4Address();

      // Act
      final result = rateLimiter.check(ip);

      // Assert
      expect(result.allowed, isTrue);
    });

    test('should allow the 5th attempt (boundary)', () {
      // Arrange
      final ip = faker.internet.ipv4Address();

      // Act — record 4 failures then check on the 5th
      for (int i = 0; i < 4; i++) {
        rateLimiter.record(ip);
      }
      final result = rateLimiter.check(ip);

      // Assert
      expect(result.allowed, isTrue);
    });

    test('should block the 6th attempt', () {
      // Arrange
      final ip = faker.internet.ipv4Address();

      // Act — record 5 failures, then check
      for (int i = 0; i < 5; i++) {
        rateLimiter.record(ip);
      }
      final result = rateLimiter.check(ip);

      // Assert
      expect(result.allowed, isFalse);
      expect(result.remaining, equals(0));
    });

    test('should return exact error message including wait minutes when blocked', () {
      // Arrange
      final ip = faker.internet.ipv4Address();

      // Act
      for (int i = 0; i < 5; i++) {
        rateLimiter.record(ip);
      }
      final result = rateLimiter.check(ip);

      // Assert — message must match the spec format
      expect(result.message, startsWith('Too many login attempts. Please try again in'));
      expect(result.message, contains('minutes'));
    });

    test('should allow attempts again after window resets', () {
      // Arrange
      final ip = faker.internet.ipv4Address();
      for (int i = 0; i < 5; i++) {
        rateLimiter.record(ip);
      }

      // Act — simulate window expiry
      rateLimiter.simulateWindowExpiry(ip);
      final result = rateLimiter.check(ip);

      // Assert
      expect(result.allowed, isTrue);
    });

    test('should track different IPs independently', () {
      // Arrange
      final ip1 = '192.168.1.1';
      final ip2 = '10.0.0.1';

      // Act — exhaust ip1 but not ip2
      for (int i = 0; i < 5; i++) {
        rateLimiter.record(ip1);
      }

      final result1 = rateLimiter.check(ip1);
      final result2 = rateLimiter.check(ip2);

      // Assert
      expect(result1.allowed, isFalse);
      expect(result2.allowed, isTrue);
    });

    test('should reset count for an IP after explicit reset call', () {
      // Arrange
      final ip = faker.internet.ipv4Address();
      for (int i = 0; i < 5; i++) {
        rateLimiter.record(ip);
      }

      // Act
      rateLimiter.reset(ip);
      final result = rateLimiter.check(ip);

      // Assert
      expect(result.allowed, isTrue);
    });
  });
}

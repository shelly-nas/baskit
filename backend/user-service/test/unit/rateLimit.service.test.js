/**
 * Unit Tests: rateLimit.service.js
 *
 * FR-001.2.2: Rate limiting — 5 failed attempts per 15 minutes per IP
 * FR-001.2.3: Account locking after 10 consecutive failed attempts
 * FR-001.4.8: Password reset rate limit — 3 requests per hour per email
 */

process.env.NODE_ENV = 'test';

jest.mock('../../../shared/src', () => ({
  database: {
    query: jest.fn(),
    getClient: jest.fn(),
    connect: jest.fn().mockResolvedValue(true),
    close: jest.fn().mockResolvedValue(true),
  },
  logger: {
    info: jest.fn(),
    error: jest.fn(),
    debug: jest.fn(),
    warn: jest.fn(),
  },
}));

const { faker } = require('@faker-js/faker');

const rateLimitService = require('../../src/services/rateLimit.service');

describe('rateLimit.service — FR-001.2.2, 2.3, 4.8', () => {
  beforeEach(() => {
    rateLimitService.clearAllRateLimits();
  });

  // ── IP rate limiting ────────────────────────────────────────────────────

  describe('checkIpRateLimit — FR-001.2.2', () => {
    it('should allow the first attempt for a new IP address', () => {
      // Arrange
      const ip = faker.internet.ip();

      // Act
      const result = rateLimitService.checkIpRateLimit(ip);

      // Assert
      expect(result.allowed).toBe(true);
    });

    it('should allow the 5th attempt (boundary)', () => {
      // Arrange
      const ip = faker.internet.ip();

      // Act — record 4 failures first
      for (let i = 0; i < 4; i++) {
        rateLimitService.recordIpFailedAttempt(ip);
      }
      const result = rateLimitService.checkIpRateLimit(ip);

      // Assert
      expect(result.allowed).toBe(true);
    });

    it('should block requests after 5 failed attempts', () => {
      // Arrange
      const ip = faker.internet.ip();

      // Act — record 5 failures
      for (let i = 0; i < 5; i++) {
        rateLimitService.recordIpFailedAttempt(ip);
      }
      const result = rateLimitService.checkIpRateLimit(ip);

      // Assert
      expect(result.allowed).toBe(false);
      expect(result.remaining).toBe(0);
    });

    it('should return a waitTime in minutes when blocked', () => {
      // Arrange
      const ip = faker.internet.ip();
      for (let i = 0; i < 5; i++) {
        rateLimitService.recordIpFailedAttempt(ip);
      }

      // Act
      const result = rateLimitService.checkIpRateLimit(ip);

      // Assert
      expect(result.waitTime).toBeGreaterThan(0);
    });

    it('should return allowed=true for a null/undefined IP (fail-open)', () => {
      // Arrange & Act
      const result = rateLimitService.checkIpRateLimit(null);

      // Assert
      expect(result.allowed).toBe(true);
    });

    it('should track different IP addresses independently', () => {
      // Arrange
      const ip1 = '192.168.1.1';
      const ip2 = '10.0.0.1';

      // Act — exhaust ip1
      for (let i = 0; i < 5; i++) {
        rateLimitService.recordIpFailedAttempt(ip1);
      }

      // Assert
      expect(rateLimitService.checkIpRateLimit(ip1).allowed).toBe(false);
      expect(rateLimitService.checkIpRateLimit(ip2).allowed).toBe(true);
    });
  });

  // ── recordIpFailedAttempt ───────────────────────────────────────────────

  describe('recordIpFailedAttempt — FR-001.2.2', () => {
    it('should increment the failed attempt counter for an IP', () => {
      // Arrange
      const ip = faker.internet.ip();

      // Act
      rateLimitService.recordIpFailedAttempt(ip);
      rateLimitService.recordIpFailedAttempt(ip);
      const status = rateLimitService.getIpRateLimitStatus(ip);

      // Assert
      expect(status.attempts).toBe(2);
    });

    it('should do nothing when IP is null', () => {
      // Arrange & Act — should not throw
      expect(() => rateLimitService.recordIpFailedAttempt(null)).not.toThrow();
    });
  });

  // ── resetIpRateLimit ────────────────────────────────────────────────────

  describe('resetIpRateLimit — FR-001.2.2', () => {
    it('should clear the IP record so subsequent checks show allowed=true', () => {
      // Arrange
      const ip = faker.internet.ip();
      for (let i = 0; i < 5; i++) {
        rateLimitService.recordIpFailedAttempt(ip);
      }

      // Act
      rateLimitService.resetIpRateLimit(ip);
      const result = rateLimitService.checkIpRateLimit(ip);

      // Assert
      expect(result.allowed).toBe(true);
    });

    it('should do nothing when IP is null', () => {
      // Arrange & Act — should not throw
      expect(() => rateLimitService.resetIpRateLimit(null)).not.toThrow();
    });
  });

  // ── checkUserLoginAttempts ──────────────────────────────────────────────

  describe('checkUserLoginAttempts — FR-001.2.3', () => {
    it('should not lock when failed attempts are below 10', () => {
      // Arrange & Act
      const result = rateLimitService.checkUserLoginAttempts('user-1', 9);

      // Assert
      expect(result.shouldLock).toBe(false);
      expect(result.lockUntil).toBeNull();
    });

    it('should lock when failed attempts reach 10', () => {
      // Arrange & Act
      const result = rateLimitService.checkUserLoginAttempts('user-1', 10);

      // Assert
      expect(result.shouldLock).toBe(true);
    });

    it('should include a future lockUntil date when shouldLock is true', () => {
      // Arrange & Act
      const result = rateLimitService.checkUserLoginAttempts('user-1', 10);

      // Assert
      expect(result.lockUntil).toBeDefined();
      expect(result.lockUntil).not.toBeNull();
      expect(new Date(result.lockUntil).getTime()).toBeGreaterThan(Date.now());
    });

    it('should report remaining attempts correctly below threshold', () => {
      // Arrange & Act
      const result = rateLimitService.checkUserLoginAttempts('user-1', 7);

      // Assert
      expect(result.remainingAttempts).toBe(3);
    });

    it('should default currentAttempts to 0 when omitted', () => {
      // Arrange & Act
      const result = rateLimitService.checkUserLoginAttempts('user-1');

      // Assert
      expect(result.shouldLock).toBe(false);
      expect(result.attempts).toBe(0);
    });
  });

  // ── checkAccountLockStatus ──────────────────────────────────────────────

  describe('checkAccountLockStatus — FR-001.2.3', () => {
    it('should return isLocked=false for an active user with no lock', () => {
      // Arrange
      const user = { status: 'active', locked_until: null };

      // Act
      const result = rateLimitService.checkAccountLockStatus(user);

      // Assert
      expect(result.isLocked).toBe(false);
    });

    it('should return isLocked=true and a reason for a permanently locked account', () => {
      // Arrange
      const user = { status: 'locked', locked_until: null };

      // Act
      const result = rateLimitService.checkAccountLockStatus(user);

      // Assert
      expect(result.isLocked).toBe(true);
      expect(result.reason).toBeDefined();
    });

    it('should return isLocked=true for a temporarily locked account', () => {
      // Arrange
      const futureDate = new Date(Date.now() + 30 * 60 * 1000); // 30 min from now
      const user = { status: 'active', locked_until: futureDate };

      // Act
      const result = rateLimitService.checkAccountLockStatus(user);

      // Assert
      expect(result.isLocked).toBe(true);
      expect(result.reason).toContain('Account locked due to multiple failed login attempts');
    });

    it('should return isLocked=false when the lock has expired', () => {
      // Arrange
      const pastDate = new Date(Date.now() - 60 * 1000); // 1 min ago
      const user = { status: 'active', locked_until: pastDate };

      // Act
      const result = rateLimitService.checkAccountLockStatus(user);

      // Assert
      expect(result.isLocked).toBe(false);
    });

    it('should return isLocked=false when user is null', () => {
      // Arrange & Act
      const result = rateLimitService.checkAccountLockStatus(null);

      // Assert
      expect(result.isLocked).toBe(false);
    });
  });

  // ── checkPasswordResetRateLimit ─────────────────────────────────────────

  describe('checkPasswordResetRateLimit — FR-001.4.8', () => {
    it('should allow the first 3 requests per email within an hour', () => {
      // Arrange
      const email = faker.internet.email();

      // Act
      rateLimitService.recordPasswordResetAttempt(email);
      rateLimitService.recordPasswordResetAttempt(email);
      const result = rateLimitService.checkPasswordResetRateLimit(email);

      // Assert — 2 attempts recorded; 3rd check should still be allowed
      expect(result.allowed).toBe(true);
    });

    it('should block the 4th request per email within an hour', () => {
      // Arrange
      const email = faker.internet.email();

      // Act — record 3 attempts
      rateLimitService.recordPasswordResetAttempt(email);
      rateLimitService.recordPasswordResetAttempt(email);
      rateLimitService.recordPasswordResetAttempt(email);
      const result = rateLimitService.checkPasswordResetRateLimit(email);

      // Assert
      expect(result.allowed).toBe(false);
    });

    it('should return allowed=true for null email (fail-open)', () => {
      // Arrange & Act
      const result = rateLimitService.checkPasswordResetRateLimit(null);

      // Assert
      expect(result.allowed).toBe(true);
    });
  });

  // ── recordPasswordResetAttempt ──────────────────────────────────────────

  describe('recordPasswordResetAttempt — FR-001.4.8', () => {
    it('should increment the password reset attempt counter', () => {
      // Arrange
      const email = faker.internet.email();

      // Act
      rateLimitService.recordPasswordResetAttempt(email);
      rateLimitService.recordPasswordResetAttempt(email);
      rateLimitService.recordPasswordResetAttempt(email);
      const result = rateLimitService.checkPasswordResetRateLimit(email);

      // Assert — 3rd attempt is the limit; now blocked
      expect(result.allowed).toBe(false);
    });

    it('should do nothing when email is null', () => {
      // Arrange & Act — should not throw
      expect(() => rateLimitService.recordPasswordResetAttempt(null)).not.toThrow();
    });
  });
});

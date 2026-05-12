/**
 * Unit Tests: audit.service.js
 *
 * FR-001.2.7: The system SHALL log all login attempts for security auditing
 * FR-001.4.x: Password reset events are logged
 * FR-001.1.6/1.7: Email verification is logged
 * FR-001.2.3: Account lockout is logged
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
const { database } = require('../../../shared/src');
const auditService = require('../../src/services/audit.service');

describe('audit.service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    database.query.mockResolvedValue({ rows: [], rowCount: 1 });
  });

  // ── logRegistration ─────────────────────────────────────────────────────

  describe('logRegistration', () => {
    it('should insert an audit event with eventType "registration"', async () => {
      // Arrange
      const userId = faker.string.uuid();
      const email = faker.internet.email();
      const ip = faker.internet.ip();

      // Act
      await auditService.logRegistration(userId, email, ip, 'Mozilla/5.0');

      // Assert
      expect(database.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO audit_logs'),
        expect.arrayContaining(['registration'])
      );
    });

    it('should include the user ID in the query parameters', async () => {
      // Arrange
      const userId = faker.string.uuid();

      // Act
      await auditService.logRegistration(userId, faker.internet.email(), faker.internet.ip(), null);

      // Assert
      expect(database.query).toHaveBeenCalledWith(
        expect.any(String),
        expect.arrayContaining([userId])
      );
    });
  });

  // ── logLoginSuccess ─────────────────────────────────────────────────────

  describe('logLoginSuccess — FR-001.2.7', () => {
    it('should insert an audit event with eventType "login_success"', async () => {
      // Arrange
      const userId = faker.string.uuid();

      // Act
      await auditService.logLoginSuccess(userId, faker.internet.email(), faker.internet.ip(), null);

      // Assert
      expect(database.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO audit_logs'),
        expect.arrayContaining(['login_success'])
      );
    });
  });

  // ── logLoginFailure ─────────────────────────────────────────────────────

  describe('logLoginFailure — FR-001.2.7', () => {
    it('should insert an audit event with eventType "login_failed"', async () => {
      // Arrange
      const userId = faker.string.uuid();

      // Act
      await auditService.logLoginFailure(userId, faker.internet.email(), 'Invalid password', faker.internet.ip(), null);

      // Assert
      expect(database.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO audit_logs'),
        expect.arrayContaining(['login_failed'])
      );
    });

    it('should accept null userId for unknown-user login failures', async () => {
      // Arrange & Act
      await auditService.logLoginFailure(null, faker.internet.email(), 'Not found', faker.internet.ip(), null);

      // Assert
      expect(database.query).toHaveBeenCalledWith(
        expect.any(String),
        expect.arrayContaining([null])
      );
    });
  });

  // ── logPasswordResetRequest ─────────────────────────────────────────────

  describe('logPasswordResetRequest — FR-001.4.1', () => {
    it('should insert an audit event with eventType "password_reset_request"', async () => {
      // Arrange
      const userId = faker.string.uuid();

      // Act
      await auditService.logPasswordResetRequest(userId, faker.internet.email(), faker.internet.ip(), null);

      // Assert
      expect(database.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO audit_logs'),
        expect.arrayContaining(['password_reset_request'])
      );
    });
  });

  // ── logPasswordResetComplete ────────────────────────────────────────────

  describe('logPasswordResetComplete — FR-001.4.4', () => {
    it('should insert an audit event with eventType "password_reset_complete"', async () => {
      // Arrange
      const userId = faker.string.uuid();

      // Act
      await auditService.logPasswordResetComplete(userId, faker.internet.email(), faker.internet.ip(), null);

      // Assert
      expect(database.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO audit_logs'),
        expect.arrayContaining(['password_reset_complete'])
      );
    });
  });

  // ── logEmailVerification ────────────────────────────────────────────────

  describe('logEmailVerification — FR-001.1.6/1.7', () => {
    it('should insert an audit event with eventType "email_verification"', async () => {
      // Arrange
      const userId = faker.string.uuid();

      // Act
      await auditService.logEmailVerification(userId, faker.internet.email(), faker.internet.ip(), null);

      // Assert
      expect(database.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO audit_logs'),
        expect.arrayContaining(['email_verification'])
      );
    });
  });

  // ── logAccountLockout ───────────────────────────────────────────────────

  describe('logAccountLockout — FR-001.2.3', () => {
    it('should insert an audit event with eventType "account_locked"', async () => {
      // Arrange
      const userId = faker.string.uuid();

      // Act
      await auditService.logAccountLockout(userId, faker.internet.email(), 'Too many attempts', faker.internet.ip(), null);

      // Assert
      expect(database.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO audit_logs'),
        expect.arrayContaining(['account_locked'])
      );
    });
  });

  // ── Silent failure on DB error ──────────────────────────────────────────

  describe('Silent failure behaviour', () => {
    it('should NOT throw when database.query rejects (audit failures are silent)', async () => {
      // Arrange
      database.query.mockRejectedValueOnce(new Error('DB connection failed'));
      const userId = faker.string.uuid();

      // Act & Assert — must not throw
      await expect(
        auditService.logLoginSuccess(userId, faker.internet.email(), faker.internet.ip(), null)
      ).resolves.not.toThrow();
    });

    it('should NOT throw when logLoginFailure DB query rejects', async () => {
      // Arrange
      database.query.mockRejectedValueOnce(new Error('Timeout'));

      // Act & Assert
      await expect(
        auditService.logLoginFailure(null, faker.internet.email(), 'error', faker.internet.ip(), null)
      ).resolves.not.toThrow();
    });
  });

  // ── Metadata serialisation ──────────────────────────────────────────────

  describe('Metadata serialisation', () => {
    it('should JSON-stringify metadata in the query parameters', async () => {
      // Arrange
      const userId = faker.string.uuid();
      const email = faker.internet.email();

      // Act
      await auditService.logRegistration(userId, email, faker.internet.ip(), null);

      // Assert — last param should be a JSON string containing the email
      const callArgs = database.query.mock.calls[0];
      const params = callArgs[1];
      const metadataParam = params[params.length - 1];
      expect(typeof metadataParam).toBe('string');
      expect(metadataParam).toContain(email);
    });
  });
});

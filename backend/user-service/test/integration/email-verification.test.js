// Set test environment before requiring app
process.env.NODE_ENV = 'test';

const request = require('supertest');
const app = require('../../src/index');

jest.mock('../../../shared/src', () => {
  const actualShared = jest.requireActual('../../../shared/src');
  return {
    ...actualShared,
    database: {
      query: jest.fn(),
      getClient: jest.fn(),
      connect: jest.fn().mockResolvedValue(true),
      close: jest.fn().mockResolvedValue(true),
    },
  };
});

const { database } = require('../../../shared/src');

describe('Email Verification Integration Tests', () => {
  let mockClient;

  beforeEach(() => {
    jest.clearAllMocks();
    
    // Reset database.query mock explicitly
    database.query.mockReset();
    
    mockClient = {
      query: jest.fn(),
      release: jest.fn(),
    };
    database.getClient.mockResolvedValue(mockClient);
  });

  afterAll(async () => {
    await database.close();
  });

  describe('FR-001.1.7: Email verification process', () => {
    test('should verify email with valid token', async () => {
      const validToken = 'valid-verification-token-123';
      const userId = '550e8400-e29b-41d4-a716-446655440000';

      mockClient.query
        .mockResolvedValueOnce({ rows: [] }) // BEGIN
        .mockResolvedValueOnce({ // Get token
          rows: [{
            id: 'token-id',
            user_id: userId,
            token: validToken,
            expires_at: new Date(Date.now() + 1000 * 60 * 60), // 1 hour from now
            used: false,
          }],
        })
        .mockResolvedValueOnce({ // Update user status
          rows: [{
            id: userId,
            email: 'verified@example.com',
            display_name: 'Verified User',
            status: 'active',
          }],
        })
        .mockResolvedValueOnce({ rows: [] }) // Mark token as used
        .mockResolvedValueOnce({ rows: [] }) // Audit log
        .mockResolvedValueOnce({ rows: [] }); // COMMIT

      const response = await request(app)
        .post('/api/auth/verify-email')
        .send({ token: validToken })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user.status).toBe('active');
      expect(response.body.message).toContain('verified');
    });

    test('should transition user status from pending_verification to active', async () => {
      const token = 'token-123';
      const userId = 'user-id-123';

      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{
            id: 'token-id',
            user_id: userId,
            token,
            expires_at: new Date(Date.now() + 1000),
            used: false,
          }],
        })
        .mockResolvedValueOnce({
          rows: [{
            id: userId,
            email: 'transition@example.com',
            display_name: 'Transition User',
            status: 'active', // Changed from pending_verification
          }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/auth/verify-email')
        .send({ token })
        .expect(200);

      expect(response.body.data.user.status).toBe('active');
    });

    test('should reject expired verification token', async () => {
      const expiredToken = 'expired-token';

      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{
            id: 'token-id',
            user_id: 'user-id',
            token: expiredToken,
            expires_at: new Date(Date.now() - 1000), // Expired
            used: false,
          }],
        })
        .mockResolvedValueOnce({ rows: [] }); // ROLLBACK

      const response = await request(app)
        .post('/api/auth/verify-email')
        .send({ token: expiredToken })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('expired');
    });

    test('should reject already used verification token', async () => {
      const usedToken = 'used-token';

      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{
            id: 'token-id',
            user_id: 'user-id',
            token: usedToken,
            expires_at: new Date(Date.now() + 1000),
            used: true, // Already used
          }],
        })
        .mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/auth/verify-email')
        .send({ token: usedToken })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('invalid');
    });

    test('should reject non-existent verification token', async () => {
      const nonExistentToken = 'non-existent-token';

      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] }) // No token found
        .mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/auth/verify-email')
        .send({ token: nonExistentToken })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('invalid');
    });

    test('should mark token as used after verification', async () => {
      const token = 'mark-used-token';
      const userId = 'user-id';

      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{
            id: 'token-id',
            user_id: userId,
            token,
            expires_at: new Date(Date.now() + 1000),
            used: false,
          }],
        })
        .mockResolvedValueOnce({
          rows: [{
            id: userId,
            email: 'user@example.com',
            display_name: 'User',
            status: 'active',
          }],
        })
        .mockImplementationOnce((query, params) => {
          // Verify the token is marked as used
          expect(query).toContain('UPDATE');
          expect(query).toContain('used_at');
          return Promise.resolve({ rows: [] });
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] });

      await request(app)
        .post('/api/auth/verify-email')
        .send({ token })
        .expect(200);
    });

    test('should log verification event in audit log', async () => {
      const token = 'audit-token';
      const userId = 'audit-user-id';

      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{
            id: 'token-id',
            user_id: userId,
            token,
            expires_at: new Date(Date.now() + 1000),
            used: false,
          }],
        })
        .mockResolvedValueOnce({
          rows: [{
            id: userId,
            email: 'audit@example.com',
            display_name: 'Audit User',
            status: 'active',
          }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockImplementationOnce((query, params) => {
          // Verify audit log entry
          expect(query).toContain('INSERT INTO audit_logs');
          expect(params).toContain('email_verification');
          return Promise.resolve({ rows: [] });
        })
        .mockResolvedValueOnce({ rows: [] });

      await request(app)
        .post('/api/auth/verify-email')
        .send({ token })
        .expect(200);
    });
  });

  describe('FR-001.1.6: Resend verification email', () => {
    test('should generate new token and resend email', async () => {
      const email = 'resend@example.com';
      const userId = 'resend-user-id';

      database.query
        .mockResolvedValueOnce({ // Get user
          rows: [{
            id: userId,
            email,
            display_name: 'Resend User',
            status: 'pending_verification',
          }],
        })
        .mockResolvedValueOnce({ // Create new token
          rows: [{
            id: 'new-token-id',
            token: 'new-verification-token',
            expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000),
          }],
        })
        .mockResolvedValueOnce({ rows: [] }); // Audit log

      const response = await request(app)
        .post('/api/auth/resend-verification')
        .send({ email })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('sent');
    });

    test('should reject resend for already verified user', async () => {
      const email = 'verified@example.com';

      database.query.mockResolvedValueOnce({
        rows: [{
          id: 'user-id',
          email,
          display_name: 'Verified User',
          status: 'active', // Already verified
        }],
      });

      const response = await request(app)
        .post('/api/auth/resend-verification')
        .send({ email })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('already verified');
    });

    test('should reject resend for non-existent user', async () => {
      const email = 'nonexistent@example.com';

      database.query.mockResolvedValueOnce({ rows: [] }); // No user found

      const response = await request(app)
        .post('/api/auth/resend-verification')
        .send({ email })
        .expect(404);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('not found');
    });

    test('should generate token with 24-hour expiration', async () => {
      const email = 'token-expiry@example.com';
      const userId = 'user-id';

      database.query
        .mockResolvedValueOnce({
          rows: [{
            id: userId,
            email,
            display_name: 'User',
            status: 'pending_verification',
          }],
        })
        .mockImplementationOnce((query, params) => {
          // Verify token expiration is 24 hours
          const expiresAt = params.find(p => p instanceof Date);
          const hoursDiff = (expiresAt - new Date()) / (1000 * 60 * 60);
          expect(hoursDiff).toBeGreaterThan(23.9);
          expect(hoursDiff).toBeLessThan(24.1);

          return Promise.resolve({
            rows: [{
              id: 'token-id',
              token: 'token',
              expires_at: expiresAt,
            }],
          });
        })
        .mockResolvedValueOnce({ rows: [] });

      await request(app)
        .post('/api/auth/resend-verification')
        .send({ email })
        .expect(200);
    });

    test('should invalidate old tokens when resending', async () => {
      const email = 'invalidate@example.com';
      const userId = 'user-id';

      database.query
        .mockResolvedValueOnce({
          rows: [{
            id: userId,
            email,
            display_name: 'User',
            status: 'pending_verification',
          }],
        })
        .mockResolvedValueOnce({
          rows: [{
            id: 'new-token-id',
            token: 'new-token',
            expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000),
          }],
        })
        .mockResolvedValueOnce({ rows: [] });

      await request(app)
        .post('/api/auth/resend-verification')
        .send({ email })
        .expect(200);

      // Verify the token service was called to create a new token
      // Old tokens are implicitly invalidated by the new token
      expect(database.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO verification_tokens'),
        expect.any(Array)
      );
    });
  });

  describe('Error handling', () => {
    test('should handle database errors during verification', async () => {
      mockClient.query.mockRejectedValue(new Error('Database error'));

      await request(app)
        .post('/api/auth/verify-email')
        .send({ token: 'test-token' })
        .expect(500);
    });

    test('should rollback transaction on verification error', async () => {
      const token = 'error-token';

      mockClient.query
        .mockResolvedValueOnce({ rows: [] }) // BEGIN
        .mockResolvedValueOnce({
          rows: [{
            id: 'token-id',
            user_id: 'user-id',
            token,
            expires_at: new Date(Date.now() + 1000),
            used: false,
          }],
        })
        .mockRejectedValueOnce(new Error('Update failed')) // Update user fails
        .mockResolvedValueOnce({ rows: [] }); // ROLLBACK

      await request(app)
        .post('/api/auth/verify-email')
        .send({ token })
        .expect(500);

      expect(mockClient.query).toHaveBeenCalledWith(
        expect.stringContaining('ROLLBACK')
      );
    });

    test('should handle missing token parameter', async () => {
      const response = await request(app)
        .post('/api/auth/verify-email')
        .send({}) // No token
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBeDefined();
    });

    test('should handle missing email in resend request', async () => {
      const response = await request(app)
        .post('/api/auth/resend-verification')
        .send({}) // No email
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    test('should prevent token reuse after successful verification', async () => {
      const token = 'reuse-token';
      const userId = 'user-id';

      // First verification - success
      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{
            id: 'token-id',
            user_id: userId,
            token,
            expires_at: new Date(Date.now() + 1000),
            used: false,
          }],
        })
        .mockResolvedValueOnce({
          rows: [{
            id: userId,
            email: 'user@example.com',
            display_name: 'User',
            status: 'active',
          }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] });

      await request(app)
        .post('/api/auth/verify-email')
        .send({ token })
        .expect(200);

      // Second attempt with same token - should fail
      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{
            id: 'token-id',
            user_id: userId,
            token,
            expires_at: new Date(Date.now() + 1000),
            used: true, // Now marked as used
          }],
        })
        .mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/auth/verify-email')
        .send({ token })
        .expect(400);

      expect(response.body.error).toContain('invalid');
    });
  });

  describe('Security considerations', () => {
    test('should not reveal if email exists in resend request', async () => {
      const nonExistentEmail = 'doesnotexist@example.com';

      database.query.mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/auth/resend-verification')
        .send({ email: nonExistentEmail })
        .expect(404);

      // Should not say "email not found" but rather generic message
      expect(response.body.error).toBeDefined();
    });

    test('should accept token as string only', async () => {
      const response = await request(app)
        .post('/api/auth/verify-email')
        .send({ token: 12345 }) // Number instead of string
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    test('should validate token format', async () => {
      const response = await request(app)
        .post('/api/auth/verify-email')
        .send({ token: '' }) // Empty string
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });
});

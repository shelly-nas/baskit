const request = require('supertest');
const app = require('../../src/index');
const { database } = require('../../shared/src');
const passwordService = require('../../src/services/password.service');
const rateLimitService = require('../../src/services/rateLimit.service');
const jwtService = require('../../src/services/jwt.service');
const jwt = require('jsonwebtoken');

/**
 * Test Suite for Login Requirements FR-001.2.x
 * 
 * This test suite validates all login-related functional requirements:
 * - FR-001.2.1: Email and password login
 * - FR-001.2.2: Rate limiting (5 attempts per 15 minutes per IP)
 * - FR-001.2.3: Account locking after 10 failed attempts
 * - FR-001.2.4: JWT tokens with 24-hour expiration
 * - FR-001.2.5: Refresh tokens with 30-day expiration
 * - FR-001.2.6: "Remember Me" functionality (30 days)
 * - FR-001.2.7: Login attempt logging for security auditing
 * - FR-001.2.8: Prevent login for unverified accounts
 */
describe('Login Requirements - FR-001.2.x', () => {
  let testUser;
  let testUserId;
  const TEST_EMAIL = 'loginreq@example.com';
  const TEST_PASSWORD = 'SecurePass123!';

  beforeAll(async () => {
    await database.connect();
  });

  afterAll(async () => {
    if (testUserId) {
      await database.query('DELETE FROM users WHERE id = $1', [testUserId]);
    }
    await database.close();
  });

  beforeEach(async () => {
    // Clear rate limits
    rateLimitService.clearAllRateLimits();

    // Delete any existing test user first to ensure clean state
    await database.query('DELETE FROM users WHERE email = $1', [TEST_EMAIL]);

    // Create verified test user
    const hashedPassword = await passwordService.hashPassword(TEST_PASSWORD);
    const result = await database.query(
      `INSERT INTO users (email, password_hash, display_name, status, is_email_verified)
       VALUES ($1, $2, $3, 'active', true)
       RETURNING id, email, display_name, status`,
      [TEST_EMAIL, hashedPassword, 'Test User']
    );
    testUser = result.rows[0];
    testUserId = testUser.id;
  });

  afterEach(async () => {
    if (testUserId) {
      await database.query('DELETE FROM user_sessions WHERE user_id = $1', [testUserId]);
      await database.query('DELETE FROM audit_logs WHERE user_id = $1', [testUserId]);
      await database.query('DELETE FROM users WHERE id = $1', [testUserId]);
      testUserId = null;
    }
  });

  /**
   * FR-001.2.1: Email and Password Login Functionality
   */
  describe('FR-001.2.1: Email and Password Login', () => {
    it('should successfully authenticate with valid email and password', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe('Login successful');
      expect(response.body.data.user).toBeDefined();
      expect(response.body.data.user.email).toBe(TEST_EMAIL);
    });

    it('should reject login with incorrect email', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'wrong@example.com',
          password: TEST_PASSWORD,
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Invalid email or password');
    });

    it('should reject login with incorrect password', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: 'WrongPassword123!',
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Invalid email or password');
    });

    it('should require both email and password fields', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({ email: TEST_EMAIL })
        .expect(400);

      expect(response.body.error).toContain('Password is required');
    });

    it('should validate email format', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'invalid-email-format',
          password: TEST_PASSWORD,
        })
        .expect(400);

      expect(response.body.error).toContain('valid email');
    });
  });

  /**
   * FR-001.2.2: Rate Limiting (5 failed attempts per 15 minutes per IP)
   */
  describe('FR-001.2.2: Rate Limiting - 5 attempts per 15 minutes', () => {
    it('should allow up to 5 failed login attempts from same IP', async () => {
      // Attempt 5 times with wrong password
      for (let i = 0; i < 5; i++) {
        const response = await request(app)
          .post('/api/auth/login')
          .send({
            email: TEST_EMAIL,
            password: 'WrongPassword123!',
          });

        expect(response.status).toBe(401);
        expect(response.body.error).toBe('Invalid email or password');
      }
    });

    it('should block 6th failed login attempt from same IP', async () => {
      // Make 5 failed attempts
      for (let i = 0; i < 5; i++) {
        await request(app)
          .post('/api/auth/login')
          .send({
            email: TEST_EMAIL,
            password: 'WrongPassword123!',
          });
      }

      // 6th attempt should be rate limited
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD, // Even with correct password
        })
        .expect(401);

      expect(response.body.error).toContain('Too many login attempts');
    });

    it('should enforce rate limit per IP address', async () => {
      // Make 5 failed attempts
      for (let i = 0; i < 5; i++) {
        await request(app)
          .post('/api/auth/login')
          .send({
            email: TEST_EMAIL,
            password: 'WrongPassword123!',
          });
      }

      // Verify rate limit is applied
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(401);

      expect(response.body.error).toContain('Too many login attempts');
    });

    it('should reset rate limit after successful login within limit', async () => {
      // Make 3 failed attempts
      for (let i = 0; i < 3; i++) {
        await request(app)
          .post('/api/auth/login')
          .send({
            email: TEST_EMAIL,
            password: 'WrongPassword123!',
          });
      }

      // Successful login should work
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(200);

      expect(response.body.success).toBe(true);
    });
  });

  /**
   * FR-001.2.3: Account Locking after 10 Consecutive Failed Attempts
   */
  describe('FR-001.2.3: Account Locking - 10 failed attempts', () => {
    it('should lock account after exactly 10 failed login attempts', async () => {
      // Make 10 failed attempts
      for (let i = 0; i < 10; i++) {
        await request(app)
          .post('/api/auth/login')
          .send({
            email: TEST_EMAIL,
            password: 'WrongPassword123!',
          });
      }

      // Verify account is locked in database
      const result = await database.query(
        'SELECT failed_login_attempts, locked_until FROM users WHERE id = $1',
        [testUserId]
      );

      expect(result.rows[0].failed_login_attempts).toBe(10);
      expect(result.rows[0].locked_until).not.toBeNull();
    });

    it('should prevent login when account is locked even with correct password', async () => {
      // Lock the account
      const lockUntil = new Date(Date.now() + 30 * 60 * 1000); // 30 minutes
      await database.query(
        'UPDATE users SET locked_until = $1, failed_login_attempts = 10 WHERE id = $2',
        [lockUntil, testUserId]
      );

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(401);

      expect(response.body.error).toContain('Account temporarily locked');
    });

    it('should include lock duration in error message', async () => {
      // Lock the account
      const lockUntil = new Date(Date.now() + 30 * 60 * 1000);
      await database.query(
        'UPDATE users SET locked_until = $1, failed_login_attempts = 10 WHERE id = $2',
        [lockUntil, testUserId]
      );

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(401);

      expect(response.body.error).toContain('locked');
      expect(response.body.error).toMatch(/\d+\s*minute/i);
    });

    it('should reset failed attempts counter on successful login', async () => {
      // Set some failed attempts
      await database.query(
        'UPDATE users SET failed_login_attempts = 5 WHERE id = $1',
        [testUserId]
      );

      await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(200);

      // Verify counter was reset
      const result = await database.query(
        'SELECT failed_login_attempts FROM users WHERE id = $1',
        [testUserId]
      );

      expect(result.rows[0].failed_login_attempts).toBe(0);
    });

    it('should increment failed attempts counter on each failed login', async () => {
      // Make 3 failed attempts
      for (let i = 0; i < 3; i++) {
        await request(app)
          .post('/api/auth/login')
          .send({
            email: TEST_EMAIL,
            password: 'WrongPassword123!',
          });
      }

      // Check counter
      const result = await database.query(
        'SELECT failed_login_attempts FROM users WHERE id = $1',
        [testUserId]
      );

      expect(result.rows[0].failed_login_attempts).toBe(3);
    });
  });

  /**
   * FR-001.2.4: JWT Access Tokens with 24-hour Expiration
   */
  describe('FR-001.2.4: JWT Access Token - 24 hour expiration', () => {
    it('should return JWT access token on successful login', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(200);

      expect(response.body.data.tokens).toBeDefined();
      expect(response.body.data.tokens.accessToken).toBeDefined();
      expect(typeof response.body.data.tokens.accessToken).toBe('string');
    });

    it('should generate access token with 24-hour expiration', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(200);

      const accessToken = response.body.data.tokens.accessToken;
      const decoded = jwt.decode(accessToken);

      // Calculate expiration time
      const now = Math.floor(Date.now() / 1000);
      const expectedExpiry = 24 * 60 * 60; // 24 hours in seconds
      const actualExpiry = decoded.exp - now;

      // Allow 5 second tolerance for test execution time
      expect(actualExpiry).toBeGreaterThan(expectedExpiry - 5);
      expect(actualExpiry).toBeLessThanOrEqual(expectedExpiry);
    });

    it('should include user information in JWT payload', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(200);

      const accessToken = response.body.data.tokens.accessToken;
      const decoded = jwt.decode(accessToken);

      expect(decoded.userId).toBe(testUserId);
      expect(decoded.email).toBe(TEST_EMAIL);
      expect(decoded.type).toBe('access');
    });

    it('should use HS256 algorithm for JWT signing', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(200);

      const accessToken = response.body.data.tokens.accessToken;
      const decoded = jwt.decode(accessToken, { complete: true });

      expect(decoded.header.alg).toBe('HS256');
    });

    it('should include issuer and audience in JWT claims', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(200);

      const accessToken = response.body.data.tokens.accessToken;
      const decoded = jwt.decode(accessToken);

      expect(decoded.iss).toBe('baskit-auth');
      expect(decoded.aud).toBe('baskit-api');
    });
  });

  /**
   * FR-001.2.5: Refresh Tokens with 30-day Expiration
   */
  describe('FR-001.2.5: Refresh Token - 30 day expiration', () => {
    it('should return refresh token on successful login', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(200);

      expect(response.body.data.tokens.refreshToken).toBeDefined();
      expect(typeof response.body.data.tokens.refreshToken).toBe('string');
    });

    it('should generate refresh token with 30-day expiration', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(200);

      const refreshToken = response.body.data.tokens.refreshToken;
      const decoded = jwt.decode(refreshToken);

      // Calculate expiration time
      const now = Math.floor(Date.now() / 1000);
      const expectedExpiry = 30 * 24 * 60 * 60; // 30 days in seconds
      const actualExpiry = decoded.exp - now;

      // Allow 5 second tolerance
      expect(actualExpiry).toBeGreaterThan(expectedExpiry - 5);
      expect(actualExpiry).toBeLessThanOrEqual(expectedExpiry);
    });

    it('should mark refresh token as type "refresh"', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(200);

      const refreshToken = response.body.data.tokens.refreshToken;
      const decoded = jwt.decode(refreshToken);

      expect(decoded.type).toBe('refresh');
    });

    it('should allow token refresh with valid refresh token', async () => {
      // Login to get tokens
      const loginResponse = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        });

      const refreshToken = loginResponse.body.data.tokens.refreshToken;

      // Use refresh token to get new tokens
      const refreshResponse = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken })
        .expect(200);

      expect(refreshResponse.body.success).toBe(true);
      expect(refreshResponse.body.data.tokens.accessToken).toBeDefined();
      expect(refreshResponse.body.data.tokens.refreshToken).toBeDefined();
    });

    it('should issue new access and refresh tokens on refresh', async () => {
      const loginResponse = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        });

      const originalAccessToken = loginResponse.body.data.tokens.accessToken;
      const originalRefreshToken = loginResponse.body.data.tokens.refreshToken;

      const refreshResponse = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken: originalRefreshToken })
        .expect(200);

      const newAccessToken = refreshResponse.body.data.tokens.accessToken;
      const newRefreshToken = refreshResponse.body.data.tokens.refreshToken;

      // Tokens should be different
      expect(newAccessToken).not.toBe(originalAccessToken);
      expect(newRefreshToken).not.toBe(originalRefreshToken);
    });

    it('should reject invalid refresh token', async () => {
      const response = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken: 'invalid-token-string' })
        .expect(401);

      expect(response.body.error).toContain('Invalid or expired refresh token');
    });
  });

  /**
   * FR-001.2.6: "Remember Me" Functionality (30 days)
   */
  describe('FR-001.2.6: Remember Me - 30 day session extension', () => {
    it('should accept rememberMe parameter on login', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
          rememberMe: true,
        })
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should extend access token to 30 days when rememberMe is true', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
          rememberMe: true,
        })
        .expect(200);

      expect(response.body.data.tokens.expiresIn).toBe('30d');
    });

    it('should use 24h expiration when rememberMe is false', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
          rememberMe: false,
        })
        .expect(200);

      expect(response.body.data.tokens.expiresIn).toBe('24h');
    });

    it('should use 24h expiration when rememberMe is not provided', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(200);

      expect(response.body.data.tokens.expiresIn).toBe('24h');
    });

    it('should create session with 30-day expiration when rememberMe is true', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
          rememberMe: true,
        })
        .expect(200);

      const sessionId = response.body.data.session.id;

      // Check session in database
      const result = await database.query(
        'SELECT expires_at FROM user_sessions WHERE id = $1',
        [sessionId]
      );

      const expiresAt = new Date(result.rows[0].expires_at);
      const now = new Date();
      const daysDifference = (expiresAt - now) / (1000 * 60 * 60 * 24);

      // Should be approximately 30 days (allow 29-31 days tolerance)
      expect(daysDifference).toBeGreaterThan(29);
      expect(daysDifference).toBeLessThan(31);
    });

    it('should create session with 24-hour expiration when rememberMe is false', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
          rememberMe: false,
        })
        .expect(200);

      const sessionId = response.body.data.session.id;

      // Check session in database
      const result = await database.query(
        'SELECT expires_at FROM user_sessions WHERE id = $1',
        [sessionId]
      );

      const expiresAt = new Date(result.rows[0].expires_at);
      const now = new Date();
      const hoursDifference = (expiresAt - now) / (1000 * 60 * 60);

      // Should be approximately 24 hours (allow 23-25 hours tolerance)
      expect(hoursDifference).toBeGreaterThan(23);
      expect(hoursDifference).toBeLessThan(25);
    });
  });

  /**
   * FR-001.2.7: Audit Logging for Security
   */
  describe('FR-001.2.7: Login Attempt Logging', () => {
    it('should log successful login attempts', async () => {
      await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(200);

      // Check audit log
      const result = await database.query(
        `SELECT * FROM audit_logs 
         WHERE user_id = $1 AND event_type = 'login_success'
         ORDER BY created_at DESC LIMIT 1`,
        [testUserId]
      );

      expect(result.rows.length).toBe(1);
      expect(result.rows[0].event_type).toBe('login_success');
      expect(result.rows[0].user_id).toBe(testUserId);
    });

    it('should log failed login attempts', async () => {
      await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: 'WrongPassword123!',
        })
        .expect(401);

      // Check audit log
      const result = await database.query(
        `SELECT * FROM audit_logs 
         WHERE event_type = 'login_failed'
         ORDER BY created_at DESC LIMIT 1`
      );

      expect(result.rows.length).toBe(1);
      expect(result.rows[0].event_type).toBe('login_failed');
    });

    it('should include IP address in audit logs', async () => {
      await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(200);

      const result = await database.query(
        `SELECT * FROM audit_logs 
         WHERE user_id = $1 AND event_type = 'login_success'
         ORDER BY created_at DESC LIMIT 1`,
        [testUserId]
      );

      expect(result.rows[0].ip_address).toBeDefined();
      expect(result.rows[0].ip_address).not.toBeNull();
    });

    it('should include timestamp in audit logs', async () => {
      await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(200);

      const result = await database.query(
        `SELECT * FROM audit_logs 
         WHERE user_id = $1 AND event_type = 'login_success'
         ORDER BY created_at DESC LIMIT 1`,
        [testUserId]
      );

      expect(result.rows[0].created_at).toBeDefined();
      expect(new Date(result.rows[0].created_at)).toBeInstanceOf(Date);
    });

    it('should log all failed attempts with email in description', async () => {
      await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: 'WrongPassword123!',
        })
        .expect(401);

      const result = await database.query(
        `SELECT * FROM audit_logs 
         WHERE event_type = 'login_failed'
         ORDER BY created_at DESC LIMIT 1`
      );

      expect(result.rows[0].event_description).toContain(TEST_EMAIL);
    });

    it('should log account locking events', async () => {
      // Make 10 failed attempts to trigger account lock
      for (let i = 0; i < 10; i++) {
        await request(app)
          .post('/api/auth/login')
          .send({
            email: TEST_EMAIL,
            password: 'WrongPassword123!',
          });
      }

      // Check for account locked event
      const result = await database.query(
        `SELECT * FROM audit_logs 
         WHERE user_id = $1 AND event_type = 'account_locked'
         ORDER BY created_at DESC LIMIT 1`,
        [testUserId]
      );

      expect(result.rows.length).toBeGreaterThan(0);
      expect(result.rows[0].event_type).toBe('account_locked');
    });

    it('should maintain audit trail for security analysis', async () => {
      // Make multiple login attempts (mix of success and failures)
      await request(app)
        .post('/api/auth/login')
        .send({ email: TEST_EMAIL, password: 'Wrong1!' });

      await request(app)
        .post('/api/auth/login')
        .send({ email: TEST_EMAIL, password: 'Wrong2!' });

      await request(app)
        .post('/api/auth/login')
        .send({ email: TEST_EMAIL, password: TEST_PASSWORD });

      // Verify all attempts are logged
      const result = await database.query(
        `SELECT * FROM audit_logs 
         WHERE user_id = $1 AND event_type LIKE 'login%'
         ORDER BY created_at ASC`,
        [testUserId]
      );

      expect(result.rows.length).toBeGreaterThanOrEqual(3);
    });
  });

  /**
   * FR-001.2.8: Prevent Login for Unverified Accounts
   */
  describe('FR-001.2.8: Unverified Account Prevention', () => {
    it('should reject login for unverified email accounts', async () => {
      // Set user as unverified
      await database.query(
        `UPDATE users 
         SET is_email_verified = false, status = 'pending_verification'
         WHERE id = $1`,
        [testUserId]
      );

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(401);

      expect(response.body.error).toBe('Please verify your email address before logging in');
    });

    it('should allow login for verified email accounts', async () => {
      // Ensure user is verified
      await database.query(
        `UPDATE users 
         SET is_email_verified = true, status = 'active'
         WHERE id = $1`,
        [testUserId]
      );

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should check email verification before password validation', async () => {
      // Set user as unverified
      await database.query(
        `UPDATE users 
         SET is_email_verified = false, status = 'pending_verification'
         WHERE id = $1`,
        [testUserId]
      );

      // Try with wrong password
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: 'WrongPassword123!',
        })
        .expect(401);

      // Should get verification error, not password error
      expect(response.body.error).toBe('Please verify your email address before logging in');
    });

    it('should prevent unverified accounts even with correct credentials', async () => {
      await database.query(
        `UPDATE users 
         SET is_email_verified = false, status = 'pending_verification'
         WHERE id = $1`,
        [testUserId]
      );

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD, // Correct password
        })
        .expect(401);

      expect(response.body.error).toContain('verify your email');
    });

    it('should not increment failed attempts for unverified accounts', async () => {
      await database.query(
        `UPDATE users 
         SET is_email_verified = false, status = 'pending_verification',
         failed_login_attempts = 0
         WHERE id = $1`,
        [testUserId]
      );

      await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(401);

      // Check failed attempts counter
      const result = await database.query(
        'SELECT failed_login_attempts FROM users WHERE id = $1',
        [testUserId]
      );

      expect(result.rows[0].failed_login_attempts).toBe(0);
    });

    it('should log unverified login attempts', async () => {
      await database.query(
        `UPDATE users 
         SET is_email_verified = false, status = 'pending_verification'
         WHERE id = $1`,
        [testUserId]
      );

      await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(401);

      // Check audit log for unverified attempt
      const result = await database.query(
        `SELECT * FROM audit_logs 
         WHERE event_type = 'login_failed'
         AND event_description LIKE '%unverified email%'
         ORDER BY created_at DESC LIMIT 1`
      );

      expect(result.rows.length).toBe(1);
    });
  });

  /**
   * Integration Tests - Multiple Requirements
   */
  describe('Integration: Combined Requirements', () => {
    it('should enforce all security measures in correct order', async () => {
      // 1. Check email verification first
      await database.query(
        `UPDATE users 
         SET is_email_verified = false
         WHERE id = $1`,
        [testUserId]
      );

      let response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(401);

      expect(response.body.error).toContain('verify your email');

      // 2. Verify user and test account lock
      await database.query(
        `UPDATE users 
         SET is_email_verified = true, 
         status = 'active',
         locked_until = $1
         WHERE id = $2`,
        [new Date(Date.now() + 30 * 60 * 1000), testUserId]
      );

      response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(401);

      expect(response.body.error).toContain('locked');

      // 3. Unlock and test rate limiting
      await database.query(
        'UPDATE users SET locked_until = NULL WHERE id = $1',
        [testUserId]
      );

      rateLimitService.clearAllRateLimits();

      // Trigger rate limit
      for (let i = 0; i < 5; i++) {
        await request(app)
          .post('/api/auth/login')
          .send({
            email: TEST_EMAIL,
            password: 'Wrong!',
          });
      }

      response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
        })
        .expect(401);

      expect(response.body.error).toContain('Too many');
    });

    it('should provide complete login response with all required data', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: TEST_EMAIL,
          password: TEST_PASSWORD,
          rememberMe: true,
        })
        .expect(200);

      // Verify complete response structure
      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('message', 'Login successful');
      expect(response.body).toHaveProperty('data');

      // User data
      expect(response.body.data.user).toBeDefined();
      expect(response.body.data.user.email).toBe(TEST_EMAIL);

      // Token data (FR-001.2.4, FR-001.2.5, FR-001.2.6)
      expect(response.body.data.tokens.accessToken).toBeDefined();
      expect(response.body.data.tokens.refreshToken).toBeDefined();
      expect(response.body.data.tokens.expiresIn).toBe('30d');

      // Session data
      expect(response.body.data.session.id).toBeDefined();
      expect(response.body.data.session.expiresAt).toBeDefined();
    });
  });
});

const request = require('supertest');
const app = require('../../src/index');
const { database } = require('../../shared/src');
const passwordService = require('../../src/services/password.service');
const rateLimitService = require('../../src/services/rateLimit.service');

describe('Login Flow - Integration Tests', () => {
  let testUser;
  let testUserId;

  beforeAll(async () => {
    // Connect to test database
    await database.connect();
  });

  afterAll(async () => {
    // Clean up and close database connection
    if (testUserId) {
      await database.query('DELETE FROM users WHERE id = $1', [testUserId]);
    }
    await database.close();
  });

  beforeEach(async () => {
    // Clear rate limits before each test
    rateLimitService.clearAllRateLimits();

    // Create a verified test user
    const hashedPassword = await passwordService.hashPassword('TestPass123!');
    const result = await database.query(
      `INSERT INTO users (email, password_hash, display_name, status, is_email_verified)
       VALUES ($1, $2, $3, 'active', true)
       RETURNING id, email, display_name, status`,
      ['logintest@example.com', hashedPassword, 'Login Test User']
    );
    testUser = result.rows[0];
    testUserId = testUser.id;
  });

  afterEach(async () => {
    // Clean up test user and sessions
    if (testUserId) {
      await database.query('DELETE FROM user_sessions WHERE user_id = $1', [testUserId]);
      await database.query('DELETE FROM audit_logs WHERE user_id = $1', [testUserId]);
      await database.query('DELETE FROM users WHERE id = $1', [testUserId]);
      testUserId = null;
    }
  });

  describe('POST /api/auth/login - Successful Login', () => {
    it('should login successfully with valid credentials', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'logintest@example.com',
          password: 'TestPass123!',
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe('Login successful');
      expect(response.body.data).toHaveProperty('user');
      expect(response.body.data).toHaveProperty('tokens');
      expect(response.body.data).toHaveProperty('session');

      // Verify user data
      expect(response.body.data.user.email).toBe('logintest@example.com');
      expect(response.body.data.user.displayName).toBe('Login Test User');

      // Verify tokens
      expect(response.body.data.tokens.accessToken).toBeDefined();
      expect(response.body.data.tokens.refreshToken).toBeDefined();
      expect(response.body.data.tokens.expiresIn).toBeDefined();

      // Verify session
      expect(response.body.data.session.id).toBeDefined();
      expect(response.body.data.session.expiresAt).toBeDefined();
    });

    it('should login with remember me and extend token expiration', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'logintest@example.com',
          password: 'TestPass123!',
          rememberMe: true,
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.tokens.expiresIn).toBe('30d');
    });

    it('should reset failed login attempts on successful login', async () => {
      // Set failed attempts
      await database.query(
        'UPDATE users SET failed_login_attempts = 5 WHERE id = $1',
        [testUserId]
      );

      await request(app)
        .post('/api/auth/login')
        .send({
          email: 'logintest@example.com',
          password: 'TestPass123!',
        })
        .expect(200);

      // Verify failed attempts reset
      const result = await database.query(
        'SELECT failed_login_attempts FROM users WHERE id = $1',
        [testUserId]
      );
      expect(result.rows[0].failed_login_attempts).toBe(0);
    });
  });

  describe('POST /api/auth/login - Failed Login Scenarios', () => {
    it('should fail with invalid email', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'TestPass123!',
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Invalid email or password');
    });

    it('should fail with invalid password', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'logintest@example.com',
          password: 'WrongPassword123!',
        })
        .expect(401);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Invalid email or password');
    });

    it('should increment failed login attempts on wrong password', async () => {
      await request(app)
        .post('/api/auth/login')
        .send({
          email: 'logintest@example.com',
          password: 'WrongPassword123!',
        })
        .expect(401);

      const result = await database.query(
        'SELECT failed_login_attempts FROM users WHERE id = $1',
        [testUserId]
      );
      expect(result.rows[0].failed_login_attempts).toBe(1);
    });

    it('should prevent login for unverified email', async () => {
      // Set user as unverified
      await database.query(
        "UPDATE users SET status = 'pending_verification', is_email_verified = false WHERE id = $1",
        [testUserId]
      );

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'logintest@example.com',
          password: 'TestPass123!',
        })
        .expect(401);

      expect(response.body.error).toBe('Please verify your email address before logging in');
    });
  });

  describe('POST /api/auth/login - Account Locking', () => {
    it('should lock account after 10 consecutive failed login attempts', async () => {
      // Make 10 failed login attempts
      for (let i = 0; i < 10; i++) {
        await request(app)
          .post('/api/auth/login')
          .send({
            email: 'logintest@example.com',
            password: 'WrongPassword123!',
          });
      }

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'logintest@example.com',
          password: 'TestPass123!', // Even with correct password
        })
        .expect(401);

      expect(response.body.error).toContain('Account locked due to multiple failed login attempts');

      // Verify account is locked
      const result = await database.query(
        'SELECT locked_until, failed_login_attempts FROM users WHERE id = $1',
        [testUserId]
      );
      expect(result.rows[0].failed_login_attempts).toBe(10);
      expect(result.rows[0].locked_until).not.toBeNull();
    });

    it('should prevent login when account is locked', async () => {
      // Lock the account
      const lockUntil = new Date(Date.now() + 30 * 60 * 1000); // 30 minutes
      await database.query(
        'UPDATE users SET locked_until = $1 WHERE id = $2',
        [lockUntil, testUserId]
      );

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'logintest@example.com',
          password: 'TestPass123!',
        })
        .expect(401);

      expect(response.body.error).toContain('Account temporarily locked');
    });
  });

  describe('POST /api/auth/login - Rate Limiting', () => {
    it('should enforce rate limiting after 5 failed attempts from same IP', async () => {
      // Make 5 failed login attempts
      for (let i = 0; i < 5; i++) {
        await request(app)
          .post('/api/auth/login')
          .send({
            email: 'logintest@example.com',
            password: 'WrongPassword123!',
          });
      }

      // 6th attempt should be rate limited
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'logintest@example.com',
          password: 'TestPass123!',
        })
        .expect(401);

      expect(response.body.error).toContain('Too many login attempts');
    });
  });

  describe('POST /api/auth/login - Input Validation', () => {
    it('should fail with missing email', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          password: 'TestPass123!',
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('Email is required');
    });

    it('should fail with missing password', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'logintest@example.com',
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('Password is required');
    });

    it('should fail with invalid email format', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'not-an-email',
          password: 'TestPass123!',
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('valid email');
    });
  });

  describe('POST /api/auth/logout', () => {
    let accessToken;
    let refreshToken;

    beforeEach(async () => {
      // Login to get tokens
      const loginResponse = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'logintest@example.com',
          password: 'TestPass123!',
        });

      accessToken = loginResponse.body.data.tokens.accessToken;
      refreshToken = loginResponse.body.data.tokens.refreshToken;
    });

    it('should logout successfully with valid token', async () => {
      const response = await request(app)
        .post('/api/auth/logout')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ refreshToken })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toBe('Logged out successfully');
    });

    it('should fail logout without authorization header', async () => {
      const response = await request(app)
        .post('/api/auth/logout')
        .send({ refreshToken })
        .expect(401);

      expect(response.body.error).toBe('No authentication token provided');
    });
  });

  describe('POST /api/auth/refresh', () => {
    let accessToken;
    let refreshToken;

    beforeEach(async () => {
      // Login to get tokens
      const loginResponse = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'logintest@example.com',
          password: 'TestPass123!',
        });

      accessToken = loginResponse.body.data.tokens.accessToken;
      refreshToken = loginResponse.body.data.tokens.refreshToken;
    });

    it('should refresh tokens successfully', async () => {
      const response = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.tokens.accessToken).toBeDefined();
      expect(response.body.data.tokens.refreshToken).toBeDefined();
      expect(response.body.data.tokens.accessToken).not.toBe(accessToken);
      expect(response.body.data.tokens.refreshToken).not.toBe(refreshToken);
    });

    it('should fail with invalid refresh token', async () => {
      const response = await request(app)
        .post('/api/auth/refresh')
        .send({ refreshToken: 'invalid-token' })
        .expect(401);

      expect(response.body.error).toContain('Invalid or expired refresh token');
    });

    it('should fail with missing refresh token', async () => {
      const response = await request(app)
        .post('/api/auth/refresh')
        .send({})
        .expect(400);

      expect(response.body.error).toBe('Refresh token is required');
    });
  });

  describe('Audit Logging', () => {
    it('should log successful login attempts', async () => {
      await request(app)
        .post('/api/auth/login')
        .send({
          email: 'logintest@example.com',
          password: 'TestPass123!',
        })
        .expect(200);

      const result = await database.query(
        "SELECT * FROM audit_logs WHERE user_id = $1 AND event_type = 'login_success' ORDER BY created_at DESC LIMIT 1",
        [testUserId]
      );

      expect(result.rows.length).toBe(1);
      expect(result.rows[0].event_description).toContain('logged in successfully');
    });

    it('should log failed login attempts', async () => {
      await request(app)
        .post('/api/auth/login')
        .send({
          email: 'logintest@example.com',
          password: 'WrongPassword123!',
        })
        .expect(401);

      const result = await database.query(
        "SELECT * FROM audit_logs WHERE event_type = 'login_failed' ORDER BY created_at DESC LIMIT 1"
      );

      expect(result.rows.length).toBe(1);
      expect(result.rows[0].event_description).toContain('Login failed');
    });
  });
});

// Set test environment before requiring app
process.env.NODE_ENV = 'test';

const request = require('supertest');
const app = require('../../src/index');

// Mock dependencies
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

describe('User Registration Integration Tests', () => {
  let mockClient;

  beforeEach(() => {
    jest.clearAllMocks();
    
    // Setup mock database client
    mockClient = {
      query: jest.fn(),
      release: jest.fn(),
    };
    database.getClient.mockResolvedValue(mockClient);
  });

  afterAll(async () => {
    // Close any open connections
    await database.close();
  });

  describe('FR-001.1.1: User registration with email, password, and display name', () => {
    test('should successfully register a new user with valid data', async () => {
      const userData = {
        email: 'newuser@example.com',
        password: 'SecurePass123!',
        displayName: 'John Doe',
      };

      // Mock no existing user
      mockClient.query
        .mockResolvedValueOnce({ rows: [] }) // BEGIN
        .mockResolvedValueOnce({ rows: [] }) // Check existing user
        .mockImplementationOnce((query, params) => { // Insert user
          return Promise.resolve({
            rows: [{
            id: '550e8400-e29b-41d4-a716-446655440000',
            email: userData.email,
            display_name: userData.displayName,
            status: 'pending_verification',
            created_at: new Date(),
          }],
          });
        })
        .mockResolvedValueOnce({ rows: [] }) // Insert preferences
        .mockImplementationOnce((query, params) => { // Create verification token
          return Promise.resolve({
            rows: [{
              id: 'token-id',
              token: 'verification-token-123',
              expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000),
            }],
          });
        })
        .mockResolvedValueOnce({ rows: [] }) // Audit log
        .mockResolvedValueOnce({ rows: [] }); // COMMIT

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect('Content-Type', /json/)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.user).toBeDefined();
      expect(response.body.data.user.email).toBe(userData.email);
      expect(response.body.data.user.displayName).toBe(userData.displayName);
      expect(response.body.data.user.status).toBe('pending_verification');
      expect(response.body.message).toContain('verify your account');
    });

    test('should return user data without password hash', async () => {
      const userData = {
        email: 'secure@example.com',
        password: 'SecurePass123!',
        displayName: 'Secure User',
      };

      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{
            id: '550e8400-e29b-41d4-a716-446655440000',
            email: userData.email,
            display_name: userData.displayName,
            status: 'pending_verification',
            created_at: new Date(),
          }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{ id: 'token-id', token: 'token', expires_at: new Date() }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(201);

      expect(response.body.data.user.password).toBeUndefined();
      expect(response.body.data.user.password_hash).toBeUndefined();
    });
  });

  describe('FR-001.1.2: Email format validation', () => {
    test('should reject invalid email formats', async () => {
      const invalidEmails = [
        'notanemail',
        '@example.com',
        'user@',
        'user @example.com',
      ];

      for (const email of invalidEmails) {
        const response = await request(app)
          .post('/api/auth/register')
          .send({
            email,
            password: 'SecurePass123!',
            displayName: 'Test User',
          })
          .expect(400);

        expect(response.body.success).toBe(false);
        expect(response.body.error).toContain('email');
      }
    });

    test('should accept valid email formats', async () => {
      const validEmail = 'valid.user+tag@example.co.uk';
      
      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{
            id: 'user-id',
            email: validEmail,
            display_name: 'Test User',
            status: 'pending_verification',
            created_at: new Date(),
          }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{ id: 'token-id', token: 'token', expires_at: new Date() }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: validEmail,
          password: 'SecurePass123!',
          displayName: 'Test User',
        })
        .expect(201);

      expect(response.body.success).toBe(true);
    });
  });

  describe('FR-001.1.3: Password complexity enforcement', () => {
    test('should reject password without uppercase letter', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'user@example.com',
          password: 'lowercase123!',
          displayName: 'Test User',
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('complexity');
    });

    test('should reject password without lowercase letter', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'user@example.com',
          password: 'UPPERCASE123!',
          displayName: 'Test User',
        })
        .expect(400);

      expect(response.body.error).toContain('complexity');
    });

    test('should reject password without number', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'user@example.com',
          password: 'NoNumbers!@#',
          displayName: 'Test User',
        })
        .expect(400);

      expect(response.body.error).toContain('complexity');
    });

    test('should reject password without special character', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'user@example.com',
          password: 'NoSpecial123',
          displayName: 'Test User',
        })
        .expect(400);

      expect(response.body.error).toContain('complexity');
    });

    test('should reject password shorter than 8 characters', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'user@example.com',
          password: 'Short1!',
          displayName: 'Test User',
        })
        .expect(400);

      expect(response.body.error).toContain('8 characters');
    });
  });

  describe('FR-001.1.4: Display name validation', () => {
    test('should reject display name shorter than 2 characters', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'user@example.com',
          password: 'SecurePass123!',
          displayName: 'A',
        })
        .expect(400);

      expect(response.body.error).toContain('2 and 50 characters');
    });

    test('should reject display name longer than 50 characters', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'user@example.com',
          password: 'SecurePass123!',
          displayName: 'A'.repeat(51),
        })
        .expect(400);

      expect(response.body.error).toContain('2 and 50 characters');
    });

    test('should accept display name exactly 2 characters', async () => {
      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{
            id: 'user-id',
            email: 'user@example.com',
            display_name: 'Jo',
            status: 'pending_verification',
            created_at: new Date(),
          }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{ id: 'token-id', token: 'token', expires_at: new Date() }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'user@example.com',
          password: 'SecurePass123!',
          displayName: 'Jo',
        })
        .expect(201);

      expect(response.body.success).toBe(true);
    });

    test('should accept display name exactly 50 characters', async () => {
      const displayName = 'A'.repeat(50);

      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{
            id: 'user-id',
            email: 'user@example.com',
            display_name: displayName,
            status: 'pending_verification',
            created_at: new Date(),
          }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{ id: 'token-id', token: 'token', expires_at: new Date() }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'user@example.com',
          password: 'SecurePass123!',
          displayName,
        })
        .expect(201);

      expect(response.body.success).toBe(true);
    });
  });

  describe('FR-001.1.5: Duplicate email prevention', () => {
    test('should reject registration with existing email', async () => {
      const existingEmail = 'existing@example.com';

      mockClient.query
        .mockResolvedValueOnce({ rows: [] }) // BEGIN
        .mockResolvedValueOnce({ // Check existing user - found!
          rows: [{ id: 'existing-user-id' }],
        })
        .mockResolvedValueOnce({ rows: [] }); // ROLLBACK

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: existingEmail,
          password: 'SecurePass123!',
          displayName: 'Duplicate User',
        })
        .expect(409);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('already exists');
      expect(mockClient.query).toHaveBeenCalledWith(
        expect.stringContaining('ROLLBACK')
      );
    });

    test('should be case-insensitive for duplicate email check', async () => {
      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{ id: 'existing-user-id' }],
        })
        .mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'USER@EXAMPLE.COM',
          password: 'SecurePass123!',
          displayName: 'Test User',
        })
        .expect(409);

      expect(response.body.error).toContain('already exists');
    });
  });

  describe('FR-001.1.6 & FR-001.1.7: Email verification', () => {
    test('should send verification email upon registration', async () => {
      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{
            id: 'user-id',
            email: 'newuser@example.com',
            display_name: 'New User',
            status: 'pending_verification',
            created_at: new Date(),
          }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{
            id: 'token-id',
            token: 'verification-token-abc123',
            expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000),
          }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'newuser@example.com',
          password: 'SecurePass123!',
          displayName: 'New User',
        })
        .expect(201);

      expect(response.body.message).toContain('verify');
      expect(response.body.data.user.status).toBe('pending_verification');
    });

    test('should set user status to pending_verification', async () => {
      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{
            id: 'user-id',
            email: 'test@example.com',
            display_name: 'Test User',
            status: 'pending_verification',
            created_at: new Date(),
          }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{ id: 'token-id', token: 'token', expires_at: new Date() }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'test@example.com',
          password: 'SecurePass123!',
          displayName: 'Test User',
        })
        .expect(201);

      expect(response.body.data.user.status).toBe('pending_verification');
    });
  });

  describe('FR-001.1.8: Password storage with bcrypt', () => {
    test('should not return password in response', async () => {
      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{
            id: 'user-id',
            email: 'secure@example.com',
            display_name: 'Secure User',
            status: 'pending_verification',
            created_at: new Date(),
          }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{ id: 'token-id', token: 'token', expires_at: new Date() }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] });

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'secure@example.com',
          password: 'SecurePass123!',
          displayName: 'Secure User',
        })
        .expect(201);

      const responseStr = JSON.stringify(response.body);
      expect(responseStr).not.toContain('SecurePass123!');
      expect(response.body.data.user.password).toBeUndefined();
      expect(response.body.data.user.password_hash).toBeUndefined();
    });

    test('should hash password before storing', async () => {
      const plainPassword = 'PlainTextPass123!';
      let storedPasswordHash;

      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] })
        .mockImplementationOnce((query, params) => {
          storedPasswordHash = params[1]; // password_hash parameter
          expect(storedPasswordHash).not.toBe(plainPassword);
          expect(storedPasswordHash).toMatch(/^\$2[aby]\$/); // bcrypt format
          
          return Promise.resolve({
            rows: [{
              id: 'user-id',
              email: params[0],
              display_name: params[2],
              status: 'pending_verification',
              created_at: new Date(),
            }],
          });
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{ id: 'token-id', token: 'token', expires_at: new Date() }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] });

      await request(app)
        .post('/api/auth/register')
        .send({
          email: 'hash@example.com',
          password: plainPassword,
          displayName: 'Hash Test',
        })
        .expect(201);

      expect(storedPasswordHash).toBeDefined();
    });
  });

  describe('Error handling and edge cases', () => {
    test('should handle database errors gracefully', async () => {
      mockClient.query.mockRejectedValue(new Error('Database connection failed'));

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'error@example.com',
          password: 'SecurePass123!',
          displayName: 'Error User',
        })
        .expect(500);

      expect(response.body.success).toBe(false);
    });

    test('should rollback transaction on error', async () => {
      mockClient.query
        .mockResolvedValueOnce({ rows: [] }) // BEGIN
        .mockResolvedValueOnce({ rows: [] }) // Check existing
        .mockRejectedValueOnce(new Error('Insert failed')) // Insert user fails
        .mockResolvedValueOnce({ rows: [] }); // ROLLBACK

      await request(app)
        .post('/api/auth/register')
        .send({
          email: 'rollback@example.com',
          password: 'SecurePass123!',
          displayName: 'Rollback Test',
        })
        .expect(500);

      expect(mockClient.query).toHaveBeenCalledWith(
        expect.stringContaining('ROLLBACK')
      );
    });

    test('should handle missing required fields', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'incomplete@example.com',
          // Missing password and displayName
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.error).toBeDefined();
    });

    test('should trim and normalize email to lowercase', async () => {
      mockClient.query
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] })
        .mockImplementationOnce((query, params) => {
          const email = params[0];
          expect(email).toBe('user@example.com');
          
          return Promise.resolve({
            rows: [{
              id: 'user-id',
              email,
              display_name: params[2],
              status: 'pending_verification',
              created_at: new Date(),
            }],
          });
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({
          rows: [{ id: 'token-id', token: 'token', expires_at: new Date() }],
        })
        .mockResolvedValueOnce({ rows: [] })
        .mockResolvedValueOnce({ rows: [] });

      await request(app)
        .post('/api/auth/register')
        .send({
          email: ' USER@EXAMPLE.COM ',
          password: 'SecurePass123!',
          displayName: 'Test User',
        })
        .expect(201);
    });
  });
});

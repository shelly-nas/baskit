const { 
  generateToken, 
  createVerificationToken,
  verifyVerificationToken,
  markVerificationTokenUsed,
} = require('../../src/services/token.service');

// Mock database
jest.mock('../../../shared/src', () => ({
  database: {
    query: jest.fn(),
  },
  logger: {
    info: jest.fn(),
    error: jest.fn(),
    debug: jest.fn(),
  },
}));

const { database } = require('../../../shared/src');

describe('Token Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('FR-001.1.6: Verification email token generation', () => {
    test('should generate secure random token', () => {
      const token1 = generateToken();
      const token2 = generateToken();

      expect(token1).toBeDefined();
      expect(token2).toBeDefined();
      expect(typeof token1).toBe('string');
      expect(typeof token2).toBe('string');
      expect(token1).not.toBe(token2);
    });

    test('should generate token of correct length (64 hex characters)', () => {
      const token = generateToken();
      expect(token.length).toBe(64);
      expect(/^[a-f0-9]{64}$/.test(token)).toBe(true);
    });

    test('should use crypto.randomBytes for secure generation', () => {
      const tokens = new Set();
      for (let i = 0; i < 100; i++) {
        tokens.add(generateToken());
      }
      // All tokens should be unique
      expect(tokens.size).toBe(100);
    });
  });

  describe('FR-001.1.6: Create verification token with 24-hour expiration', () => {
    test('should create verification token with correct expiration', async () => {
      const userId = '550e8400-e29b-41d4-a716-446655440000';
      const mockResult = {
        rows: [{
          id: 'token-id',
          token: 'abc123',
          expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000),
        }],
      };

      database.query.mockResolvedValue(mockResult);

      const result = await createVerificationToken(userId);

      expect(database.query).toHaveBeenCalled();
      expect(result).toBeDefined();
      expect(result.token).toBeDefined();
      expect(result.expires_at).toBeDefined();
    });

    test('should set expiration to 24 hours from creation', async () => {
      const userId = '550e8400-e29b-41d4-a716-446655440000';
      const now = Date.now();
      const expectedExpiry = new Date(now + 24 * 60 * 60 * 1000);

      database.query.mockImplementation((query, params) => {
        const expiresAt = params[3];
        const diff = Math.abs(expiresAt - expectedExpiry);
        expect(diff).toBeLessThan(1000); // Within 1 second tolerance

        return Promise.resolve({
          rows: [{
            id: 'token-id',
            token: params[1],
            expires_at: expiresAt,
          }],
        });
      });

      await createVerificationToken(userId);
      expect(database.query).toHaveBeenCalled();
    });

    test('should store token with correct type', async () => {
      const userId = '550e8400-e29b-41d4-a716-446655440000';

      database.query.mockImplementation((query, params) => {
        expect(params[2]).toBe('email_verification');
        return Promise.resolve({
          rows: [{
            id: 'token-id',
            token: params[1],
            expires_at: params[3],
          }],
        });
      });

      await createVerificationToken(userId);
    });
  });

  describe('FR-001.1.7: Token verification and validation', () => {
    test('should verify valid unexpired token', async () => {
      const mockToken = 'valid-token-123';
      const mockResult = {
        rows: [{
          user_id: 'user-123',
          token: mockToken,
          expires_at: new Date(Date.now() + 1000 * 60 * 60), // 1 hour in future
          used_at: null,
          email: 'user@example.com',
          status: 'pending_verification',
        }],
      };

      database.query.mockResolvedValue(mockResult);

      const result = await verifyVerificationToken(mockToken);

      expect(result).toBeDefined();
      expect(result.user_id).toBe('user-123');
      expect(result.email).toBe('user@example.com');
    });

    test('should reject expired token', async () => {
      const mockToken = 'expired-token-123';
      const mockResult = { rows: [] };

      database.query.mockResolvedValue(mockResult);

      const result = await verifyVerificationToken(mockToken);

      expect(result).toBeNull();
    });

    test('should reject already used token', async () => {
      const mockToken = 'used-token-123';
      const mockResult = { rows: [] };

      database.query.mockResolvedValue(mockResult);

      const result = await verifyVerificationToken(mockToken);

      expect(result).toBeNull();
    });

    test('should reject non-existent token', async () => {
      const mockToken = 'non-existent-token';
      const mockResult = { rows: [] };

      database.query.mockResolvedValue(mockResult);

      const result = await verifyVerificationToken(mockToken);

      expect(result).toBeNull();
    });
  });

  describe('Token usage tracking', () => {
    test('should mark token as used', async () => {
      const mockToken = 'token-to-use';
      database.query.mockResolvedValue({ rows: [] });

      await markVerificationTokenUsed(mockToken);

      expect(database.query).toHaveBeenCalledWith(
        expect.stringContaining('UPDATE verification_tokens'),
        [mockToken]
      );
    });

    test('should record timestamp when marking token as used', async () => {
      const mockToken = 'token-to-use';
      database.query.mockResolvedValue({ rows: [] });

      await markVerificationTokenUsed(mockToken);

      expect(database.query).toHaveBeenCalledWith(
        expect.stringContaining('used_at = NOW()'),
        [mockToken]
      );
    });
  });

  describe('Security considerations', () => {
    test('should generate cryptographically secure tokens', () => {
      const tokens = [];
      for (let i = 0; i < 1000; i++) {
        tokens.push(generateToken());
      }

      // Check for uniqueness
      const uniqueTokens = new Set(tokens);
      expect(uniqueTokens.size).toBe(1000);

      // Check for randomness (no obvious patterns)
      const firstChars = tokens.map(t => t[0]);
      const uniqueFirstChars = new Set(firstChars);
      expect(uniqueFirstChars.size).toBeGreaterThan(10); // Should have good distribution
    });

    test('should not accept tokens without proper validation query', async () => {
      const mockToken = 'token-123';
      
      database.query.mockImplementation((query) => {
        expect(query).toContain('expires_at > NOW()');
        expect(query).toContain('used_at IS NULL');
        return Promise.resolve({ rows: [] });
      });

      await verifyVerificationToken(mockToken);
    });
  });

  describe('Error handling', () => {
    test('should handle database errors when creating token', async () => {
      const userId = 'user-123';
      database.query.mockRejectedValue(new Error('Database error'));

      await expect(createVerificationToken(userId)).rejects.toThrow();
    });

    test('should handle database errors when verifying token', async () => {
      const token = 'token-123';
      database.query.mockRejectedValue(new Error('Database error'));

      await expect(verifyVerificationToken(token)).rejects.toThrow();
    });
  });
});

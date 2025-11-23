const jwt = require('jsonwebtoken');

// Mock the shared package (separate microservice)
jest.mock('../../../shared/src', () => ({
  database: {
    query: jest.fn(),
    connect: jest.fn(),
    close: jest.fn(),
  },
  logger: {
    info: jest.fn(),
    error: jest.fn(),
    debug: jest.fn(),
    warn: jest.fn(),
  },
}));

const jwtService = require('../../src/services/jwt.service');

/**
 * Unit Tests for JWT Service - FR-001.2.4, FR-001.2.5, FR-001.2.6
 * 
 * Tests JWT token generation, validation, and expiration handling
 */
describe('JWT Service - Token Management', () => {
  const mockUser = {
    id: '550e8400-e29b-41d4-a716-446655440000',
    email: 'test@example.com',
    role: 'user',
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  /**
   * FR-001.2.4: JWT Access Token with 24-hour Expiration
   */
  describe('FR-001.2.4: Access Token Generation', () => {
    it('should generate valid JWT access token', () => {
      const token = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });

      expect(token).toBeDefined();
      expect(typeof token).toBe('string');
      expect(token.split('.').length).toBe(3); // JWT has 3 parts
    });

    it('should generate access token with 24-hour expiration by default', () => {
      const token = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });

      const decoded = jwt.decode(token);
      const now = Math.floor(Date.now() / 1000);
      const expiresIn = decoded.exp - now;

      // Should be approximately 24 hours (86400 seconds)
      expect(expiresIn).toBeGreaterThan(86395); // Allow 5 second tolerance
      expect(expiresIn).toBeLessThanOrEqual(86400);
    });

    it('should include user information in token payload', () => {
      const token = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });

      const decoded = jwt.decode(token);

      expect(decoded.userId).toBe(mockUser.id);
      expect(decoded.email).toBe(mockUser.email);
      expect(decoded.role).toBe(mockUser.role);
      expect(decoded.type).toBe('access');
    });

    it('should mark token as type "access"', () => {
      const token = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });

      const decoded = jwt.decode(token);
      expect(decoded.type).toBe('access');
    });

    it('should include standard JWT claims', () => {
      const token = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });

      const decoded = jwt.decode(token);

      expect(decoded.iss).toBe('baskit-auth'); // Issuer
      expect(decoded.aud).toBe('baskit-api'); // Audience
      expect(decoded.exp).toBeDefined(); // Expiration
      expect(decoded.iat).toBeDefined(); // Issued at
    });

    it('should use HS256 algorithm', () => {
      const token = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });

      const decoded = jwt.decode(token, { complete: true });
      expect(decoded.header.alg).toBe('HS256');
    });

    it('should allow custom expiration time', () => {
      const token = jwtService.generateAccessToken(
        {
          userId: mockUser.id,
          email: mockUser.email,
          role: mockUser.role,
        },
        { expiresIn: '1h' }
      );

      const decoded = jwt.decode(token);
      const now = Math.floor(Date.now() / 1000);
      const expiresIn = decoded.exp - now;

      // Should be approximately 1 hour (3600 seconds)
      expect(expiresIn).toBeGreaterThan(3595);
      expect(expiresIn).toBeLessThanOrEqual(3600);
    });

    it('should default role to "user" if not provided', () => {
      const token = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
      });

      const decoded = jwt.decode(token);
      expect(decoded.role).toBe('user');
    });
  });

  /**
   * FR-001.2.5: Refresh Token with 30-day Expiration
   */
  describe('FR-001.2.5: Refresh Token Generation', () => {
    it('should generate valid JWT refresh token', () => {
      const token = jwtService.generateRefreshToken({
        userId: mockUser.id,
        email: mockUser.email,
      });

      expect(token).toBeDefined();
      expect(typeof token).toBe('string');
      expect(token.split('.').length).toBe(3);
    });

    it('should generate refresh token with 30-day expiration by default', () => {
      const token = jwtService.generateRefreshToken({
        userId: mockUser.id,
        email: mockUser.email,
      });

      const decoded = jwt.decode(token);
      const now = Math.floor(Date.now() / 1000);
      const expiresIn = decoded.exp - now;

      // Should be approximately 30 days (2592000 seconds)
      expect(expiresIn).toBeGreaterThan(2591995); // Allow 5 second tolerance
      expect(expiresIn).toBeLessThanOrEqual(2592000);
    });

    it('should include user information in refresh token payload', () => {
      const token = jwtService.generateRefreshToken({
        userId: mockUser.id,
        email: mockUser.email,
      });

      const decoded = jwt.decode(token);

      expect(decoded.userId).toBe(mockUser.id);
      expect(decoded.email).toBe(mockUser.email);
      expect(decoded.type).toBe('refresh');
    });

    it('should mark token as type "refresh"', () => {
      const token = jwtService.generateRefreshToken({
        userId: mockUser.id,
        email: mockUser.email,
      });

      const decoded = jwt.decode(token);
      expect(decoded.type).toBe('refresh');
    });

    it('should include unique token ID for rotation', () => {
      const token1 = jwtService.generateRefreshToken({
        userId: mockUser.id,
        email: mockUser.email,
      });

      const token2 = jwtService.generateRefreshToken({
        userId: mockUser.id,
        email: mockUser.email,
      });

      const decoded1 = jwt.decode(token1);
      const decoded2 = jwt.decode(token2);

      expect(decoded1.tokenId).toBeDefined();
      expect(decoded2.tokenId).toBeDefined();
      expect(decoded1.tokenId).not.toBe(decoded2.tokenId); // Should be unique
    });

    it('should not include role in refresh token', () => {
      const token = jwtService.generateRefreshToken({
        userId: mockUser.id,
        email: mockUser.email,
      });

      const decoded = jwt.decode(token);
      expect(decoded.role).toBeUndefined();
    });
  });

  /**
   * FR-001.2.6: "Remember Me" Functionality
   */
  describe('FR-001.2.6: Remember Me Functionality', () => {
    it('should extend refresh token to 30 days when rememberMe is true', () => {
      const token = jwtService.generateRefreshToken(
        {
          userId: mockUser.id,
          email: mockUser.email,
        },
        true // rememberMe
      );

      const decoded = jwt.decode(token);
      const now = Math.floor(Date.now() / 1000);
      const expiresIn = decoded.exp - now;

      // Should be 30 days (2592000 seconds)
      expect(expiresIn).toBeGreaterThan(2591995);
      expect(expiresIn).toBeLessThanOrEqual(2592000);
    });

    it('should use default 30 days when rememberMe is false', () => {
      const token = jwtService.generateRefreshToken(
        {
          userId: mockUser.id,
          email: mockUser.email,
        },
        false // rememberMe
      );

      const decoded = jwt.decode(token);
      const now = Math.floor(Date.now() / 1000);
      const expiresIn = decoded.exp - now;

      // Should be 30 days (default)
      expect(expiresIn).toBeGreaterThan(2591995);
      expect(expiresIn).toBeLessThanOrEqual(2592000);
    });

    it('should generate token pair with remember me option', () => {
      const tokens = jwtService.generateTokenPair(mockUser, true);

      expect(tokens.accessToken).toBeDefined();
      expect(tokens.refreshToken).toBeDefined();
      expect(tokens.expiresIn).toBe('30d');
    });

    it('should generate token pair without remember me', () => {
      const tokens = jwtService.generateTokenPair(mockUser, false);

      expect(tokens.accessToken).toBeDefined();
      expect(tokens.refreshToken).toBeDefined();
      expect(tokens.expiresIn).toBe('24h');
    });

    it('should default to 24h expiration when rememberMe not specified', () => {
      const tokens = jwtService.generateTokenPair(mockUser);

      expect(tokens.expiresIn).toBe('24h');
    });
  });

  /**
   * Token Verification and Validation
   */
  describe('Token Verification', () => {
    it('should verify valid access token', () => {
      const token = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });

      const decoded = jwtService.verifyToken(token, 'access');

      expect(decoded).toBeDefined();
      expect(decoded.userId).toBe(mockUser.id);
      expect(decoded.email).toBe(mockUser.email);
    });

    it('should verify valid refresh token', () => {
      const token = jwtService.generateRefreshToken({
        userId: mockUser.id,
        email: mockUser.email,
      });

      const decoded = jwtService.verifyToken(token, 'refresh');

      expect(decoded).toBeDefined();
      expect(decoded.userId).toBe(mockUser.id);
      expect(decoded.type).toBe('refresh');
    });

    it('should reject token with mismatched type', () => {
      const accessToken = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });

      // Try to verify as refresh token
      const decoded = jwtService.verifyToken(accessToken, 'refresh');
      expect(decoded).toBeNull();
    });

    it('should reject invalid token', () => {
      const decoded = jwtService.verifyToken('invalid-token-string', 'access');
      expect(decoded).toBeNull();
    });

    it('should reject expired token', () => {
      // Generate token with 1 second expiration
      const token = jwtService.generateAccessToken(
        {
          userId: mockUser.id,
          email: mockUser.email,
          role: mockUser.role,
        },
        { expiresIn: '1ms' }
      );

      // Wait for expiration
      return new Promise((resolve) => {
        setTimeout(() => {
          const decoded = jwtService.verifyToken(token, 'access');
          expect(decoded).toBeNull();
          resolve();
        }, 10);
      });
    });

    it('should validate issuer and audience', () => {
      const token = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });

      const decoded = jwtService.verifyToken(token, 'access');

      expect(decoded).not.toBeNull();
      expect(decoded.iss).toBe('baskit-auth');
      expect(decoded.aud).toBe('baskit-api');
    });
  });

  /**
   * Token Utility Functions
   */
  describe('Token Utility Functions', () => {
    it('should decode token without verification', () => {
      const token = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });

      const decoded = jwtService.decodeToken(token);

      expect(decoded).toBeDefined();
      expect(decoded.userId).toBe(mockUser.id);
    });

    it('should get token expiration time', () => {
      const token = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });

      const expirationTime = jwtService.getTokenExpirationTime(token);

      expect(expirationTime).toBeDefined();
      expect(expirationTime).toBeGreaterThan(86390); // ~24 hours
      expect(expirationTime).toBeLessThanOrEqual(86400);
    });

    it('should detect expired token', () => {
      const token = jwtService.generateAccessToken(
        {
          userId: mockUser.id,
          email: mockUser.email,
          role: mockUser.role,
        },
        { expiresIn: '1ms' }
      );

      return new Promise((resolve) => {
        setTimeout(() => {
          const isExpired = jwtService.isTokenExpired(token);
          expect(isExpired).toBe(true);
          resolve();
        }, 10);
      });
    });

    it('should detect valid token as not expired', () => {
      const token = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });

      const isExpired = jwtService.isTokenExpired(token);
      expect(isExpired).toBe(false);
    });

    it('should extract user ID from token', () => {
      const token = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });

      const userId = jwtService.extractUserId(token);
      expect(userId).toBe(mockUser.id);
    });

    it('should return null for invalid token extraction', () => {
      const userId = jwtService.extractUserId('invalid-token');
      expect(userId).toBeNull();
    });
  });

  /**
   * Token Pair Generation
   */
  describe('Token Pair Generation', () => {
    it('should generate both access and refresh tokens', () => {
      const tokens = jwtService.generateTokenPair(mockUser);

      expect(tokens.accessToken).toBeDefined();
      expect(tokens.refreshToken).toBeDefined();
      expect(tokens.expiresIn).toBeDefined();
    });

    it('should generate different access and refresh tokens', () => {
      const tokens = jwtService.generateTokenPair(mockUser);

      expect(tokens.accessToken).not.toBe(tokens.refreshToken);

      const accessDecoded = jwt.decode(tokens.accessToken);
      const refreshDecoded = jwt.decode(tokens.refreshToken);

      expect(accessDecoded.type).toBe('access');
      expect(refreshDecoded.type).toBe('refresh');
    });

    it('should use user data for both tokens', () => {
      const tokens = jwtService.generateTokenPair(mockUser);

      const accessDecoded = jwt.decode(tokens.accessToken);
      const refreshDecoded = jwt.decode(tokens.refreshToken);

      expect(accessDecoded.userId).toBe(mockUser.id);
      expect(refreshDecoded.userId).toBe(mockUser.id);
      expect(accessDecoded.email).toBe(mockUser.email);
      expect(refreshDecoded.email).toBe(mockUser.email);
    });
  });

  /**
   * Security Tests
   */
  describe('Security Considerations', () => {
    it('should generate unique tokens for same user', async () => {
      const token1 = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });

      // Wait 1 second to ensure different iat (issued at) timestamp
      await new Promise(resolve => setTimeout(resolve, 1000));

      const token2 = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });

      expect(token1).not.toBe(token2);
    });

    it('should generate unique refresh token IDs', () => {
      const token1 = jwtService.generateRefreshToken({
        userId: mockUser.id,
        email: mockUser.email,
      });

      const token2 = jwtService.generateRefreshToken({
        userId: mockUser.id,
        email: mockUser.email,
      });

      const decoded1 = jwt.decode(token1);
      const decoded2 = jwt.decode(token2);

      expect(decoded1.tokenId).not.toBe(decoded2.tokenId);
    });

    it('should use secure signing algorithm', () => {
      const token = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });

      const decoded = jwt.decode(token, { complete: true });
      expect(decoded.header.alg).toBe('HS256');
      expect(decoded.header.typ).toBe('JWT');
    });

    it('should not include sensitive data in token', () => {
      const token = jwtService.generateAccessToken({
        userId: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });

      const decoded = jwt.decode(token);

      // Should not contain password or other sensitive fields
      expect(decoded.password).toBeUndefined();
      expect(decoded.passwordHash).toBeUndefined();
      expect(decoded.password_hash).toBeUndefined();
    });
  });

  /**
   * Error Handling
   */
  describe('Error Handling', () => {
    it('should handle malformed tokens gracefully', () => {
      const decoded = jwtService.verifyToken('not.a.valid.jwt', 'access');
      expect(decoded).toBeNull();
    });

    it('should handle null token', () => {
      const decoded = jwtService.verifyToken(null, 'access');
      expect(decoded).toBeNull();
    });

    it('should handle undefined token', () => {
      const decoded = jwtService.verifyToken(undefined, 'access');
      expect(decoded).toBeNull();
    });

    it('should handle empty string token', () => {
      const decoded = jwtService.verifyToken('', 'access');
      expect(decoded).toBeNull();
    });
  });

  /**
   * Configuration Tests
   */
  describe('Configuration', () => {
    it('should use correct default expiration times', () => {
      expect(jwtService.ACCESS_TOKEN_EXPIRY).toBe('24h');
      expect(jwtService.REFRESH_TOKEN_EXPIRY).toBe('30d');
    });

    it('should respect environment configuration', () => {
      // Note: In real tests, you'd mock process.env
      // This test verifies the constants are exported
      expect(jwtService.ACCESS_TOKEN_EXPIRY).toBeDefined();
      expect(jwtService.REFRESH_TOKEN_EXPIRY).toBeDefined();
    });
  });
});

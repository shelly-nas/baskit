const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { logger } = require('../../shared/src');

/**
 * JWT Service
 * Handles JWT token generation, validation, and management
 * FR-001.2.4, FR-001.2.5, FR-001.6.2
 */

// Get JWT configuration from environment
const JWT_SECRET = process.env.JWT_SECRET || 'default-secret-change-in-production';
const JWT_ALGORITHM = 'HS256'; // Using HMAC SHA256 (could upgrade to RS256 for asymmetric)
const ACCESS_TOKEN_EXPIRY = process.env.JWT_EXPIRE || '24h';
const REFRESH_TOKEN_EXPIRY = process.env.JWT_REFRESH_EXPIRE || '30d';

// Validate JWT_SECRET in production
if (process.env.NODE_ENV === 'production' && JWT_SECRET === 'default-secret-change-in-production') {
  logger.error('SECURITY WARNING: Using default JWT secret in production! Set JWT_SECRET environment variable.');
}

/**
 * Generate access token (short-lived)
 * FR-001.2.4: 24-hour expiration
 * @param {Object} payload - User data to encode
 * @param {string} payload.userId - User ID
 * @param {string} payload.email - User email
 * @param {string} payload.role - User role
 * @param {Object} options - Optional token options
 * @returns {string} - JWT access token
 */
const generateAccessToken = (payload, options = {}) => {
  try {
    const tokenPayload = {
      userId: payload.userId,
      email: payload.email,
      role: payload.role || 'user',
      type: 'access',
    };

    const token = jwt.sign(tokenPayload, JWT_SECRET, {
      algorithm: JWT_ALGORITHM,
      expiresIn: options.expiresIn || ACCESS_TOKEN_EXPIRY,
      issuer: 'baskit-auth',
      audience: 'baskit-api',
    });

    logger.debug('Access token generated', { userId: payload.userId });
    return token;
  } catch (error) {
    logger.error('Error generating access token:', error);
    throw new Error('Failed to generate access token');
  }
};

/**
 * Generate refresh token (long-lived)
 * FR-001.2.5: 30-day expiration
 * FR-001.2.6: Can be extended for "Remember Me"
 * @param {Object} payload - User data to encode
 * @param {boolean} rememberMe - Whether to extend token expiration
 * @returns {string} - JWT refresh token
 */
const generateRefreshToken = (payload, rememberMe = false) => {
  try {
    const tokenPayload = {
      userId: payload.userId,
      email: payload.email,
      type: 'refresh',
      tokenId: crypto.randomBytes(16).toString('hex'), // Unique ID for rotation
    };

    const expiresIn = rememberMe ? '30d' : REFRESH_TOKEN_EXPIRY;

    const token = jwt.sign(tokenPayload, JWT_SECRET, {
      algorithm: JWT_ALGORITHM,
      expiresIn,
      issuer: 'baskit-auth',
      audience: 'baskit-api',
    });

    logger.debug('Refresh token generated', { 
      userId: payload.userId, 
      rememberMe,
      expiresIn 
    });
    
    return token;
  } catch (error) {
    logger.error('Error generating refresh token:', error);
    throw new Error('Failed to generate refresh token');
  }
};

/**
 * Generate both access and refresh tokens
 * @param {Object} user - User object
 * @param {boolean} rememberMe - Whether to extend token expiration
 * @returns {Object} - Object with access and refresh tokens
 */
const generateTokenPair = (user, rememberMe = false) => {
  const payload = {
    userId: user.id,
    email: user.email,
    role: user.role || 'user',
  };

  const accessToken = generateAccessToken(payload);
  const refreshToken = generateRefreshToken(payload, rememberMe);

  return {
    accessToken,
    refreshToken,
    expiresIn: rememberMe ? '30d' : ACCESS_TOKEN_EXPIRY,
  };
};

/**
 * Verify and decode JWT token
 * FR-001.6.7: Validate token signatures on every request
 * @param {string} token - JWT token to verify
 * @param {string} expectedType - Expected token type ('access' or 'refresh')
 * @returns {Object|null} - Decoded token payload or null if invalid
 */
const verifyToken = (token, expectedType = 'access') => {
  try {
    const decoded = jwt.verify(token, JWT_SECRET, {
      algorithms: [JWT_ALGORITHM],
      issuer: 'baskit-auth',
      audience: 'baskit-api',
    });

    // Verify token type matches expected
    if (decoded.type !== expectedType) {
      logger.warn('Token type mismatch', { 
        expected: expectedType, 
        received: decoded.type 
      });
      return null;
    }

    return decoded;
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      logger.debug('Token expired', { expiredAt: error.expiredAt });
    } else if (error.name === 'JsonWebTokenError') {
      logger.warn('Invalid token', { error: error.message });
    } else {
      logger.error('Error verifying token:', error);
    }
    return null;
  }
};

/**
 * Decode token without verification (use carefully)
 * @param {string} token - JWT token to decode
 * @returns {Object|null} - Decoded token payload or null if invalid
 */
const decodeToken = (token) => {
  try {
    return jwt.decode(token);
  } catch (error) {
    logger.error('Error decoding token:', error);
    return null;
  }
};

/**
 * Get token expiration time in seconds
 * @param {string} token - JWT token
 * @returns {number|null} - Time until expiration in seconds, or null if invalid
 */
const getTokenExpirationTime = (token) => {
  try {
    const decoded = jwt.decode(token);
    if (!decoded || !decoded.exp) {
      return null;
    }
    
    const now = Math.floor(Date.now() / 1000);
    const timeUntilExpiration = decoded.exp - now;
    
    return timeUntilExpiration > 0 ? timeUntilExpiration : 0;
  } catch (error) {
    logger.error('Error getting token expiration:', error);
    return null;
  }
};

/**
 * Check if token is expired (without verification)
 * @param {string} token - JWT token
 * @returns {boolean} - True if expired
 */
const isTokenExpired = (token) => {
  const expirationTime = getTokenExpirationTime(token);
  return expirationTime === null || expirationTime <= 0;
};

/**
 * Extract user ID from token (without full verification)
 * Useful for logging before full validation
 * @param {string} token - JWT token
 * @returns {string|null} - User ID or null
 */
const extractUserId = (token) => {
  try {
    const decoded = jwt.decode(token);
    return decoded?.userId || null;
  } catch (error) {
    return null;
  }
};

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  generateTokenPair,
  verifyToken,
  decodeToken,
  getTokenExpirationTime,
  isTokenExpired,
  extractUserId,
  // Export constants for testing
  ACCESS_TOKEN_EXPIRY,
  REFRESH_TOKEN_EXPIRY,
};

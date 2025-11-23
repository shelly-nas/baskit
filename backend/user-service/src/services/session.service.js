const { database, logger } = require('../../shared/src');
const crypto = require('crypto');

/**
 * Session Service
 * Handles user session management and JWT token blacklisting
 * FR-001.6.3: Rotate refresh tokens on each use
 * FR-001.6.8: Check token blacklist before accepting tokens
 * FR-001.6.11-14: Multi-device session management
 */

// In-memory token blacklist (can be replaced with Redis for production)
const tokenBlacklist = new Set();

/**
 * Create a new user session
 * @param {Object} params - Session parameters
 * @param {string} params.userId - User ID
 * @param {string} params.refreshToken - Refresh token
 * @param {string} params.ipAddress - IP address
 * @param {string} params.userAgent - User agent string
 * @param {Date} params.expiresAt - Session expiration date
 * @param {Object} client - Database client for transactions
 * @returns {Promise<Object>} - Created session
 */
const createSession = async ({ userId, refreshToken, ipAddress, userAgent, expiresAt }, client = null) => {
  try {
    const deviceInfo = parseUserAgent(userAgent);
    const sessionId = crypto.randomBytes(16).toString('hex');
    
    const queryFn = client || database;
    const result = await queryFn.query(
      `INSERT INTO user_sessions (
        id, user_id, refresh_token_hash, ip_address, user_agent, 
        device_type, device_name, browser, expires_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING id, user_id, ip_address, device_type, device_name, browser, created_at, last_activity_at, expires_at`,
      [
        sessionId,
        userId,
        hashToken(refreshToken),
        ipAddress,
        userAgent,
        deviceInfo.deviceType,
        deviceInfo.deviceName,
        deviceInfo.browser,
        expiresAt,
      ]
    );

    logger.info('Session created', { userId, sessionId, deviceType: deviceInfo.deviceType });
    return result.rows[0];
  } catch (error) {
    logger.error('Error creating session:', error);
    throw new Error('Failed to create session');
  }
};

/**
 * Get all active sessions for a user
 * FR-001.6.11: View all active sessions
 * @param {string} userId - User ID
 * @returns {Promise<Array>} - Array of active sessions
 */
const getUserSessions = async (userId) => {
  try {
    const result = await database.query(
      `SELECT 
        id, ip_address, user_agent, device_type, device_name, browser,
        created_at, last_activity_at, expires_at
      FROM user_sessions
      WHERE user_id = $1 AND is_active = true AND expires_at > NOW()
      ORDER BY last_activity_at DESC`,
      [userId]
    );

    return result.rows.map(session => ({
      ...session,
      isCurrent: false, // Will be determined by the controller based on current token
    }));
  } catch (error) {
    logger.error('Error getting user sessions:', error);
    throw new Error('Failed to retrieve sessions');
  }
};

/**
 * Update session last activity timestamp
 * @param {string} sessionId - Session ID
 * @param {Object} client - Database client for transactions
 */
const updateSessionActivity = async (sessionId, client = null) => {
  try {
    const queryFn = client || database;
    await queryFn.query(
      'UPDATE user_sessions SET last_activity_at = NOW() WHERE id = $1',
      [sessionId]
    );
    logger.debug('Session activity updated', { sessionId });
  } catch (error) {
    logger.error('Error updating session activity:', error);
    // Don't throw - this is not critical
  }
};

/**
 * Invalidate a specific session
 * FR-001.6.13: Terminate individual sessions
 * @param {string} sessionId - Session ID to invalidate
 * @param {string} userId - User ID (for verification)
 * @returns {Promise<boolean>} - True if session was invalidated
 */
const invalidateSession = async (sessionId, userId) => {
  try {
    const result = await database.query(
      'UPDATE user_sessions SET is_active = false WHERE id = $1 AND user_id = $2',
      [sessionId, userId]
    );

    const invalidated = result.rowCount > 0;
    if (invalidated) {
      logger.info('Session invalidated', { sessionId, userId });
    }
    return invalidated;
  } catch (error) {
    logger.error('Error invalidating session:', error);
    throw new Error('Failed to invalidate session');
  }
};

/**
 * Invalidate all sessions for a user except the current one
 * FR-001.6.14: Terminate all other sessions
 * @param {string} userId - User ID
 * @param {string} currentSessionId - Current session ID to keep active
 * @returns {Promise<number>} - Number of sessions invalidated
 */
const invalidateOtherSessions = async (userId, currentSessionId) => {
  try {
    const result = await database.query(
      'UPDATE user_sessions SET is_active = false WHERE user_id = $1 AND id != $2 AND is_active = true',
      [userId, currentSessionId]
    );

    logger.info('Other sessions invalidated', { 
      userId, 
      count: result.rowCount 
    });
    return result.rowCount;
  } catch (error) {
    logger.error('Error invalidating other sessions:', error);
    throw new Error('Failed to invalidate other sessions');
  }
};

/**
 * Invalidate all sessions for a user
 * FR-001.4.5: Invalidate all existing sessions after password change
 * @param {string} userId - User ID
 * @param {Object} client - Database client for transactions
 * @returns {Promise<number>} - Number of sessions invalidated
 */
const invalidateAllUserSessions = async (userId, client = null) => {
  try {
    const queryFn = client || database;
    const result = await queryFn.query(
      'UPDATE user_sessions SET is_active = false WHERE user_id = $1 AND is_active = true',
      [userId]
    );

    logger.info('All user sessions invalidated', { 
      userId, 
      count: result.rowCount 
    });
    return result.rowCount;
  } catch (error) {
    logger.error('Error invalidating all user sessions:', error);
    throw new Error('Failed to invalidate all sessions');
  }
};

/**
 * Verify refresh token against stored session
 * @param {string} refreshToken - Refresh token to verify
 * @param {string} userId - User ID
 * @returns {Promise<Object|null>} - Session data if valid, null otherwise
 */
const verifyRefreshTokenSession = async (refreshToken, userId) => {
  try {
    const tokenHash = hashToken(refreshToken);
    
    const result = await database.query(
      `SELECT id, user_id, expires_at, is_active
       FROM user_sessions
       WHERE user_id = $1 AND refresh_token_hash = $2 AND is_active = true`,
      [userId, tokenHash]
    );

    if (result.rows.length === 0) {
      return null;
    }

    const session = result.rows[0];
    
    // Check if session is expired
    if (new Date(session.expires_at) < new Date()) {
      return null;
    }

    return session;
  } catch (error) {
    logger.error('Error verifying refresh token session:', error);
    return null;
  }
};

/**
 * Add token to blacklist
 * FR-001.3.3: Add logout tokens to blacklist
 * @param {string} token - Token to blacklist
 * @param {number} expiresIn - TTL in seconds
 */
const blacklistToken = (token, expiresIn) => {
  tokenBlacklist.add(token);
  
  // Auto-remove from blacklist after expiration
  setTimeout(() => {
    tokenBlacklist.delete(token);
    logger.debug('Token removed from blacklist (expired)', { tokenPreview: token.substring(0, 20) });
  }, expiresIn * 1000);
  
  logger.debug('Token added to blacklist', { 
    tokenPreview: token.substring(0, 20),
    expiresIn 
  });
};

/**
 * Check if token is blacklisted
 * FR-001.6.8: Check token blacklist before accepting tokens
 * @param {string} token - Token to check
 * @returns {boolean} - True if token is blacklisted
 */
const isTokenBlacklisted = (token) => {
  return tokenBlacklist.has(token);
};

/**
 * Clean up expired sessions (background task)
 * @returns {Promise<number>} - Number of sessions cleaned up
 */
const cleanupExpiredSessions = async () => {
  try {
    const result = await database.query(
      'DELETE FROM user_sessions WHERE expires_at < NOW()'
    );

    if (result.rowCount > 0) {
      logger.info('Expired sessions cleaned up', { count: result.rowCount });
    }
    return result.rowCount;
  } catch (error) {
    logger.error('Error cleaning up expired sessions:', error);
    return 0;
  }
};

/**
 * Hash token for storage (to prevent token theft from database)
 * @param {string} token - Token to hash
 * @returns {string} - Hashed token
 */
const hashToken = (token) => {
  return crypto.createHash('sha256').update(token).digest('hex');
};

/**
 * Parse user agent string to extract device information
 * @param {string} userAgent - User agent string
 * @returns {Object} - Parsed device information
 */
const parseUserAgent = (userAgent) => {
  if (!userAgent) {
    return {
      deviceType: 'unknown',
      deviceName: 'Unknown Device',
      browser: 'Unknown Browser',
    };
  }

  const ua = userAgent.toLowerCase();
  let deviceType = 'desktop';
  let deviceName = 'Desktop';
  let browser = 'Unknown Browser';

  // Detect device type
  if (ua.includes('mobile') || ua.includes('android')) {
    deviceType = 'mobile';
    deviceName = 'Mobile Device';
  } else if (ua.includes('tablet') || ua.includes('ipad')) {
    deviceType = 'tablet';
    deviceName = 'Tablet';
  }

  // Detect specific devices
  if (ua.includes('iphone')) {
    deviceName = 'iPhone';
  } else if (ua.includes('ipad')) {
    deviceName = 'iPad';
  } else if (ua.includes('android')) {
    deviceName = 'Android Device';
  } else if (ua.includes('macintosh') || ua.includes('mac os x')) {
    deviceName = 'Mac';
  } else if (ua.includes('windows')) {
    deviceName = 'Windows PC';
  } else if (ua.includes('linux')) {
    deviceName = 'Linux PC';
  }

  // Detect browser
  if (ua.includes('firefox')) {
    browser = 'Firefox';
  } else if (ua.includes('chrome') && !ua.includes('edg')) {
    browser = 'Chrome';
  } else if (ua.includes('safari') && !ua.includes('chrome')) {
    browser = 'Safari';
  } else if (ua.includes('edg')) {
    browser = 'Edge';
  } else if (ua.includes('opera') || ua.includes('opr')) {
    browser = 'Opera';
  }

  return {
    deviceType,
    deviceName,
    browser,
  };
};

/**
 * Get session by ID
 * @param {string} sessionId - Session ID
 * @returns {Promise<Object|null>} - Session data or null
 */
const getSessionById = async (sessionId) => {
  try {
    const result = await database.query(
      'SELECT * FROM user_sessions WHERE id = $1',
      [sessionId]
    );

    return result.rows[0] || null;
  } catch (error) {
    logger.error('Error getting session by ID:', error);
    return null;
  }
};

module.exports = {
  createSession,
  getUserSessions,
  updateSessionActivity,
  invalidateSession,
  invalidateOtherSessions,
  invalidateAllUserSessions,
  verifyRefreshTokenSession,
  blacklistToken,
  isTokenBlacklisted,
  cleanupExpiredSessions,
  hashToken,
  parseUserAgent,
  getSessionById,
};

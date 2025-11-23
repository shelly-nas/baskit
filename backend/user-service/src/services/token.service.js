const crypto = require('crypto');
const { database, logger } = require('../../shared/src');

/**
 * Token Service
 * Handles generation and management of verification and reset tokens
 */

/**
 * Generate a secure random token
 * @returns {string} - Secure random token (64 characters hex)
 */
const generateToken = () => {
  return crypto.randomBytes(32).toString('hex');
};

/**
 * Create email verification token
 * @param {string} userId - User ID
 * @param {string} tokenType - Type of verification token (email_verification or email_change)
 * @param {Object} client - Optional database client (for transactions)
 * @returns {Promise<Object>} - Token object with token and expiration
 */
const createVerificationToken = async (userId, tokenType = 'email_verification', client = null) => {
  try {
    const token = generateToken();
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    const dbClient = client || database;
    const result = await dbClient.query(
      `INSERT INTO verification_tokens (user_id, token, token_type, expires_at)
       VALUES ($1, $2, $3, $4)
       RETURNING id, token, expires_at`,
      [userId, token, tokenType, expiresAt]
    );

    logger.info('Verification token created', { userId, tokenType });
    return result.rows[0];
  } catch (error) {
    logger.error('Error creating verification token:', error);
    throw new Error('Failed to create verification token');
  }
};

/**
 * Create password reset token
 * @param {string} userId - User ID
 * @returns {Promise<Object>} - Token object with token and expiration
 */
const createPasswordResetToken = async (userId) => {
  try {
    const token = generateToken();
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    const result = await database.query(
      `INSERT INTO password_reset_tokens (user_id, token, expires_at)
       VALUES ($1, $2, $3)
       RETURNING id, token, expires_at`,
      [userId, token, expiresAt]
    );

    logger.info('Password reset token created', { userId });
    return result.rows[0];
  } catch (error) {
    logger.error('Error creating password reset token:', error);
    throw new Error('Failed to create password reset token');
  }
};

/**
 * Verify email verification token
 * @param {string} token - Verification token
 * @param {Object} client - Optional database client (for transactions)
 * @returns {Promise<Object|null>} - Token data if valid, null otherwise
 */
const verifyVerificationToken = async (token, client = null) => {
  try {
    const dbClient = client || database;
    // Query with WHERE conditions for production and to satisfy unit tests
    const result = await dbClient.query(
      `SELECT vt.*, u.email, u.status
       FROM verification_tokens vt
       JOIN users u ON vt.user_id = u.id
       WHERE vt.token = $1 
       AND vt.used_at IS NULL 
       AND vt.expires_at > NOW()`,
      [token]
    );

    if (!result || result.rows.length === 0) {
      return null;
    }

    const tokenData = result.rows[0];
    
    // Additional JavaScript validation for integration test compatibility
    // (In mocked tests, SQL WHERE clauses aren't evaluated)
    if ((tokenData.used_at !== null && tokenData.used_at !== undefined) || tokenData.used === true) {
      return null;
    }
    
    const now = new Date();
    const expiresAt = new Date(tokenData.expires_at);
    if (expiresAt <= now) {
      return null;
    }

    return tokenData;
  } catch (error) {
    logger.error('Error verifying verification token:', error);
    throw new Error('Failed to verify token');
  }
};

/**
 * Verify password reset token
 * @param {string} token - Reset token
 * @returns {Promise<Object|null>} - Token data if valid, null otherwise
 */
const verifyPasswordResetToken = async (token) => {
  try {
    const result = await database.query(
      `SELECT prt.*, u.email
       FROM password_reset_tokens prt
       JOIN users u ON prt.user_id = u.id
       WHERE prt.token = $1 
       AND prt.used_at IS NULL 
       AND prt.expires_at > NOW()`,
      [token]
    );

    if (result.rows.length === 0) {
      return null;
    }

    return result.rows[0];
  } catch (error) {
    logger.error('Error verifying password reset token:', error);
    throw new Error('Failed to verify token');
  }
};

/**
 * Mark verification token as used
 * @param {string} token - Verification token
 * @param {Object} client - Optional database client (for transactions)
 * @returns {Promise<void>}
 */
const markVerificationTokenUsed = async (token, client = null) => {
  try {
    const dbClient = client || database;
    await dbClient.query(
      'UPDATE verification_tokens SET used_at = NOW(), used = true WHERE token = $1',
      [token]
    );
    logger.info('Verification token marked as used');
  } catch (error) {
    logger.error('Error marking verification token as used:', error);
    throw new Error('Failed to mark token as used');
  }
};

/**
 * Mark password reset token as used
 * @param {string} token - Reset token
 * @returns {Promise<void>}
 */
const markPasswordResetTokenUsed = async (token) => {
  try {
    await database.query(
      'UPDATE password_reset_tokens SET used_at = NOW() WHERE token = $1',
      [token]
    );
    logger.info('Password reset token marked as used');
  } catch (error) {
    logger.error('Error marking password reset token as used:', error);
    throw new Error('Failed to mark token as used');
  }
};

/**
 * Delete expired tokens (cleanup task)
 * @returns {Promise<void>}
 */
const cleanupExpiredTokens = async () => {
  try {
    const verificationResult = await database.query(
      'DELETE FROM verification_tokens WHERE expires_at < NOW()'
    );
    const resetResult = await database.query(
      'DELETE FROM password_reset_tokens WHERE expires_at < NOW()'
    );

    logger.info('Expired tokens cleaned up', {
      verificationTokens: verificationResult.rowCount,
      resetTokens: resetResult.rowCount,
    });
  } catch (error) {
    logger.error('Error cleaning up expired tokens:', error);
  }
};

module.exports = {
  generateToken,
  createVerificationToken,
  createPasswordResetToken,
  verifyVerificationToken,
  verifyPasswordResetToken,
  markVerificationTokenUsed,
  markPasswordResetTokenUsed,
  cleanupExpiredTokens,
};

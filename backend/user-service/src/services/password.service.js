const bcrypt = require('bcryptjs');
const { logger } = require('../../shared/src');

/**
 * Password Service
 * Handles password hashing and verification with bcrypt (cost factor 12)
 */

const SALT_ROUNDS = 12; // Cost factor for bcrypt

/**
 * Hash a password using bcrypt with cost factor 12
 * @param {string} password - Plain text password
 * @returns {Promise<string>} - Hashed password
 */
const hashPassword = async (password) => {
  try {
    const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
    logger.debug('Password hashed successfully');
    return hashedPassword;
  } catch (error) {
    logger.error('Error hashing password:', error);
    throw new Error('Failed to hash password');
  }
};

/**
 * Verify a password against its hash
 * @param {string} password - Plain text password
 * @param {string} hashedPassword - Hashed password from database
 * @returns {Promise<boolean>} - True if password matches, false otherwise
 */
const verifyPassword = async (password, hashedPassword) => {
  try {
    // Validate hash format (bcrypt hashes start with $2a$, $2b$, or $2y$)
    if (!hashedPassword || !hashedPassword.match(/^\$2[aby]\$/)) {
      throw new Error('Invalid hash format');
    }
    const isMatch = await bcrypt.compare(password, hashedPassword);
    return isMatch;
  } catch (error) {
    logger.error('Error verifying password:', error);
    throw error;
  }
};

/**
 * Check if password matches any of the last N passwords
 * @param {string} password - Plain text password
 * @param {Array<string>} passwordHashes - Array of hashed passwords from history
 * @returns {Promise<boolean>} - True if password was used before, false otherwise
 */
const isPasswordReused = async (password, passwordHashes) => {
  try {
    for (const hash of passwordHashes) {
      const isMatch = await bcrypt.compare(password, hash);
      if (isMatch) {
        return true;
      }
    }
    return false;
  } catch (error) {
    logger.error('Error checking password reuse:', error);
    throw new Error('Failed to check password history');
  }
};

module.exports = {
  hashPassword,
  verifyPassword,
  isPasswordReused,
  SALT_ROUNDS,
};

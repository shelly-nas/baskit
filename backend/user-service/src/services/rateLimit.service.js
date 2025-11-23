const { logger } = require('../../shared/src');

/**
 * Rate Limiting Service
 * Handles rate limiting for login attempts per IP and per user
 * FR-001.2.2: 5 failed attempts per 15 minutes per IP address
 * FR-001.2.3: Lock accounts after 10 consecutive failed login attempts
 */

// In-memory store for rate limiting (can be replaced with Redis in production)
const rateLimitStore = new Map();
const userAttemptStore = new Map();

const RATE_LIMIT_WINDOW_MS = parseInt(process.env.LOGIN_RATE_LIMIT_WINDOW) || 15 * 60 * 1000; // 15 minutes
const MAX_LOGIN_ATTEMPTS_PER_IP = parseInt(process.env.LOGIN_RATE_LIMIT_MAX) || 5;
const MAX_LOGIN_ATTEMPTS_PER_USER = 10; // FR-001.2.3
const ACCOUNT_LOCK_DURATION_MS = 30 * 60 * 1000; // 30 minutes

/**
 * Clean up expired entries from the store
 * @param {Map} store - The store to clean
 */
const cleanupExpiredEntries = (store) => {
  const now = Date.now();
  for (const [key, value] of store.entries()) {
    if (now > value.resetAt) {
      store.delete(key);
    }
  }
};

/**
 * Check if IP address has exceeded rate limit
 * FR-001.2.2: 5 failed attempts per 15 minutes per IP
 * @param {string} ipAddress - IP address to check
 * @returns {Object} - { allowed: boolean, remaining: number, resetAt: number }
 */
const checkIpRateLimit = (ipAddress) => {
  if (!ipAddress) {
    return { allowed: true, remaining: MAX_LOGIN_ATTEMPTS_PER_IP, resetAt: 0 };
  }

  // Clean up old entries periodically
  if (Math.random() < 0.1) { // 10% chance to cleanup on each check
    cleanupExpiredEntries(rateLimitStore);
  }

  const now = Date.now();
  const key = `ip:${ipAddress}`;
  const record = rateLimitStore.get(key);

  if (!record || now > record.resetAt) {
    // No record or expired, allow request
    return {
      allowed: true,
      remaining: MAX_LOGIN_ATTEMPTS_PER_IP - 1,
      resetAt: now + RATE_LIMIT_WINDOW_MS,
    };
  }

  const allowed = record.attempts < MAX_LOGIN_ATTEMPTS_PER_IP;
  const remaining = Math.max(0, MAX_LOGIN_ATTEMPTS_PER_IP - record.attempts);

  return {
    allowed,
    remaining,
    resetAt: record.resetAt,
    waitTime: allowed ? 0 : Math.ceil((record.resetAt - now) / 1000 / 60), // Minutes
  };
};

/**
 * Record a failed login attempt for an IP address
 * @param {string} ipAddress - IP address
 */
const recordIpFailedAttempt = (ipAddress) => {
  if (!ipAddress) return;

  const now = Date.now();
  const key = `ip:${ipAddress}`;
  const record = rateLimitStore.get(key);

  if (!record || now > record.resetAt) {
    // Create new record
    rateLimitStore.set(key, {
      attempts: 1,
      resetAt: now + RATE_LIMIT_WINDOW_MS,
    });
  } else {
    // Increment existing record
    record.attempts += 1;
    rateLimitStore.set(key, record);
  }

  logger.debug('IP failed login attempt recorded', {
    ipAddress,
    attempts: rateLimitStore.get(key).attempts,
  });
};

/**
 * Reset rate limit for an IP address (on successful login)
 * @param {string} ipAddress - IP address
 */
const resetIpRateLimit = (ipAddress) => {
  if (!ipAddress) return;

  const key = `ip:${ipAddress}`;
  rateLimitStore.delete(key);
  logger.debug('IP rate limit reset', { ipAddress });
};

/**
 * Check user failed login attempts
 * FR-001.2.3: Lock accounts after 10 consecutive failed login attempts
 * @param {string} userId - User ID
 * @param {number} currentAttempts - Current failed attempts from database
 * @returns {Object} - { shouldLock: boolean, attempts: number, lockUntil: Date|null }
 */
const checkUserLoginAttempts = (userId, currentAttempts = 0) => {
  const shouldLock = currentAttempts >= MAX_LOGIN_ATTEMPTS_PER_USER;
  
  let lockUntil = null;
  if (shouldLock) {
    lockUntil = new Date(Date.now() + ACCOUNT_LOCK_DURATION_MS);
  }

  return {
    shouldLock,
    attempts: currentAttempts,
    lockUntil,
    remainingAttempts: Math.max(0, MAX_LOGIN_ATTEMPTS_PER_USER - currentAttempts),
  };
};

/**
 * Check if user account is currently locked
 * @param {Object} user - User object with status and locked_until
 * @returns {Object} - { isLocked: boolean, lockUntil: Date|null, reason: string|null }
 */
const checkAccountLockStatus = (user) => {
  if (!user) {
    return { isLocked: false, lockUntil: null, reason: null };
  }

  // Check if account is permanently locked
  if (user.status === 'locked' && !user.locked_until) {
    return {
      isLocked: true,
      lockUntil: null,
      reason: 'Account permanently locked. Please contact support.',
    };
  }

  // Check if account is temporarily locked
  if (user.locked_until) {
    const now = new Date();
    const lockUntil = new Date(user.locked_until);

    if (lockUntil > now) {
      const minutesRemaining = Math.ceil((lockUntil - now) / 1000 / 60);
      return {
        isLocked: true,
        lockUntil,
        reason: `Account locked due to multiple failed login attempts. Account temporarily locked. Try again in ${minutesRemaining} minute${minutesRemaining !== 1 ? 's' : ''}.`,
      };
    }
    // Lock has expired, return unlocked
  }

  return { isLocked: false, lockUntil: null, reason: null };
};

/**
 * Calculate remaining time for rate limit reset
 * @param {number} resetAt - Reset timestamp in milliseconds
 * @returns {number} - Minutes remaining
 */
const getRemainingMinutes = (resetAt) => {
  const now = Date.now();
  if (resetAt <= now) return 0;
  return Math.ceil((resetAt - now) / 1000 / 60);
};

/**
 * Get rate limit status for an IP
 * @param {string} ipAddress - IP address
 * @returns {Object} - Rate limit information
 */
const getIpRateLimitStatus = (ipAddress) => {
  if (!ipAddress) return null;

  const key = `ip:${ipAddress}`;
  const record = rateLimitStore.get(key);

  if (!record) return null;

  const now = Date.now();
  if (now > record.resetAt) {
    rateLimitStore.delete(key);
    return null;
  }

  return {
    attempts: record.attempts,
    maxAttempts: MAX_LOGIN_ATTEMPTS_PER_IP,
    remaining: Math.max(0, MAX_LOGIN_ATTEMPTS_PER_IP - record.attempts),
    resetAt: record.resetAt,
    minutesRemaining: getRemainingMinutes(record.resetAt),
  };
};

/**
 * Clear all rate limit data (for testing or admin purposes)
 */
const clearAllRateLimits = () => {
  rateLimitStore.clear();
  userAttemptStore.clear();
  logger.info('All rate limits cleared');
};

module.exports = {
  checkIpRateLimit,
  recordIpFailedAttempt,
  resetIpRateLimit,
  checkUserLoginAttempts,
  checkAccountLockStatus,
  getRemainingMinutes,
  getIpRateLimitStatus,
  clearAllRateLimits,
  // Export constants for testing
  MAX_LOGIN_ATTEMPTS_PER_IP,
  MAX_LOGIN_ATTEMPTS_PER_USER,
  RATE_LIMIT_WINDOW_MS,
  ACCOUNT_LOCK_DURATION_MS,
};

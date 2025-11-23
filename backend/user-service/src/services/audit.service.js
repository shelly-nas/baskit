const { database, logger } = require('../../shared/src');

/**
 * Audit Service
 * Handles logging of security events and user activities
 */

/**
 * Log an audit event
 * @param {Object} params - Event parameters
 * @param {string} params.userId - User ID (optional)
 * @param {string} params.eventType - Event type
 * @param {string} params.eventDescription - Event description
 * @param {string} params.ipAddress - IP address
 * @param {string} params.userAgent - User agent string
 * @param {Object} params.metadata - Additional metadata
 * @param {Object} params.client - Database client for transactions (optional)
 * @returns {Promise<void>}
 */
const logEvent = async ({ 
  userId = null, 
  eventType, 
  eventDescription, 
  ipAddress = null, 
  userAgent = null, 
  metadata = null,
  client = null
}) => {
  try {
    const queryFn = client || database;
    await queryFn.query(
      `INSERT INTO audit_logs (user_id, event_type, event_description, ip_address, user_agent, metadata)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [userId, eventType, eventDescription, ipAddress, userAgent, JSON.stringify(metadata)]
    );

    logger.debug('Audit event logged', { eventType, userId });
  } catch (error) {
    logger.error('Error logging audit event:', error);
    // Don't throw error - audit logging shouldn't break the main flow
  }
};

/**
 * Log registration event
 */
const logRegistration = async (userId, email, ipAddress, userAgent, client = null) => {
  return logEvent({
    userId,
    eventType: 'registration',
    eventDescription: `User registered with email: ${email}`,
    ipAddress,
    userAgent,
    metadata: { email },
    client,
  });
};

/**
 * Log login success event
 */
const logLoginSuccess = async (userId, email, ipAddress, userAgent) => {
  return logEvent({
    userId,
    eventType: 'login_success',
    eventDescription: `User logged in successfully: ${email}`,
    ipAddress,
    userAgent,
    metadata: { email },
  });
};

/**
 * Log login failure event
 */
const logLoginFailure = async (email, reason, ipAddress, userAgent) => {
  return logEvent({
    userId: null,
    eventType: 'login_failed',
    eventDescription: `Login failed for ${email}: ${reason}`,
    ipAddress,
    userAgent,
    metadata: { email, reason },
  });
};

/**
 * Log password reset request
 */
const logPasswordResetRequest = async (userId, email, ipAddress, userAgent) => {
  return logEvent({
    userId,
    eventType: 'password_reset_request',
    eventDescription: `Password reset requested for: ${email}`,
    ipAddress,
    userAgent,
    metadata: { email },
  });
};

/**
 * Log password reset completion
 */
const logPasswordResetComplete = async (userId, email, ipAddress, userAgent) => {
  return logEvent({
    userId,
    eventType: 'password_reset_complete',
    eventDescription: `Password reset completed for: ${email}`,
    ipAddress,
    userAgent,
    metadata: { email },
  });
};

/**
 * Log email verification
 */
const logEmailVerification = async (userId, email, ipAddress, userAgent, client = null) => {
  return logEvent({
    userId,
    eventType: 'email_verification',
    eventDescription: `Email verified for: ${email}`,
    ipAddress,
    userAgent,
    metadata: { email },
    client,
  });
};

/**
 * Log account lockout
 */
const logAccountLockout = async (userId, email, reason, ipAddress, userAgent) => {
  return logEvent({
    userId,
    eventType: 'account_locked',
    eventDescription: `Account locked for ${email}: ${reason}`,
    ipAddress,
    userAgent,
    metadata: { email, reason },
  });
};

module.exports = {
  logEvent,
  logRegistration,
  logLoginSuccess,
  logLoginFailure,
  logPasswordResetRequest,
  logPasswordResetComplete,
  logEmailVerification,
  logAccountLockout,
};

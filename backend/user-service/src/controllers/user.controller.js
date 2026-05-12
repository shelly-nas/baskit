const { database, logger, ValidationError, ConflictError, UnauthorizedError, NotFoundError } = require('../../shared/src');
const { hashPassword, verifyPassword, isPasswordReused } = require('../services/password.service');
const { createVerificationToken } = require('../services/token.service');
const { sendVerificationEmail } = require('../services/email.service');
const sessionService = require('../services/session.service');

/**
 * User controller
 * Handles user profile, preferences, password, email, sessions, and account management
 */

/**
 * Get current user profile
 * GET /api/users/profile
 */
const getProfile = async (req, res) => {
  const userId = req.user.id;
  logger.info('Get user profile', { userId });

  const result = await database.query(
    `SELECT
       u.id, u.email, u.display_name, u.first_name, u.last_name,
       u.phone_number, u.profile_picture_url, u.is_email_verified,
       u.status, u.subscription_tier, u.subscription_start_date,
       u.subscription_end_date, u.last_login_at, u.created_at, u.updated_at,
       up.default_optimization, up.enable_notifications, up.notification_frequency,
       up.default_location, up.preferred_stores, up.accessibility_mode,
       up.language, up.currency, up.distance_unit
     FROM users u
     LEFT JOIN user_preferences up ON up.user_id = u.id
     WHERE u.id = $1 AND u.deleted_at IS NULL`,
    [userId]
  );

  if (result.rows.length === 0) {
    throw new NotFoundError('User not found');
  }

  const row = result.rows[0];

  res.status(200).json({
    success: true,
    data: {
      user: {
        id: row.id,
        email: row.email,
        displayName: row.display_name,
        firstName: row.first_name,
        lastName: row.last_name,
        phoneNumber: row.phone_number,
        profilePictureUrl: row.profile_picture_url,
        isEmailVerified: row.is_email_verified,
        status: row.status,
        subscriptionTier: row.subscription_tier,
        subscriptionStartDate: row.subscription_start_date,
        subscriptionEndDate: row.subscription_end_date,
        lastLoginAt: row.last_login_at,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      },
      preferences: {
        defaultOptimization: row.default_optimization,
        enableNotifications: row.enable_notifications,
        notificationFrequency: row.notification_frequency,
        defaultLocation: row.default_location,
        preferredStores: row.preferred_stores,
        accessibilityMode: row.accessibility_mode,
        language: row.language,
        currency: row.currency,
        distanceUnit: row.distance_unit,
      },
    },
  });
};

/**
 * Update user profile
 * PUT /api/users/profile
 */
const updateProfile = async (req, res) => {
  const userId = req.user.id;
  logger.info('Update user profile', { userId });

  const { displayName, firstName, lastName, phoneNumber } = req.body;

  // Validate displayName if provided
  if (displayName !== undefined) {
    if (typeof displayName !== 'string' || displayName.trim().length < 2 || displayName.trim().length > 50) {
      throw new ValidationError('Display name must be between 2 and 50 characters');
    }
  }

  // Build dynamic update query
  const updates = [];
  const values = [];
  let paramIndex = 1;

  if (displayName !== undefined) {
    updates.push(`display_name = $${paramIndex++}`);
    values.push(displayName.trim());
  }
  if (firstName !== undefined) {
    updates.push(`first_name = $${paramIndex++}`);
    values.push(firstName ? firstName.trim() : null);
  }
  if (lastName !== undefined) {
    updates.push(`last_name = $${paramIndex++}`);
    values.push(lastName ? lastName.trim() : null);
  }
  if (phoneNumber !== undefined) {
    updates.push(`phone_number = $${paramIndex++}`);
    values.push(phoneNumber ? phoneNumber.trim() : null);
  }

  if (updates.length === 0) {
    throw new ValidationError('No fields to update');
  }

  updates.push(`updated_at = NOW()`);
  values.push(userId);

  const result = await database.query(
    `UPDATE users
     SET ${updates.join(', ')}
     WHERE id = $${paramIndex} AND deleted_at IS NULL
     RETURNING id, email, display_name, first_name, last_name, phone_number,
               profile_picture_url, is_email_verified, status, updated_at`,
    values
  );

  if (result.rows.length === 0) {
    throw new NotFoundError('User not found');
  }

  const row = result.rows[0];

  res.status(200).json({
    success: true,
    message: 'Profile updated successfully',
    data: {
      user: {
        id: row.id,
        email: row.email,
        displayName: row.display_name,
        firstName: row.first_name,
        lastName: row.last_name,
        phoneNumber: row.phone_number,
        profilePictureUrl: row.profile_picture_url,
        isEmailVerified: row.is_email_verified,
        status: row.status,
        updatedAt: row.updated_at,
      },
    },
  });
};

/**
 * Request an email address change (requires current password verification)
 * PATCH /api/users/email
 */
const changeEmail = async (req, res) => {
  const userId = req.user.id;
  const ipAddress = req.ip || req.connection.remoteAddress;
  const userAgent = req.get('user-agent');
  logger.info('Change email request', { userId });

  const { currentPassword, newEmail } = req.body;

  if (!currentPassword || !newEmail) {
    throw new ValidationError('Current password and new email are required');
  }

  const normalizedEmail = newEmail.trim().toLowerCase();

  // Basic email format check
  if (!normalizedEmail.includes('@') || normalizedEmail.length > 255) {
    throw new ValidationError('Please provide a valid email address');
  }

  // Get current user with password hash
  const userResult = await database.query(
    `SELECT id, email, password_hash FROM users WHERE id = $1 AND deleted_at IS NULL`,
    [userId]
  );

  if (userResult.rows.length === 0) {
    throw new NotFoundError('User not found');
  }

  const user = userResult.rows[0];

  // Verify current password
  const isPasswordValid = await verifyPassword(currentPassword, user.password_hash);
  if (!isPasswordValid) {
    throw new UnauthorizedError('Current password is incorrect');
  }

  // Check new email is not already taken
  const emailCheck = await database.query(
    `SELECT id FROM users WHERE email = $1 AND deleted_at IS NULL`,
    [normalizedEmail]
  );

  if (emailCheck.rows.length > 0) {
    throw new ConflictError('An account with this email address already exists');
  }

  // Create email change verification token
  const verificationToken = await createVerificationToken(userId, 'email_change');

  // Send verification email to the new address
  await sendVerificationEmail(normalizedEmail, null, verificationToken.token);

  logger.info('Email change verification sent', { userId, newEmail: normalizedEmail });

  res.status(200).json({
    success: true,
    message: 'A verification email has been sent to your new address. Please verify it to complete the change.',
  });
};

/**
 * Change user password (requires current password)
 * PATCH /api/users/password
 */
const changePassword = async (req, res) => {
  const userId = req.user.id;
  const ipAddress = req.ip || req.connection.remoteAddress;
  const userAgent = req.get('user-agent');
  logger.info('Change password request', { userId });

  const { currentPassword, newPassword } = req.body;

  if (!currentPassword || !newPassword) {
    throw new ValidationError('Current password and new password are required');
  }

  // Validate new password complexity
  const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/;
  if (newPassword.length < 8 || !passwordRegex.test(newPassword)) {
    throw new ValidationError(
      'New password must be at least 8 characters and include uppercase, lowercase, a number, and a special character (@$!%*?&)'
    );
  }

  // Get current user
  const userResult = await database.query(
    `SELECT id, email, password_hash FROM users WHERE id = $1 AND deleted_at IS NULL`,
    [userId]
  );

  if (userResult.rows.length === 0) {
    throw new NotFoundError('User not found');
  }

  const user = userResult.rows[0];

  // Verify current password
  const isPasswordValid = await verifyPassword(currentPassword, user.password_hash);
  if (!isPasswordValid) {
    throw new UnauthorizedError('Current password is incorrect');
  }

  // Check new password is not the same as current
  const isSameAsCurrent = await verifyPassword(newPassword, user.password_hash);
  if (isSameAsCurrent) {
    throw new ValidationError('New password must be different from your current password');
  }

  // Check password history (last 5)
  const historyResult = await database.query(
    `SELECT password_hash FROM password_history
     WHERE user_id = $1
     ORDER BY created_at DESC
     LIMIT 5`,
    [userId]
  );

  const passwordHashes = historyResult.rows.map(r => r.password_hash);
  const isReused = await isPasswordReused(newPassword, passwordHashes);
  if (isReused) {
    throw new ValidationError('You cannot reuse one of your last 5 passwords. Please choose a different password.');
  }

  const client = await database.getClient();

  try {
    await client.query('BEGIN');

    // Rotate password history — keep only last 5
    const countResult = await client.query(
      'SELECT COUNT(*) as count FROM password_history WHERE user_id = $1',
      [userId]
    );
    const historyCount = parseInt(countResult.rows[0].count, 10);
    if (historyCount >= 5) {
      await client.query(
        `DELETE FROM password_history
         WHERE id IN (
           SELECT id FROM password_history
           WHERE user_id = $1
           ORDER BY created_at ASC
           LIMIT $2
         )`,
        [userId, historyCount - 4]
      );
    }

    // Archive current password
    await client.query(
      `INSERT INTO password_history (user_id, password_hash) VALUES ($1, $2)`,
      [userId, user.password_hash]
    );

    // Hash and store new password
    const newPasswordHash = await hashPassword(newPassword);
    await client.query(
      `UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2`,
      [newPasswordHash, userId]
    );

    // Invalidate all other sessions (keep current)
    const currentSessionId = req.user.sessionId || null;
    if (currentSessionId) {
      await sessionService.invalidateOtherSessions(userId, currentSessionId);
    } else {
      await sessionService.invalidateAllUserSessions(userId, client);
    }

    await client.query('COMMIT');

    logger.info('Password changed successfully', { userId });

    res.status(200).json({
      success: true,
      message: 'Password changed successfully',
    });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

/**
 * Get user preferences
 * GET /api/users/preferences
 */
const getPreferences = async (req, res) => {
  const userId = req.user.id;
  logger.info('Get user preferences', { userId });

  const result = await database.query(
    `SELECT * FROM user_preferences WHERE user_id = $1`,
    [userId]
  );

  if (result.rows.length === 0) {
    throw new NotFoundError('Preferences not found');
  }

  const row = result.rows[0];

  res.status(200).json({
    success: true,
    data: {
      defaultOptimization: row.default_optimization,
      enableNotifications: row.enable_notifications,
      notificationFrequency: row.notification_frequency,
      defaultLocation: row.default_location,
      preferredStores: row.preferred_stores,
      accessibilityMode: row.accessibility_mode,
      language: row.language,
      currency: row.currency,
      distanceUnit: row.distance_unit,
    },
  });
};

/**
 * Update user preferences
 * PUT /api/users/preferences
 */
const updatePreferences = async (req, res) => {
  const userId = req.user.id;
  logger.info('Update user preferences', { userId });

  const VALID_OPTIMIZATIONS = ['cheapest', 'fastest', 'healthiest', 'nearest'];
  const VALID_FREQUENCIES = ['realtime', 'daily', 'weekly', 'never'];
  const VALID_LANGUAGES = ['nl', 'en'];
  const VALID_CURRENCIES = ['EUR', 'USD', 'GBP'];
  const VALID_DISTANCE_UNITS = ['km', 'mi'];

  const {
    defaultOptimization,
    enableNotifications,
    notificationFrequency,
    defaultLocation,
    preferredStores,
    accessibilityMode,
    language,
    currency,
    distanceUnit,
  } = req.body;

  // Validate enum fields
  if (defaultOptimization !== undefined && !VALID_OPTIMIZATIONS.includes(defaultOptimization)) {
    throw new ValidationError(`defaultOptimization must be one of: ${VALID_OPTIMIZATIONS.join(', ')}`);
  }
  if (notificationFrequency !== undefined && !VALID_FREQUENCIES.includes(notificationFrequency)) {
    throw new ValidationError(`notificationFrequency must be one of: ${VALID_FREQUENCIES.join(', ')}`);
  }
  if (language !== undefined && !VALID_LANGUAGES.includes(language)) {
    throw new ValidationError(`language must be one of: ${VALID_LANGUAGES.join(', ')}`);
  }
  if (currency !== undefined && !VALID_CURRENCIES.includes(currency)) {
    throw new ValidationError(`currency must be one of: ${VALID_CURRENCIES.join(', ')}`);
  }
  if (distanceUnit !== undefined && !VALID_DISTANCE_UNITS.includes(distanceUnit)) {
    throw new ValidationError(`distanceUnit must be one of: ${VALID_DISTANCE_UNITS.join(', ')}`);
  }

  const result = await database.query(
    `INSERT INTO user_preferences (
       user_id, default_optimization, enable_notifications, notification_frequency,
       default_location, preferred_stores, accessibility_mode, language, currency, distance_unit
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
     ON CONFLICT (user_id) DO UPDATE SET
       default_optimization   = COALESCE($2, user_preferences.default_optimization),
       enable_notifications   = COALESCE($3, user_preferences.enable_notifications),
       notification_frequency = COALESCE($4, user_preferences.notification_frequency),
       default_location       = COALESCE($5, user_preferences.default_location),
       preferred_stores       = COALESCE($6, user_preferences.preferred_stores),
       accessibility_mode     = COALESCE($7, user_preferences.accessibility_mode),
       language               = COALESCE($8, user_preferences.language),
       currency               = COALESCE($9, user_preferences.currency),
       distance_unit          = COALESCE($10, user_preferences.distance_unit)
     RETURNING *`,
    [
      userId,
      defaultOptimization ?? null,
      enableNotifications ?? null,
      notificationFrequency ?? null,
      defaultLocation ?? null,
      preferredStores ? JSON.stringify(preferredStores) : null,
      accessibilityMode ?? null,
      language ?? null,
      currency ?? null,
      distanceUnit ?? null,
    ]
  );

  const row = result.rows[0];

  res.status(200).json({
    success: true,
    message: 'Preferences updated successfully',
    data: {
      defaultOptimization: row.default_optimization,
      enableNotifications: row.enable_notifications,
      notificationFrequency: row.notification_frequency,
      defaultLocation: row.default_location,
      preferredStores: row.preferred_stores,
      accessibilityMode: row.accessibility_mode,
      language: row.language,
      currency: row.currency,
      distanceUnit: row.distance_unit,
    },
  });
};

/**
 * Get all active sessions for the current user
 * GET /api/users/sessions
 */
const getSessions = async (req, res) => {
  const userId = req.user.id;
  const currentSessionId = req.user.sessionId || null;
  logger.info('Get user sessions', { userId });

  const sessions = await sessionService.getUserSessions(userId);

  const sessionsWithCurrent = sessions.map(session => ({
    ...session,
    isCurrent: currentSessionId ? session.id === currentSessionId : false,
  }));

  res.status(200).json({
    success: true,
    data: {
      sessions: sessionsWithCurrent,
    },
  });
};

/**
 * Delete a specific session
 * DELETE /api/users/sessions/:id
 */
const deleteSession = async (req, res) => {
  const userId = req.user.id;
  const { id: sessionId } = req.params;
  logger.info('Delete session', { userId, sessionId });

  if (!sessionId) {
    throw new ValidationError('Session ID is required');
  }

  await sessionService.invalidateSession(sessionId, userId);

  res.status(200).json({
    success: true,
    message: 'Session terminated successfully',
  });
};

/**
 * Delete all sessions except the current one
 * DELETE /api/users/sessions
 */
const deleteAllOtherSessions = async (req, res) => {
  const userId = req.user.id;
  const currentSessionId = req.user.sessionId || null;
  logger.info('Delete all other sessions', { userId, currentSessionId });

  if (currentSessionId) {
    await sessionService.invalidateOtherSessions(userId, currentSessionId);
  } else {
    await sessionService.invalidateAllUserSessions(userId);
  }

  res.status(200).json({
    success: true,
    message: 'All other sessions have been terminated',
  });
};

/**
 * Soft-delete user account
 * DELETE /api/users/account
 */
const deleteAccount = async (req, res) => {
  const userId = req.user.id;
  logger.info('Delete user account', { userId });

  const client = await database.getClient();

  try {
    await client.query('BEGIN');

    const result = await client.query(
      `UPDATE users
       SET status = 'deleted', deleted_at = NOW(), updated_at = NOW()
       WHERE id = $1 AND deleted_at IS NULL
       RETURNING id`,
      [userId]
    );

    if (result.rows.length === 0) {
      throw new NotFoundError('User not found');
    }

    // Invalidate all sessions
    await sessionService.invalidateAllUserSessions(userId, client);

    await client.query('COMMIT');

    logger.info('User account deleted', { userId });

    res.status(200).json({
      success: true,
      message: 'Account deleted successfully',
    });
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

module.exports = {
  getProfile,
  updateProfile,
  changeEmail,
  changePassword,
  getPreferences,
  updatePreferences,
  getSessions,
  deleteSession,
  deleteAllOtherSessions,
  deleteAccount,
};

const { database, logger, ValidationError, ConflictError, UnauthorizedError, NotFoundError } = require('../../shared/src');
const { registrationSchema } = require('../utils/validators');
const { hashPassword } = require('../services/password.service');
const { createVerificationToken } = require('../services/token.service');
const { sendVerificationEmail } = require('../services/email.service');
const { logRegistration } = require('../services/audit.service');

/**
 * Authentication controller
 * Handles user registration, login, and password management
 */

/**
 * Register a new user
 * FR-001.1.1 through FR-001.1.8
 */
const register = async (req, res) => {
  // Trim and lowercase email before validation
  const trimmedData = {
    ...req.body,
    email: req.body.email?.trim().toLowerCase(),
    displayName: req.body.displayName?.trim(),
  };
  
  const { email, password, displayName } = trimmedData;
  
  // Get client info for audit logging
  const ipAddress = req.ip || req.connection.remoteAddress;
  const userAgent = req.get('user-agent');

  logger.info('User registration attempt', { email });

  // FR-001.1.2, FR-001.1.3, FR-001.1.4: Validate input fields
  const { error, value } = registrationSchema.validate(trimmedData);
  if (error) {
    throw new ValidationError(error.details[0].message);
  }

  const client = await database.getClient();
  
  try {
    await client.query('BEGIN');

    // FR-001.1.5: Check for duplicate email addresses
    const existingUser = await client.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );

    if (existingUser.rows.length > 0) {
      throw new ConflictError('An account with this email already exists');
    }

    // FR-001.1.8: Store passwords using bcrypt hashing with cost factor 12
    const passwordHash = await hashPassword(password);

    // FR-001.1.7: Create user account with pending_verification status
    const userResult = await client.query(
      `INSERT INTO users (email, password_hash, display_name, status)
       VALUES ($1, $2, $3, 'pending_verification')
       RETURNING id, email, display_name, status, created_at`,
      [email, passwordHash, displayName]
    );

    const user = userResult.rows[0];

    // Create default user preferences
    await client.query(
      'INSERT INTO user_preferences (user_id) VALUES ($1)',
      [user.id]
    );

    // FR-001.1.6: Send verification email with time-limited token (24 hours)
    const verificationToken = await createVerificationToken(user.id, 'email_verification', client);
    await sendVerificationEmail(email, displayName, verificationToken.token);

    // Log registration event
    await logRegistration(user.id, email, ipAddress, userAgent, client);

    await client.query('COMMIT');

    logger.info('User registered successfully', { 
      userId: user.id, 
      email: user.email 
    });

    res.status(201).json({
      success: true,
      message: 'Registration successful. Please check your email to verify your account.',
      data: {
        user: {
          id: user.id,
          email: user.email,
          displayName: user.display_name,
          status: user.status,
          createdAt: user.created_at,
        },
      },
    });
  } catch (error) {
    await client.query('ROLLBACK', undefined);
    throw error;
  } finally {
    client.release();
  }
};

const login = async (req, res) => {
  // TODO: Implement user login with JWT
  logger.info('User login attempt', { email: req.body.email });
  
  res.status(200).json({
    success: true,
    message: 'User login endpoint - to be implemented',
    data: { email: req.body.email },
  });
};

const logout = async (req, res) => {
  // TODO: Implement logout logic (token blacklisting if needed)
  logger.info('User logout');
  
  res.status(200).json({
    success: true,
    message: 'User logged out successfully',
  });
};

const forgotPassword = async (req, res) => {
  // TODO: Implement password reset request
  logger.info('Password reset requested', { email: req.body.email });
  
  res.status(200).json({
    success: true,
    message: 'Password reset email sent (to be implemented)',
  });
};

const resetPassword = async (req, res) => {
  // TODO: Implement password reset with token
  logger.info('Password reset attempt');
  
  res.status(200).json({
    success: true,
    message: 'Password reset successfully (to be implemented)',
  });
};

/**
 * Verify email with token
 * FR-001.1.7: Activate account after email verification
 */
const verifyEmail = async (req, res) => {
  const { token } = req.body;
  
  const ipAddress = req.ip || req.connection.remoteAddress;
  const userAgent = req.get('user-agent');

  if (!token) {
    throw new ValidationError('Verification token is required');
  }

  logger.info('Email verification attempt');

  const tokenService = require('../services/token.service');
  const auditService = require('../services/audit.service');

  const client = await database.getClient();

  try {
    await client.query('BEGIN');

    // Verify token is valid and not expired (within transaction)
    const tokenData = await tokenService.verifyVerificationToken(token, client);

    if (!tokenData) {
      throw new ValidationError('This verification link is invalid or has expired. Please request a new one.');
    }

    // Activate user account
    const updatedUser = await client.query(
      `UPDATE users 
       SET is_email_verified = TRUE, 
           status = 'active', 
           updated_at = NOW()
       WHERE id = $1
       RETURNING id, email, display_name, status`,
      [tokenData.user_id]
    );

    // Mark token as used
    await tokenService.markVerificationTokenUsed(token, client);

    // Log verification event
    await auditService.logEmailVerification(
      tokenData.user_id, 
      tokenData.email, 
      ipAddress, 
      userAgent,
      client
    );

    await client.query('COMMIT');

    logger.info('Email verified successfully', { 
      userId: tokenData.user_id,
      email: tokenData.email 
    });

    res.status(200).json({
      success: true,
      message: 'Email verified successfully. You can now log in.',
      data: {
        user: updatedUser.rows[0],
      },
    });
  } catch (error) {
    await client.query('ROLLBACK', undefined);
    throw error;
  } finally {
    client.release();
  }
};

/**
 * Resend verification email
 */
const resendVerification = async (req, res) => {
  const { email } = req.body;

  if (!email) {
    throw new ValidationError('Email is required');
  }

  logger.info('Resend verification email requested', { email });

  // Get user
  const userResult = await database.query(
    'SELECT id, email, display_name, is_email_verified, status FROM users WHERE email = $1',
    [email]
  );

  if (userResult.rows.length === 0) {
    throw new NotFoundError('User not found');
  }

  const user = userResult.rows[0];

  // Check if already verified
  if (user.status === 'active') {
    throw new ValidationError('This account is already verified');
  }

  const tokenService = require('../services/token.service');
  const emailService = require('../services/email.service');

  // Create new verification token
  const verificationToken = await tokenService.createVerificationToken(user.id);
  
  // Send verification email
  await emailService.resendVerificationEmail(
    user.email, 
    user.display_name, 
    verificationToken.token
  );

  logger.info('Verification email resent', { email: user.email });

  res.status(200).json({
    success: true,
    message: 'Verification email sent. Please check your inbox.',
  });
};

module.exports = {
  register,
  login,
  logout,
  forgotPassword,
  resetPassword,
  verifyEmail,
  resendVerification,
};

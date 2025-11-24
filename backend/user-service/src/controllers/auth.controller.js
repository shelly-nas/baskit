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
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

/**
 * User login
 * FR-001.2.1 through FR-001.2.8
 */
const login = async (req, res) => {
  const { email, password, rememberMe = false } = req.body;
  
  // Get client info for audit logging and rate limiting
  const ipAddress = req.ip || req.connection.remoteAddress;
  const userAgent = req.get('user-agent');

  logger.info('User login attempt', { email, ipAddress });

  // Validate input fields (email and password format)
  const { loginSchema } = require('../utils/validators');
  const { error } = loginSchema.validate({ email, password });
  if (error) {
    throw new ValidationError(error.details[0].message);
  }

  const rateLimitService = require('../services/rateLimit.service');
  
  // FR-001.2.2: Check IP rate limiting (5 failed attempts per 15 minutes per IP)
  // Check early but don't throw yet - need to track user-level attempts for account locking
  const rateLimitCheck = rateLimitService.checkIpRateLimit(ipAddress);
  
  const client = await database.getClient();
  let transactionCommitted = false;

  try {
    await client.query('BEGIN');

    // Retrieve user account by email (with lowercase normalization)
    const userResult = await client.query(
      `SELECT id, email, password_hash, display_name, status, 
              is_email_verified, failed_login_attempts, locked_until,
              subscription_tier
       FROM users 
       WHERE email = $1`,
      [email.trim().toLowerCase()]
    );

    if (userResult.rows.length === 0) {
      // Don't reveal if email exists - security best practice
      const auditService = require('../services/audit.service');
      await auditService.logLoginFailure(null, email, 'Invalid credentials', ipAddress, userAgent, client);
      
      await client.query('COMMIT');
      transactionCommitted = true;
      rateLimitService.recordIpFailedAttempt(ipAddress);
      
      throw new UnauthorizedError('Invalid email or password');
    }

    const user = userResult.rows[0];

    // FR-001.2.8: Check if email is verified
    if (user.status === 'pending_verification' || !user.is_email_verified) {
      // Don't increment failed attempts for unverified accounts
      const auditService = require('../services/audit.service');
      await auditService.logLoginFailure(user.id, email, 'unverified email', ipAddress, userAgent, client);
      
      await client.query('COMMIT');
      transactionCommitted = true;
      
      throw new UnauthorizedError('Please verify your email address before logging in');
    }

    // Check if account is locked (temporary or permanent)
    const lockStatus = rateLimitService.checkAccountLockStatus(user);
    if (lockStatus.isLocked) {
      const auditService = require('../services/audit.service');
      await auditService.logLoginFailure(user.id, email, 'Account locked', ipAddress, userAgent, client);
      
      await client.query('COMMIT');
      transactionCommitted = true;
      
      throw new UnauthorizedError(lockStatus.reason);
    }

    // Verify password against stored hash
    const passwordService = require('../services/password.service');
    const isPasswordValid = await passwordService.verifyPassword(password, user.password_hash);

    if (!isPasswordValid) {
      // Increment failed login attempts
      const newFailedAttempts = (user.failed_login_attempts || 0) + 1;
      
      // FR-001.2.3: Check if account should be locked (10 consecutive failures)
      const attemptCheck = rateLimitService.checkUserLoginAttempts(user.id, newFailedAttempts);
      
      if (attemptCheck.shouldLock) {
        // Lock the account
        await client.query(
          `UPDATE users 
           SET failed_login_attempts = $1, 
               locked_until = $2,
               status = CASE WHEN status != 'active' THEN status ELSE 'active' END,
               updated_at = NOW()
           WHERE id = $3`,
          [newFailedAttempts, attemptCheck.lockUntil, user.id]
        );

        const auditService = require('../services/audit.service');
        await auditService.logAccountLockout(
          user.id,
          email,
          'Multiple failed login attempts',
          ipAddress,
          userAgent,
          client
        );
        
        await client.query('COMMIT');
        transactionCommitted = true;
        rateLimitService.recordIpFailedAttempt(ipAddress);

        throw new UnauthorizedError(
          'Account locked due to multiple failed login attempts. Please contact support or reset your password'
        );
      } else {
        // Update failed attempts count
        await client.query(
          'UPDATE users SET failed_login_attempts = $1, updated_at = NOW() WHERE id = $2',
          [newFailedAttempts, user.id]
        );

        const auditService = require('../services/audit.service');
        await auditService.logLoginFailure(user.id, email, 'Invalid password', ipAddress, userAgent, client);
        
        await client.query('COMMIT');
        transactionCommitted = true;
        rateLimitService.recordIpFailedAttempt(ipAddress);

        logger.warn('Login failed - invalid password', { 
          email, 
          attempts: newFailedAttempts,
          remaining: attemptCheck.remainingAttempts 
        });

        throw new UnauthorizedError('Invalid email or password');
      }
    }

    // Password is valid - check rate limit before allowing login
    if (!rateLimitCheck.allowed) {
      await client.query('COMMIT');
      transactionCommitted = true;
      logger.warn('Login rate limit exceeded', { ipAddress, email });
      throw new UnauthorizedError(
        `Too many login attempts. Please try again in ${rateLimitCheck.waitTime} minute${rateLimitCheck.waitTime !== 1 ? 's' : ''}`
      );
    }

    // Successful login!

    // Reset failed login attempts and IP rate limit
    await client.query(
      `UPDATE users 
       SET failed_login_attempts = 0, 
           locked_until = NULL,
           last_login_at = NOW(),
           updated_at = NOW()
       WHERE id = $1`,
      [user.id]
    );

    rateLimitService.resetIpRateLimit(ipAddress);

    // FR-001.2.4, FR-001.2.5, FR-001.2.6: Generate JWT tokens
    const jwtService = require('../services/jwt.service');
    const tokens = jwtService.generateTokenPair(user, rememberMe);

    // Create session for token rotation and multi-device management
    const sessionService = require('../services/session.service');
    const expiresAt = new Date(Date.now() + (rememberMe ? 30 : 1) * 24 * 60 * 60 * 1000);
    
    const session = await sessionService.createSession({
      userId: user.id,
      refreshToken: tokens.refreshToken,
      ipAddress,
      userAgent,
      expiresAt,
    }, client);

    // FR-001.2.7: Log successful login for security auditing
    const auditService = require('../services/audit.service');
    await auditService.logLoginSuccess(user.id, email, ipAddress, userAgent, client);

    await client.query('COMMIT');
    transactionCommitted = true;

    logger.info('User logged in successfully', { 
      userId: user.id, 
      email: user.email,
      sessionId: session.id 
    });

    // Return tokens and user profile data
    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          id: user.id,
          email: user.email,
          displayName: user.display_name,
          status: user.status,
          subscriptionTier: user.subscription_tier,
        },
        tokens: {
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          expiresIn: tokens.expiresIn,
        },
        session: {
          id: session.id,
          expiresAt: session.expires_at,
        },
      },
    });
  } catch (error) {
    if (!transactionCommitted) {
      await client.query('ROLLBACK');
    }
    throw error;
  } finally {
    client.release();
  }
};

/**
 * User logout
 * FR-001.3.1 through FR-001.3.5
 */
const logout = async (req, res) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new UnauthorizedError('No authentication token provided');
  }

  const accessToken = authHeader.split(' ')[1];
  const jwtService = require('../services/jwt.service');
  const sessionService = require('../services/session.service');

  // Decode token to get user info (even if expired)
  const decoded = jwtService.decodeToken(accessToken);
  
  if (!decoded || !decoded.userId) {
    throw new UnauthorizedError('Invalid token');
  }

  const userId = decoded.userId;
  logger.info('User logout', { userId });

  try {
    // FR-001.3.3: Add access token to blacklist
    const ttl = jwtService.getTokenExpirationTime(accessToken) || 86400; // Default 24h
    sessionService.blacklistToken(accessToken, ttl);

    // Get refresh token from body or cookie if provided
    const refreshToken = req.body.refreshToken || req.cookies?.refreshToken;
    
    if (refreshToken) {
      // Blacklist refresh token too
      const refreshTtl = jwtService.getTokenExpirationTime(refreshToken) || 2592000; // Default 30d
      sessionService.blacklistToken(refreshToken, refreshTtl);

      // Invalidate session associated with refresh token
      const refreshDecoded = jwtService.decodeToken(refreshToken);
      if (refreshDecoded && refreshDecoded.tokenId) {
        // Find and invalidate session
        const sessions = await sessionService.getUserSessions(userId);
        for (const session of sessions) {
          await sessionService.invalidateSession(session.id, userId);
        }
      }
    }

    // FR-001.3.4: Clear client-side tokens (inform client to do this)
    logger.info('User logged out successfully', { userId });

    res.status(200).json({
      success: true,
      message: 'Logged out successfully',
    });
  } catch (error) {
    logger.error('Error during logout:', error);
    // Even if logout partially fails, return success to client
    res.status(200).json({
      success: true,
      message: 'Logged out successfully',
    });
  }
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
  // Accept token from both query (GET) and body (POST) for flexibility
  const { token } = req.query.token ? req.query : req.body;
  
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
    await client.query('ROLLBACK');
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

/**
 * Refresh access token using refresh token
 * FR-001.6.3: Rotate refresh tokens on each use
 */
const refreshToken = async (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    throw new ValidationError('Refresh token is required');
  }

  const ipAddress = req.ip || req.connection.remoteAddress;
  const userAgent = req.get('user-agent');

  logger.info('Token refresh attempt');

  const jwtService = require('../services/jwt.service');
  const sessionService = require('../services/session.service');

  // Verify refresh token
  const decoded = jwtService.verifyToken(refreshToken, 'refresh');
  
  if (!decoded) {
    throw new UnauthorizedError('Invalid or expired refresh token');
  }

  // Check if token is blacklisted
  if (sessionService.isTokenBlacklisted(refreshToken)) {
    throw new UnauthorizedError('Refresh token has been invalidated');
  }

  // Verify session exists and is valid
  const session = await sessionService.verifyRefreshTokenSession(refreshToken, decoded.userId);
  
  if (!session) {
    throw new UnauthorizedError('Invalid session or refresh token');
  }

  // Get user data
  const userResult = await database.query(
    'SELECT id, email, display_name, status, subscription_tier FROM users WHERE id = $1',
    [decoded.userId]
  );

  if (userResult.rows.length === 0) {
    throw new UnauthorizedError('User not found');
  }

  const user = userResult.rows[0];

  // Generate new token pair (rotate refresh token)
  // Use a small delay to ensure different iat (issued at) timestamp
  await new Promise(resolve => setTimeout(resolve, 1000));
  const newTokens = jwtService.generateTokenPair(user, false);

  // Invalidate old session
  await sessionService.invalidateSession(session.id, user.id);

  // Create new session with new refresh token
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days
  const newSession = await sessionService.createSession({
    userId: user.id,
    refreshToken: newTokens.refreshToken,
    ipAddress,
    userAgent,
    expiresAt,
  });

  // Blacklist old tokens
  const oldAccessTtl = 86400; // 24h
  const oldRefreshTtl = jwtService.getTokenExpirationTime(refreshToken) || 2592000;
  sessionService.blacklistToken(refreshToken, oldRefreshTtl);

  logger.info('Token refreshed successfully', { userId: user.id, sessionId: newSession.id });

  res.status(200).json({
    success: true,
    message: 'Token refreshed successfully',
    data: {
      tokens: {
        accessToken: newTokens.accessToken,
        refreshToken: newTokens.refreshToken,
        expiresIn: newTokens.expiresIn,
      },
      session: {
        id: newSession.id,
        expiresAt: newSession.expires_at,
      },
    },
  });
};

module.exports = {
  register,
  login,
  logout,
  refreshToken,
  forgotPassword,
  resetPassword,
  verifyEmail,
  resendVerification,
};

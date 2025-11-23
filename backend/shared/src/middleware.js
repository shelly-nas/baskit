const logger = require('./logger');
const { UnauthorizedError } = require('./errors');

/**
 * Request logging middleware
 */
const requestLogger = (req, res, next) => {
  logger.info('Incoming request', {
    method: req.method,
    path: req.path,
    ip: req.ip,
    userAgent: req.get('user-agent'),
  });
  next();
};

/**
 * Async handler wrapper to catch errors in async route handlers
 */
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

/**
 * Validate request body using Joi schema
 */
const validate = (schema) => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errorMessage = error.details.map(detail => detail.message).join(', ');
      return res.status(400).json({
        success: false,
        error: errorMessage,
      });
    }

    req.body = value;
    next();
  };
};

/**
 * JWT Authentication middleware
 * FR-001.6.7: Validate token signatures on every request
 * FR-001.6.8: Check token blacklist before accepting tokens
 */
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedError('No authentication token provided');
    }

    const token = authHeader.split(' ')[1];
    
    // Check if token is blacklisted (logout/invalidated tokens)
    // Note: This requires session service from user-service
    // In production, this should use Redis for cross-service blacklist
    try {
      // Try to load session service if available (for user-service)
      const sessionService = require('../../user-service/src/services/session.service');
      if (sessionService.isTokenBlacklisted(token)) {
        throw new UnauthorizedError('Token has been invalidated');
      }
    } catch (loadError) {
      // Session service not available (different microservice)
      // In production, implement Redis-based blacklist checking
      logger.debug('Session service not available for blacklist check');
    }

    // Verify JWT token
    let jwtService;
    try {
      jwtService = require('../../user-service/src/services/jwt.service');
    } catch (loadError) {
      // JWT service not available - service might not have it
      logger.error('JWT service not available');
      throw new UnauthorizedError('Authentication service unavailable');
    }

    const decoded = jwtService.verifyToken(token, 'access');
    
    if (!decoded) {
      throw new UnauthorizedError('Invalid or expired token');
    }

    // Attach user info to request object
    req.user = {
      userId: decoded.userId,
      email: decoded.email,
      role: decoded.role || 'user',
    };

    logger.debug('User authenticated', { userId: req.user.userId });
    next();
  } catch (error) {
    if (error instanceof UnauthorizedError) {
      throw error;
    }
    logger.error('Authentication error:', error);
    throw new UnauthorizedError('Authentication failed');
  }
};

/**
 * Check if user has required role
 */
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      throw new UnauthorizedError('Authentication required');
    }

    if (roles.length && !roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: 'Insufficient permissions',
      });
    }

    next();
  };
};

/**
 * CORS middleware configuration
 */
const corsOptions = {
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true,
  optionsSuccessStatus: 200,
};

module.exports = {
  requestLogger,
  asyncHandler,
  validate,
  authenticate,
  authorize,
  corsOptions,
};

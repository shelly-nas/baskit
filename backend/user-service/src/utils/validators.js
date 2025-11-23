const Joi = require('joi');

/**
 * Email validation according to RFC 5322 standards
 */
const emailSchema = Joi.string()
  .email({ tlds: { allow: true } })
  .max(255)
  .required()
  .messages({
    'string.email': 'Please enter a valid email address',
    'string.empty': 'Email is required',
    'any.required': 'Email is required',
  });

/**
 * Password validation with complexity requirements
 * - Minimum 8 characters
 * - At least one uppercase letter
 * - At least one lowercase letter
 * - At least one number
 * - At least one special character
 */
const passwordSchema = Joi.string()
  .min(8)
  .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
  .required()
  .messages({
    'string.min': 'Password must be at least 8 characters long',
    'string.pattern.base': 'Password must meet complexity requirements',
    'string.empty': 'Password is required',
    'any.required': 'Password is required',
  });

/**
 * Display name validation (2-50 characters)
 */
const displayNameSchema = Joi.string()
  .min(2)
  .max(50)
  .trim()
  .required()
  .messages({
    'string.min': 'Name must be between 2 and 50 characters',
    'string.max': 'Name must be between 2 and 50 characters',
    'string.empty': 'Display name is required',
    'any.required': 'Display name is required',
  });

/**
 * User registration validation schema
 */
const registrationSchema = Joi.object({
  email: emailSchema,
  password: passwordSchema,
  displayName: displayNameSchema,
});

/**
 * User login validation schema
 */
const loginSchema = Joi.object({
  email: emailSchema,
  password: Joi.string().required().messages({
    'string.empty': 'Password is required',
    'any.required': 'Password is required',
  }),
});

/**
 * Password reset request validation schema
 */
const forgotPasswordSchema = Joi.object({
  email: emailSchema,
});

/**
 * Password reset validation schema
 */
const resetPasswordSchema = Joi.object({
  token: Joi.string().required().messages({
    'string.empty': 'Reset token is required',
    'any.required': 'Reset token is required',
  }),
  password: passwordSchema,
});

/**
 * Email verification validation schema
 */
const verifyEmailSchema = Joi.object({
  token: Joi.string().required().messages({
    'string.empty': 'Verification token is required',
    'any.required': 'Verification token is required',
  }),
}).options({ stripUnknown: true });

/**
 * Validate email format using RFC 5322 standards
 */
const isValidEmail = (email) => {
  const { error } = emailSchema.validate(email);
  return !error;
};

/**
 * Validate password complexity
 */
const isValidPassword = (password) => {
  const { error } = passwordSchema.validate(password);
  return !error;
};

/**
 * Validate display name length
 */
const isValidDisplayName = (displayName) => {
  const { error } = displayNameSchema.validate(displayName);
  return !error;
};

/**
 * Get detailed validation errors
 */
const getValidationErrors = (schema, data) => {
  const { error } = schema.validate(data, { abortEarly: false });
  
  if (!error) {
    return null;
  }

  const errors = {};
  error.details.forEach((detail) => {
    const key = detail.path[0];
    if (!errors[key]) {
      errors[key] = detail.message;
    }
  });

  return errors;
};

module.exports = {
  emailSchema,
  passwordSchema,
  displayNameSchema,
  registrationSchema,
  loginSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  verifyEmailSchema,
  isValidEmail,
  isValidPassword,
  isValidDisplayName,
  getValidationErrors,
};

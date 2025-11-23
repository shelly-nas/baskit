const { logger } = require('../../shared/src');
const nodemailer = require('nodemailer');

/**
 * Email Service
 * Handles sending emails for verification, password reset, etc.
 * 
 * Uses nodemailer with SMTP configuration from environment variables.
 * For development, can use Ethereal Email (ethereal.email) or Mailhog.
 * For production, configure with SendGrid, AWS SES, or other SMTP provider.
 */

const APP_NAME = 'Baskit';
const APP_URL = process.env.APP_URL || 'http://localhost:3000';
const FROM_EMAIL = process.env.FROM_EMAIL || 'noreply@baskit.app';

// Email transporter configuration
let transporter = null;

/**
 * Initialize email transporter
 * Creates transporter based on environment variables or falls back to Ethereal
 */
const initializeTransporter = async () => {
  if (transporter) {
    return transporter;
  }

  try {
    // Check if SMTP credentials are provided
    if (process.env.SMTP_HOST && process.env.SMTP_PORT) {
      // Use configured SMTP server
      transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: parseInt(process.env.SMTP_PORT),
        secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
        auth: process.env.SMTP_USER ? {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASS,
        } : undefined,
      });
      logger.info('Email transporter initialized with configured SMTP server');
    } else {
      // For development: create Ethereal test account
      const testAccount = await nodemailer.createTestAccount();
      transporter = nodemailer.createTransport({
        host: 'smtp.ethereal.email',
        port: 587,
        secure: false,
        auth: {
          user: testAccount.user,
          pass: testAccount.pass,
        },
      });
      logger.info('Email transporter initialized with Ethereal test account', {
        user: testAccount.user,
        note: 'Emails will be captured at https://ethereal.email',
      });
    }

    return transporter;
  } catch (error) {
    logger.error('Failed to initialize email transporter:', error);
    throw error;
  }
};

/**
 * Send email verification email
 * @param {string} email - User's email address
 * @param {string} displayName - User's display name
 * @param {string} token - Verification token
 * @returns {Promise<void>}
 */
const sendVerificationEmail = async (email, displayName, token) => {
  try {
    const verificationUrl = `${APP_URL}/verify-email?token=${token}`;
    const emailTransporter = await initializeTransporter();
    
    const mailOptions = {
      from: FROM_EMAIL,
      to: email,
      subject: `Verify your ${APP_NAME} account`,
      text: `
        Hello ${displayName},

        Welcome to ${APP_NAME}! Please verify your email address by clicking the link below:

        ${verificationUrl}

        This link will expire in 24 hours.

        If you didn't create an account with ${APP_NAME}, please ignore this email.

        Best regards,
        The ${APP_NAME} Team
      `,
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .button { 
              display: inline-block; 
              padding: 12px 24px; 
              background-color: #4CAF50; 
              color: white; 
              text-decoration: none; 
              border-radius: 4px; 
              margin: 20px 0;
            }
            .footer { margin-top: 30px; font-size: 12px; color: #666; }
          </style>
        </head>
        <body>
          <div class="container">
            <h2>Hello ${displayName},</h2>
            <p>Welcome to ${APP_NAME}! Please verify your email address by clicking the button below:</p>
            <a href="${verificationUrl}" class="button">Verify Email Address</a>
            <p>Or copy and paste this link into your browser:</p>
            <p>${verificationUrl}</p>
            <p>This link will expire in 24 hours.</p>
            <div class="footer">
              <p>If you didn't create an account with ${APP_NAME}, please ignore this email.</p>
              <p>Best regards,<br>The ${APP_NAME} Team</p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    // Send email
    const info = await emailTransporter.sendMail(mailOptions);

    logger.info('Verification email sent successfully', { 
      to: email, 
      messageId: info.messageId,
      verificationUrl,
      previewUrl: nodemailer.getTestMessageUrl(info) || 'N/A',
    });

    return true;
  } catch (error) {
    logger.error('Error sending verification email:', error);
    throw new Error('Failed to send verification email');
  }
};

/**
 * Send password reset email
 * @param {string} email - User's email address
 * @param {string} displayName - User's display name
 * @param {string} token - Reset token
 * @returns {Promise<void>}
 */
const sendPasswordResetEmail = async (email, displayName, token) => {
  try {
    const resetUrl = `${APP_URL}/reset-password?token=${token}`;
    const emailTransporter = await initializeTransporter();
    
    const mailOptions = {
      from: FROM_EMAIL,
      to: email,
      subject: `Reset your ${APP_NAME} password`,
      text: `
        Hello ${displayName},

        We received a request to reset your password for your ${APP_NAME} account.

        Click the link below to reset your password:

        ${resetUrl}

        This link will expire in 1 hour.

        If you didn't request a password reset, please ignore this email and your password will remain unchanged.

        Best regards,
        The ${APP_NAME} Team
      `,
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .button { 
              display: inline-block; 
              padding: 12px 24px; 
              background-color: #2196F3; 
              color: white; 
              text-decoration: none; 
              border-radius: 4px; 
              margin: 20px 0;
            }
            .footer { margin-top: 30px; font-size: 12px; color: #666; }
          </style>
        </head>
        <body>
          <div class="container">
            <h2>Hello ${displayName},</h2>
            <p>We received a request to reset your password for your ${APP_NAME} account.</p>
            <p>Click the button below to reset your password:</p>
            <a href="${resetUrl}" class="button">Reset Password</a>
            <p>Or copy and paste this link into your browser:</p>
            <p>${resetUrl}</p>
            <p>This link will expire in 1 hour.</p>
            <div class="footer">
              <p>If you didn't request a password reset, please ignore this email and your password will remain unchanged.</p>
              <p>Best regards,<br>The ${APP_NAME} Team</p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    // Send email
    const info = await emailTransporter.sendMail(mailOptions);

    logger.info('Password reset email sent successfully', { 
      to: email, 
      messageId: info.messageId,
      resetUrl,
      previewUrl: nodemailer.getTestMessageUrl(info) || 'N/A',
    });

    return true;
  } catch (error) {
    logger.error('Error sending password reset email:', error);
    throw new Error('Failed to send password reset email');
  }
};

/**
 * Resend verification email
 * @param {string} email - User's email address
 * @param {string} displayName - User's display name
 * @param {string} token - Verification token
 * @returns {Promise<void>}
 */
const resendVerificationEmail = async (email, displayName, token) => {
  return sendVerificationEmail(email, displayName, token);
};

module.exports = {
  sendVerificationEmail,
  sendPasswordResetEmail,
  resendVerificationEmail,
};

const express = require('express');
const router = express.Router();
const { asyncHandler, authenticate } = require('../../shared/src');
const userController = require('../controllers/user.controller');

/**
 * @route   GET /api/users/profile
 * @desc    Get current user profile
 * @access  Private
 */
router.get('/profile', authenticate, asyncHandler(userController.getProfile));

/**
 * @route   PUT /api/users/profile
 * @desc    Update user profile
 * @access  Private
 */
router.put('/profile', authenticate, asyncHandler(userController.updateProfile));

/**
 * @route   GET /api/users/preferences
 * @desc    Get user preferences
 * @access  Private
 */
router.get('/preferences', authenticate, asyncHandler(userController.getPreferences));

/**
 * @route   PUT /api/users/preferences
 * @desc    Update user preferences
 * @access  Private
 */
router.put('/preferences', authenticate, asyncHandler(userController.updatePreferences));

/**
 * @route   PATCH /api/users/email
 * @desc    Request email change (sends verification to new address)
 * @access  Private
 */
router.patch('/email', authenticate, asyncHandler(userController.changeEmail));

/**
 * @route   PATCH /api/users/password
 * @desc    Change user password
 * @access  Private
 */
router.patch('/password', authenticate, asyncHandler(userController.changePassword));

/**
 * @route   GET /api/users/sessions
 * @desc    Get all active sessions for the current user
 * @access  Private
 */
router.get('/sessions', authenticate, asyncHandler(userController.getSessions));

/**
 * @route   DELETE /api/users/sessions/:id
 * @desc    Delete a specific session
 * @access  Private
 */
router.delete('/sessions/:id', authenticate, asyncHandler(userController.deleteSession));

/**
 * @route   DELETE /api/users/sessions
 * @desc    Delete all sessions except the current one
 * @access  Private
 */
router.delete('/sessions', authenticate, asyncHandler(userController.deleteAllOtherSessions));

/**
 * @route   DELETE /api/users/account
 * @desc    Delete user account
 * @access  Private
 */
router.delete('/account', authenticate, asyncHandler(userController.deleteAccount));

module.exports = router;

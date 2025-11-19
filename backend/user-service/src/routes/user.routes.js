const express = require('express');
const router = express.Router();
const { asyncHandler, authenticate } = require('../../../shared/src');
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
 * @route   DELETE /api/users/account
 * @desc    Delete user account
 * @access  Private
 */
router.delete('/account', authenticate, asyncHandler(userController.deleteAccount));

module.exports = router;

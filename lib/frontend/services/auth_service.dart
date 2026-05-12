import 'api_client.dart';

/// Authentication Service
/// Handles user authentication operations with the backend
class AuthService {
  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await ApiClient().post('/auth/register', {
        'email': email,
        'password': password,
        'displayName': displayName,
      });

      if (response.isSuccess) {
        return {
          'success': true,
          'message':
              response.successMessage ??
              'Registration successful. Please check your email to verify your account.',
          'data': response.body['data'],
        };
      } else {
        return {
          'success': false,
          'error':
              response.errorMessage ?? 'Registration failed. Please try again.',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Login a user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient().post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.isSuccess) {
        return {
          'success': true,
          'message': response.successMessage ?? 'Login successful',
          'data': response.body['data'],
        };
      } else {
        return {
          'success': false,
          'error': response.errorMessage ?? 'Login failed. Please try again.',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Logout the current user — invalidates the session on the backend
  Future<Map<String, dynamic>> logout({
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      final client = ApiClient(authToken: accessToken);
      final body = <String, dynamic>{};
      if (refreshToken != null) body['refreshToken'] = refreshToken;

      final response = await client.post('/auth/logout', body);

      if (response.isSuccess) {
        return {
          'success': true,
          'message': response.successMessage ?? 'Logged out successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.errorMessage ?? 'Logout failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Refresh the access token using a refresh token
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await ApiClient().post('/auth/refresh', {
        'refreshToken': refreshToken,
      });

      if (response.isSuccess) {
        return {
          'success': true,
          'data': response.body['data'],
        };
      } else {
        return {
          'success': false,
          'error': response.errorMessage ?? 'Token refresh failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Verify email with token
  Future<Map<String, dynamic>> verifyEmail({required String token}) async {
    try {
      final response = await ApiClient().post('/auth/verify-email', {
        'token': token,
      });

      if (response.isSuccess) {
        return {
          'success': true,
          'message': response.successMessage ?? 'Email verified successfully',
          'data': response.body['data'],
        };
      } else {
        return {
          'success': false,
          'error': response.errorMessage ?? 'Verification failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Resend verification email
  Future<Map<String, dynamic>> resendVerification({
    required String email,
  }) async {
    try {
      final response = await ApiClient().post('/auth/resend-verification', {
        'email': email,
      });

      if (response.isSuccess) {
        return {
          'success': true,
          'message': response.successMessage ?? 'Verification email sent',
        };
      } else {
        return {
          'success': false,
          'error': response.errorMessage ?? 'Failed to send verification email',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Request a password reset email
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await ApiClient().post('/auth/forgot-password', {
        'email': email,
      });

      if (response.isSuccess) {
        return {
          'success': true,
          'message': response.successMessage ??
              'If an account exists with this email, you will receive a password reset link.',
        };
      } else {
        return {
          'success': false,
          'error': response.errorMessage ?? 'Failed to send password reset email',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Reset password using a reset token
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      final response = await ApiClient().post('/auth/reset-password', {
        'token': token,
        'password': password,
      });

      if (response.isSuccess) {
        return {
          'success': true,
          'message': response.successMessage ?? 'Password reset successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.errorMessage ?? 'Password reset failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getProfile({required String accessToken}) async {
    try {
      final response = await ApiClient(authToken: accessToken).get('/users/profile');

      if (response.isSuccess) {
        return {
          'success': true,
          'data': response.body['data'],
        };
      } else {
        return {
          'success': false,
          'error': response.errorMessage ?? 'Failed to load profile',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String accessToken,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response =
          await ApiClient(authToken: accessToken).put('/users/profile', data);

      if (response.isSuccess) {
        return {
          'success': true,
          'message': response.successMessage ?? 'Profile updated successfully',
          'data': response.body['data'],
        };
      } else {
        return {
          'success': false,
          'error': response.errorMessage ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Change user password
  Future<Map<String, dynamic>> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await ApiClient(authToken: accessToken).patch(
        '/users/password',
        {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (response.isSuccess) {
        return {
          'success': true,
          'message': response.successMessage ?? 'Password changed successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.errorMessage ?? 'Failed to change password',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Request an email address change
  Future<Map<String, dynamic>> changeEmail({
    required String accessToken,
    required String currentPassword,
    required String newEmail,
  }) async {
    try {
      final response = await ApiClient(authToken: accessToken).patch(
        '/users/email',
        {
          'currentPassword': currentPassword,
          'newEmail': newEmail,
        },
      );

      if (response.isSuccess) {
        return {
          'success': true,
          'message': response.successMessage ??
              'A verification email has been sent to your new address.',
        };
      } else {
        return {
          'success': false,
          'error': response.errorMessage ?? 'Failed to change email',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get user preferences
  Future<Map<String, dynamic>> getPreferences({
    required String accessToken,
  }) async {
    try {
      final response =
          await ApiClient(authToken: accessToken).get('/users/preferences');

      if (response.isSuccess) {
        return {
          'success': true,
          'data': response.body['data'],
        };
      } else {
        return {
          'success': false,
          'error': response.errorMessage ?? 'Failed to load preferences',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Update user preferences
  Future<Map<String, dynamic>> updatePreferences({
    required String accessToken,
    required Map<String, dynamic> prefs,
  }) async {
    try {
      final response =
          await ApiClient(authToken: accessToken).put('/users/preferences', prefs);

      if (response.isSuccess) {
        return {
          'success': true,
          'message': response.successMessage ?? 'Preferences updated successfully',
          'data': response.body['data'],
        };
      } else {
        return {
          'success': false,
          'error': response.errorMessage ?? 'Failed to update preferences',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get all active sessions for the current user
  Future<Map<String, dynamic>> getSessions({required String accessToken}) async {
    try {
      final response =
          await ApiClient(authToken: accessToken).get('/users/sessions');

      if (response.isSuccess) {
        return {
          'success': true,
          'data': response.body['data'],
        };
      } else {
        return {
          'success': false,
          'error': response.errorMessage ?? 'Failed to load sessions',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Delete a specific session by ID
  Future<Map<String, dynamic>> deleteSession({
    required String accessToken,
    required String sessionId,
  }) async {
    try {
      final response = await ApiClient(authToken: accessToken)
          .delete('/users/sessions/$sessionId');

      if (response.isSuccess) {
        return {
          'success': true,
          'message': response.successMessage ?? 'Session terminated',
        };
      } else {
        return {
          'success': false,
          'error': response.errorMessage ?? 'Failed to terminate session',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Soft-delete the current user's account
  Future<Map<String, dynamic>> deleteAccount({
    required String accessToken,
  }) async {
    try {
      final response =
          await ApiClient(authToken: accessToken).delete('/users/account');

      if (response.isSuccess) {
        return {
          'success': true,
          'message': response.successMessage ?? 'Account deleted successfully',
        };
      } else {
        return {
          'success': false,
          'error': response.errorMessage ?? 'Failed to delete account',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}

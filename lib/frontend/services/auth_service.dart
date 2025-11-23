import 'api_client.dart';

/// Authentication Service
/// Handles user authentication operations with the backend
class AuthService {
  final ApiClient _apiClient = ApiClient();

  /// Register a new user
  ///
  /// Returns a map with success status and message/error
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _apiClient.post('/auth/register', {
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
      final response = await _apiClient.post('/auth/login', {
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

  /// Verify email with token
  Future<Map<String, dynamic>> verifyEmail({required String token}) async {
    try {
      final response = await _apiClient.post('/auth/verify-email', {
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
      final response = await _apiClient.post('/auth/resend-verification', {
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
}

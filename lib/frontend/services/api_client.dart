import 'dart:convert';
import 'package:http/http.dart' as http;

/// API Client for backend communication
class ApiClient {
  // Use localhost for iOS simulator, 10.0.2.2 for Android emulator
  // For physical device, use your computer's IP address
  static const String baseUrl = 'http://localhost:3001/api';

  String? _authToken;

  ApiClient({String? authToken}) : _authToken = authToken;

  /// Update the bearer token used for authenticated requests
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Build request headers, merging in any caller-supplied overrides
  Map<String, String> _buildHeaders([Map<String, String>? extra]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  /// Make a POST request to the API
  Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(
        url,
        headers: _buildHeaders(headers),
        body: jsonEncode(body),
      );

      return ApiResponse(
        statusCode: response.statusCode,
        body: response.body.isNotEmpty ? jsonDecode(response.body) : {},
        isSuccess: response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 0,
        body: {'error': e.toString()},
        isSuccess: false,
      );
    }
  }

  /// Make a GET request to the API
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.get(
        url,
        headers: _buildHeaders(headers),
      );

      return ApiResponse(
        statusCode: response.statusCode,
        body: response.body.isNotEmpty ? jsonDecode(response.body) : {},
        isSuccess: response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 0,
        body: {'error': e.toString()},
        isSuccess: false,
      );
    }
  }

  /// Make a PATCH request to the API
  Future<ApiResponse> patch(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.patch(
        url,
        headers: _buildHeaders(headers),
        body: jsonEncode(body),
      );

      return ApiResponse(
        statusCode: response.statusCode,
        body: response.body.isNotEmpty ? jsonDecode(response.body) : {},
        isSuccess: response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 0,
        body: {'error': e.toString()},
        isSuccess: false,
      );
    }
  }

  /// Make a PUT request to the API
  Future<ApiResponse> put(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.put(
        url,
        headers: _buildHeaders(headers),
        body: jsonEncode(body),
      );

      return ApiResponse(
        statusCode: response.statusCode,
        body: response.body.isNotEmpty ? jsonDecode(response.body) : {},
        isSuccess: response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 0,
        body: {'error': e.toString()},
        isSuccess: false,
      );
    }
  }

  /// Make a DELETE request to the API
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.delete(
        url,
        headers: _buildHeaders(headers),
      );

      return ApiResponse(
        statusCode: response.statusCode,
        body: response.body.isNotEmpty ? jsonDecode(response.body) : {},
        isSuccess: response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 0,
        body: {'error': e.toString()},
        isSuccess: false,
      );
    }
  }
}

/// API Response wrapper
class ApiResponse {
  final int statusCode;
  final Map<String, dynamic> body;
  final bool isSuccess;

  ApiResponse({
    required this.statusCode,
    required this.body,
    required this.isSuccess,
  });

  String? get errorMessage {
    if (body.containsKey('error')) {
      return body['error'] as String?;
    }
    if (body.containsKey('message') && !isSuccess) {
      return body['message'] as String?;
    }
    return null;
  }

  String? get successMessage {
    if (body.containsKey('message')) {
      return body['message'] as String?;
    }
    return null;
  }
}

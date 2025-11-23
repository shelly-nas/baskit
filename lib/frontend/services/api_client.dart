import 'dart:convert';
import 'package:http/http.dart' as http;

/// API Client for backend communication
class ApiClient {
  // Use localhost for iOS simulator, 10.0.2.2 for Android emulator
  // For physical device, use your computer's IP address
  static const String baseUrl = 'http://localhost:3001/api';

  /// Make a POST request to the API
  Future<ApiResponse> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
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
  Future<ApiResponse> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
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
    return null;
  }

  String? get successMessage {
    if (body.containsKey('message')) {
      return body['message'] as String?;
    }
    return null;
  }
}

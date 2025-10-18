import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import 'logging_service.dart';
import 'network_detection_service.dart';

/// API Service for communicating with the backend
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final NetworkDetectionService _networkDetection = NetworkDetectionService();
  
  /// Get headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'SecureApp/1.0.0',
  };

  /// Get HTTP client with security configurations
  http.Client get _httpClient {
    final client = http.Client();
    
    // For production, we should use a custom HttpClient with certificate pinning
    // This is a simplified version - in production, implement proper certificate pinning
    return client;
  }

  /// Make HTTP request with error handling
  Future<ApiResponse> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {

      final baseUrl = await _networkDetection.getApiEndpoint();
      final url = Uri.parse('$baseUrl$endpoint');
      final requestHeaders = {..._headers, ...?headers};
      
      // Validate HTTPS for production endpoints
      if (!url.scheme.startsWith('https') && !url.host.startsWith('localhost')) {
        // For development, we'll allow HTTP but log a warning
        if (EnvConfig.debugMode) {

        }
        // In production, uncomment the line below to enforce HTTPS:
        // throw SecurityException('HTTPS is required for API communication in production');
      }


      if (EnvConfig.debugMode) {
        LoggingService.debug('API Request: $method $url');
        if (body != null) {
          LoggingService.debug('Request Body: ${jsonEncode(body)}');
        }
      }

      final client = _httpClient;
      http.Response response;
      
      try {
        switch (method.toUpperCase()) {
          case 'GET':
            response = await client.get(url, headers: requestHeaders).timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw Exception('Request timeout'),
            );
            break;
          case 'POST':
            response = await client.post(
              url,
              headers: requestHeaders,
              body: body != null ? jsonEncode(body) : null,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw Exception('Request timeout'),
            );
            break;
          case 'PUT':
            response = await client.put(
              url,
              headers: requestHeaders,
              body: body != null ? jsonEncode(body) : null,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw Exception('Request timeout'),
            );
            break;
          case 'DELETE':
            response = await client.delete(url, headers: requestHeaders).timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw Exception('Request timeout'),
            );
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }
      } finally {
        client.close();
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      



      
      if (EnvConfig.debugMode) {
        LoggingService.debug('API Response: ${response.statusCode} ${response.body}');
      }

      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        statusCode: response.statusCode,
        data: responseData,
        message: responseData['message'] ?? 'Request completed',
      );
    } catch (e) {

      if (EnvConfig.debugMode) {
        LoggingService.error('API Request failed: $e');
      }
      return ApiResponse(
        success: false,
        statusCode: 0,
        data: null,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Health check (Laravel endpoint)
  Future<ApiResponse> healthCheck() async {
    return await _makeRequest('GET', '/api/health');
  }

  /// Create user (Laravel endpoint)
  Future<ApiResponse> createUser({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    return await _makeRequest('POST', '/api/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    });
  }

  /// Get user by ID (Laravel endpoint)
  Future<ApiResponse> getUserById(String userId) async {
    return await _makeRequest('GET', '/api/user/profile/$userId');
  }

  /// Get user by email
  Future<ApiResponse> getUserByEmail(String email) async {
    // Since the backend doesn't have a direct email endpoint, we'll use auth
    return await _makeRequest('POST', '/api/user/auth', body: {
      'email': email,
      'password': '', // We'll handle this differently
    });
  }

  /// Update user
  Future<ApiResponse> updateUser({
    required String userId,
    String? name,
    String? email,
    String? phoneNumber,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    
    return await _makeRequest('PUT', '/api/user/$userId', body: body);
  }

  /// Upload profile picture
  Future<ApiResponse> uploadProfilePicture({
    required String userId,
    required String imageBase64,
    required String fileName,
  }) async {
    return await _makeRequest(
      'POST',
      '/api/user/$userId/profile-picture',
      body: {
        'image': imageBase64,
        'filename': fileName,
      },
    );
  }

  /// Get profile picture URL
  Future<ApiResponse> getProfilePicture(String userId) async {
    // Could add caching here later
    return await _makeRequest(
      'GET',
      '/api/user/$userId/profile-picture',
    );
  }

  /// Delete profile picture
  Future<ApiResponse> deleteProfilePicture(String userId) async {
    return await _makeRequest(
      'DELETE',
      '/api/user/$userId/profile-picture',
    );
  }

  /// Delete user
  Future<ApiResponse> deleteUser(String userId) async {
    return await _makeRequest('DELETE', '/api/user/$userId');
  }

  /// Authenticate user (Laravel endpoint)
  Future<ApiResponse> authenticateUser({
    required String email,
    required String password,
  }) async {
    return await _makeRequest('POST', '/api/auth/login', body: {
      'email': email,
      'password': password,
    });
  }

  /// Get all users
  Future<ApiResponse> getAllUsers({int limit = 50, int offset = 0}) async {
    return await _makeRequest('GET', '/api/user?limit=$limit&offset=$offset');
  }

  /// Get network information for debugging
  Future<Map<String, dynamic>> getNetworkInfo() async {
    return await _networkDetection.getNetworkInfo();
  }

  /// Refresh network endpoint detection
  Future<String> refreshNetworkEndpoint() async {
    return await _networkDetection.refreshEndpoint();
  }
}

/// Security exception for API communication
class SecurityException implements Exception {
  final String message;
  const SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}

/// API Response model
class ApiResponse {
  final bool success;
  final int statusCode;
  final Map<String, dynamic>? data;
  final String message;

  ApiResponse({
    required this.success,
    required this.statusCode,
    required this.data,
    required this.message,
  });

  /// Get data from response
  T? getData<T>(String key) {
    return data?[key] as T?;
  }

  /// Get user data from response
  Map<String, dynamic>? get userData {
    return data?['data'] as Map<String, dynamic>?;
  }

  /// Get list of users from response
  List<Map<String, dynamic>>? get usersList {
    final users = data?['data'] as List<dynamic>?;
    return users?.cast<Map<String, dynamic>>();
  }

  /// Check if response has error
  bool get hasError => !success;

  /// Get error message
  String get errorMessage => message;
}

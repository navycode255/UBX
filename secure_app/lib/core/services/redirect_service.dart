import 'package:flutter/foundation.dart';

/// Service for handling redirect locations after authentication
/// This service stores and retrieves redirect locations when users are redirected
/// to sign-in due to authentication requirements
class RedirectService {
  // Private constructor to prevent instantiation
  RedirectService._();

  // Singleton instance
  static final RedirectService _instance = RedirectService._();
  static RedirectService get instance => _instance;

  // In-memory storage for redirect data
  // In a real app, you might want to use secure storage or shared preferences
  String? _storedRedirectPath;
  Map<String, String>? _storedQueryParams;

  /// Store a redirect location with optional query parameters
  /// This is called when a user is redirected to sign-in
  void storeRedirectLocation(String path, Map<String, String>? queryParams) {
    try {
      _storedRedirectPath = path;
      _storedQueryParams = queryParams;
      
      if (kDebugMode) {
        print('🔄 RedirectService: Stored redirect location - Path: $path, QueryParams: $queryParams');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ RedirectService: Error storing redirect location: $e');
      }
    }
  }

  /// Check if there's a stored redirect location
  bool hasRedirectLocation() {
    final hasRedirect = _storedRedirectPath != null;
    
    if (kDebugMode) {
      print('🔄 RedirectService: Has redirect location: $hasRedirect');
    }
    
    return hasRedirect;
  }

  /// Get the stored redirect path
  String? getRedirectPath() {
    if (kDebugMode) {
      print('🔄 RedirectService: Getting redirect path: $_storedRedirectPath');
    }
    
    return _storedRedirectPath;
  }

  /// Get the stored redirect query parameters
  Map<String, String>? getRedirectQueryParams() {
    if (kDebugMode) {
      print('🔄 RedirectService: Getting redirect query params: $_storedQueryParams');
    }
    
    return _storedQueryParams;
  }

  /// Clear the stored redirect location
  /// This is called after successful navigation to the redirect location
  void clearRedirectLocation() {
    try {
      _storedRedirectPath = null;
      _storedQueryParams = null;
      
      if (kDebugMode) {
        print('🔄 RedirectService: Cleared redirect location');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ RedirectService: Error clearing redirect location: $e');
      }
    }
  }

  /// Get redirect location as a URI string
  String? getRedirectUri() {
    if (_storedRedirectPath == null) {
      return null;
    }

    try {
      final uri = Uri(
        path: _storedRedirectPath,
        queryParameters: _storedQueryParams,
      );
      
      if (kDebugMode) {
        print('🔄 RedirectService: Generated redirect URI: ${uri.toString()}');
      }
      
      return uri.toString();
    } catch (e) {
      if (kDebugMode) {
        print('❌ RedirectService: Error generating redirect URI: $e');
      }
      return _storedRedirectPath;
    }
  }

  /// Store redirect location from a URI string
  void storeRedirectFromUri(String uriString) {
    try {
      final uri = Uri.parse(uriString);
      _storedRedirectPath = uri.path;
      _storedQueryParams = uri.queryParameters.isNotEmpty ? uri.queryParameters : null;
      
      if (kDebugMode) {
        print('🔄 RedirectService: Stored redirect from URI - Path: ${uri.path}, QueryParams: ${uri.queryParameters}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ RedirectService: Error parsing redirect URI: $e');
      }
    }
  }

  /// Check if the stored redirect location is valid
  bool isRedirectLocationValid() {
    return _storedRedirectPath != null && _storedRedirectPath!.isNotEmpty;
  }

  /// Get redirect location info for debugging
  Map<String, dynamic> getRedirectInfo() {
    return {
      'path': _storedRedirectPath,
      'queryParams': _storedQueryParams,
      'isValid': isRedirectLocationValid(),
      'uri': getRedirectUri(),
    };
  }
}

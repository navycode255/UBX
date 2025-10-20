import 'package:flutter/material.dart';

/// Service to manage user redirect after app lockout
class RedirectService {
  static final RedirectService _instance = RedirectService._internal();
  factory RedirectService() => _instance;
  static RedirectService get instance => _instance;
  RedirectService._internal();

  String? _redirectPath;
  Map<String, dynamic>? _redirectQueryParams;

  /// Store the current location before redirecting to login
  void storeRedirectLocation(String path, [Map<String, dynamic>? queryParams]) {
    _redirectPath = path;
    _redirectQueryParams = queryParams;
    // debugPrint('🔄 RedirectService: Stored redirect location - $path');
  }

  /// Get the stored redirect location
  String? getRedirectPath() {
    return _redirectPath;
  }

  /// Get the stored query parameters
  Map<String, dynamic>? getRedirectQueryParams() {
    return _redirectQueryParams;
  }

  /// Clear the stored redirect location
  void clearRedirectLocation() {
    // debugPrint('🔄 RedirectService: Clearing redirect location');
    _redirectPath = null;
    _redirectQueryParams = null;
  }

  /// Check if there's a stored redirect location
  bool hasRedirectLocation() {
    return _redirectPath != null;
  }

  /// Get the full redirect URI with query parameters
  String? getFullRedirectUri() {
    if (_redirectPath == null) return null;
    
    if (_redirectQueryParams != null && _redirectQueryParams!.isNotEmpty) {
      final queryString = _redirectQueryParams!
          .entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      return '$_redirectPath?$queryString';
    }
    
    return _redirectPath;
  }
}


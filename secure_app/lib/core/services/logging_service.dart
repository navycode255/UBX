import 'package:flutter/foundation.dart';

/// A simple logging service that provides consistent logging across the application
/// Uses debugPrint for Flutter apps to ensure logs are only shown in debug mode
class LoggingService {
  // Private constructor to prevent instantiation
  LoggingService._();
  
  // Singleton instance
  static final LoggingService _instance = LoggingService._();
  static LoggingService get instance => _instance;

  /// Log an info message
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  /// Log a warning message
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('[WARNING] $message');
    }
  }

  /// Log an error message
  static void error(String message) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
    }
  }

  /// Log a debug message
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  /// Log a success message
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('[SUCCESS] $message');
    }
  }
}

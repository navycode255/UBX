/// Route constants for the application
/// This file contains all the route paths used throughout the app
/// Making it easy to maintain and update routes in one place
class RouteConstants {
  // Private constructor to prevent instantiation
  RouteConstants._();

  // Authentication Routes
  static const String signIn = '/signin';
  static const String signUp = '/signup';
  static const String forgotPassword = '/forgot-password';
  
  // Main App Routes
  static const String home = '/';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String biometricSettings = '/biometric-settings';
  static const String appLockoutDebug = '/app-lockout-debug';
  
  // Error Routes
  static const String notFound = '/404';
  static const String error = '/error';
  
  // Onboarding Routes
  static const String onboarding = '/onboarding';
  static const String splash = '/splash';
}

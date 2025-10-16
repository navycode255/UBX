import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_constants.dart';

/// Navigation helper class
/// This class provides easy-to-use methods for navigation throughout the app
/// It wraps go_router methods and provides a cleaner API
class NavigationHelper {
  // Private constructor to prevent instantiation
  NavigationHelper._();

  /// Navigate to a specific route
  /// This method pushes a new route onto the navigation stack
  static void goTo(BuildContext context, String route) {
    context.go(route);
  }

  /// Push a new route onto the navigation stack
  /// This method adds a new route on top of the current one
  static void push(BuildContext context, String route) {
    context.push(route);
  }

  /// Pop the current route from the navigation stack
  /// This method removes the current route and goes back
  static void pop(BuildContext context) {
    context.pop();
  }

  /// Pop the current route and go to a specific route
  /// This method replaces the current route with a new one
  static void popAndGoTo(BuildContext context, String route) {
    context.pop();
    context.go(route);
  }

  /// Replace the current route with a new one
  /// This method replaces the current route without adding to the stack
  static void replace(BuildContext context, String route) {
    context.go(route);
  }

  // Authentication Navigation Methods
  // These methods provide easy navigation for authentication flow

  /// Navigate to sign in page
  static void goToSignIn(BuildContext context) {
    context.go(RouteConstants.signIn);
  }

  /// Navigate to sign up page
  static void goToSignUp(BuildContext context) {
    context.go(RouteConstants.signUp);
  }

  /// Navigate to forgot password page
  static void goToForgotPassword(BuildContext context) {
    context.go(RouteConstants.forgotPassword);
  }

  /// Navigate to home page after successful authentication
  static void goToHome(BuildContext context) {
    context.go(RouteConstants.home);
  }

  /// Navigate to profile page
  static void goToProfile(BuildContext context) {
    context.go(RouteConstants.profile);
  }

  /// Navigate to settings page
  static void goToSettings(BuildContext context) {
    context.go(RouteConstants.settings);
  }

  // Utility Methods
  // These methods provide additional navigation utilities

  /// Check if the current route is the sign in page
  static bool isSignInPage(BuildContext context) {
    return GoRouterState.of(context).uri.path == RouteConstants.signIn;
  }

  /// Check if the current route is the sign up page
  static bool isSignUpPage(BuildContext context) {
    return GoRouterState.of(context).uri.path == RouteConstants.signUp;
  }

  /// Check if the current route is the home page
  static bool isHomePage(BuildContext context) {
    return GoRouterState.of(context).uri.path == RouteConstants.home;
  }

  /// Get the current route name
  static String getCurrentRoute(BuildContext context) {
    return GoRouterState.of(context).uri.path;
  }

  /// Navigate back with a result
  /// This method pops the current route and returns a result
  static void popWithResult(BuildContext context, dynamic result) {
    Navigator.of(context).pop(result);
  }

  /// Show a dialog and handle navigation based on result
  static Future<T?> showDialogAndNavigate<T>(
    BuildContext context,
    Widget dialog, {
    String? successRoute,
    String? failureRoute,
  }) async {
    final result = await showDialog<T>(
      context: context,
      builder: (context) => dialog,
    );

    if (result != null && successRoute != null) {
      context.go(successRoute);
    } else if (result == null && failureRoute != null) {
      context.go(failureRoute);
    }

    return result;
  }

  /// Navigate with animation
  /// This method provides custom navigation with animation
  static void navigateWithAnimation(
    BuildContext context,
    String route, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    // Custom animation can be implemented here
    // For now, using the default go_router animation
    context.go(route);
  }

  /// Clear navigation stack and go to a specific route
  /// This method clears all previous routes and navigates to the specified route
  static void clearStackAndGoTo(BuildContext context, String route) {
    // This will clear the entire navigation stack and go to the specified route
    context.go(route);
  }

  /// Navigate to a route with parameters
  /// This method allows navigation with query parameters
  static void goToWithParams(
    BuildContext context,
    String route, {
    Map<String, String>? queryParams,
  }) {
    final uri = Uri(path: route, queryParameters: queryParams);
    context.go(uri.toString());
  }

  /// Get query parameters from current route
  static Map<String, String> getQueryParams(BuildContext context) {
    return GoRouterState.of(context).uri.queryParameters;
  }
}

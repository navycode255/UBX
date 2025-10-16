import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../modules/auth/presentation/signin_page.dart';
import '../modules/auth/presentation/signup_page.dart';
import '../modules/home/presentation/home_page.dart';
import 'route_constants.dart';

/// Main application router configuration
/// This class handles all navigation logic using go_router
class AppRouter {
  // Private constructor to prevent instantiation
  AppRouter._();

  /// Global navigation key for the router
  static final GlobalKey<NavigatorState> _rootNavigatorKey = 
      GlobalKey<NavigatorState>(debugLabel: 'root');
  
  static final GlobalKey<NavigatorState> _shellNavigatorKey = 
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  /// Get the root navigator key
  static GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;

  /// Get the shell navigator key
  static GlobalKey<NavigatorState> get shellNavigatorKey => _shellNavigatorKey;

  /// Main router configuration
  /// This is where all routes are defined and configured
  static final GoRouter router = GoRouter(
    // Root navigator key for the main navigation stack
    navigatorKey: _rootNavigatorKey,
    
    // Initial route when the app starts
    initialLocation: RouteConstants.signIn,
    
    // Debug mode for development (set to false in production)
    debugLogDiagnostics: true,
    
    // Error handling for unknown routes
    errorBuilder: (context, state) => const NotFoundPage(),
    
    // Route configuration
    routes: [
      // Authentication Routes
      // These routes handle user authentication flow
      GoRoute(
        path: RouteConstants.signIn,
        name: 'signin',
        builder: (context, state) => const SignInPage(),
        // Optional: Add route metadata for analytics or debugging
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SignInPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Custom slide transition for sign in page
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          },
        ),
      ),
      
      GoRoute(
        path: RouteConstants.signUp,
        name: 'signup',
        builder: (context, state) => const SignUpPage(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SignUpPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Custom slide transition for sign up page
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          },
        ),
      ),
      
      // Main App Routes
      // These routes are for authenticated users
      GoRoute(
        path: RouteConstants.home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      
     
    ],
    
    // Global redirect logic
    // This runs before any route is navigated to
    redirect: (context, state) async {
      // Get the current location
      final String location = state.uri.path;
      
      // List of routes that don't require authentication
      const List<String> publicRoutes = [
        RouteConstants.signIn,
        RouteConstants.signUp,
        RouteConstants.forgotPassword,
      ];
      
      // Check if current route is public
      final bool isPublicRoute = publicRoutes.contains(location);
      
      // For now, allow access to home page without authentication check
      // TODO: Implement proper authentication state management
      if (location == RouteConstants.home) {
        return null; // Allow access to home page
      }
      
      // If user is not authenticated and trying to access protected route
      if (!isPublicRoute && location != RouteConstants.home) {
        return RouteConstants.signIn;
      }
      
      // No redirect needed
      return null;
    },
  );
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFF8B0000),
            ),
            const SizedBox(height: 16),
            const Text(
              '404 - Page Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B0000),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The page you are looking for does not exist.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RouteConstants.signIn),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Go to Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}

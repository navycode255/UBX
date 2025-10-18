import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../modules/auth/presentation/signin_page.dart';
import '../modules/auth/presentation/signup_page.dart';
import '../modules/auth/presentation/biometric_settings_page.dart';
import '../modules/home/presentation/home_page.dart';
import '../modules/profile/presentation/profile_page.dart';
import '../core/widgets/app_lockout_debug_page.dart';
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
        builder: (context, state) {
          // Lazy load the SignInPage
          return FutureBuilder(
            future: _loadSignInPage(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingPage('Sign In');
              }
              return snapshot.data ?? _buildErrorPage('Failed to load Sign In page');
            },
          );
        },
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: FutureBuilder(
            future: _loadSignInPage(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingPage('Sign In');
              }
              return snapshot.data ?? _buildErrorPage('Failed to load Sign In page');
            },
          ),
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
        builder: (context, state) {
          // Lazy load the SignUpPage
          return FutureBuilder(
            future: _loadSignUpPage(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingPage('Sign Up');
              }
              return snapshot.data ?? _buildErrorPage('Failed to load Sign Up page');
            },
          );
        },
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: FutureBuilder(
            future: _loadSignUpPage(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingPage('Sign Up');
              }
              return snapshot.data ?? _buildErrorPage('Failed to load Sign Up page');
            },
          ),
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
        builder: (context, state) {
          // Lazy load the HomePage
          return FutureBuilder(
            future: _loadHomePage(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingPage('Dashboard');
              }
              return snapshot.data ?? _buildErrorPage('Failed to load Dashboard');
            },
          );
        },
      ),
      
      GoRoute(
        path: RouteConstants.profile,
        name: 'profile',
        builder: (context, state) {
          // Lazy load the ProfilePage
          return FutureBuilder(
            future: _loadProfilePage(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingPage('Profile');
              }
              return snapshot.data ?? _buildErrorPage('Failed to load Profile');
            },
          );
        },
      ),
      
      GoRoute(
        path: RouteConstants.biometricSettings,
        name: 'biometric-settings',
        builder: (context, state) {
          // Lazy load the BiometricSettingsPage
          return FutureBuilder(
            future: _loadBiometricSettingsPage(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingPage('Biometric Settings');
              }
              return snapshot.data ?? _buildErrorPage('Failed to load Biometric Settings');
            },
          );
        },
      ),
      
      GoRoute(
        path: RouteConstants.appLockoutDebug,
        name: 'app-lockout-debug',
        builder: (context, state) {
          return const AppLockoutDebugPage();
        },
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
        RouteConstants.biometricSettings,
      ];
      
      // Check if current route is public
      final bool isPublicRoute = publicRoutes.contains(location);
      
      // For now, allow access to home and profile pages without authentication check
      // TODO: Implement proper authentication state management
      if (location == RouteConstants.home || location == RouteConstants.profile) {
        return null; // Allow access to home and profile pages
      }
      
      // If user is not authenticated and trying to access protected route
      if (!isPublicRoute && location != RouteConstants.home) {
        return RouteConstants.signIn;
      }
      
      // No redirect needed
      return null;
    },
  );

  // Lazy loading methods
  static Future<Widget> _loadSignInPage() async {
    // Simulate loading delay for demonstration
    await Future.delayed(const Duration(milliseconds: 100));
    return const SignInPage();
  }

  static Future<Widget> _loadSignUpPage() async {
    // Simulate loading delay for demonstration
    await Future.delayed(const Duration(milliseconds: 100));
    return const SignUpPage();
  }

  static Future<Widget> _loadHomePage() async {
    // Simulate loading delay for demonstration
    await Future.delayed(const Duration(milliseconds: 100));
    return const HomePage();
  }

  static Future<Widget> _loadProfilePage() async {
    // Simulate loading delay for demonstration
    await Future.delayed(const Duration(milliseconds: 100));
    return const ProfilePage();
  }

  static Future<Widget> _loadBiometricSettingsPage() async {
    // Simulate loading delay for demonstration
    await Future.delayed(const Duration(milliseconds: 100));
    return const BiometricSettingsPage();
  }

  // Helper methods for loading and error states
  static Widget _buildLoadingPage(String pageName) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8B0000), // Dark red
              Color(0xFF4B0082), // Purple
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Simple loading indicator without spinner
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.apps,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading $pageName...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildErrorPage(String errorMessage) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8B0000), // Dark red
              Color(0xFF4B0082), // Purple
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Retry loading
                  // This will trigger a rebuild
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF8B0000),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
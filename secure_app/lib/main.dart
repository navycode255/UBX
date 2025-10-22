import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'core/services/app_lockout_service.dart';
import 'core/widgets/splash_screen.dart';

/// Main entry point of the application
/// This function initializes the app and starts the router
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const ProviderScope(child: MainApp()));
}

/// Main application widget
/// This widget sets up the router and provides the app structure
class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> with WidgetsBindingObserver {
  final AppLockoutService _appLockoutService = AppLockoutService.instance;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAppLockout();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Initialize app lockout service
  Future<void> _initializeAppLockout() async {
    try {
      // debugPrint('🔧 MainApp: Starting app lockout initialization...');
      await _appLockoutService.initialize();
      // debugPrint('🔧 MainApp: App lockout initialization completed');
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      // debugPrint('🔧 MainApp: Error initializing app lockout: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  /// Handle app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // debugPrint('📱 MainApp: App lifecycle state changed to: $state');
    _appLockoutService.handleLifecycleStateChange(state);
    
    // If app is resuming and locked, force immediate redirect
    if (state == AppLifecycleState.resumed) {
      _checkAndRedirectIfLocked();
    }
  }

  /// Check if app is locked and redirect immediately
  Future<void> _checkAndRedirectIfLocked() async {
    try {
      final isLocked = await _appLockoutService.isAppLocked();
      // debugPrint('📱 MainApp: Checking lock status on resume - Is locked: $isLocked');
      
      if (isLocked) {
        // debugPrint('📱 MainApp: App is locked, forcing immediate redirect to sign-in');
        
        // Force a navigation to trigger router redirect
        // This will cause the router to check and redirect to sign-in
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Trigger router to check current location and redirect if needed
          final router = AppRouter.router;
          router.refresh();
        });
      }
    } catch (e) {
      // debugPrint('📱 MainApp: Error checking lock status: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    // Show splash screen while initializing
    if (!_isInitialized) {
      return const MaterialApp(
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,
      );
    }
    return MaterialApp.router(
      // Title of the application
      title: 'Secure App',
      
      // Theme configuration
      theme: ThemeData(
        // Primary color scheme
        primarySwatch: Colors.red,
        primaryColor: const Color(0xFF8B0000),
        
        // App bar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8B0000),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        
        // Elevated button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B0000),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF8B0000)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
        ),
        
        // Color scheme
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF8B0000),
          secondary: Color(0xFF4B0082),
        ),
        
        // Use material design
        useMaterial3: true,
      ),
      
      // Router configuration
      routerConfig: AppRouter.router,
      
      // Debug mode
      debugShowCheckedModeBanner: false,
    );
  }
}

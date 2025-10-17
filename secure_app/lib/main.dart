import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'core/config/env_config.dart';
import 'core/services/database_init.dart';

/// Main entry point of the application
/// This function initializes the app and starts the router
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment configuration
  await EnvConfig.init();
  
  // Validate environment variables
  try {
    EnvConfig.validate();
  } catch (e) {
    debugPrint('Environment validation failed: $e');
    // Continue with default values for development
  }
  
  // Initialize database
  try {
    await DatabaseInit.initializeDatabase();
  } catch (e) {
    debugPrint('Database initialization failed: $e');
    // Continue without database for development
  }
  
  runApp(const MainApp());
}

/// Main application widget
/// This widget sets up the router and provides the app structure
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage_service.dart';
import 'auth_service.dart';
import 'biometric_service.dart';

/// App Lockout Service
/// 
/// Handles app lockout functionality including:
/// - Detecting app pause/resume events
/// - Managing lockout state
/// - Requiring re-authentication on app resume
class AppLockoutService {
  static final AppLockoutService _instance = AppLockoutService._internal();
  factory AppLockoutService() => _instance;
  static AppLockoutService get instance => _instance;
  AppLockoutService._internal();

  final SecureStorageService _secureStorage = SecureStorageService.instance;
  final AuthService _authService = AuthService.instance;
  final BiometricService _biometricService = BiometricService.instance;

  // Stream controllers for app lifecycle events
  final StreamController<AppLifecycleState> _lifecycleController = 
      StreamController<AppLifecycleState>.broadcast();
  
  // Current app state
  AppLifecycleState _currentState = AppLifecycleState.resumed;
  
  // Lockout state
  bool _isLocked = false;
  bool _wasAuthenticated = false;
  
  // Getters
  bool get isLocked => _isLocked;
  bool get wasAuthenticated => _wasAuthenticated;
  AppLifecycleState get currentState => _currentState;
  Stream<AppLifecycleState> get lifecycleStream => _lifecycleController.stream;

  /// Initialize the app lockout service
  Future<void> initialize() async {
    try {
      // Check if user was previously authenticated
      _wasAuthenticated = await _authService.isLoggedIn();
      
      // Check if app was previously locked
      final wasLocked = await _secureStorage.isAppLocked();
      _isLocked = wasLocked;
      
      // debugPrint('AppLockoutService initialized. Was authenticated: $_wasAuthenticated, Was locked: $wasLocked');
    } catch (e) {
      // debugPrint('Error initializing AppLockoutService: $e');
    }
  }

  /// Handle app lifecycle state changes
  void handleLifecycleStateChange(AppLifecycleState state) {
    // debugPrint('🔄 App lifecycle state changed: $_currentState -> $state');
    
    _currentState = state;
    _lifecycleController.add(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // debugPrint('🔄 App is pausing/detaching - will lock if authenticated');
        _handleAppPause().catchError((e) {
          // debugPrint('Error in _handleAppPause: $e');
        });
        break;
      case AppLifecycleState.resumed:
        // debugPrint('🔄 App is resuming - checking lock status');
        _handleAppResume().catchError((e) {
          // debugPrint('Error in _handleAppResume: $e');
        });
        break;
      case AppLifecycleState.inactive:
        // debugPrint('🔄 App is inactive - no action taken');
        // App is transitioning between states, don't lock yet
        break;
      case AppLifecycleState.hidden:
        // debugPrint('🔄 App is hidden - no action taken');
        // App is hidden but not paused, don't lock yet
        break;
    }
  }

  /// Handle app pause/detach events
  Future<void> _handleAppPause() async {
    try {
      // debugPrint('🔒 _handleAppPause called - starting app lockout process');
      
      // Check if user is currently authenticated
      final isLoggedIn = await _authService.isLoggedIn();
      
      // debugPrint('🔒 App paused/detached. User logged in: $isLoggedIn, Current lock state: $_isLocked');
      
      if (isLoggedIn) {
        // User is authenticated, lock the app immediately
        // debugPrint('🔒 User is authenticated, locking app...');
        await lockApp();
        // debugPrint('🔒 App locked successfully due to pause/detach. User was authenticated.');
      } else {
        // debugPrint('🔒 User not logged in, skipping app lockout.');
      }
    } catch (e) {
      // debugPrint('🔒 Error handling app pause: $e');
    }
  }

  /// Handle app resume events
  Future<void> _handleAppResume() async {
    try {
      // debugPrint('🔄 App resumed - checking lock status');
      
      // Check current lock status from storage
      final isCurrentlyLocked = await _secureStorage.isAppLocked();
      _isLocked = isCurrentlyLocked;
      
      // debugPrint('🔄 App resume - Lock status: $isCurrentlyLocked, Was authenticated: $_wasAuthenticated');
      
      if (_isLocked && _wasAuthenticated) {
        // debugPrint('🔒 App resumed while locked. MainApp will handle immediate redirect.');
      } else if (!_isLocked) {
        // debugPrint('🔓 App resumed and not locked - allowing normal operation');
      }
    } catch (e) {
      // debugPrint('Error handling app resume: $e');
    }
  }

  /// Lock the app immediately
  Future<void> lockApp() async {
    try {
      // debugPrint('🔒 lockApp called - setting app to locked state');
      _isLocked = true;
      await _secureStorage.setAppLocked(true);
      // debugPrint('🔒 App locked successfully. Lock state: $_isLocked');
      
      // Verify the lock was set correctly
      final verifyLock = await _secureStorage.isAppLocked();
      // debugPrint('🔒 Verification - App lock status in storage: $verifyLock');
    } catch (e) {
      // debugPrint('🔒 Error locking app: $e');
    }
  }

  /// Unlock the app after successful authentication
  Future<void> unlockApp() async {
    try {
      _isLocked = false;
      await _secureStorage.setAppLocked(false);
      // debugPrint('App unlocked successfully');
    } catch (e) {
      // debugPrint('Error unlocking app: $e');
    }
  }

  /// Check if app is currently locked
  Future<bool> isAppLocked() async {
    try {
      final isLocked = await _secureStorage.isAppLocked();
      _isLocked = isLocked;
      // debugPrint('App lock status checked. Is locked: $isLocked, Internal state: $_isLocked');
      return isLocked;
    } catch (e) {
      // debugPrint('Error checking app lock status: $e');
      return false;
    }
  }

  /// Attempt to unlock with biometric authentication
  Future<UnlockResult> unlockWithBiometric() async {
    try {
      // Check if biometric authentication is available and enabled
      final isBiometricAvailable = await _biometricService.isBiometricAvailable();
      if (!isBiometricAvailable) {
        return UnlockResult.failure('Biometric authentication not available');
      }

      final isBiometricEnabled = await _biometricService.isBiometricLoginEnabled();
      if (!isBiometricEnabled) {
        return UnlockResult.failure('Biometric authentication not enabled');
      }

      // Attempt biometric authentication
      final biometricResult = await _biometricService.authenticateWithBiometric();
      if (biometricResult == null) {
        return UnlockResult.failure('Biometric authentication failed or cancelled');
      }

      // Unlock the app
      await unlockApp();
      return UnlockResult.success('App unlocked successfully');
    } catch (e) {
      return UnlockResult.failure('Biometric unlock failed: ${e.toString()}');
    }
  }

  /// Attempt to unlock with email/password authentication
  Future<UnlockResult> unlockWithCredentials({
    required String email,
    required String password,
  }) async {
    try {
      // Attempt authentication
      final authResult = await _authService.signIn(
        email: email,
        password: password,
      );

      if (!authResult.isSuccess) {
        return UnlockResult.failure(authResult.message);
      }

      // Unlock the app
      await unlockApp();
      return UnlockResult.success('App unlocked successfully');
    } catch (e) {
      return UnlockResult.failure('Credential unlock failed: ${e.toString()}');
    }
  }

  /// Sign out and clear lockout state
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _isLocked = false;
      _wasAuthenticated = false;
      await _secureStorage.setAppLocked(false);
      // debugPrint('User signed out and app unlocked');
    } catch (e) {
      // debugPrint('Error during sign out: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _lifecycleController.close();
  }
}

/// Unlock result class
class UnlockResult {
  final bool isSuccess;
  final String message;

  const UnlockResult._(this.isSuccess, this.message);

  factory UnlockResult.success(String message) => UnlockResult._(true, message);
  factory UnlockResult.failure(String message) => UnlockResult._(false, message);
}

/// Provider for AppLockoutService
final appLockoutServiceProvider = Provider<AppLockoutService>((ref) {
  return AppLockoutService.instance;
});

/// Provider for app lockout state
final appLockoutStateProvider = NotifierProvider<AppLockoutNotifier, bool>(() => AppLockoutNotifier());

/// App lockout state notifier
class AppLockoutNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void setLocked(bool isLocked) {
    state = isLocked;
  }
}

/// Provider for app lockout initialization
final appLockoutInitProvider = FutureProvider<void>((ref) async {
  final service = ref.read(appLockoutServiceProvider);
  await service.initialize();
});

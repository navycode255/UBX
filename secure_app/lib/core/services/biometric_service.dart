import 'package:local_auth/local_auth.dart';
import 'secure_storage_service.dart';
import 'pin_service.dart';

/// Simple Biometric Service for Login Shortcut
/// 
/// This service implements biometric authentication as a login shortcut:
/// 1. User logs in once with real credentials (email/password)
/// 2. App stores a refresh token or session key securely
/// 3. Next time, when biometrics succeed:
///    - App retrieves the stored token
///    - Authenticates silently (no password typing)
/// 
/// Biometrics only unlock and auto-parse stored credentials for reuse.
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  static BiometricService get instance => _instance;
  BiometricService._internal() {
    _checkAndResetAttemptCount();
  }



  // Local authentication instance
  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _secureStorage = SecureStorageService.instance;
  final PinService _pinService = PinService.instance;

  // Storage keys for biometric login
  static const String _biometricLoginEnabledKey = 'biometric_login_enabled';
  static const String _biometricLoginEmailKey = 'biometric_login_email';
  static const String _biometricLoginTokenKey = 'biometric_login_token';

  /// Check if biometric authentication is available on this device
  Future<bool> isBiometricAvailable() async {
    try {
      // Check if device supports biometrics
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        return false;
      }

      // Check if biometrics are available
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {

        return false;
      }

      // Get available biometric types
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      final hasBiometrics = availableBiometrics.isNotEmpty;
      
      // Debug info - keeping for now
      // print('Available biometrics: $availableBiometrics');
      
      return hasBiometrics;
    } catch (e) {

      return false;
    }
  }

  /// Check if biometric login is enabled for this user
  Future<bool> isBiometricLoginEnabled() async {
    try {
      final enabled = await _secureStorage.getBool(_biometricLoginEnabledKey);

      return enabled ?? false;
    } catch (e) {

      return false;
    }
  }

  /// Enable biometric login for the current user
  /// Call this after successful email/password login
  Future<bool> enableBiometricLogin({
    required String email,
    required String token,
    required String userId,
    required String name,
  }) async {
    try {
      // Check if biometrics are available
      if (!await isBiometricAvailable()) {

        return false;
      }

      // Store credentials securely
      await Future.wait([
        _secureStorage.setBool(_biometricLoginEnabledKey, true),
        _secureStorage.setString(_biometricLoginTokenKey, token),
        _secureStorage.setString(_biometricLoginEmailKey, email),
        _secureStorage.setString('biometric_user_id', userId),
        _secureStorage.setString('biometric_user_name', name),
      ]);


        return true;
    } catch (e) {

      return false;
    }
  }

  /// Disable biometric login for the current user
  Future<bool> disableBiometricLogin() async {
    try {
      await Future.wait([
        _secureStorage.setBool(_biometricLoginEnabledKey, false),
        _secureStorage.delete(_biometricLoginTokenKey),
        _secureStorage.delete(_biometricLoginEmailKey),
        _secureStorage.delete('biometric_user_id'),
        _secureStorage.delete('biometric_user_name'),
      ]);


      return true;
    } catch (e) {

      return false;
    }
  }

  /// Authenticate using biometrics and return stored credentials
  /// Returns null if authentication fails or no stored credentials
  Future<BiometricLoginResult?> authenticateWithBiometric() async {
    try {
      // Check if biometric login is enabled
      if (!await isBiometricLoginEnabled()) {

        return null;
      }

      // Check if biometrics are available
      if (!await isBiometricAvailable()) {

        return null;
      }

      // Get stored credentials
      final storedToken = await _secureStorage.getString(_biometricLoginTokenKey);
      final storedEmail = await _secureStorage.getString(_biometricLoginEmailKey);
      final storedUserId = await _secureStorage.getString('biometric_user_id');
      final storedName = await _secureStorage.getString('biometric_user_name');

      if (storedToken == null || storedEmail == null || storedUserId == null || storedName == null) {

        return null;
      }

      // Authenticate with biometrics
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Use your biometric to sign in',
        options: const AuthenticationOptions(
          stickyAuth: false,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      if (!isAuthenticated) {

        return null;
      }


      return BiometricLoginResult.success(
        email: storedEmail,
        token: storedToken,
        userId: storedUserId,
        name: storedName,
      );
    } catch (e) {

      return null;
    }
  }

  /// Reset biometric attempts and try authentication (for when user tries again after canceling PIN fallback)
  Future<BiometricLoginResult?> authenticateWithReset() async {
    try {
      // Reset attempt count when user tries again
      await _resetBiometricAttemptCount();
      // debugPrint('🔐 BiometricService: Reset biometric attempts, trying fresh authentication');
      
      // Now try biometric authentication
      return await authenticateWithFallback();
    } catch (e) {
      // debugPrint('🔐 BiometricService: Authentication reset error: $e');
      return null;
    }
  }

  /// Authenticate with biometric or PIN fallback (single attempt)
  Future<BiometricLoginResult?> authenticateWithFallback() async {
    try {
      // Get current attempt count
      final attemptCount = await _getBiometricAttemptCount();
      
      // If we've reached the limit, check if PIN fallback is available
      if (attemptCount >= 3) {
        final isPinEnabled = await _pinService.isPinEnabled();
        if (isPinEnabled) {
          return BiometricLoginResult.failure('Biometric authentication failed. Maximum attempts reached. Please use PIN fallback.', requiresPinFallback: true);
        } else {
          return BiometricLoginResult.failure('Biometric authentication failed. Maximum attempts reached. PIN fallback is not set up. Please sign in with email and password.');
        }
      }

      // Try single biometric authentication attempt
      final biometricResult = await _tryBiometricAuthentication();
      if (biometricResult != null) {
        // Reset attempt count on success
        await _resetBiometricAttemptCount();
        return biometricResult;
      }
      
      // Increment attempt count
      await _incrementBiometricAttemptCount();
      final newAttemptCount = await _getBiometricAttemptCount();
      
      // If we've reached the limit after this attempt, check if PIN fallback is available
      if (newAttemptCount >= 3) {
        final isPinEnabled = await _pinService.isPinEnabled();
        if (isPinEnabled) {
          return BiometricLoginResult.failure('Biometric authentication failed. Maximum attempts reached. Please use PIN fallback.', requiresPinFallback: true);
        } else {
          return BiometricLoginResult.failure('Biometric authentication failed. Maximum attempts reached. PIN fallback is not set up. Please sign in with email and password.');
        }
      }

      // Return failure with attempt info
      return BiometricLoginResult.failure('Biometric authentication failed. Attempt $newAttemptCount/3');
    } catch (e) {
      // debugPrint('🔐 BiometricService: Authentication error: $e');
      return null;
    }
  }

  /// Try single biometric authentication attempt
  Future<BiometricLoginResult?> _tryBiometricAuthentication() async {
    try {
      // Check if biometric authentication is available
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {

        return null;
      }

      // Check if biometric login is enabled
      final isEnabled = await isBiometricLoginEnabled();
      if (!isEnabled) {

        return null;
      }

      // Get stored credentials
      final storedToken = await _secureStorage.getString(_biometricLoginTokenKey);
      final storedEmail = await _secureStorage.getString(_biometricLoginEmailKey);
      final storedUserId = await _secureStorage.getString('biometric_user_id');
      final storedName = await _secureStorage.getString('biometric_user_name');

      if (storedToken == null || storedEmail == null || storedUserId == null || storedName == null) {

        return null;
      }

      // Try biometric authentication with immediate timeout to force single attempt
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Use biometric authentication to sign in',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false, // Ensure dialog closes after attempt
          sensitiveTransaction: false, // Ensure dialog closes after attempt
        ),
      ).timeout(
        const Duration(seconds: 3), // Very short 3 second timeout to force single attempt
        onTimeout: () {

          return false;
        },
      );

      if (isAuthenticated) {

        return BiometricLoginResult.success(
          email: storedEmail,
          token: storedToken,
          userId: storedUserId,
          name: storedName,
        );
      } else {

        
        // Immediately try to stop authentication to force dialog closure
        try {
          await _localAuth.stopAuthentication();
        } catch (e) {

        }
        
        // Return immediately without delay to force dialog closure
        return null;
      }
    } catch (e) {

      
      // Try to stop authentication on error too
      try {
        await _localAuth.stopAuthentication();
      } catch (stopError) {

      }
      
      return null;
    }
  }

  /// Show PIN fallback after reaching attempt limit
  Future<BiometricLoginResult?> _showPinFallbackAfterLimit() async {
    // Check if PIN is available as fallback
    final isPinEnabled = await _pinService.isPinEnabled();
    if (!isPinEnabled) {
      // No PIN fallback available - return failure with helpful message
      return BiometricLoginResult.failure('Biometric authentication failed. PIN fallback is not set up. Please sign in with email and password or set up PIN in settings.');
    }

    // Check if PIN is locked
    final isPinLocked = await _pinService.isPinLocked();
    if (isPinLocked) {
      return BiometricLoginResult.failure('PIN is locked due to too many failed attempts.');
    }

    // Return a special result indicating PIN fallback is needed
    return BiometricLoginResult.pinFallbackRequired('Biometric authentication failed 3 times. Please use PIN to continue.');
  }

  /// Authenticate with PIN fallback
  Future<BiometricLoginResult?> authenticateWithPin(String pin) async {
    try {
      // debugPrint('🔐 BiometricService: ===== STARTING PIN AUTHENTICATION =====');
      // debugPrint('🔐 BiometricService: PIN received: "$pin" (length: ${pin.length})');
      
      // Check if PIN is enabled first
      // debugPrint('🔐 BiometricService: Checking if PIN is enabled...');
      final isPinEnabled = await _pinService.isPinEnabled();
      // debugPrint('🔐 BiometricService: PIN enabled check result: $isPinEnabled');
      
      if (!isPinEnabled) {
        // debugPrint('❌ BiometricService: PIN authentication is not enabled');
        // debugPrint('🔐 BiometricService: Returning failure result');
        return BiometricLoginResult.failure('PIN authentication is not enabled. Please set up PIN in settings.');
      }
      
      // debugPrint('✅ BiometricService: PIN is enabled, proceeding with verification');
      
      // Verify PIN
      // debugPrint('🔐 BiometricService: Calling _pinService.verifyPin("$pin")');
      final pinResult = await _pinService.verifyPin(pin);
      // debugPrint('🔐 BiometricService: PIN verification completed');
      // debugPrint('🔐 BiometricService: PIN verification success: ${pinResult.isSuccess}');
      // debugPrint('🔐 BiometricService: PIN verification message: ${pinResult.message}');
      
      if (!pinResult.isSuccess) {
        // debugPrint('❌ BiometricService: PIN verification failed');
        // debugPrint('🔐 BiometricService: Returning failure result with message: ${pinResult.message}');
        return BiometricLoginResult.failure(pinResult.message);
      }

      // debugPrint('✅ BiometricService: PIN verification successful, retrieving user credentials');

      // Get user credentials from regular authentication storage
      // debugPrint('🔐 BiometricService: Getting stored email...');
      final storedEmail = await _secureStorage.getEmail();
      // debugPrint('🔐 BiometricService: Stored email: $storedEmail');
      
      // debugPrint('🔐 BiometricService: Getting stored userId...');
      final storedUserId = await _secureStorage.getUserId();
      // debugPrint('🔐 BiometricService: Stored userId: $storedUserId');
      
      // debugPrint('🔐 BiometricService: Getting stored name...');
      final storedName = await _secureStorage.getName();
      // debugPrint('🔐 BiometricService: Stored name: $storedName');
      
      // debugPrint('🔐 BiometricService: Getting stored token...');
      final storedToken = await _secureStorage.getAuthToken();
      // debugPrint('🔐 BiometricService: Stored token: $storedToken');

      // debugPrint('🔐 BiometricService: Checking if all credentials are present...');
      // debugPrint('  - Email: ${storedEmail != null ? "✅ Present" : "❌ Missing"}');
      // debugPrint('  - UserId: ${storedUserId != null ? "✅ Present" : "❌ Missing"}');
      // debugPrint('  - Name: ${storedName != null ? "✅ Present" : "❌ Missing"}');
      // debugPrint('  - Token: ${storedToken != null ? "✅ Present" : "❌ Missing"}');

      if (storedEmail == null || storedUserId == null || storedName == null || storedToken == null) {
        // debugPrint('❌ BiometricService: Missing user credentials for PIN fallback');
        // debugPrint('🔐 BiometricService: Cannot proceed with authentication');
        // debugPrint('🔐 BiometricService: Returning null result');
        return null;
      }

      // debugPrint('✅ BiometricService: All credentials present, creating success result');
      // debugPrint('🔐 BiometricService: Creating BiometricLoginResult.success with:');
      // debugPrint('  - Email: $storedEmail');
      // debugPrint('  - UserId: $storedUserId');
      // debugPrint('  - Name: $storedName');
      // debugPrint('  - Token: $storedToken');

      final result = BiometricLoginResult.success(
        email: storedEmail,
        token: storedToken,
        userId: storedUserId,
        name: storedName,
      );
      
      // debugPrint('🔐 BiometricService: Success result created: $result');
      // debugPrint('🔐 BiometricService: Result isSuccess: ${result.isSuccess}');
      // debugPrint('🔐 BiometricService: ===== PIN AUTHENTICATION COMPLETED SUCCESSFULLY =====');
      
      return result;
    } catch (e) {
      // debugPrint('❌ BiometricService: PIN authentication error: $e');
      // debugPrint('❌ BiometricService: Stack trace: ${StackTrace.current}');
      // debugPrint('🔐 BiometricService: ===== PIN AUTHENTICATION FAILED =====');
      return null;
    }
  }

  /// Check if PIN fallback is available
  Future<bool> isPinFallbackAvailable() async {
    try {
      final isPinEnabled = await _pinService.isPinEnabled();
      final isPinLocked = await _pinService.isPinLocked();
      return isPinEnabled && !isPinLocked;
    } catch (e) {

      return false;
    }
  }

  /// Get PIN status information
  Future<PinStatus> getPinStatus() async {
    try {
      final isEnabled = await _pinService.isPinEnabled();
      final isLocked = await _pinService.isPinLocked();
      final remainingAttempts = await _pinService.getRemainingAttempts();
      final lockoutTimeRemaining = await _pinService.getLockoutTimeRemaining();

      return PinStatus(
        isEnabled: isEnabled,
        isLocked: isLocked,
        remainingAttempts: remainingAttempts,
        lockoutTimeRemaining: lockoutTimeRemaining,
      );
    } catch (e) {

      return PinStatus(
        isEnabled: false,
        isLocked: false,
        remainingAttempts: 0,
        lockoutTimeRemaining: 0,
      );
    }
  }

  /// Get available biometric types (for UI display)
  Future<List<BiometricType>> getAvailableBiometricTypes() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();

      return biometrics;
    } catch (e) {

      return [];
    }
  }

  /// Get primary biometric type for UI display
  Future<String> getPrimaryBiometricType() async {
    try {
      final biometrics = await getAvailableBiometricTypes();

      
      // Check for specific biometric types first (most reliable)
      if (biometrics.contains(BiometricType.face)) {

        return 'Face';
      } else if (biometrics.contains(BiometricType.fingerprint)) {

        return 'Fingerprint';
      } else if (biometrics.contains(BiometricType.iris)) {

        return 'Iris';
      } else if (biometrics.contains(BiometricType.strong) && biometrics.contains(BiometricType.weak)) {
        // Device has both strong and weak - prioritize strong (fingerprint)

        return 'Fingerprint';
      } else if (biometrics.contains(BiometricType.strong)) {

        return 'Fingerprint';
      } else if (biometrics.contains(BiometricType.weak)) {

        return 'Face';
      } else {

        return 'Biometric';
      }
    } catch (e) {

      return 'Biometric';
    }
  }

  /// Intelligently detect biometric type based on device characteristics
  Future<String> _detectBiometricTypeFromDevice() async {
    try {
      // Get device info to help with detection
      final deviceInfo = await _getDeviceInfo();

      
      // For devices with both strong and weak, prioritize based on common patterns
      // Most modern devices: strong = fingerprint, weak = face
      // But some devices might be different, so we'll use a smart approach
      
      // Try to determine by checking if we can get more specific info
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      

      
      // Default logic: if both are available, prefer face recognition for better UX
      // (face recognition is generally faster and more convenient)

      return 'Face';
    } catch (e) {

      // Fallback: prefer face recognition as it's more user-friendly
      return 'Face';
    }
  }

  /// Get basic device information for biometric detection
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      return {
        'canCheckBiometrics': await _localAuth.canCheckBiometrics,
        'isDeviceSupported': await _localAuth.isDeviceSupported(),
        'availableBiometrics': await _localAuth.getAvailableBiometrics(),
      };
    } catch (e) {

      return {};
    }
  }

  // Biometric attempt tracking methods
  static const String _biometricAttemptCountKey = 'biometric_attempt_count';
  static const String _biometricAttemptResetTimeKey = 'biometric_attempt_reset_time';

  /// Get current biometric attempt count
  Future<int> _getBiometricAttemptCount() async {
    try {
      final countString = await _secureStorage.getString(_biometricAttemptCountKey);
      return int.tryParse(countString ?? '0') ?? 0;
    } catch (e) {

      return 0;
    }
  }

  /// Increment biometric attempt count
  Future<void> _incrementBiometricAttemptCount() async {
    try {
      final currentCount = await _getBiometricAttemptCount();
      await _secureStorage.setString(_biometricAttemptCountKey, (currentCount + 1).toString());
      
      // Set reset time (24 hours from now)
      final resetTime = DateTime.now().add(const Duration(hours: 24));
      await _secureStorage.setString(_biometricAttemptResetTimeKey, resetTime.toIso8601String());
    } catch (e) {

    }
  }

  /// Reset biometric attempt count
  Future<void> _resetBiometricAttemptCount() async {
    try {
      await _secureStorage.setString(_biometricAttemptCountKey, '0');
      await _secureStorage.setString(_biometricAttemptResetTimeKey, '');
    } catch (e) {

    }
  }

  /// Public method to reset biometric attempts (for PIN fallback cancellation)
  Future<void> resetBiometricAttempts() async {
    await _resetBiometricAttemptCount();
  }

  /// Check if attempt count should be reset (after 24 hours)
  Future<void> _checkAndResetAttemptCount() async {
    try {
      final resetTimeString = await _secureStorage.getString(_biometricAttemptResetTimeKey);
      if (resetTimeString != null) {
        final resetTime = DateTime.parse(resetTimeString);
        if (DateTime.now().isAfter(resetTime)) {
          await _resetBiometricAttemptCount();
        }
      }
    } catch (e) {

    }
  }
}

/// Result of biometric authentication
class BiometricLoginResult {
  final String? email;
  final String? token;
  final String? userId;
  final String? name;
  final bool isPinFallbackRequired;
  final String? message;

  BiometricLoginResult({
    this.email,
    this.token,
    this.userId,
    this.name,
    this.isPinFallbackRequired = false,
    this.message,
  });

  /// Create a successful biometric login result
  factory BiometricLoginResult.success({
    required String email,
    required String token,
    required String userId,
    required String name,
  }) {
    return BiometricLoginResult(
      email: email,
      token: token,
      userId: userId,
      name: name,
      isPinFallbackRequired: false,
    );
  }

  /// Create a PIN fallback required result
  factory BiometricLoginResult.pinFallbackRequired([String? message]) {
    return BiometricLoginResult(
      isPinFallbackRequired: true,
      message: message ?? 'Please use PIN to continue',
    );
  }

  /// Create a failure result
  factory BiometricLoginResult.failure(String message, {bool requiresPinFallback = false}) {
    return BiometricLoginResult(
      isPinFallbackRequired: requiresPinFallback,
      message: message,
    );
  }

  /// Check if the result is successful
  bool get isSuccess => email != null && token != null && userId != null && name != null;

  /// Check if PIN fallback is required
  bool get requiresPinFallback => isPinFallbackRequired;
  
  @override
  String toString() {
    if (isPinFallbackRequired) {
      return 'BiometricLoginResult(pinFallbackRequired: true, message: $message)';
    } else if (isSuccess) {
      return 'BiometricLoginResult(email: $email, userId: $userId, name: $name, token: ${token!.substring(0, 10)}...)';
    } else {
      return 'BiometricLoginResult(failure: $message)';
    }
  }
}

/// PIN status information
class PinStatus {
  final bool isEnabled;
  final bool isLocked;
  final int remainingAttempts;
  final int lockoutTimeRemaining;

  PinStatus({
    required this.isEnabled,
    required this.isLocked,
    required this.remainingAttempts,
    required this.lockoutTimeRemaining,
  });

  @override
  String toString() {
    return 'PinStatus(enabled: $isEnabled, locked: $isLocked, attempts: $remainingAttempts, lockoutTime: ${lockoutTimeRemaining}s)';
  }
}

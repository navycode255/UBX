import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'secure_storage_service.dart';
import 'pin_service.dart';

/// Handles fingerprint and face recognition authentication
class BiometricService {
  // Private constructor to prevent instantiation
  BiometricService._();
  
  // Singleton instance
  static final BiometricService _instance = BiometricService._();
  static BiometricService get instance => _instance;

  // Local authentication instance
  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _secureStorage = SecureStorageService.instance;
  final PinService _pinService = PinService();

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types on the device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if biometric authentication is enabled for the user
  Future<bool> isBiometricEnabled() async {
    try {
      return await _secureStorage.getBiometricEnabled() ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Enable biometric authentication for the user
  Future<bool> enableBiometric() async {
    try {
      // First check if biometric is available
      if (!await isBiometricAvailable()) {
        return false;
      }

      // Authenticate to enable biometric
      final isAuthenticated = await authenticateWithBiometric(
        reason: 'Enable biometric authentication for secure login',
      );

      if (isAuthenticated) {
        await _secureStorage.setBiometricEnabled(true);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Disable biometric authentication for the user
  Future<bool> disableBiometric() async {
    try {
      await _secureStorage.setBiometricEnabled(false);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate using biometric (fingerprint/face recognition)
  Future<bool> authenticateWithBiometric({
    String reason = 'Authenticate to continue',
    bool stickyAuth = true,
  }) async {
    try {
      // Check if biometric is available
      if (!await isBiometricAvailable()) {
        throw BiometricException('Biometric authentication is not available on this device');
      }

      // Check if biometric is enabled
      if (!await isBiometricEnabled()) {
        throw BiometricException('Biometric authentication is not enabled');
      }

      // Get available biometric types
      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        throw BiometricException('No biometric methods are available');
      }

      // Authenticate
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      return isAuthenticated;
    } on PlatformException catch (e) {
      throw BiometricException('Biometric authentication failed: ${e.message}');
    } catch (e) {
      throw BiometricException('Biometric authentication error: ${e.toString()}');
    }
  }

  /// Authenticate with biometric and return stored credentials
  Future<BiometricAuthResult> authenticateAndGetCredentials() async {
    try {
      // Authenticate with biometric
      final isAuthenticated = await authenticateWithBiometric(
        reason: 'Use biometric to sign in securely',
      );

      if (!isAuthenticated) {
        return BiometricAuthResult.failure('Biometric authentication failed');
      }

      // Get stored credentials
      final credentials = await _secureStorage.getStoredCredentials();
      if (credentials == null) {
        return BiometricAuthResult.failure('No stored credentials found');
      }

      return BiometricAuthResult.success(credentials);
    } catch (e) {
      return BiometricAuthResult.failure(e.toString());
    }
  }

  /// Check if biometric authentication is set up and ready
  Future<BiometricSetupStatus> getBiometricSetupStatus() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricSetupStatus.notAvailable;
      }

      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        return BiometricSetupStatus.availableButNotEnabled;
      }

      final hasCredentials = await _secureStorage.hasStoredCredentials();
      if (!hasCredentials) {
        return BiometricSetupStatus.enabledButNoCredentials;
      }

      return BiometricSetupStatus.ready;
    } catch (e) {
      return BiometricSetupStatus.error;
    }
  }

  /// Get user-friendly biometric type names
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face Recognition';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }

  /// Get primary biometric type for display
  Future<String> getPrimaryBiometricType() async {
    try {
      final availableTypes = await getAvailableBiometrics();
      if (availableTypes.isEmpty) {
        return 'Biometric';
      }

      // Prioritize fingerprint and face recognition
      if (availableTypes.contains(BiometricType.fingerprint)) {
        return getBiometricTypeName(BiometricType.fingerprint);
      } else if (availableTypes.contains(BiometricType.face)) {
        return getBiometricTypeName(BiometricType.face);
      } else {
        return getBiometricTypeName(availableTypes.first);
      }
    } catch (e) {
      return 'Biometric';
    }
  }

  /// Authenticate with biometric or PIN fallback
  Future<BiometricAuthResult> authenticateWithFallback({
    String reason = 'Authenticate to continue',
    bool allowPinFallback = true,
  }) async {
    try {
      // First try biometric authentication
      final biometricResult = await _tryBiometricAuthentication(reason);
      if (biometricResult.isSuccess) {
        return biometricResult;
      }

      // If biometric fails and PIN fallback is allowed, try PIN
      if (allowPinFallback && await _pinService.isPinEnabled()) {
        return BiometricAuthResult.failure('Biometric authentication failed. Please use PIN as fallback.');
      }

      return biometricResult;
    } catch (e) {
      return BiometricAuthResult.failure('Authentication failed: ${e.toString()}');
    }
  }

  /// Try biometric authentication
  Future<BiometricAuthResult> _tryBiometricAuthentication(String reason) async {
    try {
      // Check if biometric is available and enabled
      if (!await isBiometricAvailable() || !await isBiometricEnabled()) {
        return BiometricAuthResult.failure('Biometric authentication is not available');
      }

      // Authenticate with biometric
      final isAuthenticated = await authenticateWithBiometric(reason: reason);
      if (!isAuthenticated) {
        return BiometricAuthResult.failure('Biometric authentication failed');
      }

      // Get stored credentials
      final credentials = await _secureStorage.getStoredCredentials();
      if (credentials == null) {
        return BiometricAuthResult.failure('No stored credentials found');
      }

      return BiometricAuthResult.success(credentials);
    } catch (e) {
      return BiometricAuthResult.failure('Biometric authentication error: ${e.toString()}');
    }
  }

  /// Authenticate with PIN fallback
  Future<BiometricAuthResult> authenticateWithPin(String pin) async {
    try {
      // Verify PIN
      final pinResult = await _pinService.verifyPin(pin);
      if (!pinResult.isSuccess) {
        return BiometricAuthResult.failure(pinResult.message);
      }

      // Get stored credentials
      final credentials = await _secureStorage.getStoredCredentials();
      if (credentials == null) {
        return BiometricAuthResult.failure('No stored credentials found');
      }

      return BiometricAuthResult.success(credentials);
    } catch (e) {
      return BiometricAuthResult.failure('PIN authentication error: ${e.toString()}');
    }
  }

  /// Check if PIN fallback is available
  Future<bool> isPinFallbackAvailable() async {
    try {
      return await _pinService.isPinEnabled() && _pinService.isPinAvailable;
    } catch (e) {
      return false;
    }
  }

  /// Get PIN setup status
  Future<PinSetupStatus> getPinSetupStatus() async {
    try {
      return await _pinService.getPinSetupStatus();
    } catch (e) {
      return PinSetupStatus(
        isEnabled: false,
        isLocked: false,
        remainingAttempts: 3,
        lockoutTimeRemaining: 0,
      );
    }
  }

  /// Setup PIN as fallback
  Future<PinResult> setupPinFallback(String pin) async {
    try {
      return await _pinService.setupPin(pin);
    } catch (e) {
      return PinResult.failure('Failed to setup PIN: ${e.toString()}');
    }
  }

  /// Change PIN fallback
  Future<PinResult> changePinFallback(String currentPin, String newPin) async {
    try {
      return await _pinService.changePin(currentPin, newPin);
    } catch (e) {
      return PinResult.failure('Failed to change PIN: ${e.toString()}');
    }
  }

  /// Disable PIN fallback
  Future<PinResult> disablePinFallback(String currentPin) async {
    try {
      return await _pinService.disablePin(currentPin);
    } catch (e) {
      return PinResult.failure('Failed to disable PIN: ${e.toString()}');
    }
  }

  /// Get comprehensive authentication status
  Future<AuthenticationStatus> getAuthenticationStatus() async {
    try {
      final biometricAvailable = await isBiometricAvailable();
      final biometricEnabled = await isBiometricEnabled();
      final pinEnabled = await _pinService.isPinEnabled();
      final pinLocked = await _pinService.isPinLocked();
      final pinRemainingAttempts = await _pinService.getRemainingAttempts();

      return AuthenticationStatus(
        biometricAvailable: biometricAvailable,
        biometricEnabled: biometricEnabled,
        pinEnabled: pinEnabled,
        pinLocked: pinLocked,
        pinRemainingAttempts: pinRemainingAttempts,
        hasAnyAuth: biometricEnabled || pinEnabled,
      );
    } catch (e) {
      return AuthenticationStatus(
        biometricAvailable: false,
        biometricEnabled: false,
        pinEnabled: false,
        pinLocked: false,
        pinRemainingAttempts: 0,
        hasAnyAuth: false,
      );
    }
  }
}

/// Biometric authentication result
class BiometricAuthResult {
  final bool isSuccess;
  final String message;
  final StoredCredentials? credentials;

  const BiometricAuthResult._(this.isSuccess, this.message, this.credentials);

  factory BiometricAuthResult.success(StoredCredentials credentials) => 
      BiometricAuthResult._(true, 'Authentication successful', credentials);
  
  factory BiometricAuthResult.failure(String message) => 
      BiometricAuthResult._(false, message, null);
}

/// Biometric setup status
enum BiometricSetupStatus {
  notAvailable,
  availableButNotEnabled,
  enabledButNoCredentials,
  ready,
  error,
}

/// Custom exception for biometric operations
class BiometricException implements Exception {
  final String message;
  
  const BiometricException(this.message);
  
  @override
  String toString() => 'BiometricException: $message';
}

/// Comprehensive authentication status
class AuthenticationStatus {
  final bool biometricAvailable;
  final bool biometricEnabled;
  final bool pinEnabled;
  final bool pinLocked;
  final int pinRemainingAttempts;
  final bool hasAnyAuth;

  const AuthenticationStatus({
    required this.biometricAvailable,
    required this.biometricEnabled,
    required this.pinEnabled,
    required this.pinLocked,
    required this.pinRemainingAttempts,
    required this.hasAnyAuth,
  });

  bool get canUseBiometric => biometricAvailable && biometricEnabled;
  bool get canUsePin => pinEnabled && !pinLocked;
  bool get hasFallback => canUseBiometric || canUsePin;
}

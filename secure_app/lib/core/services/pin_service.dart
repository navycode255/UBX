import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'secure_storage_service.dart';

/// PIN Service for Biometric Fallback
/// 
/// This service handles PIN authentication as a fallback when biometric
/// authentication is not available or fails.
class PinService {
  static final PinService _instance = PinService._internal();
  factory PinService() => _instance;
  static PinService get instance => _instance;
  PinService._internal();

  final SecureStorageService _secureStorage = SecureStorageService.instance;

  // Storage keys for PIN authentication
  static const String _pinEnabledKey = 'pin_enabled';
  static const String _pinHashKey = 'pin_hash';
  static const String _pinAttemptsKey = 'pin_attempts';
  static const String _pinLockoutKey = 'pin_lockout';
  static const String _pinLockoutTimeKey = 'pin_lockout_time';

  // PIN security settings
  static const int _maxAttempts = 3;
  static const int _lockoutDurationMinutes = 5;

  /// Check if PIN authentication is enabled
  Future<bool> isPinEnabled() async {
    try {
      final enabled = await _secureStorage.getBool(_pinEnabledKey);
      return enabled ?? false;
    } catch (e) {

      return false;
    }
  }

  /// Check if PIN is currently locked due to too many failed attempts
  Future<bool> isPinLocked() async {
    try {
      final lockoutTime = await _secureStorage.getString(_pinLockoutTimeKey);
      if (lockoutTime == null) return false;

      final lockoutDateTime = DateTime.parse(lockoutTime);
      final now = DateTime.now();
      final difference = now.difference(lockoutDateTime);

      // If lockout period has expired, clear the lockout
      if (difference.inMinutes >= _lockoutDurationMinutes) {
        await _clearLockout();
        return false;
      }

      return true;
    } catch (e) {

      return false;
    }
  }

  /// Get remaining PIN attempts before lockout
  Future<int> getRemainingAttempts() async {
    try {
      final attempts = await _secureStorage.getString(_pinAttemptsKey);
      if (attempts == null) return _maxAttempts;
      
      final attemptCount = int.tryParse(attempts) ?? 0;
      return _maxAttempts - attemptCount;
    } catch (e) {

      return _maxAttempts;
    }
  }

  /// Get lockout time remaining in seconds
  Future<int> getLockoutTimeRemaining() async {
    try {
      final lockoutTime = await _secureStorage.getString(_pinLockoutTimeKey);
      if (lockoutTime == null) return 0;

      final lockoutDateTime = DateTime.parse(lockoutTime);
      final now = DateTime.now();
      final difference = now.difference(lockoutDateTime);

      if (difference.inMinutes >= _lockoutDurationMinutes) {
        await _clearLockout();
        return 0;
      }

      final remainingSeconds = (_lockoutDurationMinutes * 60) - difference.inSeconds;
      return remainingSeconds > 0 ? remainingSeconds : 0;
    } catch (e) {

      return 0;
    }
  }

  /// Setup PIN authentication
  Future<PinResult> setupPin(String pin) async {
    try {
      // Validate PIN
      if (pin.length < 4) {
        return PinResult.failure('PIN must be at least 4 digits');
      }

      if (pin.length > 8) {
        return PinResult.failure('PIN must be no more than 8 digits');
      }

      // Hash the PIN for secure storage
      final pinHash = _hashPin(pin);

      // Store PIN hash and enable PIN authentication
      await _secureStorage.setString(_pinHashKey, pinHash);
      await _secureStorage.setBool(_pinEnabledKey, true);
      await _resetAttempts();


      return PinResult.success('PIN setup successful');
    } catch (e) {

      return PinResult.failure('Failed to setup PIN: $e');
    }
  }

  /// Verify PIN authentication
  Future<PinResult> verifyPin(String pin) async {
    try {
      // Check if PIN is locked
      if (await isPinLocked()) {
        final remainingTime = await getLockoutTimeRemaining();
        return PinResult.failure('PIN is locked. Try again in ${remainingTime}s');
      }

      // Check if PIN is enabled
      if (!await isPinEnabled()) {
        return PinResult.failure('PIN authentication is not enabled');
      }

      // Get stored PIN hash
      final storedHash = await _secureStorage.getString(_pinHashKey);
      if (storedHash == null) {
        return PinResult.failure('No PIN found. Please setup PIN first');
      }

      // Hash the provided PIN
      final providedHash = _hashPin(pin);

      // Compare hashes
      if (storedHash == providedHash) {
        // PIN is correct, reset attempts
        await _resetAttempts();

        return PinResult.success('PIN verification successful');
      } else {
        // PIN is incorrect, increment attempts
        await _incrementAttempts();
        final remainingAttempts = await getRemainingAttempts();
        
        if (remainingAttempts <= 0) {
          await _lockPin();
          return PinResult.failure('PIN locked due to too many failed attempts');
        }
        
        return PinResult.failure('Incorrect PIN. $remainingAttempts attempts remaining');
      }
    } catch (e) {

      return PinResult.failure('Failed to verify PIN: $e');
    }
  }

  /// Change PIN (requires current PIN verification)
  Future<PinResult> changePin(String currentPin, String newPin) async {
    try {
      // Verify current PIN first
      final verifyResult = await verifyPin(currentPin);
      if (!verifyResult.isSuccess) {
        return verifyResult;
      }

      // Setup new PIN
      return await setupPin(newPin);
    } catch (e) {

      return PinResult.failure('Failed to change PIN: $e');
    }
  }

  /// Disable PIN authentication
  Future<PinResult> disablePin(String currentPin) async {
    try {
      // Verify current PIN first
      final verifyResult = await verifyPin(currentPin);
      if (!verifyResult.isSuccess) {
        return verifyResult;
      }

      // Clear PIN data
      await _secureStorage.delete(_pinEnabledKey);
      await _secureStorage.delete(_pinHashKey);
      await _clearLockout();


      return PinResult.success('PIN disabled successfully');
    } catch (e) {

      return PinResult.failure('Failed to disable PIN: $e');
    }
  }

  /// Hash PIN for secure storage
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Reset failed attempts counter
  Future<void> _resetAttempts() async {
    await _secureStorage.delete(_pinAttemptsKey);
  }

  /// Increment failed attempts counter
  Future<void> _incrementAttempts() async {
    try {
      final attempts = await _secureStorage.getString(_pinAttemptsKey);
      final attemptCount = (int.tryParse(attempts ?? '0') ?? 0) + 1;
      await _secureStorage.setString(_pinAttemptsKey, attemptCount.toString());
    } catch (e) {

    }
  }

  /// Lock PIN due to too many failed attempts
  Future<void> _lockPin() async {
    try {
      await _secureStorage.setBool(_pinLockoutKey, true);
      await _secureStorage.setString(_pinLockoutTimeKey, DateTime.now().toIso8601String());

    } catch (e) {

    }
  }

  /// Clear PIN lockout
  Future<void> _clearLockout() async {
    try {
      await _secureStorage.delete(_pinLockoutKey);
      await _secureStorage.delete(_pinLockoutTimeKey);
    } catch (e) {

    }
  }
}

/// Result class for PIN operations
class PinResult {
  final bool isSuccess;
  final String message;

  PinResult._(this.isSuccess, this.message);

  factory PinResult.success(String message) => PinResult._(true, message);
  factory PinResult.failure(String message) => PinResult._(false, message);
}

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
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
      if (pin.length != 4) {
        return PinResult.failure('PIN must be exactly 4 digits');
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
      // debugPrint('🔐 PinService: ===== STARTING PIN VERIFICATION =====');
      // debugPrint('🔐 PinService: PIN received: "$pin" (length: ${pin.length})');
      
      // Check if PIN is locked
      // debugPrint('🔐 PinService: Checking if PIN is locked...');
      final isLocked = await isPinLocked();
      // debugPrint('🔐 PinService: PIN locked check result: $isLocked');
      
      if (isLocked) {
        // debugPrint('❌ PinService: PIN is locked');
        final remainingTime = await getLockoutTimeRemaining();
        // debugPrint('🔐 PinService: Remaining lockout time: ${remainingTime}s');
        return PinResult.failure('PIN is locked. Try again in ${remainingTime}s');
      }

      // debugPrint('✅ PinService: PIN is not locked, checking if enabled...');
      
      // Check if PIN is enabled
      final isEnabled = await isPinEnabled();
      // debugPrint('🔐 PinService: PIN enabled check result: $isEnabled');
      
      if (!isEnabled) {
        // debugPrint('❌ PinService: PIN authentication is not enabled');
        return PinResult.failure('PIN authentication is not enabled');
      }

      // debugPrint('✅ PinService: PIN is enabled, retrieving stored hash...');

      // Get stored PIN hash
      // debugPrint('🔐 PinService: Getting stored PIN hash from secure storage...');
      final storedHash = await _secureStorage.getString(_pinHashKey);
      // debugPrint('🔐 PinService: Stored hash retrieved: ${storedHash != null ? "Present" : "Missing"}');
      
      if (storedHash == null) {
        // debugPrint('❌ PinService: No PIN found in storage');
        return PinResult.failure('No PIN found. Please setup PIN first');
      }

      // debugPrint('✅ PinService: Stored hash found, hashing provided PIN...');

      // Hash the provided PIN
      // debugPrint('🔐 PinService: Hashing provided PIN: "$pin"');
      final providedHash = _hashPin(pin);
      // debugPrint('🔐 PinService: Provided hash: $providedHash');
      // debugPrint('🔐 PinService: Stored hash: $storedHash');

      // debugPrint('🔐 PinService: Comparing hashes...');
      // Compare hashes
      if (storedHash == providedHash) {
        // debugPrint('✅ PinService: PIN hashes match! PIN is correct');
        // PIN is correct, reset attempts
        // debugPrint('🔐 PinService: Resetting PIN attempts...');
        await _resetAttempts();
        // debugPrint('🔐 PinService: PIN attempts reset successfully');

        // debugPrint('🔐 PinService: ===== PIN VERIFICATION SUCCESSFUL =====');
        return PinResult.success('PIN verification successful');
      } else {
        // debugPrint('❌ PinService: PIN hashes do not match! PIN is incorrect');
        // PIN is incorrect, increment attempts
        // debugPrint('🔐 PinService: Incrementing PIN attempts...');
        await _incrementAttempts();
        final remainingAttempts = await getRemainingAttempts();
        // debugPrint('🔐 PinService: Remaining attempts after increment: $remainingAttempts');
        
        if (remainingAttempts <= 0) {
          // debugPrint('❌ PinService: No attempts remaining, locking PIN...');
          await _lockPin();
          // debugPrint('🔐 PinService: PIN locked due to too many failed attempts');
          return PinResult.failure('PIN locked due to too many failed attempts');
        }
        
        // debugPrint('🔐 PinService: ===== PIN VERIFICATION FAILED =====');
        return PinResult.failure('Incorrect PIN. $remainingAttempts attempts remaining');
      }
    } catch (e) {
      // debugPrint('❌ PinService: PIN verification error: $e');
      // debugPrint('❌ PinService: Stack trace: ${StackTrace.current}');
      // debugPrint('🔐 PinService: ===== PIN VERIFICATION ERROR =====');
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
      // debugPrint('🔐 PinService: ===== STARTING PIN DISABLE =====');
      // debugPrint('🔐 PinService: PIN received: "$currentPin" (length: ${currentPin.length})');
      
      // Verify current PIN first
      // debugPrint('🔐 PinService: Verifying current PIN before disable...');
      final verifyResult = await verifyPin(currentPin);
      // debugPrint('🔐 PinService: PIN verification result - Success: ${verifyResult.isSuccess}, Message: ${verifyResult.message}');
      
      if (!verifyResult.isSuccess) {
        // debugPrint('❌ PinService: PIN verification failed, cannot disable PIN');
        // debugPrint('🔐 PinService: ===== PIN DISABLE FAILED - VERIFICATION FAILED =====');
        return verifyResult;
      }

      // debugPrint('✅ PinService: PIN verification successful, proceeding to disable...');

      // Clear PIN data
      // debugPrint('🔐 PinService: Deleting PIN enabled key...');
      await _secureStorage.delete(_pinEnabledKey);
      // debugPrint('🔐 PinService: Deleting PIN hash key...');
      await _secureStorage.delete(_pinHashKey);
      // debugPrint('🔐 PinService: Clearing PIN lockout...');
      await _clearLockout();

      // debugPrint('✅ PinService: PIN data cleared successfully');
      // debugPrint('🔐 PinService: ===== PIN DISABLE COMPLETED SUCCESSFULLY =====');
      return PinResult.success('PIN disabled successfully');
    } catch (e) {
      // debugPrint('❌ PinService: PIN disable error: $e');
      // debugPrint('❌ PinService: Stack trace: ${StackTrace.current}');
      // debugPrint('🔐 PinService: ===== PIN DISABLE FAILED WITH ERROR =====');
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

  /// Reset PIN for new user (clear PIN data without verification)
  Future<void> resetPinForNewUser() async {
    try {
      // Clear all PIN-related data
      await _secureStorage.delete(_pinEnabledKey);
      await _secureStorage.delete(_pinHashKey);
      await _clearLockout();
      
      print('🔒 PIN reset for new user - PIN disabled');
    } catch (e) {
      print('⚠️ Failed to reset PIN for new user: $e');
      // Don't throw error as this shouldn't block signup
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
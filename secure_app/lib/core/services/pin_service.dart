import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Service for handling PIN authentication as a fallback to biometric authentication
class PinService {
  static final PinService _instance = PinService._internal();
  factory PinService() => _instance;
  PinService._internal();

  static const String _pinKey = 'user_pin';
  static const String _pinEnabledKey = 'pin_enabled';
  static const String _attemptsKey = 'pin_attempts';
  static const String _lockoutUntilKey = 'pin_lockout_until';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // PIN configuration
  static const int _pinLength = 6;
  static const int _maxAttempts = 3;
  static const int _lockoutDurationMinutes = 5;

  /// Check if PIN authentication is available
  bool get isPinAvailable => true;

  /// Check if PIN is enabled for the current user
  Future<bool> isPinEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _pinEnabledKey);
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Check if PIN is currently locked due to too many failed attempts
  Future<bool> isPinLocked() async {
    try {
      final lockoutUntil = await _secureStorage.read(key: _lockoutUntilKey);
      if (lockoutUntil == null) return false;
      
      final lockoutTime = DateTime.parse(lockoutUntil);
      final now = DateTime.now();
      
      if (now.isAfter(lockoutTime)) {
        // Lockout period has expired, clear it
        await _secureStorage.delete(key: _lockoutUntilKey);
        await _secureStorage.delete(key: _attemptsKey);
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
      final attempts = await _secureStorage.read(key: _attemptsKey);
      if (attempts == null) return _maxAttempts;
      
      final currentAttempts = int.tryParse(attempts) ?? 0;
      return _maxAttempts - currentAttempts;
    } catch (e) {
      return _maxAttempts;
    }
  }

  /// Get lockout time remaining in minutes
  Future<int> getLockoutTimeRemaining() async {
    try {
      final lockoutUntil = await _secureStorage.read(key: _lockoutUntilKey);
      if (lockoutUntil == null) return 0;
      
      final lockoutTime = DateTime.parse(lockoutUntil);
      final now = DateTime.now();
      
      if (now.isAfter(lockoutTime)) {
        return 0;
      }
      
      final difference = lockoutTime.difference(now);
      return difference.inMinutes + 1; // Round up
    } catch (e) {
      return 0;
    }
  }

  /// Set up PIN for the current user
  Future<PinResult> setupPin(String pin) async {
    try {
      // Validate PIN
      final validationResult = _validatePin(pin);
      if (!validationResult.isSuccess) {
        return validationResult;
      }

      // Check if PIN is already set
      final existingPin = await _secureStorage.read(key: _pinKey);
      if (existingPin != null) {
        return PinResult.failure('PIN is already set. Use changePin to update it.');
      }

      // Hash and store the PIN
      final hashedPin = _hashPin(pin);
      await _secureStorage.write(key: _pinKey, value: hashedPin);
      await _secureStorage.write(key: _pinEnabledKey, value: 'true');
      
      // Reset attempts and lockout
      await _secureStorage.delete(key: _attemptsKey);
      await _secureStorage.delete(key: _lockoutUntilKey);

      return PinResult.success('PIN has been set up successfully');
    } catch (e) {
      return PinResult.failure('Failed to set up PIN: ${e.toString()}');
    }
  }

  /// Change existing PIN
  Future<PinResult> changePin(String currentPin, String newPin) async {
    try {
      // Validate new PIN
      final validationResult = _validatePin(newPin);
      if (!validationResult.isSuccess) {
        return validationResult;
      }

      // Verify current PIN
      final verifyResult = await verifyPin(currentPin);
      if (!verifyResult.isSuccess) {
        return PinResult.failure('Current PIN is incorrect');
      }

      // Hash and store the new PIN
      final hashedPin = _hashPin(newPin);
      await _secureStorage.write(key: _pinKey, value: hashedPin);
      
      // Reset attempts and lockout
      await _secureStorage.delete(key: _attemptsKey);
      await _secureStorage.delete(key: _lockoutUntilKey);

      return PinResult.success('PIN has been changed successfully');
    } catch (e) {
      return PinResult.failure('Failed to change PIN: ${e.toString()}');
    }
  }

  /// Verify PIN
  Future<PinResult> verifyPin(String pin) async {
    try {
      // Check if PIN is locked
      if (await isPinLocked()) {
        final lockoutTime = await getLockoutTimeRemaining();
        return PinResult.failure('PIN is locked. Try again in $lockoutTime minutes.');
      }

      // Check if PIN is enabled
      if (!await isPinEnabled()) {
        return PinResult.failure('PIN authentication is not enabled');
      }

      // Get stored PIN
      final storedPin = await _secureStorage.read(key: _pinKey);
      if (storedPin == null) {
        return PinResult.failure('No PIN found. Please set up a PIN first.');
      }

      // Hash the provided PIN and compare
      final hashedPin = _hashPin(pin);
      if (hashedPin == storedPin) {
        // Reset attempts on successful verification
        await _secureStorage.delete(key: _attemptsKey);
        await _secureStorage.delete(key: _lockoutUntilKey);
        return PinResult.success('PIN verified successfully');
      } else {
        // Increment failed attempts
        await _incrementFailedAttempts();
        return PinResult.failure('Incorrect PIN');
      }
    } catch (e) {
      return PinResult.failure('Failed to verify PIN: ${e.toString()}');
    }
  }

  /// Disable PIN authentication
  Future<PinResult> disablePin(String currentPin) async {
    try {
      // Verify current PIN before disabling
      final verifyResult = await verifyPin(currentPin);
      if (!verifyResult.isSuccess) {
        return PinResult.failure('Current PIN is incorrect');
      }

      // Remove PIN and disable
      await _secureStorage.delete(key: _pinKey);
      await _secureStorage.write(key: _pinEnabledKey, value: 'false');
      await _secureStorage.delete(key: _attemptsKey);
      await _secureStorage.delete(key: _lockoutUntilKey);

      return PinResult.success('PIN authentication has been disabled');
    } catch (e) {
      return PinResult.failure('Failed to disable PIN: ${e.toString()}');
    }
  }

  /// Reset PIN (for admin/recovery purposes)
  Future<PinResult> resetPin() async {
    try {
      await _secureStorage.delete(key: _pinKey);
      await _secureStorage.write(key: _pinEnabledKey, value: 'false');
      await _secureStorage.delete(key: _attemptsKey);
      await _secureStorage.delete(key: _lockoutUntilKey);

      return PinResult.success('PIN has been reset');
    } catch (e) {
      return PinResult.failure('Failed to reset PIN: ${e.toString()}');
    }
  }

  /// Validate PIN format and requirements
  PinResult _validatePin(String pin) {
    if (pin.isEmpty) {
      return PinResult.failure('PIN cannot be empty');
    }

    if (pin.length != _pinLength) {
      return PinResult.failure('PIN must be $_pinLength digits');
    }

    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      return PinResult.failure('PIN must contain only digits');
    }

    // Check for common weak PINs
    if (_isWeakPin(pin)) {
      return PinResult.failure('PIN is too weak. Please choose a more secure PIN');
    }

    return PinResult.success('PIN is valid');
  }

  /// Check if PIN is weak (common patterns)
  bool _isWeakPin(String pin) {
    // Check for sequential numbers (123456, 654321)
    if (pin == '123456' || pin == '654321') return true;
    
    // Check for repeated numbers (111111, 222222)
    if (pin == pin[0] * _pinLength) return true;
    
    // Check for common patterns
    final commonPins = ['000000', '111111', '222222', '333333', '444444', '555555', '666666', '777777', '888888', '999999'];
    if (commonPins.contains(pin)) return true;
    
    return false;
  }

  /// Hash PIN for secure storage
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Increment failed attempts and handle lockout
  Future<void> _incrementFailedAttempts() async {
    try {
      final attempts = await _secureStorage.read(key: _attemptsKey);
      final currentAttempts = (int.tryParse(attempts ?? '0') ?? 0) + 1;
      
      await _secureStorage.write(key: _attemptsKey, value: currentAttempts.toString());
      
      if (currentAttempts >= _maxAttempts) {
        // Lock the PIN
        final lockoutUntil = DateTime.now().add(Duration(minutes: _lockoutDurationMinutes));
        await _secureStorage.write(key: _lockoutUntilKey, value: lockoutUntil.toIso8601String());
      }
    } catch (e) {
      // Ignore errors in attempt tracking
    }
  }

  /// Get PIN setup status
  Future<PinSetupStatus> getPinSetupStatus() async {
    try {
      final isEnabled = await isPinEnabled();
      final isLocked = await isPinLocked();
      final remainingAttempts = await getRemainingAttempts();
      final lockoutTimeRemaining = await getLockoutTimeRemaining();

      return PinSetupStatus(
        isEnabled: isEnabled,
        isLocked: isLocked,
        remainingAttempts: remainingAttempts,
        lockoutTimeRemaining: lockoutTimeRemaining,
      );
    } catch (e) {
      return PinSetupStatus(
        isEnabled: false,
        isLocked: false,
        remainingAttempts: _maxAttempts,
        lockoutTimeRemaining: 0,
      );
    }
  }
}

/// Result of PIN operations
class PinResult {
  final bool isSuccess;
  final String message;

  const PinResult._(this.isSuccess, this.message);

  factory PinResult.success(String message) => PinResult._(true, message);
  factory PinResult.failure(String message) => PinResult._(false, message);
}

/// PIN setup status information
class PinSetupStatus {
  final bool isEnabled;
  final bool isLocked;
  final int remainingAttempts;
  final int lockoutTimeRemaining;

  const PinSetupStatus({
    required this.isEnabled,
    required this.isLocked,
    required this.remainingAttempts,
    required this.lockoutTimeRemaining,
  });

  bool get isAvailable => isEnabled && !isLocked;
  bool get hasAttemptsRemaining => remainingAttempts > 0;
}

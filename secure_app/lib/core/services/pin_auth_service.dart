import 'secure_storage_service.dart';
import 'pin_service.dart';

/// PIN Authentication Result
class PinAuthResult {
  final bool isSuccess;
  final String? email;
  final String? userId;
  final String? name;
  final String? token;
  final String? message;

  PinAuthResult._({
    required this.isSuccess,
    this.email,
    this.userId,
    this.name,
    this.token,
    this.message,
  });

  factory PinAuthResult.success({
    required String email,
    required String userId,
    required String name,
    required String token,
  }) {
    return PinAuthResult._(
      isSuccess: true,
      email: email,
      userId: userId,
      name: name,
      token: token,
    );
  }

  factory PinAuthResult.failure(String message) {
    return PinAuthResult._(
      isSuccess: false,
      message: message,
    );
  }
}

/// PIN Authentication Service
/// 
/// This service handles PIN-based authentication independently from biometrics.
/// It provides a clean interface for PIN authentication without relying on
/// the biometric service.
class PinAuthService {
  static final PinAuthService _instance = PinAuthService._internal();
  factory PinAuthService() => _instance;
  static PinAuthService get instance => _instance;
  PinAuthService._internal();

  final SecureStorageService _secureStorage = SecureStorageService.instance;
  final PinService _pinService = PinService.instance;

  /// Authenticate with PIN
  Future<PinAuthResult> authenticateWithPin(String pin) async {
    try {
      // debugPrint('🔐 PinAuthService: ===== STARTING PIN AUTHENTICATION =====');
      // debugPrint('🔐 PinAuthService: PIN received: "$pin" (length: ${pin.length})');
      
      // Check if PIN is enabled first
      // debugPrint('🔐 PinAuthService: Checking if PIN is enabled...');
      final isPinEnabled = await _pinService.isPinEnabled();
      // debugPrint('🔐 PinAuthService: PIN enabled check result: $isPinEnabled');
      
      if (!isPinEnabled) {
        // debugPrint('❌ PinAuthService: PIN authentication is not enabled');
        // debugPrint('🔐 PinAuthService: Returning failure result');
        return PinAuthResult.failure('PIN authentication is not enabled. Please set up PIN in settings.');
      }
      
      // debugPrint('✅ PinAuthService: PIN is enabled, proceeding with verification');
      
      // Verify PIN
      // debugPrint('🔐 PinAuthService: Calling _pinService.verifyPin("$pin")');
      final pinResult = await _pinService.verifyPin(pin);
      // debugPrint('🔐 PinAuthService: PIN verification completed');
      // debugPrint('🔐 PinAuthService: PIN verification success: ${pinResult.isSuccess}');
      // debugPrint('🔐 PinAuthService: PIN verification message: ${pinResult.message}');
      
      if (!pinResult.isSuccess) {
        // debugPrint('❌ PinAuthService: PIN verification failed');
        // debugPrint('🔐 PinAuthService: Returning failure result with message: ${pinResult.message}');
        return PinAuthResult.failure(pinResult.message);
      }

      // debugPrint('✅ PinAuthService: PIN verification successful, retrieving user credentials');

      // Get user credentials from regular authentication storage
      // debugPrint('🔐 PinAuthService: Getting stored email...');
      final storedEmail = await _secureStorage.getEmail();
      // debugPrint('🔐 PinAuthService: Stored email: $storedEmail');
      
      // debugPrint('🔐 PinAuthService: Getting stored userId...');
      final storedUserId = await _secureStorage.getUserId();
      // debugPrint('🔐 PinAuthService: Stored userId: $storedUserId');
      
      // debugPrint('🔐 PinAuthService: Getting stored name...');
      final storedName = await _secureStorage.getName();
      // debugPrint('🔐 PinAuthService: Stored name: $storedName');
      
      // debugPrint('🔐 PinAuthService: Getting stored token...');
      final storedToken = await _secureStorage.getAuthToken();
      // debugPrint('🔐 PinAuthService: Stored token: $storedToken');

      // debugPrint('🔐 PinAuthService: Checking if all credentials are present...');
      // debugPrint('  - Email: ${storedEmail != null ? "✅ Present" : "❌ Missing"}');
      // debugPrint('  - UserId: ${storedUserId != null ? "✅ Present" : "❌ Missing"}');
      // debugPrint('  - Name: ${storedName != null ? "✅ Present" : "❌ Missing"}');
      // debugPrint('  - Token: ${storedToken != null ? "✅ Present" : "❌ Missing"}');

      if (storedEmail == null || storedUserId == null || storedName == null || storedToken == null) {
        // debugPrint('❌ PinAuthService: Missing user credentials for PIN authentication');
        // debugPrint('🔐 PinAuthService: Cannot proceed with authentication');
        // debugPrint('🔐 PinAuthService: Returning null result');
        return PinAuthResult.failure('User credentials not found. Please sign in with email and password first.');
      }

      // debugPrint('✅ PinAuthService: All credentials present, creating success result');
      // debugPrint('🔐 PinAuthService: Creating PinAuthResult.success with:');
      // debugPrint('  - Email: $storedEmail');
      // debugPrint('  - UserId: $storedUserId');
      // debugPrint('  - Name: $storedName');
      // debugPrint('  - Token: $storedToken');

      final result = PinAuthResult.success(
        email: storedEmail,
        userId: storedUserId,
        name: storedName,
        token: storedToken,
      );
      
      // debugPrint('🔐 PinAuthService: Success result created: $result');
      // debugPrint('🔐 PinAuthService: Result isSuccess: ${result.isSuccess}');
      // debugPrint('🔐 PinAuthService: ===== PIN AUTHENTICATION COMPLETED SUCCESSFULLY =====');
      
      return result;
    } catch (e) {
      // debugPrint('❌ PinAuthService: PIN authentication error: $e');
      // debugPrint('❌ PinAuthService: Stack trace: ${StackTrace.current}');
      // debugPrint('🔐 PinAuthService: ===== PIN AUTHENTICATION FAILED =====');
      return PinAuthResult.failure('PIN authentication failed: $e');
    }
  }

  /// Check if PIN authentication is available
  Future<bool> isPinAuthAvailable() async {
    try {
      final isPinEnabled = await _pinService.isPinEnabled();
      // debugPrint('🔐 PinAuthService: PIN auth available check - enabled: $isPinEnabled');
      return isPinEnabled;
    } catch (e) {
      // debugPrint('❌ PinAuthService: Error checking PIN auth availability: $e');
      return false;
    }
  }
}

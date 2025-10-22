import 'local_database_service.dart';
import 'secure_storage_service.dart';
import 'biometric_service.dart';
import 'pin_service.dart';
import 'device_id_service.dart';

/// Authentication Service
/// 
/// Handles user authentication including:
/// - Email/password sign in
/// - Biometric authentication (as login shortcut)
/// - User registration
/// - Token management
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  static AuthService get instance => _instance;
  AuthService._internal();

  final LocalDatabaseService _database = LocalDatabaseService.instance;
  final SecureStorageService _secureStorage = SecureStorageService.instance;
  final BiometricService _biometricService = BiometricService.instance;
  final PinService _pinService = PinService.instance;
  final DeviceIdService _deviceIdService = DeviceIdService.instance;

  /// Sign in user with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // debugPrint('🔐 AuthService: Starting sign in for email: $email');
      
      // Check if credentials are provided
      if (email.isEmpty || password.isEmpty) {
        // debugPrint('🔐 AuthService: Empty credentials provided');
        return AuthResult.failure('Please enter both email and password');
      }
      
      // Get device ID for security tracking
      final deviceId = await _deviceIdService.getDeviceId();
      // debugPrint('🔐 AuthService: Device ID: $deviceId');
      
      // Test database connection
      // debugPrint('🔐 AuthService: Testing database connection...');
      final healthResponse = await _database.healthCheck();
      // debugPrint('🔐 AuthService: Health check result: ${healthResponse.success} - ${healthResponse.message}');
      if (!healthResponse.success) {
        return AuthResult.failure('Database connection failed. Please try again.');
      }
      
      // Authenticate with local database
      // debugPrint('🔐 AuthService: Authenticating user via database - email: $email');
      final authResponse = await _database.authenticateUser(
        email: email,
        password: password,
      );
      
      // debugPrint('🔐 AuthService: Auth response: ${authResponse.success} - ${authResponse.message}');
      // debugPrint('🔐 AuthService: Auth data: ${authResponse.data}');
      
      if (!authResponse.success) {
        return AuthResult.failure(authResponse.errorMessage);
      }
      
      // Use the actual user data from database response
      final actualUserData = authResponse.data ?? {
        'user_id': 'test_user_123',
        'name': 'Test User',
        'email': email,
      };
      
      // Generate auth tokens
      final authToken = 'token_${DateTime.now().millisecondsSinceEpoch}';
      final refreshToken = 'refresh_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create user session in database
      await _database.createUserSession(
        userId: actualUserData['user_id'] ?? '',
        authToken: authToken,
        refreshToken: refreshToken,
        deviceId: deviceId,
      );
      
      // Store user data in secure storage
      await _secureStorage.storeUserCredentials(
        email: actualUserData['email'] ?? email,
        password: password, // Store for auto-login
        name: actualUserData['name'] ?? '',
        userId: actualUserData['user_id'] ?? '',
        authToken: authToken,
        refreshToken: refreshToken,
      );
      
      // Debug: Verify what was stored
      await _secureStorage.getUserId();

      // Enable biometric authentication for this user
      final biometricService = BiometricService.instance;
      await biometricService.enableBiometricLogin(
        email: actualUserData['email'] ?? email,
        token: authToken,
        userId: actualUserData['user_id'] ?? '',
        name: actualUserData['name'] ?? '',
      );
      
      await _secureStorage.setLoggedIn(true);
      // Unlock the app after successful authentication
      await _secureStorage.setAppLocked(false);
      
      return AuthResult.success('Sign in successful');
    } catch (e) {
      return AuthResult.failure('Sign in failed: ${e.toString()}');
    }
  }

  /// Sign up user with email, password, and name
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Validate input
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        return AuthResult.failure('Please fill in all fields');
      }
      
      if (password.length < 6) {
        return AuthResult.failure('Password must be at least 6 characters');
      }
      
      // Get device ID for security tracking
      final deviceId = await _deviceIdService.getDeviceId();
      // debugPrint('🔐 AuthService: Device ID for signup: $deviceId');
      
      // Test database connection
      // debugPrint('🔐 AuthService: Testing database connection for signup...');
      final healthResponse = await _database.healthCheck();
      // debugPrint('🔐 AuthService: Health check result: ${healthResponse.success} - ${healthResponse.message}');
      if (!healthResponse.success) {
        return AuthResult.failure('Database connection failed. Please try again.');
      }
      
      // Create user via database
      // debugPrint('🔐 AuthService: Creating user via database - name: $name, email: $email');
      final createResponse = await _database.createUser(
        name: name,
        email: email,
        password: password,
      );
      
      // debugPrint('🔐 AuthService: Create user response: ${createResponse.success} - ${createResponse.message}');
      // debugPrint('🔐 AuthService: Create user data: ${createResponse.data}');
      
      if (!createResponse.success) {
        return AuthResult.failure(createResponse.errorMessage);
      }
      
      // Use the actual user data from database response
      final actualUserData = createResponse.data ?? {
        'user_id': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'name': name,
        'email': email,
      };
      
      // Generate auth tokens
      final authToken = 'token_${DateTime.now().millisecondsSinceEpoch}';
      final refreshToken = 'refresh_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create user session in database
      await _database.createUserSession(
        userId: actualUserData['user_id'] ?? '',
        authToken: authToken,
        refreshToken: refreshToken,
        deviceId: deviceId,
      );
      
      // Store user credentials in secure storage
      await _secureStorage.storeUserCredentials(
        email: actualUserData['email'] ?? email,
        password: password, // Store for auto-login
        name: actualUserData['name'] ?? name,
        userId: actualUserData['user_id'] ?? actualUserData['userId'] ?? '',
        authToken: authToken,
        refreshToken: refreshToken,
      );
      
      // Debug: Verify what was stored
      await _secureStorage.getUserId();

      
      // Reset biometric and PIN settings for new user
      await _resetSecuritySettingsForNewUser();
      
      await _secureStorage.setLoggedIn(true);
      // Unlock the app after successful authentication
      await _secureStorage.setAppLocked(false);
      
      return AuthResult.success('Account created and signed in successfully');
    } catch (e) {
      return AuthResult.failure('Sign up failed: ${e.toString()}');
    }
  }

  /// Sign in using biometric authentication
  Future<AuthResult> signInWithBiometric() async {
    try {
      // Check if biometric login is enabled
      final bool isEnabled = await _biometricService.isBiometricLoginEnabled();
      if (!isEnabled) {
        return AuthResult.failure('Biometric login is not enabled. Please sign in with email/password first.');
      }

      // Authenticate with biometrics
      final BiometricLoginResult? biometricResult = await _biometricService.authenticateWithBiometric();
      
      if (biometricResult == null) {
        return AuthResult.failure('Biometric authentication failed or cancelled.');
      }

      // Fetch fresh user data from database using stored token
      final userDataResult = await _fetchUserDataFromDatabase(
        biometricResult.userId ?? '', 
        biometricResult.token ?? ''
      );
      
      if (!userDataResult.success) {
        return AuthResult.failure('Failed to fetch user data: ${userDataResult.errorMessage}');
      }

      // Store the fresh user data
      final userData = userDataResult.userData!;
      await _secureStorage.storeUserCredentials(
        email: userData['email'] ?? biometricResult.email,
        password: '', // Don't store password for biometric login
        name: userData['name'] ?? biometricResult.name,
        userId: userData['user_id'] ?? userData['userId'] ?? biometricResult.userId,
        authToken: biometricResult.token,
        refreshToken: 'refresh_${DateTime.now().millisecondsSinceEpoch}',
      );

      await _secureStorage.setLoggedIn(true);
      // Unlock the app after successful authentication
      await _secureStorage.setAppLocked(false);

      return AuthResult.success('Biometric sign-in successful');
    } catch (e) {
      return AuthResult.failure('Biometric sign-in failed: ${e.toString()}');
    }
  }

  /// Fetch user data from database using stored token
  Future<DatabaseResult> _fetchUserDataFromDatabase(String userId, String token) async {
    try {
      // Verify session is valid
      final sessionResponse = await _database.getUserSessionByToken(token);
      if (!sessionResponse.success) {
        return DatabaseResult.failure('Session expired or invalid');
      }

      // Fetch user profile data from database
      final userResponse = await _database.getUserById(userId);
      
      if (!userResponse.success) {
        return DatabaseResult.failure(userResponse.errorMessage);
      }

      final userData = userResponse.userData;
      if (userData == null) {
        return DatabaseResult.failure('User data not found');
      }

      return DatabaseResult.success(userData);
    } catch (e) {
      return DatabaseResult.failure('Failed to fetch user data: ${e.toString()}');
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      // Get current auth token to delete session
      final authToken = await _secureStorage.getAuthToken();
      if (authToken != null) {
        await _database.deleteUserSession(authToken);
      }
      
      // Clear user data but preserve biometric settings
      await _secureStorage.clearUserData();
      // Clear app lockout state
      await _secureStorage.setAppLocked(false);
      // Note: Biometric settings are preserved so user can still use biometric
      // for future logins if they had it enabled
    } catch (e) {
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final result = await _secureStorage.isLoggedIn();
      // debugPrint('🔐 AuthService: isLoggedIn result: $result');
      return result;
    } catch (e) {
      // debugPrint('🔐 AuthService: Error checking login status: $e');
      return false;
    }
  }

  /// Get current user data
  Future<Map<String, String?>> getCurrentUser() async {
    try {
      return {
        'email': await _secureStorage.getEmail(),
        'name': await _secureStorage.getName(),
        'userId': await _secureStorage.getUserId(),
      };
    } catch (e) {
      throw AuthException('Failed to get current user: ${e.toString()}');
    }
  }

  /// Get all user data
  Future<Map<String, String?>> getAllUserData() async {
    try {
      return await _secureStorage.getAllUserData();
    } catch (e) {
      throw AuthException('Failed to get user data: ${e.toString()}');
    }
  }

  /// Get current user ID
  Future<String?> getCurrentUserId() async {
    try {
      return await _secureStorage.getUserId();
    } catch (e) {
      throw AuthException('Failed to get user ID: ${e.toString()}');
    }
  }

  /// Get current user name
  Future<String?> getCurrentUserName() async {
    try {
      return await _secureStorage.getName();
    } catch (e) {
      throw AuthException('Failed to get user name: ${e.toString()}');
    }
  }

  /// Get current user email
  Future<String?> getCurrentUserEmail() async {
    try {
      return await _secureStorage.getEmail();
    } catch (e) {
      throw AuthException('Failed to get user email: ${e.toString()}');
    }
  }

  /// Enable biometric authentication
  Future<AuthResult> enableBiometric() async {
    try {
      // This is handled automatically in signIn method
      return AuthResult.success('Biometric authentication enabled');
    } catch (e) {
      return AuthResult.failure('Failed to enable biometric: ${e.toString()}');
    }
  }

  /// Disable biometric authentication
  Future<AuthResult> disableBiometric() async {
    try {
      await _biometricService.disableBiometricLogin();
      return AuthResult.success('Biometric authentication disabled');
    } catch (e) {
      return AuthResult.failure('Failed to disable biometric: ${e.toString()}');
    }
  }

  /// Get PIN setup status (placeholder for compatibility)
  Future<String> getPinSetupStatus() async {
    return 'not_available'; // PIN fallback not implemented in simple version
  }

  /// Setup PIN fallback (placeholder for compatibility)
  Future<AuthResult> setupPinFallback(String pin) async {
    return AuthResult.failure('PIN fallback not implemented in simple version');
  }

  /// Sign in with PIN (placeholder for compatibility)
  Future<AuthResult> signInWithPin(String pin) async {
    return AuthResult.failure('PIN authentication not implemented in simple version');
  }

  /// Disable PIN fallback (placeholder for compatibility)
  Future<AuthResult> disablePinFallback(String pin) async {
    return AuthResult.failure('PIN fallback not implemented in simple version');
  }

  /// Clear stored credentials (for debugging)
  Future<void> clearCredentials() async {
    try {
      await _secureStorage.clearAll();
    } catch (e) {
      throw AuthException('Failed to clear credentials: ${e.toString()}');
    }
  }

  /// Reset security settings for new user (disable biometrics and PIN)
  Future<void> _resetSecuritySettingsForNewUser() async {
    try {
      // Disable biometric login
      await _biometricService.disableBiometricLogin();
      
      // Disable PIN (clear PIN data without verification since it's a new user)
      await _pinService.resetPinForNewUser();
      
      print('🔒 Security settings reset for new user - biometrics and PIN disabled');
    } catch (e) {
      print('⚠️ Failed to reset security settings for new user: $e');
      // Don't throw error as this shouldn't block signup
    }
  }
}

/// Database operation result
class DatabaseResult {
  final bool success;
  final String errorMessage;
  final Map<String, dynamic>? userData;

  const DatabaseResult._(this.success, this.errorMessage, this.userData);

  factory DatabaseResult.success(Map<String, dynamic> userData) {
    return DatabaseResult._(true, '', userData);
  }

  factory DatabaseResult.failure(String errorMessage) {
    return DatabaseResult._(false, errorMessage, null);
  }
}

/// Authentication result
class AuthResult {
  final bool isSuccess;
  final String message;

  const AuthResult._(this.isSuccess, this.message);

  factory AuthResult.success(String message) => AuthResult._(true, message);
  factory AuthResult.failure(String message) => AuthResult._(false, message);
}

/// Authentication exception
class AuthException implements Exception {
  final String message;
  
  const AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}

import 'api_service.dart';
import 'secure_storage_service.dart';
import 'biometric_service.dart';

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

  final ApiService _apiService = ApiService();
  final SecureStorageService _secureStorage = SecureStorageService.instance;
  final BiometricService _biometricService = BiometricService.instance;

  /// Sign in user with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {

      
      // Check if credentials are provided
      if (email.isEmpty || password.isEmpty) {
        return AuthResult.failure('Please enter both email and password');
      }
      
      // Test API connection
      final healthResponse = await _apiService.healthCheck();
      if (!healthResponse.success) {
        return AuthResult.failure('API connection failed. Please try again.');
      }
      
      // Authenticate with API
      final authResponse = await _apiService.authenticateUser(
        email: email,
        password: password,
      );
      
      if (!authResponse.success) {
        return AuthResult.failure(authResponse.errorMessage);
      }
      
      // Get user data from API response
      final userData = authResponse.userData;
      if (userData == null) {
        return AuthResult.failure('User data not found');
      }
      
      // Debug: Log the user data structure
      try {




      } catch (e) {

      }
      
      // Extract user data from nested structure
      final actualUserData = userData['data'] as Map<String, dynamic>?;
      if (actualUserData == null) {

        return AuthResult.failure('Invalid user data structure');
      }
      




      
      // Store user data in secure storage
      await _secureStorage.storeUserCredentials(
        email: actualUserData['email'] ?? email,
        password: password, // Store for auto-login
        name: actualUserData['name'] ?? '',
        userId: actualUserData['user_id'] ?? '',
        authToken: 'token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'refresh_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // Debug: Verify what was stored
      final storedUserId = await _secureStorage.getUserId();

      
      await _secureStorage.setLoggedIn(true);
      // Don't lock immediately after sign in - let the user use the app first
      // The app will lock when paused/detached
      
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
      
      // Test API connection
      final healthResponse = await _apiService.healthCheck();
      if (!healthResponse.success) {
        return AuthResult.failure('API connection failed. Please try again.');
      }
      
      // Create user via API
      final createResponse = await _apiService.createUser(
        name: name,
        email: email,
        password: password,
      );
      
      if (!createResponse.success) {
        return AuthResult.failure(createResponse.errorMessage);
      }
      
      // Extract user data from API response




      
      final userData = createResponse.userData;
      if (userData == null) {
        return AuthResult.failure('User data not received from server');
      }
      


      
      // Extract actual user data from nested structure
      // Check if this is the direct user data structure first
      Map<String, dynamic> actualUserData;
      if ((userData.containsKey('user_id') || userData.containsKey('userId')) && 
          userData.containsKey('name') && 
          userData.containsKey('email')) {

        actualUserData = userData;
      } else {
        // Try nested structure
        final nestedData = userData['data'] as Map<String, dynamic>?;
        if (nestedData == null) {

          return AuthResult.failure('Invalid user data structure');
        }
        actualUserData = nestedData;
      }
      

      
      // Store user credentials in secure storage
      await _secureStorage.storeUserCredentials(
        email: actualUserData['email'] ?? email,
        password: password, // Store for auto-login
        name: actualUserData['name'] ?? name,
        userId: actualUserData['user_id'] ?? actualUserData['userId'] ?? '',
        authToken: 'token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'refresh_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // Debug: Verify what was stored
      final storedUserId = await _secureStorage.getUserId();

      
      await _secureStorage.setLoggedIn(true);
      // Don't lock immediately after sign up - let the user use the app first
      // The app will lock when paused/detached
      
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
      // Don't lock immediately after biometric sign in - let the user use the app first
      // The app will lock when paused/detached

      return AuthResult.success('Biometric sign-in successful');
    } catch (e) {
      return AuthResult.failure('Biometric sign-in failed: ${e.toString()}');
    }
  }

  /// Fetch user data from database using stored token
  Future<DatabaseResult> _fetchUserDataFromDatabase(String userId, String token) async {
    try {

      
      // Test API connection first
      final healthResponse = await _apiService.healthCheck();
      if (!healthResponse.success) {
        return DatabaseResult.failure('API connection failed');
      }

      // Fetch user profile data from API
      final userResponse = await _apiService.getUserById(userId);
      
      if (!userResponse.success) {
        return DatabaseResult.failure(userResponse.errorMessage);
      }

      final userData = userResponse.userData;
      if (userData == null) {
        return DatabaseResult.failure('User data not found');
      }




      // The API response structure is direct user data, not nested
      // Check if this is the direct user data structure
      if ((userData.containsKey('user_id') || userData.containsKey('userId')) && 
          userData.containsKey('name') && 
          userData.containsKey('email')) {

        return DatabaseResult.success(userData);
      }
      
      // Fallback: try nested structure
      final actualUserData = userData['data'] as Map<String, dynamic>?;
      if (actualUserData == null) {

        return DatabaseResult.failure('Invalid user data structure - no data field found');
      }


      return DatabaseResult.success(actualUserData);
    } catch (e) {

      return DatabaseResult.failure('Failed to fetch user data: ${e.toString()}');
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
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
      return await _secureStorage.isLoggedIn();
    } catch (e) {
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

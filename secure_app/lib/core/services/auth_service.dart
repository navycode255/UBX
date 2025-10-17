import 'secure_storage_service.dart';
import '../../modules/auth/data/user_repository.dart';
import 'database_service.dart';
import 'user_service.dart';
import 'biometric_service.dart';

/// Authentication Service
/// This service handles user authentication operations and integrates with secure storage and database
class AuthService {
  // Private constructor to prevent instantiation
  AuthService._();
  
  // Singleton instance
  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  // Services
  final SecureStorageService _secureStorage = SecureStorageService.instance;
  final UserRepository _userRepository = UserRepository();
  final DatabaseService _database = DatabaseService.instance;
  final UserService _userService = UserService.instance;
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
      
      // Test database connection
      final isConnected = await _database.testConnection();
      if (!isConnected) {
        return AuthResult.failure('Database connection failed. Please try again.');
      }
      
      // Verify password against database
      final isValidPassword = await _userRepository.verifyPassword(email, password);
      if (!isValidPassword) {
        return AuthResult.failure('Invalid email or password');
      }
      
      // Get user data
      final user = await _userRepository.findByEmail(email);
      if (user == null) {
        return AuthResult.failure('User not found');
      }
      
      // Update last login
      await _userRepository.updateLastLogin(user.userId);
      
      // Store user data in secure storage
      await _secureStorage.storeUserCredentials(
        email: user.email,
        password: password, // Store for auto-login
        name: user.name,
        userId: user.userId,
        authToken: 'token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'refresh_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      await _secureStorage.setLoggedIn(true);
      
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
      
      // Test database connection
      final isConnected = await _database.testConnection();
      if (!isConnected) {
        return AuthResult.failure('Database connection failed. Please try again.');
      }
      
      // Check if user already exists
      final emailExists = await _userRepository.emailExists(email);
      if (emailExists) {
        return AuthResult.failure('An account with this email already exists');
      }
      
      // Create new user in database
      final userId = await _userRepository.createUser(
        name: name,
        email: email,
        password: password,
      );
      
      // Create user profile
      await _userService.ensureUserProfile(userId);
      
      // Store user credentials in secure storage
      await _secureStorage.storeUserCredentials(
        email: email,
        password: password,
        name: name,
        userId: userId,
        authToken: 'token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'refresh_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      await _secureStorage.setLoggedIn(true);
      
      return AuthResult.success('Account created successfully');
    } catch (e) {
      return AuthResult.failure('Sign up failed: ${e.toString()}');
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      await _secureStorage.clearUserData();
    } catch (e) {
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }

  /// Check if user is currently logged in
  Future<bool> isLoggedIn() async {
    try {
      return await _secureStorage.isLoggedIn();
    } catch (e) {
      return false;
    }
  }

  /// Get current user's email
  Future<String?> getCurrentUserEmail() async {
    try {
      return await _secureStorage.getEmail();
    } catch (e) {
      return null;
    }
  }

  /// Get current user's name
  Future<String?> getCurrentUserName() async {
    try {
      return await _secureStorage.getName();
    } catch (e) {
      return null;
    }
  }

  /// Get current user's ID
  Future<String?> getCurrentUserId() async {
    try {
      return await _secureStorage.getUserId();
    } catch (e) {
      return null;
    }
  }

  /// Get stored credentials for auto-login
  Future<StoredCredentials?> getStoredCredentials() async {
    try {
      final hasCredentials = await _secureStorage.hasStoredCredentials();
      if (!hasCredentials) return null;

      final email = await _secureStorage.getEmail();
      final password = await _secureStorage.getPassword();
      final name = await _secureStorage.getName();

      if (email != null && password != null) {
        return StoredCredentials(
          email: email,
          password: password,
          name: name,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Auto-login with stored credentials
  Future<AuthResult> autoLogin() async {
    try {
      final credentials = await getStoredCredentials();
      if (credentials == null) {
        return AuthResult.failure('No stored credentials found');
      }

      return await signIn(
        email: credentials.email,
        password: credentials.password,
      );
    } catch (e) {
      return AuthResult.failure('Auto-login failed: ${e.toString()}');
    }
  }

  /// Refresh authentication token
  Future<AuthResult> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        return AuthResult.failure('No refresh token available');
      }

      // TODO: Implement actual token refresh with your backend API
      // For now, we'll simulate a successful refresh
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Generate new tokens
      final newAuthToken = 'token_${DateTime.now().millisecondsSinceEpoch}';
      final newRefreshToken = 'refresh_${DateTime.now().millisecondsSinceEpoch}';
      
      await _secureStorage.storeAuthToken(newAuthToken);
      await _secureStorage.storeRefreshToken(newRefreshToken);
      
      return AuthResult.success('Token refreshed successfully');
    } catch (e) {
      return AuthResult.failure('Token refresh failed: ${e.toString()}');
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

  /// Sign in using biometric authentication
  Future<AuthResult> signInWithBiometric() async {
    try {
      // Check if biometric is available and enabled
      final setupStatus = await _biometricService.getBiometricSetupStatus();
      
      if (setupStatus == BiometricSetupStatus.notAvailable) {
        return AuthResult.failure('Biometric authentication is not available on this device');
      }
      
      if (setupStatus == BiometricSetupStatus.availableButNotEnabled) {
        return AuthResult.failure('Biometric authentication is not enabled. Please enable it in settings.');
      }
      
      if (setupStatus == BiometricSetupStatus.enabledButNoCredentials) {
        return AuthResult.failure('No stored credentials found. Please sign in with email and password first.');
      }

      // Authenticate with biometric and get credentials
      final biometricResult = await _biometricService.authenticateAndGetCredentials();
      
      if (!biometricResult.isSuccess) {
        return AuthResult.failure(biometricResult.message);
      }

      // Use the retrieved credentials to sign in
      return await signIn(
        email: biometricResult.credentials!.email,
        password: biometricResult.credentials!.password,
      );
    } catch (e) {
      return AuthResult.failure('Biometric sign in failed: ${e.toString()}');
    }
  }

  /// Enable biometric authentication
  Future<AuthResult> enableBiometric() async {
    try {
      final success = await _biometricService.enableBiometric();
      
      if (success) {
        return AuthResult.success('Biometric authentication enabled successfully');
      } else {
        return AuthResult.failure('Failed to enable biometric authentication');
      }
    } catch (e) {
      return AuthResult.failure('Enable biometric failed: ${e.toString()}');
    }
  }

  /// Disable biometric authentication
  Future<AuthResult> disableBiometric() async {
    try {
      final success = await _biometricService.disableBiometric();
      
      if (success) {
        return AuthResult.success('Biometric authentication disabled successfully');
      } else {
        return AuthResult.failure('Failed to disable biometric authentication');
      }
    } catch (e) {
      return AuthResult.failure('Disable biometric failed: ${e.toString()}');
    }
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      return await _biometricService.isBiometricAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      return await _biometricService.isBiometricEnabled();
    } catch (e) {
      return false;
    }
  }

  /// Get biometric setup status
  Future<BiometricSetupStatus> getBiometricSetupStatus() async {
    try {
      return await _biometricService.getBiometricSetupStatus();
    } catch (e) {
      return BiometricSetupStatus.error;
    }
  }

  /// Get primary biometric type for display
  Future<String> getPrimaryBiometricType() async {
    try {
      return await _biometricService.getPrimaryBiometricType();
    } catch (e) {
      return 'Biometric';
    }
  }
}

/// Authentication result class
class AuthResult {
  final bool isSuccess;
  final String message;

  const AuthResult._(this.isSuccess, this.message);

  factory AuthResult.success(String message) => AuthResult._(true, message);
  factory AuthResult.failure(String message) => AuthResult._(false, message);
}


/// Custom exception for authentication operations
class AuthException implements Exception {
  final String message;
  
  const AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}

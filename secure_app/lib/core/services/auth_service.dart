import 'secure_storage_service.dart';

/// Authentication Service
/// This service handles user authentication operations and integrates with secure storage
class AuthService {
  // Private constructor to prevent instantiation
  AuthService._();
  
  // Singleton instance
  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  // Secure storage service instance
  final SecureStorageService _secureStorage = SecureStorageService.instance;

  /// Sign in user with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // TODO: Implement actual authentication with your backend API
      // For now, we'll simulate authentication by checking stored credentials
      
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if credentials are provided
      if (email.isEmpty || password.isEmpty) {
        return AuthResult.failure('Please enter both email and password');
      }
      
      // Check if user has stored credentials (simulating user registration)
      final hasStoredCredentials = await _secureStorage.hasStoredCredentials();
      
      if (hasStoredCredentials) {
        // Get stored credentials for validation
        final storedEmail = await _secureStorage.getEmail();
        final storedPassword = await _secureStorage.getPassword();
        
        // Validate credentials
        if (storedEmail == email && storedPassword == password) {
          // Update login status and tokens
          await _secureStorage.setLoggedIn(true);
          await _secureStorage.storeAuthToken('token_${DateTime.now().millisecondsSinceEpoch}');
          await _secureStorage.storeRefreshToken('refresh_${DateTime.now().millisecondsSinceEpoch}');
          
          return AuthResult.success('Sign in successful');
        } else {
          return AuthResult.failure('Invalid email or password');
        }
      } else {
        // No stored credentials - user needs to sign up first
        return AuthResult.failure('No account found. Please sign up first.');
      }
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
      // TODO: Implement actual registration with your backend API
      // For now, we'll simulate registration by storing credentials
      
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Validate input
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        return AuthResult.failure('Please fill in all fields');
      }
      
      // Check if user already exists
      final hasExistingCredentials = await _secureStorage.hasStoredCredentials();
      if (hasExistingCredentials) {
        final storedEmail = await _secureStorage.getEmail();
        if (storedEmail == email) {
          return AuthResult.failure('An account with this email already exists');
        }
      }
      
      // Store new user credentials securely
      await _secureStorage.storeUserCredentials(
        email: email,
        password: password,
        name: name,
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        authToken: 'token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'refresh_${DateTime.now().millisecondsSinceEpoch}',
      );
      
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
}

/// Authentication result class
class AuthResult {
  final bool isSuccess;
  final String message;

  const AuthResult._(this.isSuccess, this.message);

  factory AuthResult.success(String message) => AuthResult._(true, message);
  factory AuthResult.failure(String message) => AuthResult._(false, message);
}

/// Stored credentials class
class StoredCredentials {
  final String email;
  final String password;
  final String? name;

  const StoredCredentials({
    required this.email,
    required this.password,
    this.name,
  });
}

/// Custom exception for authentication operations
class AuthException implements Exception {
  final String message;
  
  const AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// This service handles secure storage of sensitive user data using Flutter Secure Storage
/// which encrypts data using platform-specific secure storage mechanisms
class SecureStorageService {
  // Private constructor to prevent instantiation
  SecureStorageService._();
  
  // Singleton instance
  static final SecureStorageService _instance = SecureStorageService._();
  static SecureStorageService get instance => _instance;

  // Flutter Secure Storage instance with custom options
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const String _emailKey = 'user_email';
  static const String _passwordKey = 'user_password';
  static const String _nameKey = 'user_name';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _appLockedKey = 'app_locked';

  /// Store user email securely
  Future<void> storeEmail(String email) async {
    try {
      await _storage.write(key: _emailKey, value: email);
    } catch (e) {
      throw SecureStorageException('Failed to store email: $e');
    }
  }

  /// Retrieve user email
  Future<String?> getEmail() async {
    try {
      return await _storage.read(key: _emailKey);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve email: $e');
    }
  }

  /// Store user password securely
  Future<void> storePassword(String password) async {
    try {
      await _storage.write(key: _passwordKey, value: password);
    } catch (e) {
      throw SecureStorageException('Failed to store password: $e');
    }
  }

  /// Retrieve user password
  Future<String?> getPassword() async {
    try {
      return await _storage.read(key: _passwordKey);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve password: $e');
    }
  }

  /// Store user name securely
  Future<void> storeName(String name) async {
    try {
      await _storage.write(key: _nameKey, value: name);
    } catch (e) {
      throw SecureStorageException('Failed to store name: $e');
    }
  }

  /// Retrieve user name
  Future<String?> getName() async {
    try {
      return await _storage.read(key: _nameKey);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve name: $e');
    }
  }

  /// Store authentication token
  Future<void> storeAuthToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      throw SecureStorageException('Failed to store auth token: $e');
    }
  }

  /// Retrieve authentication token
  Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve auth token: $e');
    }
  }

  /// Store refresh token
  Future<void> storeRefreshToken(String refreshToken) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (e) {
      throw SecureStorageException('Failed to store refresh token: $e');
    }
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve refresh token: $e');
    }
  }

  /// Store user ID
  Future<void> storeUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
    } catch (e) {
      throw SecureStorageException('Failed to store user ID: $e');
    }
  }

  /// Retrieve user ID
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve user ID: $e');
    }
  }

  /// Set login status
  Future<void> setLoggedIn(bool isLoggedIn) async {
    try {
      await _storage.write(key: _isLoggedInKey, value: isLoggedIn.toString());
    } catch (e) {
      throw SecureStorageException('Failed to set login status: $e');
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final value = await _storage.read(key: _isLoggedInKey);
      return value == 'true';
    } catch (e) {
      throw SecureStorageException('Failed to check login status: $e');
    }
  }

  /// Store complete user credentials
  Future<void> storeUserCredentials({
    required String email,
    required String password,
    String? name,
    String? userId,
    String? authToken,
    String? refreshToken,
  }) async {
    try {
      await Future.wait([
        storeEmail(email),
        storePassword(password),
        if (name != null) storeName(name),
        if (userId != null) storeUserId(userId),
        if (authToken != null) storeAuthToken(authToken),
        if (refreshToken != null) storeRefreshToken(refreshToken),
        setLoggedIn(true),
      ]);
    } catch (e) {
      throw SecureStorageException('Failed to store user credentials: $e');
    }
  }

  /// Clear all stored data (logout)
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw SecureStorageException('Failed to clear storage: $e');
    }
  }

  /// Clear specific user data (but preserve biometric settings)
  Future<void> clearUserData() async {
    try {
      await Future.wait([
        _storage.delete(key: _emailKey),
        _storage.delete(key: _passwordKey),
        _storage.delete(key: _nameKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _tokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _isLoggedInKey),
        // Note: We intentionally keep _biometricEnabledKey to preserve biometric settings
      ]);
    } catch (e) {
      throw SecureStorageException('Failed to clear user data: $e');
    }
  }

  /// Check if user has stored credentials
  Future<bool> hasStoredCredentials() async {
    try {
      final email = await getEmail();
      final password = await getPassword();
      return email != null && password != null;
    } catch (e) {
      return false;
    }
  }

  /// Set biometric authentication enabled status
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
    } catch (e) {
      throw SecureStorageException('Failed to set biometric enabled status: $e');
    }
  }

  /// Get biometric authentication enabled status
  Future<bool?> getBiometricEnabled() async {
    try {
      final value = await _storage.read(key: _biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      throw SecureStorageException('Failed to get biometric enabled status: $e');
    }
  }

  /// Get stored credentials for biometric authentication
  Future<StoredCredentials?> getStoredCredentials() async {
    try {
      final email = await getEmail();
      final password = await getPassword();
      final name = await getName();

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

  /// Store boolean value securely
  Future<void> setBool(String key, bool value) async {
    try {
      await _storage.write(key: key, value: value.toString());
    } catch (e) {
      throw SecureStorageException('Failed to store boolean: $e');
    }
  }

  /// Retrieve boolean value
  Future<bool?> getBool(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value == null) return null;
      return value.toLowerCase() == 'true';
    } catch (e) {
      throw SecureStorageException('Failed to retrieve boolean: $e');
    }
  }

  /// Store string value securely
  Future<void> setString(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw SecureStorageException('Failed to store string: $e');
    }
  }

  /// Retrieve string value
  Future<String?> getString(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve string: $e');
    }
  }

  /// Delete a specific key
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to delete key: $e');
    }
  }

  /// Set app locked status
  Future<void> setAppLocked(bool isLocked) async {
    try {
      await _storage.write(key: _appLockedKey, value: isLocked.toString());
    } catch (e) {
      throw SecureStorageException('Failed to set app locked status: $e');
    }
  }

  /// Check if app is locked
  Future<bool> isAppLocked() async {
    try {
      final value = await _storage.read(key: _appLockedKey);
      return value == 'true';
    } catch (e) {
      throw SecureStorageException('Failed to check app locked status: $e');
    }
  }

  /// Get all stored user data
  Future<Map<String, String?>> getAllUserData() async {
    try {
      return {
        'email': await getEmail(),
        'password': await getPassword(),
        'name': await getName(),
        'userId': await getUserId(),
        'authToken': await getAuthToken(),
        'refreshToken': await getRefreshToken(),
        'isLoggedIn': (await isLoggedIn()).toString(),
        'biometricEnabled': (await getBiometricEnabled()).toString(),
        'appLocked': (await isAppLocked()).toString(),
      };
    } catch (e) {
      throw SecureStorageException('Failed to retrieve all user data: $e');
    }
  }
}

/// Stored credentials class for biometric authentication
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

/// Custom exception for secure storage operations
class SecureStorageException implements Exception {
  final String message;
  
  const SecureStorageException(this.message);
  
  @override
  String toString() => 'SecureStorageException: $message';
}

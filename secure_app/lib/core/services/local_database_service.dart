import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// Local Database Service using SQLite
/// 
/// Handles all local data storage and retrieval operations
/// Replaces the API service for offline functionality
class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  static LocalDatabaseService get instance => _instance;
  LocalDatabaseService._internal();

  static Database? _database;
  static const String _databaseName = 'secure_app.db';
  static const int _databaseVersion = 2;

  /// Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        phone_number TEXT,
        profile_picture_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // User sessions table
    await db.execute('''
      CREATE TABLE user_sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        auth_token TEXT NOT NULL,
        refresh_token TEXT NOT NULL,
        device_id TEXT,
        created_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // App settings table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_users_email ON users (email)');
    await db.execute('CREATE INDEX idx_sessions_user_id ON user_sessions (user_id)');
    await db.execute('CREATE INDEX idx_sessions_auth_token ON user_sessions (auth_token)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add device_id column to user_sessions table
      await db.execute('ALTER TABLE user_sessions ADD COLUMN device_id TEXT');
    }
  }

  /// Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate unique ID
  String _generateId() {
    return const Uuid().v4();
  }

  /// Health check (always returns success for local database)
  Future<DatabaseResponse> healthCheck() async {
    try {
      final db = await database;
      await db.rawQuery('SELECT 1');
      return DatabaseResponse.success('Database is healthy', {'status': 'ok'});
    } catch (e) {
      return DatabaseResponse.failure('Database health check failed: $e');
    }
  }

  /// Create user
  Future<DatabaseResponse> createUser({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final db = await database;
      final userId = _generateId();
      final passwordHash = _hashPassword(password);
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if user already exists
      final existingUser = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (existingUser.isNotEmpty) {
        return DatabaseResponse.failure('User with this email already exists');
      }

      // Insert new user
      await db.insert('users', {
        'id': userId,
        'name': name,
        'email': email,
        'password_hash': passwordHash,
        'phone_number': phoneNumber,
        'created_at': now,
        'updated_at': now,
      });

      return DatabaseResponse.success('User created successfully', {
        'user_id': userId,
        'name': name,
        'email': email,
        'phone_number': phoneNumber,
      });
    } catch (e) {
      return DatabaseResponse.failure('Failed to create user: $e');
    }
  }

  /// Authenticate user
  Future<DatabaseResponse> authenticateUser({
    required String email,
    required String password,
  }) async {
    try {
      final db = await database;
      final passwordHash = _hashPassword(password);

      final users = await db.query(
        'users',
        where: 'email = ? AND password_hash = ?',
        whereArgs: [email, passwordHash],
      );

      if (users.isEmpty) {
        return DatabaseResponse.failure('Invalid email or password');
      }

      final user = users.first;
      return DatabaseResponse.success('Authentication successful', {
        'user_id': user['id'],
        'name': user['name'],
        'email': user['email'],
        'phone_number': user['phone_number'],
        'profile_picture_path': user['profile_picture_path'],
      });
    } catch (e) {
      return DatabaseResponse.failure('Authentication failed: $e');
    }
  }

  /// Get user by ID
  Future<DatabaseResponse> getUserById(String userId) async {
    try {
      final db = await database;
      final users = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (users.isEmpty) {
        return DatabaseResponse.failure('User not found');
      }

      final user = users.first;
      return DatabaseResponse.success('User found', {
        'user_id': user['id'],
        'name': user['name'],
        'email': user['email'],
        'phone_number': user['phone_number'],
        'profile_picture_path': user['profile_picture_path'],
        'created_at': user['created_at'],
        'updated_at': user['updated_at'],
      });
    } catch (e) {
      return DatabaseResponse.failure('Failed to get user: $e');
    }
  }

  /// Get user by email
  Future<DatabaseResponse> getUserByEmail(String email) async {
    try {
      final db = await database;
      final users = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (users.isEmpty) {
        return DatabaseResponse.failure('User not found');
      }

      final user = users.first;
      return DatabaseResponse.success('User found', {
        'user_id': user['id'],
        'name': user['name'],
        'email': user['email'],
        'phone_number': user['phone_number'],
        'profile_picture_path': user['profile_picture_path'],
        'created_at': user['created_at'],
        'updated_at': user['updated_at'],
      });
    } catch (e) {
      return DatabaseResponse.failure('Failed to get user: $e');
    }
  }

  /// Update user
  Future<DatabaseResponse> updateUser({
    required String userId,
    String? name,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final updateData = <String, dynamic>{
        'updated_at': now,
      };

      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;

      final rowsAffected = await db.update(
        'users',
        updateData,
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (rowsAffected == 0) {
        return DatabaseResponse.failure('User not found');
      }

      return DatabaseResponse.success('User updated successfully', {
        'user_id': userId,
        ...updateData,
      });
    } catch (e) {
      return DatabaseResponse.failure('Failed to update user: $e');
    }
  }

  /// Update profile picture path
  Future<DatabaseResponse> updateProfilePicture({
    required String userId,
    required String imagePath,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final rowsAffected = await db.update(
        'users',
        {
          'profile_picture_path': imagePath,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (rowsAffected == 0) {
        return DatabaseResponse.failure('User not found');
      }

      return DatabaseResponse.success('Profile picture updated successfully', {
        'user_id': userId,
        'profile_picture_path': imagePath,
      });
    } catch (e) {
      return DatabaseResponse.failure('Failed to update profile picture: $e');
    }
  }

  /// Delete user
  Future<DatabaseResponse> deleteUser(String userId) async {
    try {
      final db = await database;

      // Delete user sessions first (due to foreign key constraint)
      await db.delete(
        'user_sessions',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // Delete user
      final rowsAffected = await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (rowsAffected == 0) {
        return DatabaseResponse.failure('User not found');
      }

      return DatabaseResponse.success('User deleted successfully');
    } catch (e) {
      return DatabaseResponse.failure('Failed to delete user: $e');
    }
  }

  /// Create user session
  Future<DatabaseResponse> createUserSession({
    required String userId,
    required String authToken,
    required String refreshToken,
    String? deviceId,
    int? expiresInHours,
  }) async {
    try {
      final db = await database;
      final sessionId = _generateId();
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = now + ((expiresInHours ?? 24) * 60 * 60 * 1000);

      // Delete any existing sessions for this user
      await db.delete(
        'user_sessions',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // Create new session
      await db.insert('user_sessions', {
        'id': sessionId,
        'user_id': userId,
        'auth_token': authToken,
        'refresh_token': refreshToken,
        'device_id': deviceId,
        'created_at': now,
        'expires_at': expiresAt,
      });

      return DatabaseResponse.success('Session created successfully', {
        'session_id': sessionId,
        'user_id': userId,
        'auth_token': authToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt,
      });
    } catch (e) {
      return DatabaseResponse.failure('Failed to create session: $e');
    }
  }

  /// Get user session by auth token
  Future<DatabaseResponse> getUserSessionByToken(String authToken) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final sessions = await db.query(
        'user_sessions',
        where: 'auth_token = ? AND expires_at > ?',
        whereArgs: [authToken, now],
      );

      if (sessions.isEmpty) {
        return DatabaseResponse.failure('Session not found or expired');
      }

      final session = sessions.first;
      return DatabaseResponse.success('Session found', {
        'session_id': session['id'],
        'user_id': session['user_id'],
        'auth_token': session['auth_token'],
        'refresh_token': session['refresh_token'],
        'expires_at': session['expires_at'],
      });
    } catch (e) {
      return DatabaseResponse.failure('Failed to get session: $e');
    }
  }

  /// Delete user session
  Future<DatabaseResponse> deleteUserSession(String authToken) async {
    try {
      final db = await database;

      final rowsAffected = await db.delete(
        'user_sessions',
        where: 'auth_token = ?',
        whereArgs: [authToken],
      );

      if (rowsAffected == 0) {
        return DatabaseResponse.failure('Session not found');
      }

      return DatabaseResponse.success('Session deleted successfully');
    } catch (e) {
      return DatabaseResponse.failure('Failed to delete session: $e');
    }
  }

  /// Get all users (for admin purposes)
  Future<DatabaseResponse> getAllUsers({int limit = 50, int offset = 0}) async {
    try {
      final db = await database;
      final users = await db.query(
        'users',
        limit: limit,
        offset: offset,
        orderBy: 'created_at DESC',
      );

      final userList = users.map((user) => {
        'user_id': user['id'],
        'name': user['name'],
        'email': user['email'],
        'phone_number': user['phone_number'],
        'profile_picture_path': user['profile_picture_path'],
        'created_at': user['created_at'],
        'updated_at': user['updated_at'],
      }).toList();

      return DatabaseResponse.success('Users retrieved successfully', {
        'users': userList,
        'total': userList.length,
      });
    } catch (e) {
      return DatabaseResponse.failure('Failed to get users: $e');
    }
  }

  /// Set app setting
  Future<DatabaseResponse> setAppSetting(String key, String value) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        'app_settings',
        {
          'key': key,
          'value': value,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return DatabaseResponse.success('Setting saved successfully');
    } catch (e) {
      return DatabaseResponse.failure('Failed to save setting: $e');
    }
  }

  /// Get app setting
  Future<DatabaseResponse> getAppSetting(String key) async {
    try {
      final db = await database;
      final settings = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: [key],
      );

      if (settings.isEmpty) {
        return DatabaseResponse.failure('Setting not found');
      }

      return DatabaseResponse.success('Setting found', {
        'key': key,
        'value': settings.first['value'],
      });
    } catch (e) {
      return DatabaseResponse.failure('Failed to get setting: $e');
    }
  }

  /// Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

/// Database response model
class DatabaseResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const DatabaseResponse._(this.success, this.message, this.data);

  factory DatabaseResponse.success(String message, [Map<String, dynamic>? data]) {
    return DatabaseResponse._(true, message, data);
  }

  factory DatabaseResponse.failure(String message) {
    return DatabaseResponse._(false, message, null);
  }

  /// Get data from response
  T? getData<T>(String key) {
    return data?[key] as T?;
  }

  /// Get user data from response
  Map<String, dynamic>? get userData {
    return data;
  }

  /// Get list of users from response
  List<Map<String, dynamic>>? get usersList {
    final users = data?['users'] as List<dynamic>?;
    return users?.cast<Map<String, dynamic>>();
  }

  /// Check if response has error
  bool get hasError => !success;

  /// Get error message
  String get errorMessage => message;
}

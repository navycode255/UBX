import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/database_service.dart';

/// User data model
class User {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? phoneNumber;
  final String passwordHash;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.passwordHash,
    this.isActive = true,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'password_hash': passwordHash,
      'is_active': isActive,
      'is_verified': isVerified,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'last_login_at': lastLoginAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'].toString(),
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phone_number'],
      passwordHash: map['password_hash'] ?? '',
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      isVerified: map['is_verified'] == 1 || map['is_verified'] == true,
      createdAt: DateTime.parse(map['created_at'].toString()),
      updatedAt: DateTime.parse(map['updated_at'].toString()),
      lastLoginAt: map['last_login_at'] != null 
          ? DateTime.parse(map['last_login_at'].toString())
          : null,
    );
  }
}

/// User repository for database operations
class UserRepository {
  final DatabaseService _db = DatabaseService.instance;
  final _uuid = const Uuid();

  /// Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Create a new user
  Future<String> createUser({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    final userId = _uuid.v4();
    final passwordHash = _hashPassword(password);
    final now = DateTime.now();

    final sql = '''
      INSERT INTO users (
        user_id, name, email, phone_number, password_hash, 
        is_active, is_verified, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''';

    final values = [
      userId,
      name,
      email,
      phoneNumber,
      passwordHash,
      true,
      false,
      now,
      now,
    ];

    await _db.insert(sql, values);
    return userId;
  }

  /// Find user by email
  Future<User?> findByEmail(String email) async {
    final sql = 'SELECT * FROM users WHERE email = ? AND is_active = true';
    final result = await _db.queryFirst(sql, [email]);
    
    return result != null ? User.fromMap(result.fields) : null;
  }

  /// Find user by user ID
  Future<User?> findById(String userId) async {
    final sql = 'SELECT * FROM users WHERE user_id = ? AND is_active = true';
    final result = await _db.queryFirst(sql, [userId]);
    
    return result != null ? User.fromMap(result.fields) : null;
  }

  /// Verify user password
  Future<bool> verifyPassword(String email, String password) async {
    final user = await findByEmail(email);
    if (user == null) return false;
    
    final hashedPassword = _hashPassword(password);
    return user.passwordHash == hashedPassword;
  }

  /// Update user last login
  Future<void> updateLastLogin(String userId) async {
    final sql = 'UPDATE users SET last_login_at = ? WHERE user_id = ?';
    await _db.update(sql, [DateTime.now(), userId]);
  }

  /// Update user information
  Future<void> updateUser(String userId, {
    String? name,
    String? phoneNumber,
  }) async {
    final updates = <String>[];
    final values = <Object?>[];

    if (name != null) {
      updates.add('name = ?');
      values.add(name);
    }
    if (phoneNumber != null) {
      updates.add('phone_number = ?');
      values.add(phoneNumber);
    }

    if (updates.isNotEmpty) {
      updates.add('updated_at = ?');
      values.add(DateTime.now());
      values.add(userId);

      final sql = 'UPDATE users SET ${updates.join(', ')} WHERE user_id = ?';
      await _db.update(sql, values);
    }
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    final sql = 'SELECT COUNT(*) as count FROM users WHERE email = ?';
    final result = await _db.queryFirst(sql, [email]);
    return result?.fields['count'] > 0;
  }

  /// Delete user (soft delete)
  Future<void> deleteUser(String userId) async {
    final sql = 'UPDATE users SET is_active = false, updated_at = ? WHERE user_id = ?';
    await _db.update(sql, [DateTime.now(), userId]);
  }

  /// Get all users (for admin purposes)
  Future<List<User>> getAllUsers() async {
    final sql = 'SELECT * FROM users WHERE is_active = true ORDER BY created_at DESC';
    final results = await _db.query(sql);
    
    return results.map((row) => User.fromMap(row.fields)).toList();
  }
}

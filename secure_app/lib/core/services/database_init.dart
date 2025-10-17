import 'database_service.dart';

class DatabaseInit {
  static final DatabaseService _db = DatabaseService.instance;

  /// Initialize database with required tables
  static Future<void> initializeDatabase() async {
    try {
      // Test connection first
      final isConnected = await _db.testConnection();
      if (!isConnected) {
        throw Exception('Cannot connect to database');
      }

      // Create database if it doesn't exist
      await _createDatabase();
      
      // Create tables
      await _createTables();
      
      print('Database initialized successfully');
    } catch (e) {
      print('Database initialization failed: $e');
      rethrow;
    }
  }

  /// Create database if it doesn't exist
  static Future<void> _createDatabase() async {
    final sql = '''
      CREATE DATABASE IF NOT EXISTS secure_app_db
      CHARACTER SET utf8mb4
      COLLATE utf8mb4_unicode_ci
    ''';
    
    await _db.query(sql);
  }

  /// Create all required tables
  static Future<void> _createTables() async {
    // Users table
    await _db.query('''
      CREATE TABLE IF NOT EXISTS users (
        id INT PRIMARY KEY AUTO_INCREMENT,
        user_id VARCHAR(255) UNIQUE NOT NULL,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        phone_number VARCHAR(20),
        password_hash VARCHAR(255) NOT NULL,
        is_active BOOLEAN DEFAULT TRUE,
        is_verified BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        last_login_at TIMESTAMP NULL,
        
        INDEX idx_email (email),
        INDEX idx_user_id (user_id),
        INDEX idx_phone (phone_number)
      )
    ''');

    // User profiles table
    await _db.query('''
      CREATE TABLE IF NOT EXISTS user_profiles (
        id INT PRIMARY KEY AUTO_INCREMENT,
        user_id VARCHAR(255) NOT NULL,
        profile_picture_url VARCHAR(500),
        bio TEXT,
        date_of_birth DATE,
        gender ENUM('male', 'female', 'other', 'prefer_not_to_say'),
        address TEXT,
        city VARCHAR(100),
        country VARCHAR(100),
        timezone VARCHAR(50) DEFAULT 'UTC',
        language VARCHAR(10) DEFAULT 'en',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id)
      )
    ''');

    // Auth tokens table
    await _db.query('''
      CREATE TABLE IF NOT EXISTS auth_tokens (
        id INT PRIMARY KEY AUTO_INCREMENT,
        user_id VARCHAR(255) NOT NULL,
        access_token VARCHAR(500) NOT NULL,
        refresh_token VARCHAR(500) NOT NULL,
        token_type VARCHAR(50) DEFAULT 'Bearer',
        expires_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        is_revoked BOOLEAN DEFAULT FALSE,
        device_id VARCHAR(255),
        device_info TEXT,
        ip_address VARCHAR(45),
        user_agent TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id),
        INDEX idx_access_token (access_token(100)),
        INDEX idx_refresh_token (refresh_token(100)),
        INDEX idx_expires_at (expires_at)
      )
    ''');

    // User sessions table
    await _db.query('''
      CREATE TABLE IF NOT EXISTS user_sessions (
        id INT PRIMARY KEY AUTO_INCREMENT,
        user_id VARCHAR(255) NOT NULL,
        session_id VARCHAR(255) UNIQUE NOT NULL,
        device_id VARCHAR(255),
        device_name VARCHAR(255),
        device_type ENUM('mobile', 'tablet', 'desktop', 'web'),
        os_name VARCHAR(100),
        os_version VARCHAR(50),
        app_version VARCHAR(20),
        is_active BOOLEAN DEFAULT TRUE,
        last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        expires_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id),
        INDEX idx_session_id (session_id),
        INDEX idx_device_id (device_id),
        INDEX idx_last_activity (last_activity_at)
      )
    ''');

    // Working hours table
    await _db.query('''
      CREATE TABLE IF NOT EXISTS working_hours (
        id INT PRIMARY KEY AUTO_INCREMENT,
        user_id VARCHAR(255) NOT NULL,
        day_of_week ENUM('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday') NOT NULL,
        start_time TIME NOT NULL,
        end_time TIME NOT NULL,
        is_working BOOLEAN DEFAULT TRUE,
        break_start_time TIME NULL,
        break_end_time TIME NULL,
        timezone VARCHAR(50) DEFAULT 'UTC',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        UNIQUE KEY unique_user_day (user_id, day_of_week),
        INDEX idx_user_id (user_id)
      )
    ''');

    // Password reset tokens table
    await _db.query('''
      CREATE TABLE IF NOT EXISTS password_reset_tokens (
        id INT PRIMARY KEY AUTO_INCREMENT,
        user_id VARCHAR(255) NOT NULL,
        token VARCHAR(255) UNIQUE NOT NULL,
        expires_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        is_used BOOLEAN DEFAULT FALSE,
        used_at TIMESTAMP NULL,
        ip_address VARCHAR(45),
        user_agent TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id),
        INDEX idx_token (token),
        INDEX idx_expires_at (expires_at)
      )
    ''');

    // Email verification tokens table
    await _db.query('''
      CREATE TABLE IF NOT EXISTS email_verification_tokens (
        id INT PRIMARY KEY AUTO_INCREMENT,
        user_id VARCHAR(255) NOT NULL,
        token VARCHAR(255) UNIQUE NOT NULL,
        expires_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        is_used BOOLEAN DEFAULT FALSE,
        used_at TIMESTAMP NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        INDEX idx_user_id (user_id),
        INDEX idx_token (token),
        INDEX idx_expires_at (expires_at)
      )
    ''');

    // Audit logs table
    await _db.query('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id INT PRIMARY KEY AUTO_INCREMENT,
        user_id VARCHAR(255),
        action VARCHAR(100) NOT NULL,
        resource_type VARCHAR(50),
        resource_id VARCHAR(255),
        old_values JSON,
        new_values JSON,
        ip_address VARCHAR(45),
        user_agent TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        
        INDEX idx_user_id (user_id),
        INDEX idx_action (action),
        INDEX idx_created_at (created_at)
      )
    ''');

    // App settings table
    await _db.query('''
      CREATE TABLE IF NOT EXISTS app_settings (
        id INT PRIMARY KEY AUTO_INCREMENT,
        setting_key VARCHAR(100) UNIQUE NOT NULL,
        setting_value TEXT,
        setting_type ENUM('string', 'number', 'boolean', 'json') DEFAULT 'string',
        description TEXT,
        is_public BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        
        INDEX idx_setting_key (setting_key)
      )
    ''');

    // Insert default app settings
    await _insertDefaultSettings();
  }

  /// Insert default app settings
  static Future<void> _insertDefaultSettings() async {
    // Check if settings already exist
    final existingSettings = await _db.queryFirst('SELECT COUNT(*) as count FROM app_settings');
    if (existingSettings?.fields['count'] > 0) return;

    final settings = [
      ['app_name', 'Secure App', 'string', 'Application name', true],
      ['app_version', '1.0.0', 'string', 'Current app version', true],
      ['maintenance_mode', 'false', 'boolean', 'Maintenance mode status', false],
      ['max_login_attempts', '5', 'number', 'Maximum login attempts before lockout', false],
      ['session_timeout_minutes', '30', 'number', 'Session timeout in minutes', false],
      ['password_min_length', '8', 'number', 'Minimum password length', false],
      ['require_email_verification', 'true', 'boolean', 'Require email verification for new users', false],
    ];

    for (final setting in settings) {
      await _db.query('''
        INSERT INTO app_settings (setting_key, setting_value, setting_type, description, is_public)
        VALUES (?, ?, ?, ?, ?)
      ''', setting);
    }
  }
}

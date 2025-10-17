import 'dart:async';
import 'package:mysql1/mysql1.dart';
import '../config/env_config.dart';
import 'logging_service.dart';

class DatabaseService {
  static DatabaseService? _instance;
  MySqlConnection? _connection;
  
  // Private constructor for singleton pattern
  DatabaseService._();
  
  /// Get singleton instance
  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }
  
  /// Get database connection
  Future<MySqlConnection> get connection async {
    if (_connection == null) {
      await _connect();
    }
    return _connection!;
  }
  
  /// Establish database connection
  Future<void> _connect() async {
    try {
      final settings = ConnectionSettings(
        host: EnvConfig.dbHost,
        port: EnvConfig.dbPort,
        user: EnvConfig.dbUser,
        password: EnvConfig.dbPassword,
        db: EnvConfig.dbName,
        timeout: Duration(seconds: EnvConfig.apiTimeoutSeconds),
      );
      
      _connection = await MySqlConnection.connect(settings);
      
      if (EnvConfig.debugMode) {
        LoggingService.success('Database connected successfully');
      }
    } catch (e) {
      if (EnvConfig.debugMode) {
        LoggingService.error('Database connection failed: $e');
      }
      rethrow;
    }
  }
  
  /// Close database connection
  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
  
  /// Execute a query and return results
  Future<Results> query(String sql, [List<Object?>? values]) async {
    try {
      final conn = await connection;
      return await conn.query(sql, values);
    } catch (e) {
      if (EnvConfig.debugMode) {
        LoggingService.error('Query failed: $e');
        LoggingService.debug('SQL: $sql');
        LoggingService.debug('Values: $values');
      }
      rethrow;
    }
  }
  
  /// Execute a query and return the first result
  Future<ResultRow?> queryFirst(String sql, [List<Object?>? values]) async {
    final results = await query(sql, values);
    return results.isNotEmpty ? results.first : null;
  }
  
  /// Execute an insert query and return the insert ID
  Future<int> insert(String sql, [List<Object?>? values]) async {
    final results = await query(sql, values);
    return results.insertId ?? 0;
  }
  
  /// Execute an update/delete query and return affected rows
  Future<int> update(String sql, [List<Object?>? values]) async {
    final results = await query(sql, values);
    return results.affectedRows ?? 0;
  }
  
  /// Start a transaction
  Future<void> transaction(Future<void> Function(TransactionContext) action) async {
    final conn = await connection;
    await conn.transaction(action);
  }
  
  /// Test database connection
  Future<bool> testConnection() async {
    try {
      await query('SELECT 1');
      return true;
    } catch (e) {
      if (EnvConfig.debugMode) {
        LoggingService.error('Database connection test failed: $e');
      }
      return false;
    }
  }
}

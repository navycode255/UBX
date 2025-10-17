import 'package:dotenv/dotenv.dart';

/// Environment configuration class for managing app settings
class EnvConfig {
  static const String _envFile = '.env';
  static final DotEnv _dotenv = DotEnv();
  
  /// Initialize environment variables
  static Future<void> init() async {
    _dotenv.load([_envFile]);
  }
  
  // Database Configuration
  static String get dbHost => _dotenv['DB_HOST'] ?? 'localhost';
  static int get dbPort => int.tryParse(_dotenv['DB_PORT'] ?? '3306') ?? 3306;
  static String get dbName => _dotenv['DB_NAME'] ?? 'secure_app_db';
  static String get dbUser => _dotenv['DB_USER'] ?? 'root';
  static String get dbPassword => _dotenv['DB_PASSWORD'] ?? '';
  
  // App Configuration
  static String get appName => _dotenv['APP_NAME'] ?? 'Secure App';
  static String get appVersion => _dotenv['APP_VERSION'] ?? '1.0.0';
  static bool get debugMode => _dotenv['DEBUG_MODE']?.toLowerCase() == 'true';
  
  // Security Configuration
  static String get jwtSecret => _dotenv['JWT_SECRET'] ?? 'default-secret-key';
  static String get encryptionKey => _dotenv['ENCRYPTION_KEY'] ?? 'default-32-char-encryption-key-here';
  static int get sessionTimeoutMinutes => int.tryParse(_dotenv['SESSION_TIMEOUT_MINUTES'] ?? '30') ?? 30;
  static int get maxLoginAttempts => int.tryParse(_dotenv['MAX_LOGIN_ATTEMPTS'] ?? '5') ?? 5;
  
  // API Configuration
  static String get apiBaseUrl => _dotenv['API_BASE_URL'] ?? 'http://localhost:3000';
  static int get apiTimeoutSeconds => int.tryParse(_dotenv['API_TIMEOUT_SECONDS'] ?? '30') ?? 30;
  
  /// Get database connection string
  static String get databaseUrl => 'mysql://$dbUser:$dbPassword@$dbHost:$dbPort/$dbName';
  
  /// Validate required environment variables
  static bool validate() {
    final requiredVars = ['DB_HOST', 'DB_NAME', 'DB_USER'];
    for (final varName in requiredVars) {
      if (_dotenv[varName] == null || _dotenv[varName]!.isEmpty) {
        throw Exception('Required environment variable $varName is not set');
      }
    }
    return true;
  }
}

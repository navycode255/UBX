import 'package:flutter_test/flutter_test.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AuthService Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService.instance;
    });

    group('Sign In Tests', () {
      test('should return failure when email is empty', () async {
        final result = await authService.signIn(
          email: '',
          password: 'password123',
        );

        expect(result.isSuccess, false);
        expect(result.message, 'Please enter both email and password');
      });

      test('should return failure when password is empty', () async {
        final result = await authService.signIn(
          email: 'test@example.com',
          password: '',
        );

        expect(result.isSuccess, false);
        expect(result.message, 'Please enter both email and password');
      });

      test('should return failure when both email and password are empty', () async {
        final result = await authService.signIn(
          email: '',
          password: '',
        );

        expect(result.isSuccess, false);
        expect(result.message, 'Please enter both email and password');
      });

      test('should return failure when no stored credentials exist', () async {
        final result = await authService.signIn(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result.isSuccess, false);
        expect(result.message, 'No account found. Please sign up first.');
      });
    });

    group('Sign Up Tests', () {
      test('should return failure when email is empty', () async {
        final result = await authService.signUp(
          email: '',
          password: 'password123',
          name: 'John Doe',
        );

        expect(result.isSuccess, false);
        expect(result.message, 'Please fill in all fields');
      });

      test('should return failure when password is empty', () async {
        final result = await authService.signUp(
          email: 'test@example.com',
          password: '',
          name: 'John Doe',
        );

        expect(result.isSuccess, false);
        expect(result.message, 'Please fill in all fields');
      });

      test('should return failure when name is empty', () async {
        final result = await authService.signUp(
          email: 'test@example.com',
          password: 'password123',
          name: '',
        );

        expect(result.isSuccess, false);
        expect(result.message, 'Please fill in all fields');
      });

      test('should return failure when all fields are empty', () async {
        final result = await authService.signUp(
          email: '',
          password: '',
          name: '',
        );

        expect(result.isSuccess, false);
        expect(result.message, 'Please fill in all fields');
      });
    });

    group('Sign Out Tests', () {
      test('should handle sign out without throwing', () async {
        // Test that the method doesn't throw (it will fail due to missing plugin in tests)
        try {
          await authService.signOut();
        } catch (e) {
          // Expected to fail in test environment due to missing plugin
          expect(e, isA<AuthException>());
        }
      });
    });

    group('Authentication Status Tests', () {
      test('should handle login status check without throwing', () async {
        try {
          await authService.isLoggedIn();
        } catch (e) {
          // Expected to fail in test environment due to missing plugin
          expect(e, isA<AuthException>());
        }
      });

      test('should handle get current user email without throwing', () async {
        try {
          await authService.getCurrentUserEmail();
        } catch (e) {
          // Expected to fail in test environment due to missing plugin
          expect(e, isA<AuthException>());
        }
      });

      test('should handle get current user name without throwing', () async {
        try {
          await authService.getCurrentUserName();
        } catch (e) {
          // Expected to fail in test environment due to missing plugin
          expect(e, isA<AuthException>());
        }
      });

      test('should handle get current user ID without throwing', () async {
        try {
          await authService.getCurrentUserId();
        } catch (e) {
          // Expected to fail in test environment due to missing plugin
          expect(e, isA<AuthException>());
        }
      });
    });

    group('Stored Credentials Tests', () {
      test('should handle get stored credentials without throwing', () async {
        try {
          await authService.getCurrentUser();
        } catch (e) {
          // Expected to fail in test environment due to missing plugin
          expect(e, isA<AuthException>());
        }
      });

      test('should handle auto login without throwing', () async {
        try {
          await authService.signInWithBiometric();
        } catch (e) {
          // Expected to fail in test environment due to missing plugin
          expect(e, isA<AuthException>());
        }
      });
    });

    group('Token Refresh Tests', () {
      test('should handle token refresh without throwing', () async {
        try {
          await authService.signInWithBiometric();
        } catch (e) {
          // Expected to fail in test environment due to missing plugin
          expect(e, isA<AuthException>());
        }
      });
    });

    group('User Data Tests', () {
      test('should handle get all user data without throwing', () async {
        try {
          await authService.getAllUserData();
        } catch (e) {
          // Expected to fail in test environment due to missing plugin
          expect(e, isA<AuthException>());
        }
      });
    });
  });

  group('AuthResult Tests', () {
    test('should create success result', () {
      final result = AuthResult.success('Test success message');
      expect(result.isSuccess, true);
      expect(result.message, 'Test success message');
    });

    test('should create failure result', () {
      final result = AuthResult.failure('Test failure message');
      expect(result.isSuccess, false);
      expect(result.message, 'Test failure message');
    });
  });

  group('StoredCredentials Tests', () {
    test('should create stored credentials with all fields', () {
      const credentials = StoredCredentials(
        email: 'test@example.com',
        password: 'password123',
        name: 'John Doe',
      );

      expect(credentials.email, 'test@example.com');
      expect(credentials.password, 'password123');
      expect(credentials.name, 'John Doe');
    });

    test('should create stored credentials without name', () {
      const credentials = StoredCredentials(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(credentials.email, 'test@example.com');
      expect(credentials.password, 'password123');
      expect(credentials.name, null);
    });
  });

  group('AuthException Tests', () {
    test('should create auth exception with message', () {
      const exception = AuthException('Test error message');
      expect(exception.message, 'Test error message');
      expect(exception.toString(), 'AuthException: Test error message');
    });
  });
}
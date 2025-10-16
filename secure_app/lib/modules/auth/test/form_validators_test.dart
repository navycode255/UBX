import 'package:flutter_test/flutter_test.dart';
import '../../../core/utils/form_validators.dart';

void main() {
  group('FormValidators Tests', () {
    group('Email Validation Tests', () {
      test('should return null for valid email', () {
        const validEmails = [
          'test@example.com',
          'user.name@domain.co.uk',
          'user123@test-domain.com',
        ];

        for (final email in validEmails) {
          final result = FormValidators.validateEmail(email);
          expect(result, isNull, reason: 'Email "$email" should be valid');
        }
      });

      test('should return error message for null email', () {
        final result = FormValidators.validateEmail(null);
        expect(result, 'Email is required');
      });

      test('should return error message for empty email', () {
        final result = FormValidators.validateEmail('');
        expect(result, 'Email is required');
      });

      test('should return error message for invalid email formats', () {
        const invalidEmails = [
          'invalid-email',
          '@example.com',
          'test@',
          'test.example.com',
          'test@.com',
          'test@example.',
          'test space@example.com',
          'test@example .com',
        ];

        for (final email in invalidEmails) {
          final result = FormValidators.validateEmail(email);
          expect(result, isNotNull, reason: 'Email "$email" should be invalid');
          expect(result, contains('valid email'), reason: 'Error message should mention valid email');
        }
      });
    });

    group('Password Validation Tests', () {
      test('should return null for valid password', () {
        const validPasswords = [
          'Password123!',
          'MySecure1@',
          'Test123#',
          'ValidPass1\$',
          'StrongP@ss1',
        ];

        for (final password in validPasswords) {
          final result = FormValidators.validatePassword(password);
          expect(result, isNull, reason: 'Password "$password" should be valid');
        }
      });

      test('should return error message for null password', () {
        final result = FormValidators.validatePassword(null);
        expect(result, 'Password is required');
      });

      test('should return error message for empty password', () {
        final result = FormValidators.validatePassword('');
        expect(result, 'Password is required');
      });

      test('should return error message for password too short', () {
        const shortPasswords = ['123', 'Ab1!', 'Pass1', 'Test@'];

        for (final password in shortPasswords) {
          final result = FormValidators.validatePassword(password);
          expect(result, contains('at least 8 characters'), 
              reason: 'Password "$password" should be too short');
        }
      });

      test('should return error message for password without uppercase', () {
        const passwordsWithoutUppercase = [
          'password123!',
          'mypassword1@',
          'testpass1#',
        ];

        for (final password in passwordsWithoutUppercase) {
          final result = FormValidators.validatePassword(password);
          expect(result, contains('uppercase letter'), 
              reason: 'Password "$password" should require uppercase');
        }
      });

      test('should return error message for password without lowercase', () {
        const passwordsWithoutLowercase = [
          'PASSWORD123!',
          'MYPASSWORD1@',
          'TESTPASS1#',
        ];

        for (final password in passwordsWithoutLowercase) {
          final result = FormValidators.validatePassword(password);
          expect(result, contains('lowercase letter'), 
              reason: 'Password "$password" should require lowercase');
        }
      });

      test('should return error message for password without number', () {
        const passwordsWithoutNumber = [
          'Password!',
          'MyPassword@',
          'TestPass#',
        ];

        for (final password in passwordsWithoutNumber) {
          final result = FormValidators.validatePassword(password);
          expect(result, contains('number'), 
              reason: 'Password "$password" should require number');
        }
      });

      test('should return error message for password without special character', () {
        const passwordsWithoutSpecial = [
          'Password123',
          'MyPassword1',
          'TestPass1',
        ];

        for (final password in passwordsWithoutSpecial) {
          final result = FormValidators.validatePassword(password);
          expect(result, contains('special character'), 
              reason: 'Password "$password" should require special character');
        }
      });
    });

    group('Name Validation Tests', () {
      test('should return null for valid names', () {
        const validNames = [
          'John Doe',
          'Jane Smith',
          'Very Long Name That Is Still Valid',
        ];

        for (final name in validNames) {
          final result = FormValidators.validateName(name);
          expect(result, isNull, reason: 'Name "$name" should be valid');
        }
      });

      test('should return error message for null name', () {
        final result = FormValidators.validateName(null);
        expect(result, 'Name is required');
      });

      test('should return error message for empty name', () {
        final result = FormValidators.validateName('');
        expect(result, 'Name is required');
      });

      test('should return error message for name too short', () {
        const shortNames = ['A', 'a', '1', '!'];

        for (final name in shortNames) {
          final result = FormValidators.validateName(name);
          expect(result, contains('at least 2 characters'), 
              reason: 'Name "$name" should be too short');
        }
      });

      test('should return error message for name with only spaces', () {
        const spaceNames = [' '];

        for (final name in spaceNames) {
          final result = FormValidators.validateName(name);
          expect(result, contains('at least 2 characters'), 
              reason: 'Name "$name" should be too short');
        }
      });

      test('should return error message for name with invalid characters', () {
        const invalidNames = ['John123', 'Jane@Doe', 'Test#Name', 'User\$Name'];

        for (final name in invalidNames) {
          final result = FormValidators.validateName(name);
          expect(result, contains('letters and spaces'), 
              reason: 'Name "$name" should have invalid characters');
        }
      });
    });

    group('Confirm Password Validation Tests', () {
      test('should return null when passwords match', () {
        const password = 'Password123!';
        const confirmPassword = 'Password123!';

        final result = FormValidators.validateConfirmPassword(password, confirmPassword);
        expect(result, isNull);
      });

      test('should return error message when passwords do not match', () {
        const password = 'Password123!';
        const confirmPassword = 'DifferentPassword123!';

        final result = FormValidators.validateConfirmPassword(password, confirmPassword);
        expect(result, 'Passwords do not match');
      });

      test('should return error message when confirm password is null', () {
        const password = 'Password123!';

        final result = FormValidators.validateConfirmPassword(password, null);
        expect(result, 'Passwords do not match');
      });

      test('should return error message when confirm password is empty', () {
        const password = 'Password123!';

        final result = FormValidators.validateConfirmPassword(password, '');
        expect(result, 'Passwords do not match');
      });

      test('should handle case sensitivity', () {
        const password = 'Password123!';
        const confirmPassword = 'password123!';

        final result = FormValidators.validateConfirmPassword(password, confirmPassword);
        expect(result, 'Passwords do not match');
      });

      test('should handle whitespace differences', () {
        const password = 'Password123!';
        const confirmPassword = ' Password123! ';

        final result = FormValidators.validateConfirmPassword(password, confirmPassword);
        expect(result, 'Passwords do not match');
      });
    });

    group('Required Field Validation Tests', () {
      test('should return null for non-empty value', () {
        final result = FormValidators.validateRequired('test value', 'Test Field');
        expect(result, isNull);
      });

      test('should return error message for null value', () {
        final result = FormValidators.validateRequired(null, 'Test Field');
        expect(result, 'Test Field is required');
      });

      test('should return error message for empty value', () {
        final result = FormValidators.validateRequired('', 'Test Field');
        expect(result, 'Test Field is required');
      });
    });

    group('Minimum Length Validation Tests', () {
      test('should return null for value with sufficient length', () {
        final result = FormValidators.validateMinLength('test value', 5, 'Test Field');
        expect(result, isNull);
      });

      test('should return error message for value too short', () {
        final result = FormValidators.validateMinLength('test', 5, 'Test Field');
        expect(result, 'Test Field must be at least 5 characters long');
      });

      test('should return error message for null value', () {
        final result = FormValidators.validateMinLength(null, 5, 'Test Field');
        expect(result, 'Test Field is required');
      });

      test('should return error message for empty value', () {
        final result = FormValidators.validateMinLength('', 5, 'Test Field');
        expect(result, 'Test Field is required');
      });
    });

    group('Maximum Length Validation Tests', () {
      test('should return null for value within length limit', () {
        final result = FormValidators.validateMaxLength('test', 10, 'Test Field');
        expect(result, isNull);
      });

      test('should return null for null value', () {
        final result = FormValidators.validateMaxLength(null, 10, 'Test Field');
        expect(result, isNull);
      });

      test('should return error message for value too long', () {
        final result = FormValidators.validateMaxLength('very long test value', 10, 'Test Field');
        expect(result, 'Test Field must be no more than 10 characters long');
      });
    });

    group('Numeric Validation Tests', () {
      test('should return null for valid number', () {
        final result = FormValidators.validateNumeric('123', 'Test Field');
        expect(result, isNull);
      });

      test('should return null for valid decimal', () {
        final result = FormValidators.validateNumeric('123.45', 'Test Field');
        expect(result, isNull);
      });

      test('should return error message for null value', () {
        final result = FormValidators.validateNumeric(null, 'Test Field');
        expect(result, 'Test Field is required');
      });

      test('should return error message for empty value', () {
        final result = FormValidators.validateNumeric('', 'Test Field');
        expect(result, 'Test Field is required');
      });

      test('should return error message for invalid number', () {
        final result = FormValidators.validateNumeric('abc', 'Test Field');
        expect(result, 'Test Field must be a valid number');
      });
    });

    group('URL Validation Tests', () {
      test('should return null for valid URLs', () {
        const validUrls = [
          'https://www.example.com',
          'http://example.com',
          'https://subdomain.example.com/path',
          'https://example.com:8080/path?query=value',
          'https://example.com#fragment',
        ];

        for (final url in validUrls) {
          final result = FormValidators.validateUrl(url);
          expect(result, isNull, reason: 'URL "$url" should be valid');
        }
      });

      test('should return error message for null URL', () {
        final result = FormValidators.validateUrl(null);
        expect(result, 'URL is required');
      });

      test('should return error message for empty URL', () {
        final result = FormValidators.validateUrl('');
        expect(result, 'URL is required');
      });

      test('should return error message for invalid URL formats', () {
        const invalidUrls = [
          'not-a-url',
          'ftp://example.com',
          'example.com',
          'www.example.com',
          'https://',
          'https://.com',
        ];

        for (final url in invalidUrls) {
          final result = FormValidators.validateUrl(url);
          expect(result, isNotNull, reason: 'URL "$url" should be invalid');
          expect(result, contains('valid URL'), 
              reason: 'Error message should mention valid URL');
        }
      });
    });
  });
}
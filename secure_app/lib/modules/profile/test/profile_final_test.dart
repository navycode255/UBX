import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import '../data/profile_state.dart';
import '../data/user_profile_repository.dart';

void main() {
  group('Profile Module Final Tests', () {
    group('ProfileState Model Tests', () {
      test('should create default profile state with correct initial values', () {
        const state = ProfileState();

        expect(state.userName, 'Loading...');
        expect(state.userEmail, 'Loading...');
        expect(state.userPhoneNumber, '');
        expect(state.hasProfilePicture, false);
        expect(state.profilePictureFile, null);
        expect(state.isLoading, true);
        expect(state.error, null);
      });

      test('should create profile state with custom values', () {
        final testFile = File('test_path');
        final state = ProfileState(
          userName: 'John Doe',
          userEmail: 'john@example.com',
          userPhoneNumber: '+1234567890',
          hasProfilePicture: true,
          profilePictureFile: testFile,
          isLoading: false,
          error: 'Test error',
        );

        expect(state.userName, 'John Doe');
        expect(state.userEmail, 'john@example.com');
        expect(state.userPhoneNumber, '+1234567890');
        expect(state.hasProfilePicture, true);
        expect(state.profilePictureFile, testFile);
        expect(state.isLoading, false);
        expect(state.error, 'Test error');
      });

      test('should copy with new values', () {
        const originalState = ProfileState(
          userName: 'John Doe',
          userEmail: 'john@example.com',
          userPhoneNumber: '+1234567890',
          hasProfilePicture: false,
          isLoading: true,
        );

        final newFile = File('new_path');
        final copiedState = originalState.copyWith(
          userName: 'Jane Doe',
          userEmail: 'jane@example.com',
          userPhoneNumber: '+0987654321',
          hasProfilePicture: true,
          profilePictureFile: newFile,
          isLoading: false,
          error: 'New error',
        );

        expect(copiedState.userName, 'Jane Doe');
        expect(copiedState.userEmail, 'jane@example.com');
        expect(copiedState.userPhoneNumber, '+0987654321');
        expect(copiedState.hasProfilePicture, true);
        expect(copiedState.profilePictureFile, newFile);
        expect(copiedState.isLoading, false);
        expect(copiedState.error, 'New error');
      });

      test('should copy with partial values keeping original values', () {
        const originalState = ProfileState(
          userName: 'John Doe',
          userEmail: 'john@example.com',
          userPhoneNumber: '+1234567890',
          hasProfilePicture: false,
          isLoading: true,
        );

        final copiedState = originalState.copyWith(
          userName: 'Jane Doe',
          isLoading: false,
        );

        expect(copiedState.userName, 'Jane Doe');
        expect(copiedState.userEmail, 'john@example.com'); // Original value
        expect(copiedState.userPhoneNumber, '+1234567890'); // Original value
        expect(copiedState.hasProfilePicture, false); // Original value
        expect(copiedState.profilePictureFile, null); // Original value
        expect(copiedState.isLoading, false);
        expect(copiedState.error, null); // Original value
      });

      test('should return true for hasError when error is not null', () {
        const stateWithError = ProfileState(error: 'Test error');
        expect(stateWithError.hasError, true);
      });

      test('should return false for hasError when error is null', () {
        const stateWithoutError = ProfileState(error: null);
        expect(stateWithoutError.hasError, false);
      });

      test('should return true for isLoaded when not loading and no error', () {
        const loadedState = ProfileState(
          isLoading: false,
          error: null,
        );
        expect(loadedState.isLoaded, true);
      });

      test('should return false for isLoaded when loading', () {
        const loadingState = ProfileState(
          isLoading: true,
          error: null,
        );
        expect(loadingState.isLoaded, false);
      });

      test('should return false for isLoaded when has error', () {
        const errorState = ProfileState(
          isLoading: false,
          error: 'Test error',
        );
        expect(errorState.isLoaded, false);
      });

      test('should return false for isLoaded when loading and has error', () {
        const loadingErrorState = ProfileState(
          isLoading: true,
          error: 'Test error',
        );
        expect(loadingErrorState.isLoaded, false);
      });
    });

    group('UserProfile Model Tests', () {
      test('should create UserProfile with all fields', () {
        final now = DateTime.now();
        final profile = UserProfile(
          id: 'profile123',
          userId: 'user123',
          profilePictureUrl: 'https://example.com/pic.jpg',
          bio: 'Test bio',
          dateOfBirth: DateTime(1990, 1, 1),
          gender: 'Male',
          address: '123 Test St',
          city: 'Test City',
          country: 'Test Country',
          timezone: 'UTC',
          language: 'en',
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.id, 'profile123');
        expect(profile.userId, 'user123');
        expect(profile.profilePictureUrl, 'https://example.com/pic.jpg');
        expect(profile.bio, 'Test bio');
        expect(profile.dateOfBirth, DateTime(1990, 1, 1));
        expect(profile.gender, 'Male');
        expect(profile.address, '123 Test St');
        expect(profile.city, 'Test City');
        expect(profile.country, 'Test Country');
        expect(profile.timezone, 'UTC');
        expect(profile.language, 'en');
        expect(profile.createdAt, now);
        expect(profile.updatedAt, now);
      });

      test('should create UserProfile with minimal fields', () {
        final now = DateTime.now();
        final profile = UserProfile(
          id: 'profile123',
          userId: 'user123',
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.id, 'profile123');
        expect(profile.userId, 'user123');
        expect(profile.profilePictureUrl, null);
        expect(profile.bio, null);
        expect(profile.dateOfBirth, null);
        expect(profile.gender, null);
        expect(profile.address, null);
        expect(profile.city, null);
        expect(profile.country, null);
        expect(profile.timezone, 'UTC');
        expect(profile.language, 'en');
        expect(profile.createdAt, now);
        expect(profile.updatedAt, now);
      });

      test('should convert to map correctly', () {
        final now = DateTime.now();
        final profile = UserProfile(
          id: 'profile123',
          userId: 'user123',
          profilePictureUrl: 'https://example.com/pic.jpg',
          bio: 'Test bio',
          dateOfBirth: DateTime(1990, 1, 1),
          gender: 'Male',
          address: '123 Test St',
          city: 'Test City',
          country: 'Test Country',
          timezone: 'UTC',
          language: 'en',
          createdAt: now,
          updatedAt: now,
        );

        final map = profile.toMap();

        expect(map['id'], 'profile123');
        expect(map['user_id'], 'user123');
        expect(map['profile_picture_url'], 'https://example.com/pic.jpg');
        expect(map['bio'], 'Test bio');
        expect(map['date_of_birth'], '1990-01-01');
        expect(map['gender'], 'Male');
        expect(map['address'], '123 Test St');
        expect(map['city'], 'Test City');
        expect(map['country'], 'Test Country');
        expect(map['timezone'], 'UTC');
        expect(map['language'], 'en');
        expect(map['created_at'], now);
        expect(map['updated_at'], now);
      });

      test('should create from map correctly', () {
        final now = DateTime.now();
        final map = {
          'id': 'profile123',
          'user_id': 'user123',
          'profile_picture_url': 'https://example.com/pic.jpg',
          'bio': 'Test bio',
          'date_of_birth': '1990-01-01',
          'gender': 'Male',
          'address': '123 Test St',
          'city': 'Test City',
          'country': 'Test Country',
          'timezone': 'UTC',
          'language': 'en',
          'created_at': now,
          'updated_at': now,
        };

        final profile = UserProfile.fromMap(map);

        expect(profile.id, 'profile123');
        expect(profile.userId, 'user123');
        expect(profile.profilePictureUrl, 'https://example.com/pic.jpg');
        expect(profile.bio, 'Test bio');
        expect(profile.dateOfBirth, DateTime(1990, 1, 1));
        expect(profile.gender, 'Male');
        expect(profile.address, '123 Test St');
        expect(profile.city, 'Test City');
        expect(profile.country, 'Test Country');
        expect(profile.timezone, 'UTC');
        expect(profile.language, 'en');
        expect(profile.createdAt, now);
        expect(profile.updatedAt, now);
      });

      test('should handle null values in fromMap', () {
        final now = DateTime.now();
        final map = {
          'id': 'profile123',
          'user_id': 'user123',
          'profile_picture_url': null,
          'bio': null,
          'date_of_birth': null,
          'gender': null,
          'address': null,
          'city': null,
          'country': null,
          'timezone': 'UTC',
          'language': 'en',
          'created_at': now,
          'updated_at': now,
        };

        final profile = UserProfile.fromMap(map);

        expect(profile.id, 'profile123');
        expect(profile.userId, 'user123');
        expect(profile.profilePictureUrl, null);
        expect(profile.bio, null);
        expect(profile.dateOfBirth, null);
        expect(profile.gender, null);
        expect(profile.address, null);
        expect(profile.city, null);
        expect(profile.country, null);
        expect(profile.timezone, 'UTC');
        expect(profile.language, 'en');
        expect(profile.createdAt, now);
        expect(profile.updatedAt, now);
      });
    });

    group('ProfileState Edge Cases', () {
      test('should handle null values in copyWith', () {
        const originalState = ProfileState(
          userName: 'John Doe',
          userEmail: 'john@example.com',
          userPhoneNumber: '+1234567890',
          hasProfilePicture: true,
          isLoading: false,
          error: 'Test error',
        );

        final copiedState = originalState.copyWith(
          userName: null,
          userEmail: null,
          userPhoneNumber: null,
          hasProfilePicture: null,
          profilePictureFile: null,
          isLoading: null,
          error: null,
        );

        expect(copiedState.userName, 'John Doe'); // Original value
        expect(copiedState.userEmail, 'john@example.com'); // Original value
        expect(copiedState.userPhoneNumber, '+1234567890'); // Original value
        expect(copiedState.hasProfilePicture, true); // Original value
        expect(copiedState.profilePictureFile, null); // Original value
        expect(copiedState.isLoading, false); // Original value
        expect(copiedState.error, 'Test error'); // Original value
      });

      test('should handle empty strings in profile state', () {
        const state = ProfileState(
          userName: '',
          userEmail: '',
          userPhoneNumber: '',
          error: '',
        );

        expect(state.userName, '');
        expect(state.userEmail, '');
        expect(state.userPhoneNumber, '');
        expect(state.error, '');
        expect(state.hasError, true); // Empty string is considered an error
      });

      test('should handle whitespace strings in profile state', () {
        const state = ProfileState(
          userName: '   ',
          userEmail: '   ',
          userPhoneNumber: '   ',
          error: '   ',
        );

        expect(state.userName, '   ');
        expect(state.userEmail, '   ');
        expect(state.userPhoneNumber, '   ');
        expect(state.error, '   ');
        expect(state.hasError, true); // Whitespace string is considered an error
      });
    });

    group('ProfileState Validation', () {
      test('should validate hasError property with different error types', () {
        const stateWithStringError = ProfileState(error: 'Some error');
        const stateWithEmptyError = ProfileState(error: '');
        const stateWithoutError = ProfileState(error: null);
        
        expect(stateWithStringError.hasError, true);
        expect(stateWithEmptyError.hasError, true);
        expect(stateWithoutError.hasError, false);
      });

      test('should validate isLoaded property with different states', () {
        const loadedState = ProfileState(isLoading: false, error: null);
        const loadingState = ProfileState(isLoading: true, error: null);
        const errorState = ProfileState(isLoading: false, error: 'Error');
        const loadingErrorState = ProfileState(isLoading: true, error: 'Error');
        
        expect(loadedState.isLoaded, true);
        expect(loadingState.isLoaded, false);
        expect(errorState.isLoaded, false);
        expect(loadingErrorState.isLoaded, false);
      });
    });

    group('UserProfile Edge Cases', () {
      test('should handle empty strings in UserProfile', () {
        final now = DateTime.now();
        final profile = UserProfile(
          id: '',
          userId: '',
          profilePictureUrl: '',
          bio: '',
          gender: '',
          address: '',
          city: '',
          country: '',
          timezone: '',
          language: '',
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.id, '');
        expect(profile.userId, '');
        expect(profile.profilePictureUrl, '');
        expect(profile.bio, '');
        expect(profile.gender, '');
        expect(profile.address, '');
        expect(profile.city, '');
        expect(profile.country, '');
        expect(profile.timezone, '');
        expect(profile.language, '');
      });

      test('should handle special characters in UserProfile', () {
        final now = DateTime.now();
        final profile = UserProfile(
          id: 'profile-123_test@domain.com',
          userId: 'user-123_test@domain.com',
          profilePictureUrl: 'https://example.com/path/to/image.jpg?param=value&other=123',
          bio: 'Bio with special chars: !@#\$%^&*()_+-=[]{}|;:,.<>?',
          gender: 'Other/Non-binary',
          address: '123 Main St., Apt. #4B, City, State 12345',
          city: 'New York City',
          country: 'United States of America',
          timezone: 'America/New_York',
          language: 'en-US',
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.id, 'profile-123_test@domain.com');
        expect(profile.userId, 'user-123_test@domain.com');
        expect(profile.profilePictureUrl, 'https://example.com/path/to/image.jpg?param=value&other=123');
        expect(profile.bio, 'Bio with special chars: !@#\$%^&*()_+-=[]{}|;:,.<>?');
        expect(profile.gender, 'Other/Non-binary');
        expect(profile.address, '123 Main St., Apt. #4B, City, State 12345');
        expect(profile.city, 'New York City');
        expect(profile.country, 'United States of America');
        expect(profile.timezone, 'America/New_York');
        expect(profile.language, 'en-US');
      });
    });
  });
}

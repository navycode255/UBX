import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import '../data/user_profile_repository.dart';

void main() {
  group('UserProfileRepository Tests', () {
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

    group('Repository Class Tests', () {
      test('should create UserProfileRepository instance', () {
        final repository = UserProfileRepository();
        expect(repository, isA<UserProfileRepository>());
      });

      test('should have all required methods', () {
        final repository = UserProfileRepository();
        
        // Test that all methods exist by checking their signatures
        expect(repository.createUserProfile, isA<Function>());
        expect(repository.getProfileByUserId, isA<Function>());
        expect(repository.updateUserProfile, isA<Function>());
        expect(repository.deleteUserProfile, isA<Function>());
        expect(repository.profileExists, isA<Function>());
        expect(repository.uploadProfilePicture, isA<Function>());
        expect(repository.getProfilePictureFile, isA<Function>());
        expect(repository.deleteProfilePicture, isA<Function>());
      });
    });
  });
}
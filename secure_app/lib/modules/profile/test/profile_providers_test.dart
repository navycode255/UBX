import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../data/profile_providers.dart';
import '../data/profile_state.dart';
import '../data/profile_notifier.dart';

void main() {
  group('Profile Providers Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('profileNotifierProvider', () {
      test('should provide ProfileNotifier instance', () {
        final notifier = container.read(profileNotifierProvider.notifier);
        expect(notifier, isA<ProfileNotifier>());
      });

      test('should provide initial ProfileState', () {
        final state = container.read(profileNotifierProvider);
        expect(state, isA<ProfileState>());
        expect(state.isLoading, true);
        expect(state.userName, 'Loading...');
        expect(state.userEmail, 'Loading...');
      });
    });

    group('profileDataProvider', () {
      test('should provide ProfileState from notifier', () {
        final state = container.read(profileDataProvider);
        expect(state, isA<ProfileState>());
      });

      test('should update when notifier state changes', () {
        final notifier = container.read(profileNotifierProvider.notifier);
        
        // Update state
        notifier.state = const ProfileState(
          userName: 'John Doe',
          userEmail: 'john@example.com',
          userPhoneNumber: '+255734567890',
          hasProfilePicture: true,
          isLoading: false,
        );

        final updatedState = container.read(profileDataProvider);
        expect(updatedState.userName, 'John Doe');
        expect(updatedState.userEmail, 'john@example.com');
        expect(updatedState.userPhoneNumber, '+255734567890');
        expect(updatedState.hasProfilePicture, true);
        expect(updatedState.isLoading, false);
      });
    });

    group('userNameProvider', () {
      test('should provide user name from profile state', () {
        final notifier = container.read(profileNotifierProvider.notifier);
        notifier.state = const ProfileState(userName: 'John Doe');
        
        final userName = container.read(userNameProvider);
        expect(userName, 'John Doe');
      });

      test('should update when profile state changes', () {
        final notifier = container.read(profileNotifierProvider.notifier);
        
        // Initial state
        expect(container.read(userNameProvider), 'Loading...');
        
        // Update state
        notifier.state = const ProfileState(userName: 'Jane Doe');
        expect(container.read(userNameProvider), 'Jane Doe');
      });
    });

    group('userEmailProvider', () {
      test('should provide user email from profile state', () {
        final notifier = container.read(profileNotifierProvider.notifier);
        notifier.state = const ProfileState(userEmail: 'john@example.com');
        
        final userEmail = container.read(userEmailProvider);
        expect(userEmail, 'john@example.com');
      });

      test('should update when profile state changes', () {
        final notifier = container.read(profileNotifierProvider.notifier);
        
        // Initial state
        expect(container.read(userEmailProvider), 'Loading...');
        
        // Update state
        notifier.state = const ProfileState(userEmail: 'jane@example.com');
        expect(container.read(userEmailProvider), 'jane@example.com');
      });
    });

    group('userPhoneNumberProvider', () {
      test('should provide user phone number from profile state', () {
        final notifier = container.read(profileNotifierProvider.notifier);
        notifier.state = const ProfileState(userPhoneNumber: '+1234567890');
        
        final userPhoneNumber = container.read(userPhoneNumberProvider);
        expect(userPhoneNumber, '+1234567890');
      });

      test('should provide empty string for default state', () {
        final userPhoneNumber = container.read(userPhoneNumberProvider);
        expect(userPhoneNumber, '');
      });
    });

    group('profilePictureProvider', () {
      test('should provide profile picture file from profile state', () {
        final notifier = container.read(profileNotifierProvider.notifier);
        final testFile = File('test_path');
        notifier.state = ProfileState(profilePictureFile: testFile);
        
        final profilePicture = container.read(profilePictureProvider);
        expect(profilePicture, testFile);
      });

      test('should provide null for default state', () {
        final profilePicture = container.read(profilePictureProvider);
        expect(profilePicture, null);
      });
    });

    group('hasProfilePictureProvider', () {
      test('should provide hasProfilePicture from profile state', () {
        final notifier = container.read(profileNotifierProvider.notifier);
        notifier.state = const ProfileState(hasProfilePicture: true);
        
        final hasProfilePicture = container.read(hasProfilePictureProvider);
        expect(hasProfilePicture, true);
      });

      test('should provide false for default state', () {
        final hasProfilePicture = container.read(hasProfilePictureProvider);
        expect(hasProfilePicture, false);
      });
    });

    group('profileLoadingProvider', () {
      test('should provide loading state from profile state', () {
        final notifier = container.read(profileNotifierProvider.notifier);
        notifier.state = const ProfileState(isLoading: false);
        
        final isLoading = container.read(profileLoadingProvider);
        expect(isLoading, false);
      });

      test('should provide true for default state', () {
        final isLoading = container.read(profileLoadingProvider);
        expect(isLoading, true);
      });
    });

    group('profileErrorProvider', () {
      test('should provide error from profile state', () {
        final notifier = container.read(profileNotifierProvider.notifier);
        notifier.state = const ProfileState(error: 'Test error');
        
        final error = container.read(profileErrorProvider);
        expect(error, 'Test error');
      });

      test('should provide null for default state', () {
        final error = container.read(profileErrorProvider);
        expect(error, null);
      });
    });

    group('profileLoadedProvider', () {
      test('should return true when loaded (not loading and no error)', () {
        final notifier = container.read(profileNotifierProvider.notifier);
        notifier.state = const ProfileState(
          isLoading: false,
          error: null,
        );
        
        final isLoaded = container.read(profileLoadedProvider);
        expect(isLoaded, true);
      });

      test('should return false when loading', () {
        final notifier = container.read(profileNotifierProvider.notifier);
        notifier.state = const ProfileState(
          isLoading: true,
          error: null,
        );
        
        final isLoaded = container.read(profileLoadedProvider);
        expect(isLoaded, false);
      });

      test('should return false when has error', () {
        final notifier = container.read(profileNotifierProvider.notifier);
        notifier.state = const ProfileState(
          isLoading: false,
          error: 'Test error',
        );
        
        final isLoaded = container.read(profileLoadedProvider);
        expect(isLoaded, false);
      });

      test('should return false when loading and has error', () {
        final notifier = container.read(profileNotifierProvider.notifier);
        notifier.state = const ProfileState(
          isLoading: true,
          error: 'Test error',
        );
        
        final isLoaded = container.read(profileLoadedProvider);
        expect(isLoaded, false);
      });
    });
  });
}

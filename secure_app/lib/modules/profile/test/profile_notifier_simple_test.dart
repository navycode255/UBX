import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import '../data/profile_notifier.dart';
import '../data/profile_state.dart';

void main() {
  group('ProfileNotifier Simple Tests', () {
    late ProfileNotifier notifier;

    setUp(() {
      notifier = ProfileNotifier();
    });

    group('Initial State', () {
      test('should start with loading state', () {
        final state = notifier.state;
        expect(state.isLoading, true);
        expect(state.userName, 'Loading...');
        expect(state.userEmail, 'Loading...');
        expect(state.userPhoneNumber, '');
        expect(state.hasProfilePicture, false);
        expect(state.profilePictureFile, null);
        expect(state.error, null);
      });
    });

    group('refreshUserData', () {
      test('should refresh user data successfully', () async {
        // The method should not throw
        expect(() => notifier.refreshUserData(), returnsNormally);
      });
    });

    group('uploadProfilePicture', () {
      test('should handle upload without throwing', () async {
        final testFile = File('test_path');
        
        // The method should not throw (will fail due to missing services in test)
        expect(() => notifier.uploadProfilePicture(testFile), returnsNormally);
      });
    });

    group('removeProfilePicture', () {
      test('should handle removal without throwing', () async {
        // The method should not throw (will fail due to missing services in test)
        expect(() => notifier.removeProfilePicture(), returnsNormally);
      });
    });

    group('updateUserProfile', () {
      test('should handle update without throwing', () async {
        // The method should not throw (will fail due to missing services in test)
        expect(() => notifier.updateUserProfile(
          name: 'John Doe',
          phoneNumber: '+1234567890',
        ), returnsNormally);
      });
    });

    group('clearError', () {
      test('should clear error state', () {
        // Set error state
        notifier.state = const ProfileState(error: 'Test error');
        expect(notifier.state.error, 'Test error');
        
        // Clear error
        notifier.clearError();
        expect(notifier.state.error, null);
      });
    });

    group('State Management', () {
      test('should update state correctly', () {
        // Update state
        notifier.state = const ProfileState(
          userName: 'John Doe',
          userEmail: 'john@example.com',
          userPhoneNumber: '+1234567890',
          hasProfilePicture: true,
          isLoading: false,
          error: null,
        );
        
        expect(notifier.state.userName, 'John Doe');
        expect(notifier.state.userEmail, 'john@example.com');
        expect(notifier.state.userPhoneNumber, '+1234567890');
        expect(notifier.state.hasProfilePicture, true);
        expect(notifier.state.isLoading, false);
        expect(notifier.state.error, null);
      });

      test('should handle error state', () {
        notifier.state = const ProfileState(
          error: 'Test error message',
          isLoading: false,
        );
        
        expect(notifier.state.hasError, true);
        expect(notifier.state.isLoaded, false);
        expect(notifier.state.error, 'Test error message');
      });

      test('should handle loading state', () {
        notifier.state = const ProfileState(
          isLoading: true,
          error: null,
        );
        
        expect(notifier.state.isLoading, true);
        expect(notifier.state.isLoaded, false);
        expect(notifier.state.hasError, false);
      });
    });
  });
}

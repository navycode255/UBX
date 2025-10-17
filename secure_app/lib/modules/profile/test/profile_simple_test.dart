import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import '../data/profile_state.dart';

void main() {
  group('Profile Module Simple Tests', () {
    group('ProfileState Basic Tests', () {
      test('should create default profile state', () {
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

      test('should handle partial updates in copyWith', () {
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
    });

    group('ProfileState Validation', () {
      test('should validate hasError property', () {
        const stateWithError = ProfileState(error: 'Some error');
        const stateWithoutError = ProfileState(error: null);
        
        expect(stateWithError.hasError, true);
        expect(stateWithoutError.hasError, false);
      });

      test('should validate isLoaded property', () {
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
  });
}

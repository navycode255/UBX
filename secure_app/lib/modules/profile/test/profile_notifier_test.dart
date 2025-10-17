import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import '../data/profile_state.dart';

void main() {
  group('ProfileNotifier Tests', () {
    group('ProfileState Tests (Core Functionality)', () {
      test('should create ProfileState with default values', () {
        const state = ProfileState();
        
        expect(state.isLoading, true);
        expect(state.userName, 'Loading...');
        expect(state.userEmail, 'Loading...');
        expect(state.userPhoneNumber, '');
        expect(state.hasProfilePicture, false);
        expect(state.profilePictureFile, null);
        expect(state.error, null);
      });

      test('should create ProfileState with custom values', () {
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

      test('should copy ProfileState with new values', () {
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

      test('should validate hasError property', () {
        const stateWithError = ProfileState(error: 'Test error');
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

      test('should handle empty strings', () {
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

      test('should handle whitespace strings', () {
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
      test('should validate hasError with different error types', () {
        const stateWithStringError = ProfileState(error: 'Some error');
        const stateWithEmptyError = ProfileState(error: '');
        const stateWithoutError = ProfileState(error: null);
        
        expect(stateWithStringError.hasError, true);
        expect(stateWithEmptyError.hasError, true);
        expect(stateWithoutError.hasError, false);
      });

      test('should validate isLoaded with different states', () {
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
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/user_service.dart';
import 'profile_state.dart';

/// Profile state notifier
class ProfileNotifier extends Notifier<ProfileState> {
  final AuthService _authService = AuthService.instance;
  final UserService _userService = UserService.instance;

  @override
  ProfileState build() {
    _loadUserData();
    return const ProfileState();
  }

  /// Load user data from database
  Future<void> _loadUserData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      final userWithProfile = await _userService.getUserWithProfile(currentUserId);
      if (userWithProfile != null) {
        // Load profile picture file
        final pictureFile = await _userService.getProfilePictureFile(currentUserId);
        
        state = state.copyWith(
          userName: userWithProfile.displayName,
          userEmail: userWithProfile.email,
          userPhoneNumber: userWithProfile.phoneNumber ?? '',
          hasProfilePicture: userWithProfile.profilePictureUrl != null,
          profilePictureFile: pictureFile,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'User profile not found',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile: ${e.toString()}',
      );
    }
  }

  /// Refresh user data
  Future<void> refreshUserData() async {
    await _loadUserData();
  }

  /// Upload profile picture
  Future<void> uploadProfilePicture(File imageFile) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      final imagePath = await _userService.uploadProfilePicture(currentUserId, imageFile);
      
      if (imagePath != null) {
        state = state.copyWith(
          hasProfilePicture: true,
          profilePictureFile: imageFile,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to upload profile picture',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error uploading picture: ${e.toString()}',
      );
    }
  }

  /// Remove profile picture
  Future<void> removeProfilePicture() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      final success = await _userService.deleteProfilePicture(currentUserId);
      
      if (success) {
        state = state.copyWith(
          hasProfilePicture: false,
          profilePictureFile: null,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to remove profile picture',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error removing picture: ${e.toString()}',
      );
    }
  }

  /// Update user profile information
  Future<void> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? bio,
    String? city,
    String? country,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      // Update basic user info
      if (name != null || phoneNumber != null) {
        await _userService.updateUserInfo(
          currentUserId,
          name: name,
          phoneNumber: phoneNumber,
        );
      }

      // Update profile info
      if (bio != null || city != null || country != null) {
        await _userService.updateUserProfile(
          currentUserId,
          bio: bio,
          city: city,
          country: country,
        );
      }

      // Refresh data
      await _loadUserData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error updating profile: ${e.toString()}',
      );
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

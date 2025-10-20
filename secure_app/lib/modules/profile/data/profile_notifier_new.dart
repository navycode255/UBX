import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/profile_service.dart';
import 'profile_state.dart';

/// Profile state notifier using local database
class ProfileNotifier extends Notifier<ProfileState> {
  final AuthService _authService = AuthService.instance;
  final ProfileService _profileService = ProfileService.instance;

  @override
  ProfileState build() {
    // Don't call _loadUserData() here to avoid infinite loop
    // Call it explicitly when needed
    return const ProfileState();
  }

  /// Load user data from local database
  Future<void> _loadUserData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Check if user is logged in first
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (!isLoggedIn) {
        state = state.copyWith(
          isLoading: false,
          error: 'Please sign in to view your profile',
        );
        return;
      }

      // Fetch user data from local database
      final response = await _profileService.getCurrentProfile();
      
      if (response.success && response.profileData != null) {
        final userData = response.profileData!;
        
        // Check if user has profile picture
        bool hasProfilePicture = false;
        File? profilePictureFile;
        
        try {
          hasProfilePicture = await _profileService.hasProfilePicture();
          if (hasProfilePicture) {
            final picturePath = await _profileService.getProfilePicturePath();
            if (picturePath != null) {
              profilePictureFile = File(picturePath);
            }
          }
        } catch (e) {
          // Silently handle profile picture errors - don't want to break the flow
          debugPrint('Error loading profile picture: $e');
        }
        
        state = state.copyWith(
          userName: userData['name'] ?? 'User',
          userEmail: userData['email'] ?? 'user@example.com',
          userPhoneNumber: userData['phone_number'] ?? '',
          hasProfilePicture: hasProfilePicture,
          profilePictureFile: profilePictureFile,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.errorMessage.isNotEmpty ? response.errorMessage : 'Failed to load user profile',
        );
      }
    } catch (e) {
      // Handle database errors gracefully
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile: ${e.toString()}',
      );
    }
  }

  /// Initialize profile data (call this when profile page loads)
  Future<void> initializeProfile() async {
    // Check authentication status first
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (!isLoggedIn) {
        state = state.copyWith(
          isLoading: false,
          error: 'Please sign in to view your profile',
          userName: 'Not Signed In',
          userEmail: 'Please sign in',
          userPhoneNumber: '',
        );
        return;
      }
    } catch (e) {
      debugPrint('Error checking authentication: $e');
    }
    
    // Load from local database
    await _loadUserData();
    
    // If still loading after database call, set a fallback state
    if (state.isLoading) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load profile data.',
        userName: 'User',
        userEmail: 'user@example.com',
        userPhoneNumber: '',
      );
    }
    
    // If we have an error but no user data, try to get user data from secure storage as fallback
    if (state.hasError && (state.userName == 'User' || state.userEmail == 'user@example.com')) {
      try {
        final storedName = await _authService.getCurrentUserName();
        final storedEmail = await _authService.getCurrentUserEmail();
        
        if (storedName != null || storedEmail != null) {
          state = state.copyWith(
            userName: storedName ?? 'User',
            userEmail: storedEmail ?? 'user@example.com',
            error: null, // Clear the error since we have some data
          );
        }
      } catch (e) {
        debugPrint('Error getting stored user data: $e');
      }
    }
  }

  /// Refresh user data from local database
  Future<void> refreshUserData() async {
    await _loadUserData();
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Retry loading profile data
  Future<void> retryLoadProfile() async {
    await _loadUserData();
  }

  /// Update user profile via local database
  Future<void> updateUserProfile({
    String? name,
    String? phoneNumber,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _profileService.updateProfile(
        name: name,
        phoneNumber: phoneNumber,
      );

      if (response.success) {
        // Update state with new data
        state = state.copyWith(
          userName: name ?? state.userName,
          userPhoneNumber: phoneNumber ?? state.userPhoneNumber,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.errorMessage.isNotEmpty ? response.errorMessage : 'Failed to update profile',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update profile: ${e.toString()}',
      );
    }
  }

  /// Upload profile picture to local storage
  Future<void> uploadProfilePicture(File imageFile) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Get app documents directory
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final profilePicturesDir = Directory('${documentsDirectory.path}/profile_pictures');
      
      // Create directory if it doesn't exist
      if (!await profilePicturesDir.exists()) {
        await profilePicturesDir.create(recursive: true);
      }
      
      // Generate unique filename
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = '${profilePicturesDir.path}/$fileName';
      
      // Copy file to app directory
      final targetFile = await imageFile.copy(targetPath);
      
      // Update profile picture in database
      final response = await _profileService.updateProfilePicture(targetPath);

      if (response.success) {
        state = state.copyWith(
          hasProfilePicture: true,
          profilePictureFile: targetFile,
          isLoading: false,
          error: null,
        );
      } else {
        // Clean up the copied file if database update failed
        try {
          await targetFile.delete();
        } catch (e) {
          debugPrint('Failed to clean up copied file: $e');
        }
        
        state = state.copyWith(
          isLoading: false,
          error: response.errorMessage.isNotEmpty ? response.errorMessage : 'Failed to upload profile picture',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error uploading picture: ${e.toString()}',
      );
    }
  }

  /// Remove profile picture from local storage
  Future<void> removeProfilePicture() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _profileService.deleteProfilePicture();

      if (response.success) {
        state = state.copyWith(
          hasProfilePicture: false,
          profilePictureFile: null,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.errorMessage.isNotEmpty ? response.errorMessage : 'Failed to remove profile picture',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error removing picture: ${e.toString()}',
      );
    }
  }

  /// Force stop loading and show error (for debugging)
  void forceStopLoading() {
    state = state.copyWith(
      isLoading: false,
      error: 'Loading timeout - please try again',
    );
  }

  /// Update phone number locally
  void updatePhoneNumberLocally(String phoneNumber) {
    state = state.copyWith(
      userPhoneNumber: phoneNumber,
      error: null,
    );
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      return await _profileService.getUserStatistics();
    } catch (e) {
      debugPrint('Error getting user statistics: $e');
      return {};
    }
  }
}

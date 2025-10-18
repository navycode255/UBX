import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/user_model.dart';
import 'profile_state.dart';

/// Profile state notifier
class ProfileNotifier extends Notifier<ProfileState> {
  final AuthService _authService = AuthService.instance;
  final ApiService _apiService = ApiService();

  @override
  ProfileState build() {
    // Don't call _loadUserData() here to avoid infinite loop
    // Call it explicitly when needed
    return const ProfileState();
  }

  /// Load user data from API
  Future<void> _loadUserData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Check if user is logged in first
      final isLoggedIn = await _authService.isLoggedIn();
      
      final currentUserId = await _authService.getCurrentUserId();
      
      if (!isLoggedIn || currentUserId == null || currentUserId.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'Please sign in to view your profile',
        );
        return;
      }

      // Test API connection first

      final healthResponse = await _apiService.healthCheck();

      
      // Fetch user data from API with timeout
      final response = await _apiService.getUserById(currentUserId).timeout(
        const Duration(seconds: 10),
        onTimeout: () {

          return ApiResponse(
            success: false,
            statusCode: 408,
            data: null,
            message: 'Request timeout - please check your connection',
          );
        },
      );
      
      if (response.success && response.data != null) {
        
        // Extract the actual user data from the API response
        final userData = response.data!['data'] as Map<String, dynamic>?;
        if (userData == null) {

          state = state.copyWith(
            isLoading: false,
            error: 'Invalid user data structure',
          );
          return;
        }
        
        final user = UserModel.fromJson(userData);
        
        // Check if user has profile picture
        bool hasProfilePicture = false;
        File? profilePictureFile;
        
        try {
          final pictureResponse = await _apiService.getProfilePicture(currentUserId);
          if (pictureResponse.success && pictureResponse.data != null) {
            final pictureData = pictureResponse.data!['data'] as Map<String, dynamic>?;
            if (pictureData != null && pictureData['image_url'] != null) {
              hasProfilePicture = true;
              // Note: In a real implementation, you'd download and cache the image
              // For now, we'll just mark that a profile picture exists
            }
          }
        } catch (e) {
          // Silently handle profile picture errors - don't want to break the flow
        }
        
        state = state.copyWith(
          userName: user.name,
          userEmail: user.email,
          userPhoneNumber: user.phoneNumber ?? '',
          hasProfilePicture: hasProfilePicture,
          profilePictureFile: profilePictureFile,
          isLoading: false,
          error: null,
        );
      } else {
        // Handle different error scenarios
        if (response.statusCode == 404) {
          state = state.copyWith(
            isLoading: false,
            error: 'Profile not found. Please complete your profile setup.',
            userName: 'Profile Not Found',
            userEmail: 'Complete your profile',
            userPhoneNumber: '',
          );
        } else if (response.statusCode == 408) {
          state = state.copyWith(
            isLoading: false,
            error: 'Request timeout. Please check your internet connection.',
          );
        } else if (response.statusCode == 500) {
          state = state.copyWith(
            isLoading: false,
            error: 'Server error. Please try again later.',
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: response.message.isNotEmpty ? response.message : 'Failed to load user profile',
          );
        }
      }
    } catch (e) {
      // Handle API errors gracefully
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

    }
    
    // First, try to load from API
    await _loadUserData();
    
    // If still loading after API call, set a fallback state
    if (state.isLoading) {

      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load profile data. Please check your connection.',
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

      }
    }
  }

  /// Refresh user data from API
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

  /// Create user profile if it doesn't exist
  Future<void> createUserProfile({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) {
        state = state.copyWith(error: 'User not authenticated');
        return;
      }

      final response = await _apiService.createUser(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );

      if (response.success) {
        // Refresh user data after successful creation
        await _loadUserData();
      } else {
        state = state.copyWith(
          error: response.message.isNotEmpty ? response.message : 'Failed to create profile',
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to create profile: ${e.toString()}',
      );
    }
  }

  /// Update user profile via API
  Future<void> updateUserProfile({
    String? name,
    String? phoneNumber,
  }) async {
    try {
      final currentUserId = await _authService.getCurrentUserId();
      if (currentUserId == null) {
        state = state.copyWith(error: 'User not authenticated');
        return;
      }

      final response = await _apiService.updateUser(
        userId: currentUserId,
        name: name,
        phoneNumber: phoneNumber,
      );

      if (response.success) {
        // Refresh user data after successful update
        await _loadUserData();
      } else {
        state = state.copyWith(
          error: response.message.isNotEmpty ? response.message : 'Failed to update profile',
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update profile: ${e.toString()}',
      );
    }
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

      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to API
      final response = await _apiService.uploadProfilePicture(
        userId: currentUserId,
        imageBase64: base64Image,
        fileName: fileName,
      );

      if (response.success) {
        state = state.copyWith(
          hasProfilePicture: true,
          profilePictureFile: imageFile,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message.isNotEmpty ? response.message : 'Failed to upload profile picture',
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

      // Delete from API
      final response = await _apiService.deleteProfilePicture(currentUserId);

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
          error: response.message.isNotEmpty ? response.message : 'Failed to remove profile picture',
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

  /// Update phone number locally (fallback when API fails)
  void updatePhoneNumberLocally(String phoneNumber) {
    state = state.copyWith(
      userPhoneNumber: phoneNumber,
      error: null,
    );
  }
}

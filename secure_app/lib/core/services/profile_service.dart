import 'package:flutter/foundation.dart';
import 'local_database_service.dart';
import 'secure_storage_service.dart';
import 'dart:io';

/// Profile Service for managing user profile data locally
/// 
/// Handles profile picture management, user data updates, and local storage
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  static ProfileService get instance => _instance;
  ProfileService._internal();

  final LocalDatabaseService _database = LocalDatabaseService.instance;
  final SecureStorageService _secureStorage = SecureStorageService.instance;

  /// Get current user profile
  Future<ProfileResult> getCurrentProfile() async {
    try {
      final userId = await _secureStorage.getUserId();
      if (userId == null) {
        return ProfileResult.failure('User not logged in');
      }

      final response = await _database.getUserById(userId);
      if (!response.success) {
        return ProfileResult.failure(response.errorMessage);
      }

      return ProfileResult.success(response.userData!);
    } catch (e) {
      return ProfileResult.failure('Failed to get profile: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<ProfileResult> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final userId = await _secureStorage.getUserId();
      if (userId == null) {
        return ProfileResult.failure('User not logged in');
      }

      final response = await _database.updateUser(
        userId: userId,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
      );

      if (!response.success) {
        return ProfileResult.failure(response.errorMessage);
      }

      // Note: Secure storage will be updated when user signs in again
      // For now, we just update the database

      return ProfileResult.success(response.userData!);
    } catch (e) {
      return ProfileResult.failure('Failed to update profile: ${e.toString()}');
    }
  }

  /// Update profile picture
  Future<ProfileResult> updateProfilePicture(String imagePath) async {
    try {
      final userId = await _secureStorage.getUserId();
      if (userId == null) {
        return ProfileResult.failure('User not logged in');
      }

      // Verify file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        return ProfileResult.failure('Image file not found');
      }

      final response = await _database.updateProfilePicture(
        userId: userId,
        imagePath: imagePath,
      );

      if (!response.success) {
        return ProfileResult.failure(response.errorMessage);
      }

      return ProfileResult.success(response.userData!);
    } catch (e) {
      return ProfileResult.failure('Failed to update profile picture: ${e.toString()}');
    }
  }

  /// Delete profile picture
  Future<ProfileResult> deleteProfilePicture() async {
    try {
      final userId = await _secureStorage.getUserId();
      if (userId == null) {
        return ProfileResult.failure('User not logged in');
      }

      // Get current profile to find existing picture
      final profileResponse = await _database.getUserById(userId);
      if (!profileResponse.success) {
        return ProfileResult.failure(profileResponse.errorMessage);
      }

      final currentProfile = profileResponse.userData!;
      final currentPicturePath = currentProfile['profile_picture_path'] as String?;

      // Delete the file if it exists
      if (currentPicturePath != null && currentPicturePath.isNotEmpty) {
        try {
          final file = File(currentPicturePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Warning: Failed to delete profile picture file: $e');
          // Continue with database update even if file deletion fails
        }
      }

      // Update database to remove picture path
      final response = await _database.updateProfilePicture(
        userId: userId,
        imagePath: '', // Empty string to remove picture
      );

      if (!response.success) {
        return ProfileResult.failure(response.errorMessage);
      }

      return ProfileResult.success(response.userData!);
    } catch (e) {
      return ProfileResult.failure('Failed to delete profile picture: ${e.toString()}');
    }
  }

  /// Get profile picture path
  Future<String?> getProfilePicturePath() async {
    try {
      final userId = await _secureStorage.getUserId();
      if (userId == null) {
        return null;
      }

      final response = await _database.getUserById(userId);
      if (!response.success) {
        return null;
      }

      final profile = response.userData!;
      final picturePath = profile['profile_picture_path'] as String?;
      
      // Verify file still exists
      if (picturePath != null && picturePath.isNotEmpty) {
        final file = File(picturePath);
        if (await file.exists()) {
          return picturePath;
        } else {
          // File doesn't exist, clear the database record
          await _database.updateProfilePicture(userId: userId, imagePath: '');
          return null;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting profile picture path: $e');
      return null;
    }
  }

  /// Check if profile picture exists
  Future<bool> hasProfilePicture() async {
    final path = await getProfilePicturePath();
    return path != null && path.isNotEmpty;
  }

  /// Get user statistics (placeholder for future features)
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final userId = await _secureStorage.getUserId();
      if (userId == null) {
        return {};
      }

      // This could be expanded to include various user statistics
      // For now, return basic profile info
      final profileResponse = await _database.getUserById(userId);
      if (!profileResponse.success) {
        return {};
      }

      final profile = profileResponse.userData!;
      return {
        'account_created': profile['created_at'],
        'last_updated': profile['updated_at'],
        'has_profile_picture': await hasProfilePicture(),
      };
    } catch (e) {
      debugPrint('Error getting user statistics: $e');
      return {};
    }
  }
}

/// Profile operation result
class ProfileResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const ProfileResult._(this.success, this.message, this.data);

  factory ProfileResult.success(Map<String, dynamic> data) {
    return ProfileResult._(true, 'Success', data);
  }

  factory ProfileResult.failure(String message) {
    return ProfileResult._(false, message, null);
  }

  /// Get profile data
  Map<String, dynamic>? get profileData => data;

  /// Check if operation failed
  bool get hasError => !success;

  /// Get error message
  String get errorMessage => message;
}

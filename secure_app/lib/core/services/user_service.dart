import '../../modules/auth/data/user_repository.dart';
import '../../modules/profile/data/user_profile_repository.dart';
import 'dart:io';

/// Combined user data model with profile information
class UserWithProfile {
  final User user;
  final UserProfile? profile;

  UserWithProfile({
    required this.user,
    this.profile,
  });

  String get displayName => user.name;
  String get email => user.email;
  String? get phoneNumber => user.phoneNumber;
  String? get profilePictureUrl => profile?.profilePictureUrl;
  String? get bio => profile?.bio;
  String? get city => profile?.city;
  String? get country => profile?.country;
}

/// User service for managing user and profile data
class UserService {
  static UserService? _instance;
  final UserRepository _userRepository = UserRepository();
  final UserProfileRepository _profileRepository = UserProfileRepository();

  UserService._();
  
  static UserService get instance {
    _instance ??= UserService._();
    return _instance!;
  }

  /// Get user with profile data
  Future<UserWithProfile?> getUserWithProfile(String userId) async {
    try {
      final user = await _userRepository.findById(userId);
      if (user == null) return null;

      final profile = await _profileRepository.getProfileByUserId(userId);
      
      return UserWithProfile(
        user: user,
        profile: profile,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get user with profile by email
  Future<UserWithProfile?> getUserWithProfileByEmail(String email) async {
    try {
      final user = await _userRepository.findByEmail(email);
      if (user == null) return null;

      final profile = await _profileRepository.getProfileByUserId(user.userId);
      
      return UserWithProfile(
        user: user,
        profile: profile,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create user profile if it doesn't exist
  Future<void> ensureUserProfile(String userId) async {
    try {
      final profileExists = await _profileRepository.profileExists(userId);
      if (!profileExists) {
        await _profileRepository.createUserProfile(userId: userId);
      }
    } catch (e) {
      // Profile creation is optional, don't throw
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String userId, {
    String? profilePictureUrl,
    String? bio,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? city,
    String? country,
    String? timezone,
    String? language,
  }) async {
    await _profileRepository.updateUserProfile(
      userId,
      profilePictureUrl: profilePictureUrl,
      bio: bio,
      dateOfBirth: dateOfBirth,
      gender: gender,
      address: address,
      city: city,
      country: country,
      timezone: timezone,
      language: language,
    );
  }

  /// Update user basic information
  Future<void> updateUserInfo(String userId, {
    String? name,
    String? phoneNumber,
  }) async {
    await _userRepository.updateUser(
      userId,
      name: name,
      phoneNumber: phoneNumber,
    );
  }

  /// Upload profile picture
  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    return await _profileRepository.uploadProfilePicture(userId, imageFile);
  }

  /// Get profile picture file
  Future<File?> getProfilePictureFile(String userId) async {
    return await _profileRepository.getProfilePictureFile(userId);
  }

  /// Delete profile picture
  Future<bool> deleteProfilePicture(String userId) async {
    return await _profileRepository.deleteProfilePicture(userId);
  }
}

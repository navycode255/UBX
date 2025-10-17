import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/image_service.dart';

/// User profile data model
class UserProfile {
  final String id;
  final String userId;
  final String? profilePictureUrl;
  final String? bio;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? city;
  final String? country;
  final String timezone;
  final String language;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    this.profilePictureUrl,
    this.bio,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.city,
    this.country,
    this.timezone = 'UTC',
    this.language = 'en',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'profile_picture_url': profilePictureUrl,
      'bio': bio,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'gender': gender,
      'address': address,
      'city': city,
      'country': country,
      'timezone': timezone,
      'language': language,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'].toString(),
      userId: map['user_id'] ?? '',
      profilePictureUrl: map['profile_picture_url'],
      bio: map['bio'],
      dateOfBirth: map['date_of_birth'] != null 
          ? DateTime.parse(map['date_of_birth'].toString())
          : null,
      gender: map['gender'],
      address: map['address'],
      city: map['city'],
      country: map['country'],
      timezone: map['timezone'] ?? 'UTC',
      language: map['language'] ?? 'en',
      createdAt: DateTime.parse(map['created_at'].toString()),
      updatedAt: DateTime.parse(map['updated_at'].toString()),
    );
  }
}

/// User profile repository for database operations
class UserProfileRepository {
  final DatabaseService _db = DatabaseService.instance;
  final _uuid = const Uuid();

  /// Create a new user profile
  Future<String> createUserProfile({
    required String userId,
    String? profilePictureUrl,
    String? bio,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? city,
    String? country,
    String timezone = 'UTC',
    String language = 'en',
  }) async {
    final profileId = _uuid.v4();
    final now = DateTime.now();

    final sql = '''
      INSERT INTO user_profiles (
        id, user_id, profile_picture_url, bio, date_of_birth, 
        gender, address, city, country, timezone, language, 
        created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''';

    final values = [
      profileId,
      userId,
      profilePictureUrl,
      bio,
      dateOfBirth?.toIso8601String().split('T')[0],
      gender,
      address,
      city,
      country,
      timezone,
      language,
      now,
      now,
    ];

    await _db.insert(sql, values);
    return profileId;
  }

  /// Get user profile by user ID
  Future<UserProfile?> getProfileByUserId(String userId) async {
    final sql = 'SELECT * FROM user_profiles WHERE user_id = ?';
    final result = await _db.queryFirst(sql, [userId]);
    
    return result != null ? UserProfile.fromMap(result.fields) : null;
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
    final updates = <String>[];
    final values = <Object?>[];

    if (profilePictureUrl != null) {
      updates.add('profile_picture_url = ?');
      values.add(profilePictureUrl);
    }
    if (bio != null) {
      updates.add('bio = ?');
      values.add(bio);
    }
    if (dateOfBirth != null) {
      updates.add('date_of_birth = ?');
      values.add(dateOfBirth.toIso8601String().split('T')[0]);
    }
    if (gender != null) {
      updates.add('gender = ?');
      values.add(gender);
    }
    if (address != null) {
      updates.add('address = ?');
      values.add(address);
    }
    if (city != null) {
      updates.add('city = ?');
      values.add(city);
    }
    if (country != null) {
      updates.add('country = ?');
      values.add(country);
    }
    if (timezone != null) {
      updates.add('timezone = ?');
      values.add(timezone);
    }
    if (language != null) {
      updates.add('language = ?');
      values.add(language);
    }

    if (updates.isNotEmpty) {
      updates.add('updated_at = ?');
      values.add(DateTime.now());
      values.add(userId);

      final sql = 'UPDATE user_profiles SET ${updates.join(', ')} WHERE user_id = ?';
      await _db.update(sql, values);
    }
  }

  /// Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    final sql = 'DELETE FROM user_profiles WHERE user_id = ?';
    await _db.update(sql, [userId]);
  }

  /// Check if user profile exists
  Future<bool> profileExists(String userId) async {
    final sql = 'SELECT COUNT(*) as count FROM user_profiles WHERE user_id = ?';
    final result = await _db.queryFirst(sql, [userId]);
    return result?.fields['count'] > 0;
  }

  /// Upload and save profile picture
  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final imageService = ImageService.instance;
      
      // Save image locally
      final localPath = await imageService.saveImageToLocal(imageFile, userId);
      if (localPath == null) return null;
      
      // Convert to base64 for database storage
      final base64String = await imageService.imageToBase64(imageFile);
      if (base64String == null) return null;
      
      // Update profile with image data
      await updateUserProfile(
        userId,
        profilePictureUrl: localPath,
      );
      
      return localPath;
    } catch (e) {
      return null;
    }
  }

  /// Get profile picture file
  Future<File?> getProfilePictureFile(String userId) async {
    try {
      final profile = await getProfileByUserId(userId);
      if (profile?.profilePictureUrl != null) {
        final imageService = ImageService.instance;
        return imageService.getImageFile(profile!.profilePictureUrl);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Delete profile picture
  Future<bool> deleteProfilePicture(String userId) async {
    try {
      final imageService = ImageService.instance;
      
      // Delete local file
      await imageService.deleteLocalImage(userId);
      
      // Update database
      await updateUserProfile(
        userId,
        profilePictureUrl: null,
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }
}

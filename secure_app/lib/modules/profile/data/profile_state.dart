import 'dart:io';

/// Profile state model
class ProfileState {
  final String userName;
  final String userEmail;
  final String userPhoneNumber;
  final bool hasProfilePicture;
  final File? profilePictureFile;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.userName = 'Loading...',
    this.userEmail = 'Loading...',
    this.userPhoneNumber = '',
    this.hasProfilePicture = false,
    this.profilePictureFile,
    this.isLoading = true,
    this.error,
  });

  ProfileState copyWith({
    String? userName,
    String? userEmail,
    String? userPhoneNumber,
    bool? hasProfilePicture,
    File? profilePictureFile,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhoneNumber: userPhoneNumber ?? this.userPhoneNumber,
      hasProfilePicture: hasProfilePicture ?? this.hasProfilePicture,
      profilePictureFile: profilePictureFile ?? this.profilePictureFile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get hasError => error != null;
  bool get isLoaded => !isLoading && error == null;
}

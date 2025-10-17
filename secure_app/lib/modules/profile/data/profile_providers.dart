import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'profile_notifier.dart';
import 'profile_state.dart';

/// Profile state notifier provider
final profileNotifierProvider = NotifierProvider<ProfileNotifier, ProfileState>(() {
  return ProfileNotifier();
});

/// Profile data providers
final profileDataProvider = Provider<ProfileState>((ref) {
  return ref.watch(profileNotifierProvider);
});

/// User name provider
final userNameProvider = Provider<String>((ref) {
  return ref.watch(profileNotifierProvider).userName;
});

/// User email provider
final userEmailProvider = Provider<String>((ref) {
  return ref.watch(profileNotifierProvider).userEmail;
});

/// User phone number provider
final userPhoneNumberProvider = Provider<String>((ref) {
  return ref.watch(profileNotifierProvider).userPhoneNumber;
});

/// Profile picture provider
final profilePictureProvider = Provider<File?>((ref) {
  return ref.watch(profileNotifierProvider).profilePictureFile;
});

/// Has profile picture provider
final hasProfilePictureProvider = Provider<bool>((ref) {
  return ref.watch(profileNotifierProvider).hasProfilePicture;
});

/// Loading state provider
final profileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(profileNotifierProvider).isLoading;
});

/// Error state provider
final profileErrorProvider = Provider<String?>((ref) {
  return ref.watch(profileNotifierProvider).error;
});

/// Profile loaded state provider
final profileLoadedProvider = Provider<bool>((ref) {
  final state = ref.watch(profileNotifierProvider);
  return state.isLoaded;
});

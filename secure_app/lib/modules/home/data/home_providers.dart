import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_notifier.dart';
import 'home_state.dart';

/// Home page providers
class HomeProviders {
  // Private constructor to prevent instantiation
  HomeProviders._();

  /// Home state notifier provider
  static final homeNotifierProvider = NotifierProvider<HomeNotifier, HomeState>(
    () => HomeNotifier(),
  );

  /// Home data provider (alias for easier access)
  static final homeDataProvider = homeNotifierProvider;

  /// Home loading state provider
  static final homeLoadingProvider = Provider<bool>((ref) {
    return ref.watch(homeNotifierProvider).isLoading;
  });

  /// Home error provider
  static final homeErrorProvider = Provider<String?>((ref) {
    return ref.watch(homeNotifierProvider).error;
  });

  /// User data provider
  static final userDataProvider = Provider<Map<String, String?>>((ref) {
    return ref.watch(homeNotifierProvider).userData;
  });

  /// Biometric status provider
  static final biometricStatusProvider = Provider<bool>((ref) {
    return ref.watch(homeNotifierProvider).isBiometricEnabled;
  });

  /// Biometric type provider
  static final biometricTypeProvider = Provider<String>((ref) {
    return ref.watch(homeNotifierProvider).biometricType;
  });
}

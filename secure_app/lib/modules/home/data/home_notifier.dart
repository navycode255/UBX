import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/biometric_service.dart';
import 'home_state.dart';

/// Home page state notifier
class HomeNotifier extends Notifier<HomeState> {
  final AuthService _authService = AuthService.instance;
  final BiometricService _biometricService = BiometricService.instance;

  @override
  HomeState build() {
    // Initialize with loading state
    return const HomeState();
  }

  /// Load user data and biometric status
  Future<void> loadUserData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Load user data and biometric status in parallel
      final results = await Future.wait([
        _authService.getAllUserData(),
        _biometricService.isBiometricLoginEnabled(),
        _biometricService.getPrimaryBiometricType(),
      ]);

      final userData = results[0] as Map<String, String?>;
      final isBiometricEnabled = results[1] as bool;
      final biometricType = results[2] as String;

      state = state.copyWith(
        isLoading: false,
        userData: userData,
        isBiometricEnabled: isBiometricEnabled,
        biometricType: biometricType,
        error: null,
      );

      // debugPrint('🏠 HomeNotifier: User data loaded successfully');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load user data: ${e.toString()}',
      );
      // debugPrint('🏠 HomeNotifier: Error loading user data: $e');
    }
  }

  /// Refresh only biometric status (more efficient)
  Future<void> refreshBiometricStatus() async {
    try {
      final isBiometricEnabled = await _biometricService.isBiometricLoginEnabled();
      final biometricType = await _biometricService.getPrimaryBiometricType();
      
      state = state.copyWith(
        isBiometricEnabled: isBiometricEnabled,
        biometricType: biometricType,
      );

      // debugPrint('🏠 HomeNotifier: Biometric status refreshed');
    } catch (e) {
      // debugPrint('🏠 HomeNotifier: Error refreshing biometric status: $e');
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Force refresh all data
  Future<void> refreshAll() async {
    await loadUserData();
  }
}

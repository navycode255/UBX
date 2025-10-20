/// Home page state
class HomeState {
  final bool isLoading;
  final bool isBiometricEnabled;
  final String biometricType;
  final Map<String, String?> userData;
  final String? error;

  const HomeState({
    this.isLoading = true,
    this.isBiometricEnabled = false,
    this.biometricType = 'Biometric',
    this.userData = const {},
    this.error,
  });

  HomeState copyWith({
    bool? isLoading,
    bool? isBiometricEnabled,
    String? biometricType,
    Map<String, String?>? userData,
    String? error,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      biometricType: biometricType ?? this.biometricType,
      userData: userData ?? this.userData,
      error: error ?? this.error,
    );
  }

  bool get hasError => error != null;
  bool get hasUserData => userData.isNotEmpty;
  String get userName => userData['name'] ?? 'User';
  String get userEmail => userData['email'] ?? 'user@example.com';
}

import 'package:flutter_test/flutter_test.dart';
import 'profile_state_test.dart' as profile_state_test;
import 'profile_providers_test.dart' as profile_providers_test;
import 'profile_notifier_test.dart' as profile_notifier_test;

void main() {
  group('Profile Module Test Suite', () {
    group('ProfileState Tests', () {
      profile_state_test.main();
    });

    group('Profile Providers Tests', () {
      profile_providers_test.main();
    });

    group('Profile Notifier Tests', () {
      profile_notifier_test.main();
    });
  });
}

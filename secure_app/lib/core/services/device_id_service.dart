import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'secure_storage_service.dart';

/// Device ID Service
/// 
/// Handles device unique identification for security and API requests
class DeviceIdService {
  static final DeviceIdService _instance = DeviceIdService._internal();
  factory DeviceIdService() => _instance;
  static DeviceIdService get instance => _instance;
  DeviceIdService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final SecureStorageService _secureStorage = SecureStorageService.instance;

  // Storage key for device ID
  static const String _deviceIdKey = 'device_unique_id';

  /// Get or create unique device ID
  Future<String> getDeviceId() async {
    try {
      // First, try to get stored device ID
      String? storedDeviceId = await _secureStorage.getString(_deviceIdKey);
      
      if (storedDeviceId != null && storedDeviceId.isNotEmpty) {
        return storedDeviceId;
      }

      // Generate new device ID based on device characteristics
      String deviceId = await _generateDeviceId();
      
      // Store the device ID securely
      await _secureStorage.setString(_deviceIdKey, deviceId);
      
      return deviceId;
    } catch (e) {
      // Fallback to a random UUID if device ID generation fails
      return _generateFallbackDeviceId();
    }
  }

  /// Generate device ID based on device characteristics
  Future<String> _generateDeviceId() async {
    try {
      if (Platform.isAndroid) {
        return await _generateAndroidDeviceId();
      } else if (Platform.isIOS) {
        return await _generateIOSDeviceId();
      } else {
        return _generateFallbackDeviceId();
      }
    } catch (e) {
      return _generateFallbackDeviceId();
    }
  }

  /// Generate Android device ID
  Future<String> _generateAndroidDeviceId() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      
      // Use a combination of device characteristics for uniqueness
      final deviceCharacteristics = [
        androidInfo.id, // Android ID
        androidInfo.model,
        androidInfo.brand,
        androidInfo.device,
        androidInfo.product,
        androidInfo.hardware,
        androidInfo.fingerprint,
      ].where((element) => element != null && element.isNotEmpty).join('|');
      
      // Create a hash of the device characteristics
      return _createHash(deviceCharacteristics);
    } catch (e) {
      return _generateFallbackDeviceId();
    }
  }

  /// Generate iOS device ID
  Future<String> _generateIOSDeviceId() async {
    try {
      final iosInfo = await _deviceInfo.iosInfo;
      
      // Use a combination of device characteristics for uniqueness
      final deviceCharacteristics = [
        iosInfo.identifierForVendor,
        iosInfo.name,
        iosInfo.model,
        iosInfo.systemName,
        iosInfo.systemVersion,
        iosInfo.localizedModel,
      ].where((element) => element != null && element.isNotEmpty).join('|');
      
      // Create a hash of the device characteristics
      return _createHash(deviceCharacteristics);
    } catch (e) {
      return _generateFallbackDeviceId();
    }
  }

  /// Generate fallback device ID using timestamp and random data
  String _generateFallbackDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    return _createHash('fallback_${timestamp}_${random}');
  }

  /// Create a hash from device characteristics
  String _createHash(String input) {
    // Use a simple hash function for device ID generation
    // In production, you might want to use a more sophisticated approach
    final bytes = input.codeUnits;
    int hash = 0;
    for (int byte in bytes) {
      hash = ((hash << 5) - hash) + byte;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return 'device_${hash.abs().toRadixString(36)}';
  }

  /// Get device information for debugging/logging
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'Android',
          'id': androidInfo.id,
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'product': androidInfo.product,
          'hardware': androidInfo.hardware,
          'fingerprint': androidInfo.fingerprint,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'iOS',
          'identifierForVendor': iosInfo.identifierForVendor,
          'name': iosInfo.name,
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'localizedModel': iosInfo.localizedModel,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      } else {
        return {
          'platform': 'Unknown',
          'error': 'Unsupported platform',
        };
      }
    } catch (e) {
      return {
        'platform': 'Unknown',
        'error': e.toString(),
      };
    }
  }

  /// Clear stored device ID (for testing or reset purposes)
  Future<void> clearDeviceId() async {
    try {
      await _secureStorage.delete(_deviceIdKey);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Check if device ID is stored
  Future<bool> hasDeviceId() async {
    try {
      final deviceId = await _secureStorage.getString(_deviceIdKey);
      return deviceId != null && deviceId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}


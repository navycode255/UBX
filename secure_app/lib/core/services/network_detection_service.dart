import 'dart:io';
import 'package:http/http.dart' as http;

/// Network Detection Service
/// Automatically detects the correct API endpoint based on network configuration
class NetworkDetectionService {
  static final NetworkDetectionService _instance = NetworkDetectionService._internal();
  factory NetworkDetectionService() => _instance;
  NetworkDetectionService._internal();

  // Possible API endpoints to try (HTTPS preferred, HTTP fallback for development)
  static const List<String> _possibleEndpoints = [
    'https://10.197.105.153:5000', // Current computer IP (for phone testing) - HTTPS
    'https://10.112.78.153:5000',  // Previous Wi-Fi IP - HTTPS
    'http://localhost:5000',       // Local development (emulator only) - HTTP for local dev
    'https://192.168.137.1:5000',  // Computer hotspot gateway - HTTPS
    'https://192.168.43.1:5000',   // Android hotspot gateway - HTTPS
    'https://192.168.137.2:5000',  // Computer connected to phone hotspot - HTTPS
    'https://192.168.43.2:5000',   // Computer connected to phone hotspot - HTTPS
    'https://192.168.1.1:5000',    // Router gateway - HTTPS
    // HTTP fallbacks for development
    'http://10.197.105.153:5000',  // HTTP fallback
    'http://10.112.78.153:5000',   // HTTP fallback
  ];

  String? _cachedEndpoint;
  DateTime? _lastCheck;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Get the working API endpoint
  Future<String> getApiEndpoint() async {

    
    // Return cached endpoint if still valid
    if (_cachedEndpoint != null && 
        _lastCheck != null && 
        DateTime.now().difference(_lastCheck!) < _cacheTimeout) {

      return _cachedEndpoint!;
    }

    // Get current computer IP and add to endpoints
    final currentIp = await _getCurrentComputerIp();
    final endpoints = _getEndpointsWithCurrentIp(currentIp);
    

    // Try each endpoint to find the working one
    for (final endpoint in endpoints) {
      try {

        final isWorking = await _testEndpoint(endpoint);
        if (isWorking) {

          _cachedEndpoint = endpoint;
          _lastCheck = DateTime.now();
          return endpoint;
        } else {

        }
      } catch (e) {

        // Continue to next endpoint
        continue;
      }
    }

    // If no endpoint works, return the first one as fallback

    _cachedEndpoint = endpoints.first;
    _lastCheck = DateTime.now();
    return _cachedEndpoint!;
  }

  /// Get current computer IP address
  Future<String?> _getCurrentComputerIp() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {

            return addr.address;
          }
        }
      }
    } catch (e) {

    }
    return null;
  }

  /// Get endpoints list with current IP prioritized
  List<String> _getEndpointsWithCurrentIp(String? currentIp) {
    final endpoints = List<String>.from(_possibleEndpoints);
    
    if (currentIp != null) {
      final currentEndpoint = 'http://$currentIp:5000';
      // Remove if already exists and add to front
      endpoints.remove(currentEndpoint);
      endpoints.insert(0, currentEndpoint);

    }
    
    return endpoints;
  }

  /// Test if an endpoint is working
  Future<bool> _testEndpoint(String endpoint) async {
    try {
      final uri = Uri.parse('$endpoint/api/health');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 2),
        onTimeout: () {

          throw Exception('Timeout');
        },
      );
      

      return response.statusCode == 200;
    } catch (e) {

      return false;
    }
  }

  /// Get current network info for debugging
  Future<Map<String, dynamic>> getNetworkInfo() async {
    final endpoint = await getApiEndpoint();
    final isWorking = await _testEndpoint(endpoint);
    
    return {
      'currentEndpoint': endpoint,
      'isWorking': isWorking,
      'lastChecked': _lastCheck?.toIso8601String(),
      'allEndpoints': _possibleEndpoints,
    };
  }

  /// Force refresh of endpoint detection
  Future<String> refreshEndpoint() async {
    _cachedEndpoint = null;
    _lastCheck = null;
    return await getApiEndpoint();
  }
}

import 'dart:io';

/// Network utilities for automatic IP detection
class NetworkUtils {
  /// Automatically detect the best IP address for database connection
  /// This will work for both WiFi and phone hotspot scenarios
  static Future<String> getBestDatabaseHost() async {
    try {
      // Get all network interfaces
      final interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        includeLoopback: false,
      );

      // Priority order for IP detection
      final List<String> preferredPrefixes = [
        '192.168.43.',  // Android hotspot
        '192.168.137.', // Android hotspot alternative
        '172.20.10.',   // iPhone hotspot
        '192.168.1.',   // Common home router
        '192.168.0.',   // Common home router
        '10.0.0.',      // Some routers
        '10.112.',      // Your current network
      ];

      // Find the best IP address
      for (final prefix in preferredPrefixes) {
        for (final interface in interfaces) {
          for (final addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4) {
              final ip = addr.address;
              if (ip.startsWith(prefix)) {

                return ip;
              }
            }
          }
        }
      }

      // Fallback: return the first non-loopback IPv4 address
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {

            return addr.address;
          }
        }
      }

      // Ultimate fallback

      return 'localhost';
    } catch (e) {

      return 'localhost';
    }
  }

  /// Test database connectivity with a given host
  static Future<bool> testDatabaseConnection(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: Duration(seconds: 5));
      await socket.close();

      return true;
    } catch (e) {

      return false;
    }
  }

  /// Get the best available database host with connectivity test
  static Future<String> getBestDatabaseHostWithTest() async {
    final host = await getBestDatabaseHost();
    
    // Test the connection
    final isConnected = await testDatabaseConnection(host, 3306);
    
    if (isConnected) {
      return host;
    } else {
      // If the detected host doesn't work, try localhost

      final localhostWorks = await testDatabaseConnection('localhost', 3306);
      return localhostWorks ? 'localhost' : host;
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../config/env_config.dart';
import 'database_service.dart';
import 'api_service.dart';

/// Debug service for database connection testing and monitoring
class DebugService {
  static final DebugService _instance = DebugService._internal();
  factory DebugService() => _instance;
  DebugService._internal();

  /// Test database connection with detailed information
  static Future<DatabaseDebugInfo> testDatabaseConnection() async {
    final debugInfo = DatabaseDebugInfo();
    
    try {
      // Get configuration
      debugInfo.host = await EnvConfig.dbHost;
      debugInfo.port = EnvConfig.dbPort;
      debugInfo.database = EnvConfig.dbName;
      debugInfo.username = EnvConfig.dbUser;
      debugInfo.password = EnvConfig.dbPassword;
      debugInfo.timeout = EnvConfig.apiTimeoutSeconds;
      
      // Test API connection first
      final apiService = ApiService();
      final apiResponse = await apiService.healthCheck();
      debugInfo.apiTest = apiResponse.success;
      
      // Get network information
      final networkInfo = await apiService.getNetworkInfo();
      debugInfo.networkInfo = networkInfo;
      
      // Test network connectivity
      debugInfo.networkTest = await _testNetworkConnectivity(debugInfo.host, debugInfo.port);
      
      // Test database connection
      debugInfo.databaseTest = await _testDatabaseConnection(debugInfo);
      
      // Get system information
      debugInfo.systemInfo = await _getSystemInfo();
      
      debugInfo.isSuccess = debugInfo.apiTest && debugInfo.networkTest && debugInfo.databaseTest;
      
      if (debugInfo.isSuccess) {
        debugInfo.message = 'API and Database connections successful!';
      } else {
        debugInfo.message = 'Connection failed. Check details below.';
      }
      
    } catch (e) {
      debugInfo.isSuccess = false;
      debugInfo.message = 'Debug test failed: ${e.toString()}';
      debugInfo.error = e.toString();
    }
    
    return debugInfo;
  }

  /// Test network connectivity
  static Future<bool> _testNetworkConnectivity(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: Duration(seconds: 5));
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Test database connection
  static Future<bool> _testDatabaseConnection(DatabaseDebugInfo debugInfo) async {
    try {
      final db = DatabaseService.instance;
      return await db.testConnection();
    } catch (e) {
      debugInfo.error = e.toString();
      return false;
    }
  }

  /// Get system information
  static Future<SystemInfo> _getSystemInfo() async {
    return SystemInfo(
      platform: Platform.operatingSystem,
      version: Platform.operatingSystemVersion,
      isConnected: await _isConnectedToInternet(),
      localIp: await _getLocalIpAddress(),
    );
  }

  /// Check internet connectivity
  static Future<bool> _isConnectedToInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get local IP address
  static Future<String> _getLocalIpAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return 'Unknown';
  }
}

/// Database debug information model
class DatabaseDebugInfo {
  String host = '';
  int port = 0;
  String database = '';
  String username = '';
  String password = '';
  int timeout = 0;
  bool apiTest = false;
  bool networkTest = false;
  bool databaseTest = false;
  bool isSuccess = false;
  String message = '';
  String error = '';
  SystemInfo? systemInfo;
  Map<String, dynamic>? networkInfo;
}

/// System information model
class SystemInfo {
  final String platform;
  final String version;
  final bool isConnected;
  final String localIp;

  SystemInfo({
    required this.platform,
    required this.version,
    required this.isConnected,
    required this.localIp,
  });
}

/// Debug UI Widget for displaying database connection status
class DatabaseDebugWidget extends StatefulWidget {
  final bool showDetails;
  final VoidCallback? onRefresh;

  const DatabaseDebugWidget({
    super.key,
    this.showDetails = false,
    this.onRefresh,
  });

  @override
  State<DatabaseDebugWidget> createState() => _DatabaseDebugWidgetState();
}

class _DatabaseDebugWidgetState extends State<DatabaseDebugWidget> {
  DatabaseDebugInfo? _debugInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runDebugTest();
  }

  Future<void> _runDebugTest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final debugInfo = await DebugService.testDatabaseConnection();
      if (mounted) {
        setState(() {
          _debugInfo = debugInfo;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _debugInfo = DatabaseDebugInfo()
            ..isSuccess = false
            ..message = 'Debug test failed: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text('Testing database connection...'),
            ],
          ),
        ),
      );
    }

    if (_debugInfo == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(height: 8),
              const Text('Debug information not available'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _runDebugTest,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _debugInfo!.isSuccess ? Icons.check_circle : Icons.error,
                  color: _debugInfo!.isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Database Connection Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _debugInfo!.isSuccess ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _runDebugTest,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Status message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _debugInfo!.isSuccess ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _debugInfo!.isSuccess ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Text(
                _debugInfo!.message,
                style: TextStyle(
                  color: _debugInfo!.isSuccess ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            if (widget.showDetails) ...[
              const SizedBox(height: 16),
              
              // Connection Details
              _buildSection('Connection Details', [
                _buildInfoRow('Host', _debugInfo!.host),
                _buildInfoRow('Port', _debugInfo!.port.toString()),
                _buildInfoRow('Database', _debugInfo!.database),
                _buildInfoRow('Username', _debugInfo!.username),
                _buildInfoRow('Timeout', '${_debugInfo!.timeout}s'),
              ]),

              const SizedBox(height: 16),
              
              // Test Results
              _buildSection('Test Results', [
                _buildTestRow('API Connection', _debugInfo!.apiTest),
                _buildTestRow('Network Connectivity', _debugInfo!.networkTest),
                _buildTestRow('Database Connection', _debugInfo!.databaseTest),
              ]),

              if (_debugInfo!.networkInfo != null) ...[
                const SizedBox(height: 16),
                
                // Network Information
                _buildSection('Network Information', [
                  _buildInfoRow('Current Endpoint', _debugInfo!.networkInfo!['currentEndpoint'] ?? 'Unknown'),
                  _buildInfoRow('Is Working', _debugInfo!.networkInfo!['isWorking'] == true ? 'Yes' : 'No'),
                  _buildInfoRow('Last Checked', _debugInfo!.networkInfo!['lastChecked'] ?? 'Never'),
                ]),
              ],

              if (_debugInfo!.systemInfo != null) ...[
                const SizedBox(height: 16),
                
                // System Information
                _buildSection('System Information', [
                  _buildInfoRow('Platform', _debugInfo!.systemInfo!.platform),
                  _buildInfoRow('Version', _debugInfo!.systemInfo!.version),
                  _buildInfoRow('Local IP', _debugInfo!.systemInfo!.localIp),
                  _buildInfoRow('Internet', _debugInfo!.systemInfo!.isConnected ? 'Connected' : 'Disconnected'),
                ]),
              ],

              if (_debugInfo!.error.isNotEmpty) ...[
                const SizedBox(height: 16),
                
                // Error Details
                _buildSection('Error Details', [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      _debugInfo!.error,
                      style: TextStyle(
                        color: Colors.red[800],
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ]),
              ],
            ] else ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    // Toggle details view
                  });
                },
                child: const Text('Show Details'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestRow(String label, bool passed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            color: passed ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            passed ? 'PASS' : 'FAIL',
            style: TextStyle(
              color: passed ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

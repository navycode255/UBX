import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/biometric_service.dart';
import 'pin_setup_page.dart';
import 'pin_verification_dialog.dart';

class BiometricSettingsPage extends StatefulWidget {
  const BiometricSettingsPage({super.key});

  @override
  State<BiometricSettingsPage> createState() => _BiometricSettingsPageState();
}

class _BiometricSettingsPageState extends State<BiometricSettingsPage> {
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  String _biometricType = 'Biometric';
  bool _isPinEnabled = false;
  bool _isPinLocked = false;
  int _pinRemainingAttempts = 3;
  int _pinLockoutTimeRemaining = 0;
  bool _isLoading = false;
  
  final AuthService _authService = AuthService.instance;
  final BiometricService _biometricService = BiometricService.instance;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  /// Load current biometric and PIN status
  Future<void> _loadBiometricStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      final isEnabled = await _biometricService.isBiometricEnabled();
      final biometricType = await _biometricService.getPrimaryBiometricType();
      final pinStatus = await _authService.getPinSetupStatus();

      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable;
          _isBiometricEnabled = isEnabled;
          _biometricType = biometricType;
          _isPinEnabled = pinStatus.isEnabled;
          _isPinLocked = pinStatus.isLocked;
          _pinRemainingAttempts = pinStatus.remainingAttempts;
          _pinLockoutTimeRemaining = pinStatus.lockoutTimeRemaining;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load authentication status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Toggle biometric authentication
  Future<void> _toggleBiometric() async {
    setState(() {
      _isLoading = true;
    });

    try {
      AuthResult result;
      
      if (_isBiometricEnabled) {
        result = await _authService.disableBiometric();
      } else {
        result = await _authService.enableBiometric();
      }

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.green,
            ),
          );
          
          // Reload status
          await _loadBiometricStatus();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle biometric: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Setup PIN fallback
  Future<void> _setupPin() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PinSetupPage(isSetup: true),
      ),
    ).then((_) {
      // Refresh status after returning from PIN setup
      _loadBiometricStatus();
    });
  }

  /// Change PIN
  Future<void> _changePin() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PinSetupPage(isSetup: false),
      ),
    ).then((_) {
      // Refresh status after returning from PIN change
      _loadBiometricStatus();
    });
  }

  /// Disable PIN
  Future<void> _disablePin() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Disable PIN'),
        content: const Text(
          'Are you sure you want to disable PIN authentication? You will no longer be able to use PIN as a fallback for biometric authentication.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDisablePin();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  /// Confirm disable PIN with current PIN verification
  Future<void> _confirmDisablePin() async {
    showPinVerificationDialog(
      context: context,
      title: 'Verify Current PIN',
      subtitle: 'Enter your current PIN to disable PIN authentication',
      onSuccess: () async {
        final result = await _authService.disablePinFallback('');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: result.isSuccess ? Colors.green : Colors.red,
            ),
          );
          if (result.isSuccess) {
            _loadBiometricStatus();
          }
        }
      },
      onCancel: () {
        // User cancelled
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Biometric Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF8B0000),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B0000),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _biometricType.toLowerCase().contains('fingerprint')
                                  ? Icons.fingerprint
                                  : Icons.face,
                              color: const Color(0xFF8B0000),
                              size: 32,
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Biometric Authentication',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.05,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    _isBiometricAvailable
                                        ? 'Use $_biometricType for quick and secure sign-in'
                                        : 'Biometric authentication is not available on this device',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Status Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Status',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isBiometricAvailable
                                    ? (_isBiometricEnabled ? Colors.green : Colors.orange)
                                    : Colors.red,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Text(
                                _isBiometricAvailable
                                    ? (_isBiometricEnabled
                                        ? 'Biometric authentication is enabled'
                                        : 'Biometric authentication is available but not enabled')
                                    : 'Biometric authentication is not available',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Toggle Card
                  if (_isBiometricAvailable) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(screenWidth * 0.05),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isBiometricEnabled ? 'Disable Biometric' : 'Enable Biometric',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    Text(
                                      _isBiometricEnabled
                                          ? 'Turn off biometric authentication'
                                          : 'Turn on biometric authentication for quick sign-in',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isBiometricEnabled,
                                onChanged: _isLoading ? null : (_) => _toggleBiometric(),
                                activeThumbColor: const Color(0xFF8B0000),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: screenHeight * 0.03),

                  // PIN Status Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.pin,
                              color: const Color(0xFF8B0000),
                              size: 24,
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Text(
                              'PIN Fallback',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isPinEnabled ? Colors.green : Colors.grey,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Text(
                                _isPinEnabled
                                    ? 'PIN authentication is enabled as fallback'
                                    : 'PIN authentication is not set up',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        if (_isPinEnabled) ...[
                          SizedBox(height: screenHeight * 0.02),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _changePin,
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Change PIN'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B0000),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _disablePin,
                                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                                  label: const Text('Disable PIN'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          SizedBox(height: screenHeight * 0.02),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _setupPin,
                              icon: const Icon(Icons.add_circle_outline, size: 18),
                              label: const Text('Setup PIN Fallback'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B0000),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Information Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue[200]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              'Important Information',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Text(
                          '• Biometric authentication uses your device\'s built-in security features\n'
                          '• Your biometric data never leaves your device\n'
                          '• You can still sign in with your email and password\n'
                          '• Biometric settings are stored securely on your device',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.blue[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

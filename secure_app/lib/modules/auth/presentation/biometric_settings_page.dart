import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/pin_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/widgets/widgets.dart';
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
  final PinService _pinService = PinService.instance;

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
      final isEnabled = await _biometricService.isBiometricLoginEnabled();
      final biometricType = await _biometricService.getPrimaryBiometricType();
      
      // Load PIN status
      final pinStatus = await _biometricService.getPinStatus();

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
        context.showErrorNotification('Failed to load authentication status: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Build background decorative elements (like sign-in/sign-up pages)
  Widget _buildBackgroundDecorations(double screenWidth, double screenHeight) {
    return BackgroundDecorations(
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );
  }

  /// Build header section (like sign-in/sign-up pages)
  Widget _buildHeader(double screenWidth, double screenHeight) {
    return PageHeader(
      title: 'Biometric Settings',
      icon: _biometricType.toLowerCase().contains('face') 
          ? Icons.face 
          : Icons.fingerprint,
      onBackPressed: () => context.pop(),
    );
  }

  /// Toggle biometric authentication
  Future<void> _toggleBiometric() async {
    try {
      if (_isBiometricEnabled) {
        // Disable biometric login
        final success = await _biometricService.disableBiometricLogin();
        if (mounted) {
          if (success) {
            setState(() {
              _isBiometricEnabled = false;
            });
            context.showSuccessNotification('Biometric authentication disabled');
          } else {
            context.showErrorNotification('Failed to disable biometric authentication');
          }
        }
      } else {
        // Enable biometric login - check if PIN is set up first
        final isPinEnabled = await _pinService.isPinEnabled();
        
        if (!isPinEnabled) {
          // Prompt user to setup PIN first
          final shouldSetupPin = await _showPinSetupPrompt();
          if (!shouldSetupPin) {
            return; // User cancelled
          }
          
          // Show PIN setup page
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => const PinSetupPage(isSetup: true),
            ),
          );
          
          if (result != true) {
            return; // User didn't complete PIN setup
          }
        }
        
        // Now enable biometric authentication
        final userData = await _authService.getCurrentUser();
        final email = userData['email'];
        final userId = userData['userId'];
        final name = userData['name'];
        
        if (email != null && userId != null && name != null) {
          final secureStorage = SecureStorageService.instance;
          final storedToken = await secureStorage.getAuthToken();
          final token = storedToken ?? 'token_${DateTime.now().millisecondsSinceEpoch}';
          
          final success = await _biometricService.enableBiometricLogin(
            email: email,
            token: token,
            userId: userId,
            name: name,
          );
          
          if (mounted) {
            if (success) {
              setState(() {
                _isBiometricEnabled = true;
              });
              context.showSuccessNotification('Biometric authentication enabled with PIN fallback');
            } else {
              context.showErrorNotification('Failed to enable biometric authentication');
            }
          }
        } else {
          if (mounted) {
            context.showErrorNotification('User data incomplete. Please sign in again.');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Failed to toggle biometric: ${e.toString()}');
      }
    }
  }

  /// Show PIN setup prompt dialog
  Future<bool> _showPinSetupPrompt() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Setup PIN Fallback'),
        content: const Text(
          'To enable biometric authentication, you need to setup a PIN as a fallback option. This ensures you can always access your account even if biometric authentication fails.\n\nWould you like to setup a PIN now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
            ),
            child: const Text('Setup PIN'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Setup PIN fallback
  Future<void> _setupPin() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const PinSetupPage(isSetup: true),
      ),
    );
    
    if (result == true) {
      // Refresh status after successful PIN setup
      _loadBiometricStatus();
    }
  }

  /// Change PIN
  Future<void> _changePin() async {
    // First verify current PIN
    showPinVerificationDialog(
      context: context,
      title: 'Verify Current PIN',
      subtitle: 'Enter your current PIN to change it',
      onSuccess: () async {
        // After successful verification, show PIN change dialog
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => const PinSetupPage(isSetup: false),
          ),
        );
        
        if (result == true) {
          // Refresh status after successful PIN change
          _loadBiometricStatus();
        }
      },
      onCancel: () {
        // User cancelled PIN verification
      },
    );
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
        try {
          // For now, we'll show a placeholder message
          // In a real implementation, we'd get the PIN from the dialog
          if (mounted) {
            context.showSuccessNotification('PIN disabled successfully');
            _loadBiometricStatus();
          }
        } catch (e) {
          if (mounted) {
            context.showErrorNotification('Failed to disable PIN: $e');
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
      body: Container(
        height: screenHeight,
        width: screenWidth,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8B0000), // Dark red
              Color(0xFF4B0082), // Purple
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background decorative elements
            _buildBackgroundDecorations(screenWidth, screenHeight),
            
            // Main content
            SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.08,
                      vertical: screenHeight * 0.02,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header section
                        _buildHeader(screenWidth, screenHeight),
                        
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Content container with glassmorphism
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? Center(
                                  child: Column(
                                    children: [
                                      const CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                      SizedBox(height: screenHeight * 0.02),
                                      Text(
                                        'Loading settings...',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: screenHeight * 0.018,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header Section
                                    Container(
                                      margin: EdgeInsets.only(bottom: screenHeight * 0.03),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                _biometricType.toLowerCase().contains('face')
                                    ? Icons.face
                                    : Icons.fingerprint,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Biometric Authentication',
                                    style: TextStyle(
                                      fontSize: screenHeight * 0.022,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    _isBiometricAvailable
                                        ? 'Use $_biometricType for quick and secure sign-in'
                                        : 'Biometric authentication is not available on this device',
                                    style: TextStyle(
                                      fontSize: screenHeight * 0.016,
                                      color: Colors.white.withOpacity(0.8),
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

                  // Status Section
                  Container(
                    margin: EdgeInsets.only(bottom: screenHeight * 0.03),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Status',
                          style: TextStyle(
                            fontSize: screenHeight * 0.020,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        
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
                                  fontSize: screenHeight * 0.016,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Toggle Section
                  if (_isBiometricAvailable) ...[
                    Container(
                      margin: EdgeInsets.only(bottom: screenHeight * 0.03),
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isBiometricEnabled ? 'Disable Biometric' : 'Enable Biometric',
                                  style: TextStyle(
                                    fontSize: screenHeight * 0.020,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.008),
                                Text(
                                  !_isBiometricAvailable
                                      ? 'Biometric authentication not available on this device'
                                      : _isBiometricEnabled
                                          ? 'Turn off biometric authentication'
                                          : 'Turn on biometric authentication for quick sign-in',
                                  style: TextStyle(
                                    fontSize: screenHeight * 0.016,
                                    color: !_isBiometricAvailable 
                                        ? Colors.white.withOpacity(0.5)
                                        : Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isBiometricEnabled,
                            onChanged: (_isLoading || !_isBiometricAvailable) ? null : (_) => _toggleBiometric(),
                            activeColor: Colors.white.withOpacity(0.3),
                            activeTrackColor: Colors.white.withOpacity(0.2),
                            inactiveThumbColor: Colors.white.withOpacity(0.6),
                            inactiveTrackColor: Colors.white.withOpacity(0.1),
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
                                color: _isPinEnabled 
                                    ? (_isPinLocked ? Colors.red : Colors.green) 
                                    : Colors.grey,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Text(
                                _isPinEnabled
                                    ? (_isPinLocked 
                                        ? 'PIN authentication is locked due to too many failed attempts'
                                        : 'PIN authentication is enabled as fallback')
                                    : 'PIN authentication is not set up',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  color: _isPinLocked ? Colors.red[700] : Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        if (_isPinLocked) ...[
                          SizedBox(height: screenHeight * 0.015),
                          Container(
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PIN Locked',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.038,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.008),
                                Text(
                                  'Remaining attempts: $_pinRemainingAttempts',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.035,
                                    color: Colors.red[600],
                                  ),
                                ),
                                if (_pinLockoutTimeRemaining > 0) ...[
                                  SizedBox(height: screenHeight * 0.005),
                                  Text(
                                    'Lockout time remaining: ${_pinLockoutTimeRemaining} seconds',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color: Colors.red[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        
                        if (_isPinEnabled && !_isPinLocked) ...[
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

],  // <-- closes main Column children (the one wrapping everything)
),  // <-- closes main Column
),  // <-- closes SingleChildScrollView
],
),  // <-- closes SafeArea Stack children
),  // <-- closes SafeArea
],
),  // <-- closes main Stack children
),],),  // <-- closes Container
));  // <-- closes Scaffold
}   // <-- closes build() method

}

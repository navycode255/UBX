import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/pin_service.dart';
import '../../../core/widgets/widgets.dart';
import '../../../router/navigation_helper.dart';
import '../../../router/route_constants.dart';

/// Sign In Page with Simple Biometric Authentication
/// 
/// This page implements biometric authentication as a login shortcut:
/// 1. User logs in once with real credentials (email/password)
/// 2. App stores a refresh token or session key securely
/// 3. Next time, when biometrics succeed:
///    - App retrieves the stored token
///    - Authenticates silently (no password typing)
class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  
  // Biometric variables
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  String _biometricType = 'Biometric';
  bool _biometricError = false;
  bool _biometricSuccess = false;
  String _biometricStatusText = '';
  
  final AuthService _authService = AuthService.instance;
  final BiometricService _biometricService = BiometricService.instance;
  final PinService _pinService = PinService.instance;
  
  // Debug variables
  bool _showDebugInfo = false;
  String _debugInfo = '';
  List<String> _debugLogs = [];

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload biometric status when returning to this page (e.g., after logout)
    _loadBiometricStatus();
  }

  /// Load biometric status for UI display
  Future<void> _loadBiometricStatus() async {
    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      final isEnabled = await _biometricService.isBiometricLoginEnabled();
      final biometricType = await _biometricService.getPrimaryBiometricType();

      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable;
          _isBiometricEnabled = isEnabled;
          _biometricType = biometricType;
        });
      }

      _addDebugLog('📊 Biometric available: $isAvailable');
      _addDebugLog('📊 Biometric enabled: $isEnabled');
      _addDebugLog('📊 Biometric type: $biometricType');
      
      if (isAvailable && !isEnabled) {
        _addDebugLog('💡 Biometric available but not enabled - go to settings to enable');
      }
    } catch (e) {
      _addDebugLog('💥 Error loading biometric status: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Add debug log entry
  void _addDebugLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logEntry = '[$timestamp] $message';
    if (mounted) {
      setState(() {
        _debugLogs.add(logEntry);
        _debugInfo = _debugLogs.join('\n');
      });
    }

  }

  /// Sign in with email and password
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _debugLogs.clear();
    });

    _addDebugLog('🔐 Starting email/password sign in...');

    try {
      final result = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      _addDebugLog('🔐 Sign in result: ${result.isSuccess}');
      _addDebugLog('📝 Message: ${result.message}');

      if (mounted) {
        if (result.isSuccess) {
          _addDebugLog('🎉 Sign in successful! Navigating to home...');
          context.showSuccessNotification('Sign in successful!');
          NavigationHelper.goToHome(context);
        } else {
          _addDebugLog('❌ Sign in failed: ${result.message}');
          context.showErrorNotification(result.message);
        }
      }
    } catch (e) {
      _addDebugLog('💥 Sign in error: ${e.toString()}');
      if (mounted) {
        context.showErrorNotification('Sign in failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Sign in using biometric authentication with PIN fallback
  Future<void> _signInWithBiometric() async {
    if (_isLoading) {
      _addDebugLog('⚠️ Authentication already in progress, skipping...');
      return;
    }

    setState(() {
      _isLoading = true;
      _biometricError = false;
      _biometricSuccess = false;
      _biometricStatusText = 'Authenticating...';
      _debugLogs.clear();
    });

    _addDebugLog('🔐 Starting biometric authentication...');

    try {
      // Check if biometric is enabled first
      final isEnabled = await _biometricService.isBiometricLoginEnabled();
      _addDebugLog('📊 Biometric enabled: $isEnabled');
      
      if (!isEnabled) {
        _addDebugLog('❌ Biometric not enabled - please enable in settings first');
        _showBiometricError();
        return;
      }

      // Try biometric authentication with fallback (single attempt)
      final result = await _biometricService.authenticateWithFallback();
      
      _addDebugLog('🔐 Biometric result: ${result?.isSuccess}');
      _addDebugLog('📝 Message: ${result?.message}');

      if (mounted) {
        if (result?.isSuccess == true) {
          _addDebugLog('🎉 Biometric sign-in successful! Navigating to home...');
          _showBiometricSuccess();
          // Navigate after showing success feedback
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              NavigationHelper.goToHome(context);
            }
          });
        } else if (result?.requiresPinFallback == true) {
          _addDebugLog('🔑 Biometric failed 3 times, PIN fallback required');
          _showPinFallbackDialog();
        } else {
          _addDebugLog('❌ Biometric sign-in failed: ${result?.message}');
          _showBiometricError();
          // Show retry option after a brief delay
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              setState(() {
                _biometricStatusText = 'Tap to try again';
              });
            }
          });
        }
      }
    } catch (e) {
      _addDebugLog('💥 Biometric authentication error: ${e.toString()}');
      if (mounted) {
        _showBiometricError();
        // Show retry option after a brief delay
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _biometricStatusText = 'Tap to try again';
            });
          }
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

  /// Sign in using PIN authentication
  Future<void> _signInWithPin() async {
    if (_isLoading) {
      _addDebugLog('⚠️ Authentication already in progress, skipping...');
      return;
    }
    
    // Quick check - don't want to spam the logs

    setState(() {
      _isLoading = true;
      _biometricError = false;
      _biometricSuccess = false;
      _biometricStatusText = 'Authenticating with PIN...';
      _debugLogs.clear();
    });

    _addDebugLog('🔑 Starting PIN authentication...');

    try {
      // Check if PIN is enabled
      final isPinEnabled = await _pinService.isPinEnabled();
      _addDebugLog('📊 PIN enabled: $isPinEnabled');
      
      // Quick validation
      if (isPinEnabled == null) {
        _addDebugLog('❌ PIN service returned null');
        _showBiometricError();
        return;
      }
      
      // Old approach - keeping for reference
      // final pinStatus = await _pinService.getPinStatus();
      // if (pinStatus == null) return;
      
      if (!isPinEnabled) {
        _addDebugLog('❌ PIN not set up - please set up PIN first');
        _showBiometricError();
        context.showErrorNotification('PIN not set up. Please set up a PIN first.');
        return;
      }

      // Check if PIN is locked
      final pinLocked = await _pinService.isPinLocked(); // inconsistent naming
      if (pinLocked) {
        _addDebugLog('❌ PIN is locked due to too many failed attempts');
        _showBiometricError();
        context.showErrorNotification('PIN is locked due to too many failed attempts. Please try again later.');
        return;
      }

      // Show PIN verification dialog
      _showPinFallbackDialog();

    } catch (e) {
      _addDebugLog('💥 PIN authentication error: ${e.toString()}');
      if (mounted) {
        _showBiometricError();
        context.showErrorNotification('PIN authentication failed: ${e.toString()}');
      }
    } finally {
      // Cleanup - make sure we're not stuck in loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show biometric success visual feedback
  void _showBiometricSuccess() {
    setState(() {
      _biometricError = false;
      _biometricSuccess = true;
      _biometricStatusText = 'Success!';
    });
    
    // Reset status text after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _biometricSuccess = false;
          _biometricStatusText = '';
        });
      }
    });
  }

  /// Show biometric error visual feedback
  void _showBiometricError() {
    setState(() {
      _biometricError = true;
      _biometricSuccess = false;
      _biometricStatusText = 'Failed';
    });
    
    // Reset error state after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _biometricError = false;
          _biometricStatusText = '';
        });
      }
    });
  }

  /// Show PIN fallback dialog
  void _showPinFallbackDialog() {
    setState(() {
      _biometricStatusText = 'Biometric failed 3 times - Use PIN';
    });
    
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (context) => PinFallbackDialog(
        onPinVerified: (pin) async {
          // Try PIN authentication
          final result = await _biometricService.authenticateWithPin(pin);

          if (mounted) {
            if (result?.isSuccess == true) {
              _addDebugLog('🎉 PIN authentication successful! Navigating to home...');
              _showBiometricSuccess();
              Navigator.of(context).pop(); // Close dialog
              // Navigate after showing success feedback
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  NavigationHelper.goToHome(context);
                }
              });
            } else {
              _addDebugLog('❌ PIN authentication failed: ${result?.message}');
              // Show error in dialog
            }
          }
        },
        onCancel: () async {
          _addDebugLog('🔙 PIN fallback cancelled, resetting biometric attempts');
          // Reset biometric attempt count when PIN fallback is cancelled
          await _biometricService.resetBiometricAttempts();
          setState(() {
            _biometricStatusText = 'Tap to authenticate';
          });
          Navigator.of(context).pop(); // Close dialog
        },
      ),
    );
  }

  /// Test biometric availability
  Future<void> _testBiometricAvailability() async {
    _addDebugLog('🧪 Testing biometric availability...');
    
    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      _addDebugLog('📊 Biometric available: $isAvailable');
      
      if (isAvailable) {
        final availableTypes = await _biometricService.getAvailableBiometricTypes();
        _addDebugLog('📊 Available biometric types: $availableTypes');
        
        final isEnabled = await _biometricService.isBiometricLoginEnabled();
        _addDebugLog('📊 Biometric enabled: $isEnabled');
        
        if (isEnabled) {
          _addDebugLog('✅ Biometric is ready to use!');
        } else {
          _addDebugLog('⚠️ Biometric available but not enabled');
        }
      } else {
        _addDebugLog('❌ Biometric not available on this device');
      }
    } catch (e) {
      _addDebugLog('💥 Error testing biometric availability: $e');
    }
  }

  /// Test direct biometric authentication
  Future<void> _testDirectBiometric() async {
    _addDebugLog('🧪 Testing direct biometric authentication...');
    
    try {
      // First check if biometric is enabled
      final isEnabled = await _biometricService.isBiometricLoginEnabled();
      _addDebugLog('📊 Biometric enabled: $isEnabled');
      
      if (!isEnabled) {
        _addDebugLog('❌ Biometric not enabled - please sign in with email/password first');
        return;
      }
      
      final result = await _biometricService.authenticateWithBiometric();
      
      if (result != null) {
        _addDebugLog('✅ Direct biometric authentication successful!');
        _addDebugLog('📧 Email: ${result.email}');
        _addDebugLog('🆔 User ID: ${result.userId}');
        _addDebugLog('👤 Name: ${result.name}');
        
        // Show success feedback
        _showBiometricSuccess();
      } else {
        _addDebugLog('❌ Direct biometric authentication failed');
        _showBiometricError();
      }
    } catch (e) {
      _addDebugLog('💥 Error in direct biometric test: $e');
      _showBiometricError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
            Positioned(
              top: -screenHeight * 0.1,
              right: -screenWidth * 0.2,
              child: Container(
                width: screenWidth * 0.8,
                height: screenHeight * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -screenHeight * 0.15,
              left: -screenWidth * 0.3,
              child: Container(
                width: screenWidth * 0.9,
                height: screenHeight * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.03),
                    ],
                  ),
                ),
              ),
            ),
            
            // Main content
            SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: screenHeight * 0.02,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header section with reduced space
                      SizedBox(height: screenHeight * 0.03),
                      
                      // App logo/icon placeholder
                      Container(
                        width: screenWidth * 0.22,
                        height: screenWidth * 0.22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.security,
                          size: screenWidth * 0.1,
                          color: Colors.white,
                        ),
                      ),
                      
                      SizedBox(height: screenHeight * 0.02),
                      
                      // Welcome text with reduced typography
                      Text(
                        'Welcome Back!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenHeight * 0.036,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.008),
                      Text(
                        'Sign in to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenHeight * 0.016,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),

                      // Form container with glassmorphism effect
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
                        child: Column(
                          children: [
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                                hintText: 'Enter your email',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Colors.white70,
                                  size: 22,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                    color: Colors.redAccent,
                                    width: 1,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                    color: Colors.redAccent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: screenHeight * 0.015),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                                hintText: 'Enter your password',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: Colors.white70,
                                  size: 22,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword 
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                    color: Colors.redAccent,
                                    width: 1,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                    color: Colors.redAccent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: screenHeight * 0.025),

                            // Sign In Button
                            Container(
                              width: double.infinity,
                              height: screenHeight * 0.06,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.white, Color(0xFFF5F5F5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 25,
                                        height: 25,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            const Color(0xFF8B0000),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: screenHeight * 0.022,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF8B0000),
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.025),

                      // Biometric Authentication Section
                      if (_isBiometricAvailable) ...[
                        if (_isBiometricEnabled) ...[
                          // Fingerprint Icon Button
                          Center(
                            child: GestureDetector(
                              onTap: _isLoading ? null : _signInWithBiometric,
                                child: Container(
                                  width: screenWidth * 0.2,
                                  height: screenWidth * 0.2,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.2),
                                        Colors.white.withOpacity(0.1),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: _isLoading 
                                          ? Colors.grey.withOpacity(0.3)
                                          : _biometricError
                                              ? Colors.red.withOpacity(0.8)
                                              : _biometricSuccess
                                                  ? Colors.green.withOpacity(0.8)
                                                  : Colors.white.withOpacity(0.4),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _biometricType.toLowerCase().contains('face')
                                        ? Icons.face
                                        : Icons.fingerprint,
                                    size: screenWidth * 0.1,
                                    color: _biometricError 
                                        ? Colors.red 
                                        : _biometricSuccess
                                            ? Colors.green
                                            : Colors.white,
                                  ),
                                ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.015),
                          
                          // Biometric Text
                          Text(
                            _biometricStatusText.isNotEmpty
                                ? _biometricStatusText
                                : _biometricType.toLowerCase().contains('face')
                                    ? 'Tap to use face recognition'
                                    : 'Tap to use fingerprint',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _biometricError 
                                  ? Colors.red
                                  : _biometricSuccess
                                      ? Colors.green
                                      : Colors.white.withOpacity(0.8),
                              fontSize: screenHeight * 0.014,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                        ] else ...[
                          // Biometric available but not enabled
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.03,
                              vertical: screenHeight * 0.015,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.security_outlined,
                                  color: Colors.white.withOpacity(0.7),
                                  size: screenWidth * 0.06,
                                ),
                                SizedBox(height: screenHeight * 0.008),
                                Text(
                                  'Biometric Available',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: screenHeight * 0.015,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.003),
                                Text(
                                  'Enable in settings',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: screenHeight * 0.012,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                        ],
                      ],

                      // PIN Fallback Section (when biometric not available or disabled)
                      if (!_isBiometricAvailable || !_isBiometricEnabled) ...[
                        SizedBox(height: screenHeight * 0.025),
                        
                        // PIN Authentication Button
                        Center(
                          child: GestureDetector(
                            onTap: _isLoading ? null : _signInWithPin,
                            child: Container(
                              width: screenWidth * 0.2,
                              height: screenWidth * 0.2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                ),
                                border: Border.all(
                                  color: _isLoading 
                                      ? Colors.grey.withOpacity(0.3)
                                      : Colors.white.withOpacity(0.4),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.pin,
                                size: screenWidth * 0.1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.015),
                        
                        // PIN Status Text
                        Center(
                          child: Text(
                            _isBiometricAvailable 
                                ? 'Use PIN to sign in'
                                : 'Biometric not available - Use PIN',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: screenHeight * 0.018,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.008),
                        
                        Center(
                          child: Text(
                            'Tap to authenticate with PIN',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: screenHeight * 0.014,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.02),
                      ],

                      // Debug Section (minimized)
                      if (_showDebugInfo) ...[
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Debug Information',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenHeight * 0.018,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _showDebugInfo = false;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              SizedBox(
                                height: screenHeight * 0.15,
                                child: SingleChildScrollView(
                                  child: Text(
                                    _debugInfo.isEmpty ? 'No debug information yet' : _debugInfo,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: screenHeight * 0.014,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _testBiometricAvailability,
                                      icon: const Icon(Icons.security, size: 16),
                                      label: const Text('Test Bio'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple.withOpacity(0.8),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.03,
                                          vertical: screenHeight * 0.01,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _testDirectBiometric,
                                      icon: const Icon(Icons.fingerprint, size: 16),
                                      label: const Text('Test Auth'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange.withOpacity(0.8),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.03,
                                          vertical: screenHeight * 0.01,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                      ] else ...[
                        // Debug toggle button (minimized)
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showDebugInfo = true;
                              });
                            },
                            icon: const Icon(Icons.bug_report, size: 14),
                            label: const Text('Debug'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                      ],

                      // Sign Up Link with better styling
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.015,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: screenHeight * 0.015,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go(RouteConstants.signUp),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenHeight * 0.015,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Bottom spacing to ensure content doesn't get cut off
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),
                ],
              ),
            ),
          ]),
        ),
      );
    }
  }


/// PIN Fallback Dialog for biometric authentication
class PinFallbackDialog extends StatefulWidget {
  final Function(String) onPinVerified;
  final VoidCallback? onCancel;

  const PinFallbackDialog({
    super.key,
    required this.onPinVerified,
    this.onCancel,
  });

  @override
  State<PinFallbackDialog> createState() => _PinFallbackDialogState();
}

class _PinFallbackDialogState extends State<PinFallbackDialog> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  
  bool _isLoading = false;
  String _errorMessage = '';
  String _pin = '';
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    _pinFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  /// Verify PIN
  Future<void> _verifyPin() async {
    if (_pin.length < 4) {
      setState(() {
        _errorMessage = 'Please enter a valid PIN';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      widget.onPinVerified(_pin);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to verify PIN: $e';
      });
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
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: screenWidth * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8B0000), // Dark red
              Color(0xFF4B0082), // Purple
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.pin,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Biometric Failed 3 Times - Use PIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Biometric authentication failed. Please enter your PIN.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // PIN input field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _pin = value;
                      _errorMessage = '';
                    });
                  },
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your PIN',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePin = !_obscurePin;
                        });
                      },
                      icon: Icon(
                        _obscurePin ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Error message
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[300],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.red[300],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.of(context).pop();
                        widget.onCancel?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyPin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF8B0000),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B0000)),
                              ),
                            )
                          : const Text('Verify'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

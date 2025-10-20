import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/pin_service.dart';
import '../../../core/services/pin_auth_service.dart';
import '../../../core/services/secure_storage_service.dart';
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
  String? _lastErrorMessage;
  
  // Biometric variables
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  String _biometricType = 'Biometric';
  bool _biometricError = false;
  bool _biometricSuccess = false;
  String _biometricStatusText = '';
  bool _pinFallbackWasShown = false;
  
  // PIN variables
  bool _isPinEnabled = false;
  
  final AuthService _authService = AuthService.instance;
  final BiometricService _biometricService = BiometricService.instance;
  final PinService _pinService = PinService.instance;
  final PinAuthService _pinAuthService = PinAuthService.instance;
  final SecureStorageService _secureStorage = SecureStorageService.instance;
  

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

  /// Load biometric and PIN status for UI display
  Future<void> _loadBiometricStatus() async {
    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      final isEnabled = await _biometricService.isBiometricLoginEnabled();
      final biometricType = await _biometricService.getPrimaryBiometricType();
      final isPinEnabled = await _pinService.isPinEnabled();

      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable;
          _isBiometricEnabled = isEnabled;
          _biometricType = biometricType;
          _isPinEnabled = isPinEnabled;
        });
      }

    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  /// Sign in with email and password
  Future<void> _signIn() async {
    if (_isLoading) {
      return;
    }
    
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _lastErrorMessage = null;
    });

    try {
      final result = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (result.isSuccess) {
          context.showSuccessNotification('Sign in successful!');
          NavigationHelper.goAfterLogin(context);
        } else {
          _handleSignInError(result.message);
        }
      }
    } catch (e) {
      if (mounted) {
        _handleSignInError('Sign in failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    
    // Safety timeout - ensure loading state is reset after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  /// Handle sign in error
  void _handleSignInError(String message) {
    if (mounted) {
      setState(() {
        _lastErrorMessage = message;
      });
      
      // Show error notification
      context.showErrorNotification(message, duration: const Duration(seconds: 4));
    }
  }


  /// Clear error state when user starts typing
  void _clearErrorState() {
    if (_lastErrorMessage != null) {
      setState(() {
        _lastErrorMessage = null;
      });
    }
  }

  /// Sign in using biometric authentication with PIN fallback
  Future<void> _signInWithBiometric() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _biometricError = false;
      _biometricSuccess = false;
      _biometricStatusText = 'Authenticating...';
      _lastErrorMessage = null;
    });

    try {
      // Check if biometric is enabled first
      final isEnabled = await _biometricService.isBiometricLoginEnabled();
      
      if (!isEnabled) {
        _showBiometricError();
        return;
      }

      // Try biometric authentication with fallback (single attempt)
      // If PIN fallback was previously shown, reset attempts and try fresh
      final result = _pinFallbackWasShown 
          ? await _biometricService.authenticateWithReset()
          : await _biometricService.authenticateWithFallback();
      
      if (mounted) {
        if (result?.isSuccess == true) {
          _pinFallbackWasShown = false; // Reset flag on success
          _showBiometricSuccess();
          
          // Store user credentials in regular authentication storage for PIN fallback
          await _secureStorage.storeEmail(result!.email!);
          await _secureStorage.storeUserId(result.userId!);
          await _secureStorage.storeName(result.name!);
          await _secureStorage.storeAuthToken(result.token!);
          
          // Set user as logged in after successful biometric authentication
          await _secureStorage.setLoggedIn(true);
          await _secureStorage.setAppLocked(false);
          
          // Navigate immediately without delay
          NavigationHelper.goAfterLogin(context);
        } else if (result?.isPinFallbackRequired == true) {
          _pinFallbackWasShown = true; // Mark that PIN fallback was shown
          _showPinFallbackDialog();
        } else {
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
      return;
    }

    setState(() {
      _isLoading = true;
      _biometricError = false;
      _biometricSuccess = false;
      _biometricStatusText = 'Authenticating with PIN...';
      _lastErrorMessage = null;
    });

    try {
      // Check if PIN is enabled
      final isPinEnabled = await _pinService.isPinEnabled();
      
      // Quick validation
      if (!isPinEnabled) {
        _showBiometricError();
        context.showErrorNotification('PIN not set up. Please set up a PIN first.');
        return;
      }

      // Check if PIN is locked
      final pinLocked = await _pinService.isPinLocked();
      if (pinLocked) {
        _showBiometricError();
        context.showErrorNotification('PIN is locked due to too many failed attempts. Please try again later.');
        return;
      }

      // Show PIN verification dialog
      _showPinFallbackDialog();

    } catch (e) {
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
          try {
            // Try PIN authentication using dedicated PIN auth service
            final result = await _pinAuthService.authenticateWithPin(pin);
            
            if (mounted) {
              if (result.isSuccess) {
                // Store user credentials in regular authentication storage
                await _secureStorage.storeEmail(result.email!);
                await _secureStorage.storeUserId(result.userId!);
                await _secureStorage.storeName(result.name!);
                await _secureStorage.storeAuthToken(result.token!);
                
                // Set user as logged in after successful PIN authentication
                await _secureStorage.setLoggedIn(true);
                await _secureStorage.setAppLocked(false);
                
                // Add a small delay to ensure state is properly set
                await Future.delayed(const Duration(milliseconds: 100));
                
                // Navigate BEFORE closing the dialog to avoid context issues
                NavigationHelper.goAfterLogin(context);
                
                // Show success notification and close dialog AFTER navigation
                _showBiometricSuccess();
                Navigator.of(context).pop(); // Close dialog
              } else {
                // Show error in dialog
                setState(() {
                  _lastErrorMessage = result.message ?? 'PIN authentication failed';
                });
              }
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _lastErrorMessage = 'PIN authentication error: $e';
              });
            }
          }
        },
        onCancel: () async {
          // Reset biometric attempt count when PIN fallback is cancelled
          await _biometricService.resetBiometricAttempts();
          _pinFallbackWasShown = false; // Reset flag when cancelled
          setState(() {
            _biometricStatusText = 'Tap to authenticate';
          });
          Navigator.of(context).pop(); // Close dialog
        },
      ),
    );
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
                              onChanged: (_) => _clearErrorState(),
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
                              onChanged: (_) => _clearErrorState(),
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
                                        _lastErrorMessage != null ? 'Try Again' : 'Sign In',
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
                        
                        // PIN Authentication Button (only show if PIN is enabled)
                        if (_isPinEnabled) ...[
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
  final Future<void> Function(String) onPinVerified;
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
    if (_pin.length != 4) {
      setState(() {
        _errorMessage = 'PIN must be exactly 4 digits';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      await widget.onPinVerified(_pin);
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
                          'Use PIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
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
                  maxLength: 4,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
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
                    counterText: '', // Hide the character counter
                    counter: const SizedBox.shrink(), // Completely remove counter
                  ),
                ),
              ),
              
              // Error message (hidden visually)
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                // Error message is now hidden but still logged for debugging
                const SizedBox.shrink(),
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

import 'package:flutter/material.dart';
import '../../../router/navigation_helper.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/biometric_service.dart';
import 'pin_verification_dialog.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _isPinFallbackAvailable = false;
  String _biometricType = 'Biometric';
  final AuthService _authService = AuthService.instance;
  final BiometricService _biometricService = BiometricService.instance;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Check biometric availability and status
  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      final isEnabled = await _biometricService.isBiometricEnabled();
      final biometricType = await _biometricService.getPrimaryBiometricType();
      final isPinAvailable = await _authService.isPinFallbackAvailable();

      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable;
          _isBiometricEnabled = isEnabled;
          _biometricType = biometricType;
          _isPinFallbackAvailable = isPinAvailable;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Handle biometric sign in with PIN fallback
  Future<void> _handleBiometricSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signInWithBiometricAndFallback();

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.green,
            ),
          );
          NavigationHelper.goToHome(context);
        }
      } else {
        // If biometric fails and PIN is available, show PIN fallback option
        if (mounted && _isPinFallbackAvailable) {
          _showPinFallbackOption();
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric sign in failed: ${e.toString()}'),
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

  /// Show PIN fallback option
  void _showPinFallbackOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.security,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text('Use PIN Instead'),
          ],
        ),
        content: const Text(
          'Biometric authentication failed. You can use your PIN as a fallback to sign in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showPinVerificationDialog();
            },
            child: const Text('Use PIN'),
          ),
        ],
      ),
    );
  }

  /// Show PIN verification dialog
  void _showPinVerificationDialog() {
    showPinVerificationDialog(
      context: context,
      title: 'Enter Your PIN',
      subtitle: 'Use your PIN to sign in securely',
      onSuccess: () {
        NavigationHelper.goToHome(context);
      },
      onCancel: () {
        // User cancelled PIN entry
      },
    );
  }

  /// Handle sign in process with secure storage
  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result.isSuccess) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to home page after successful sign in
          NavigationHelper.goToHome(context);
        }
      } else {
        // Show error message
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
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    
    return Scaffold(
        resizeToAvoidBottomInset: false,
      body: Container(
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
            // Background gradient circles/bubbles - responsive positioning
            Positioned(
              top: screenHeight * 0.06, // 6% from top
              right: screenWidth * 0.08, // 8% from right
              child: Container(
                width: screenWidth * 0.2, // 20% of screen width
                height: screenWidth * 0.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.15, // 15% from top
              right: screenWidth * 0.2, // 20% from right
              child: Container(
                width: screenWidth * 0.15, // 15% of screen width
                height: screenWidth * 0.15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.03),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.1, // 10% from top
              right: screenWidth * 0.3, // 30% from right
              child: Container(
                width: screenWidth * 0.1, // 10% of screen width
                height: screenWidth * 0.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.18, // 18% from top
              right: screenWidth * 0.12, // 12% from right
              child: Container(
                width: screenWidth * 0.08, // 8% of screen width
                height: screenWidth * 0.08,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.04),
                      Colors.white.withOpacity(0.01),
                    ],
                  ),
                ),
              ),
            ),
            // Purple to red gradient overlay for header area - responsive height
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.25, // 25% of screen height
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF4B0082).withOpacity(0.15), // Purple shadow on left
                      const Color(0xFF4B0082).withOpacity(0.05), // Purple fading
                      const Color(0xFF8B0000).withOpacity(0.1), // Red starting
                      const Color(0xFF8B0000).withOpacity(0.2), // Red on right
                    ],
                    stops: const [0.0, 0.3, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Main content
            Column(
              children: [
                // Header with title - responsive positioning
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      screenWidth * 0.05, // 5% from left
                      screenHeight * 0.02, // 2% from top
                      screenWidth * 0.05, // 5% from right
                      screenHeight * 0.07, // 7% from bottom
                    ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.08, // 8% of screen width
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Sign in!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.06, // 6% of screen width
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ),
                ),
            
            // Form Card - starts lower and covers full width to bottom
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                 child: Padding(
                   padding: EdgeInsets.fromLTRB(
                     screenWidth * 0.08, // 8% from left
                     screenHeight * 0.06, // 6% from top
                     screenWidth * 0.08, // 8% from right
                     screenHeight * 0.04, // 4% from bottom
                   ),
                   child: Form(
                     key: _formKey,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.stretch,
                       children: [
                         SizedBox(height: screenHeight * 0.025), // 2.5% of screen height
                        
                        // Email Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'Enter your email',
                                hintStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(color: Color(0xFF003447)),
                                ),
                                 contentPadding: const EdgeInsets.symmetric(
                                   horizontal: 16.0,
                                   vertical: 16.0,
                                 ),
                              ),
                              validator: FormValidators.validateEmail,
                            ),
                          ],
                        ),
                        
                         SizedBox(height: screenHeight * 0.03), // 3% of screen height
                        
                        // Password Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Password',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                hintStyle: const TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: const BorderSide(color: Color(0xFF003447)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 16.0,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: FormValidators.validatePassword,
                            ),
                          ],
                        ),
                        
                         SizedBox(height: screenHeight * 0.02), // 2% of screen height
                        
                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Handle forgot password
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFF8B0000),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        
                         SizedBox(height: screenHeight * 0.04), // 4% of screen height
                        
                        // Sign In Button
                        Container(
                          height: screenHeight * 0.07, // 7% of screen height
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xFF100C08), // Dark green-black
                                Color(0xFF95122C), // Dark red
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'SIGN IN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                          ),
                        ),
                        
                        // Biometric Sign In Button (if available and enabled)
                        if (_isBiometricAvailable && _isBiometricEnabled) ...[
                          SizedBox(height: screenHeight * 0.02), // 2% of screen height
                          
                          // Divider with "OR"
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: screenHeight * 0.02), // 2% of screen height
                          
                          // Biometric Sign In Button
                          Container(
                            height: screenHeight * 0.07, // 7% of screen height
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF8B0000),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleBiometricSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _biometricType.toLowerCase().contains('fingerprint') 
                                        ? Icons.fingerprint 
                                        : Icons.face,
                                    color: const Color(0xFF8B0000),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SIGN IN WITH $_biometricType',
                                    style: const TextStyle(
                                      color: Color(0xFF8B0000),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // PIN Sign In Button (if PIN fallback is available)
                        if (_isPinFallbackAvailable) ...[
                          SizedBox(height: screenHeight * 0.02), // 2% of screen height
                          
                          // Divider with "OR"
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: screenHeight * 0.02), // 2% of screen height
                          
                          // PIN Sign In Button
                          Container(
                            height: screenHeight * 0.07, // 7% of screen height
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF8B0000),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _showPinVerificationDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.pin,
                                    color: const Color(0xFF8B0000),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SIGN IN WITH PIN',
                                    style: const TextStyle(
                                      color: Color(0xFF8B0000),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        
                        const Spacer(),
                        
                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have account? ",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigate to sign up page
                                NavigationHelper.goToSignUp(context);
                              },
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  color: Color(0xFF8B0000),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../router/navigation_helper.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/custom_notification.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService.instance;
  
  // Debug variables
  bool _showDebugInfo = false;
  String _debugInfo = '';
  List<String> _debugLogs = [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Handle sign up process with secure storage
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _debugLogs.clear();
    });

    _addDebugLog('🚀 Starting sign up process...');
    _addDebugLog('📧 Email: ${_emailController.text.trim()}');
    _addDebugLog('👤 Name: ${_nameController.text.trim()}');

    try {
      final result = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      _addDebugLog('🔐 Sign up result: ${result.isSuccess}');
      _addDebugLog('📝 Message: ${result.message}');

      if (mounted) {
        if (result.isSuccess) {
          _addDebugLog('🎉 Sign up successful! Enabling biometric login...');
          
          // Show a brief message about biometric being enabled
          context.showSuccessNotification(
            'Account created! Biometric login enabled. You can now use fingerprint/face to sign in next time.',
          );
          
          _addDebugLog('🎉 Biometric login enabled! Navigating to home...');
          
          // Small delay to show the message
          await Future.delayed(const Duration(milliseconds: 1500));
          NavigationHelper.goToHome(context);
        } else {
          _addDebugLog('❌ Sign up failed: ${result.message}');
          context.showErrorNotification('Sign up failed: ${result.message}');
        }
      }
    } catch (e) {
      _addDebugLog('💥 Sign up error: ${e.toString()}');
      if (mounted) {
        context.showErrorNotification('Sign up failed: ${e.toString()}');
      }
    } finally {
      _addDebugLog('🏁 Sign up process completed');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Add debug log entry
  void _addDebugLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logEntry = '[$timestamp] $message';
    if (mounted) {
      setState(() {
        _debugLogs.add(logEntry);
        _debugInfo = _debugLogs.join('\n');
      });
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
                              Icons.person_add,
                              size: screenWidth * 0.1,
                              color: Colors.white,
                            ),
                          ),
                          
                          SizedBox(height: screenHeight * 0.02),
                          
                          // Welcome text with reduced typography
                          Text(
                            'Create Account',
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
                            'Sign up to get started',
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
                                // Name Field
                                TextFormField(
                                  controller: _nameController,
                                  keyboardType: TextInputType.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    labelStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 16,
                                    ),
                                    hintText: 'Enter your full name',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
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
                                      return 'Please enter your name';
                                    }
                                    if (value.length < 2) {
                                      return 'Name must be at least 2 characters';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: screenHeight * 0.015),

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
                                SizedBox(height: screenHeight * 0.015),

                                // Confirm Password Field
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    labelStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 16,
                                    ),
                                    hintText: 'Confirm your password',
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
                                        _obscureConfirmPassword 
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.white70,
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
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
                                      return 'Please confirm your password';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: screenHeight * 0.025),

                                // Sign Up Button
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
                                    onPressed: _isLoading ? null : _handleSignUp,
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
                                            'Sign Up',
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

                          // Sign In Link with better styling
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
                                  "Already have an account? ",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: screenHeight * 0.015,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text(
                                    'Sign In',
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
          ],
        ),
      ),
    );
  }
}

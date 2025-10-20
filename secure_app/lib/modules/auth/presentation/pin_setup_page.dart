import 'package:flutter/material.dart';
import '../../../core/services/pin_service.dart';
import '../../../core/widgets/widgets.dart';

class PinSetupPage extends StatefulWidget {
  final bool isSetup; // true for setup, false for change
  final String? currentPin; // required for change

  const PinSetupPage({
    super.key,
    this.isSetup = true,
    this.currentPin,
  });

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final FocusNode _confirmPinFocusNode = FocusNode();
  
  bool _isLoading = false;
  String _errorMessage = '';
  String _pin = '';
  String _confirmPin = '';
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  final PinService _pinService = PinService.instance;

  @override
  void initState() {
    super.initState();
    _pinFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _pinFocusNode.dispose();
    _confirmPinFocusNode.dispose();
    super.dispose();
  }

  /// Build background decorative elements
  Widget _buildBackgroundDecorations(double screenWidth, double screenHeight) {
    return BackgroundDecorations(
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );
  }

  /// Build header section
  Widget _buildHeader(double screenWidth, double screenHeight) {
    return PageHeader(
      title: widget.isSetup ? 'Setup PIN' : 'Change PIN',
      icon: Icons.pin,
      onBackPressed: () => Navigator.of(context).pop(),
    );
  }

  /// Build PIN input field
  Widget _buildPinInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required ValueChanged<String> onChanged,
  }) {
    return PinInputField(
      label: label,
      hint: hint,
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      onToggleVisibility: onToggleObscure,
      onChanged: onChanged,
      onSubmitted: () => onChanged(controller.text),
    );
  }

  /// Setup PIN
  Future<void> _setupPin() async {
    // debugPrint('🔐 PIN Setup: _pin length: ${_pin.length}, _pin value: "$_pin"');
    // debugPrint('🔐 PIN Setup: _confirmPin length: ${_confirmPin.length}, _confirmPin value: "$_confirmPin"');
    
    if (_pin.length < 4) {
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits';
      });
      return;
    }

    if (_pin != _confirmPin) {
      setState(() {
        _errorMessage = 'PINs do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _pinService.setupPin(_pin);
      
      if (mounted) {
        if (result.isSuccess) {
          context.showSuccessNotification(result.message);
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _errorMessage = result.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to setup PIN: $e';
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

  /// Change PIN
  Future<void> _changePin() async {
    if (_pin.length < 4) {
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits';
      });
      return;
    }

    if (_pin != _confirmPin) {
      setState(() {
        _errorMessage = 'PINs do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _pinService.changePin(widget.currentPin!, _pin);
      
      if (mounted) {
        if (result.isSuccess) {
          context.showSuccessNotification(result.message);
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _errorMessage = result.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to change PIN: $e';
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
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: screenHeight * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header section
                    _buildHeader(screenWidth, screenHeight),
                    
                    SizedBox(height: screenHeight * 0.04),
                    
                    // Content container with glassmorphism
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.06),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            widget.isSetup ? 'Create Your PIN' : 'Change Your PIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenHeight * 0.024,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          SizedBox(height: screenHeight * 0.03),
                          
                          // PIN input field
                          _buildPinInputField(
                            label: 'Enter PIN',
                            hint: 'Enter 4-8 digits',
                            controller: _pinController,
                            focusNode: _pinFocusNode,
                            obscureText: _obscurePin,
                            onToggleObscure: () {
                              setState(() {
                                _obscurePin = !_obscurePin;
                              });
                            },
                            onChanged: (value) {
                              // debugPrint('🔐 PIN Setup: PIN onChanged called with value: "$value"');
                              setState(() {
                                _pin = value;
                                _errorMessage = '';
                              });
                            },
                          ),
                          
                          SizedBox(height: screenHeight * 0.02),
                          
                          // Confirm PIN input field
                          _buildPinInputField(
                            label: 'Confirm PIN',
                            hint: 'Re-enter your PIN',
                            controller: _confirmPinController,
                            focusNode: _confirmPinFocusNode,
                            obscureText: _obscureConfirmPin,
                            onToggleObscure: () {
                              setState(() {
                                _obscureConfirmPin = !_obscureConfirmPin;
                              });
                            },
                            onChanged: (value) {
                              // debugPrint('🔐 PIN Setup: Confirm PIN onChanged called with value: "$value"');
                              setState(() {
                                _confirmPin = value;
                                _errorMessage = '';
                              });
                            },
                          ),
                          
                          // Error message
                          if (_errorMessage.isNotEmpty) ...[
                            SizedBox(height: screenHeight * 0.02),
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
                          
                          // Spacing before buttons
                          SizedBox(height: screenHeight * 0.03),
                          
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
                                  onPressed: _isLoading ? null : (widget.isSetup ? _setupPin : _changePin),
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
                                      : Text(widget.isSetup ? 'Setup PIN' : 'Change PIN'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
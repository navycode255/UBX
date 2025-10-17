import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/auth_service.dart';
import '../../../router/navigation_helper.dart';

class PinSetupPage extends StatefulWidget {
  final bool isSetup; // true for setup, false for verification
  final String? currentPin; // required for verification

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isSetup ? 'Setup PIN' : 'Verify PIN'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Header
              Icon(
                Icons.security,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              
              Text(
                widget.isSetup ? 'Create Your PIN' : 'Enter Your PIN',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                widget.isSetup 
                  ? 'Set up a 6-digit PIN as a fallback for biometric authentication'
                  : 'Enter your PIN to continue',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // PIN Input
              _buildPinInput(),
              const SizedBox(height: 16),

              // Confirm PIN Input (only for setup)
              if (widget.isSetup) ...[
                _buildConfirmPinInput(),
                const SizedBox(height: 16),
              ],

              // Error Message
              if (_errorMessage.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Spacer(),

              // Action Buttons
              _buildActionButtons(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PIN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _pinController,
          focusNode: _pinFocusNode,
          obscureText: _obscurePin,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(
            hintText: 'Enter 6-digit PIN',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePin ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600,
              ),
              onPressed: () {
                setState(() {
                  _obscurePin = !_obscurePin;
                });
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: (value) {
            setState(() {
              _pin = value;
              _errorMessage = '';
            });
          },
          onSubmitted: (value) {
            if (widget.isSetup) {
              _confirmPinFocusNode.requestFocus();
            } else {
              _handleSubmit();
            }
          },
        ),
      ],
    );
  }

  Widget _buildConfirmPinInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm PIN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPinController,
          focusNode: _confirmPinFocusNode,
          obscureText: _obscureConfirmPin,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(
            hintText: 'Confirm 6-digit PIN',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPin ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade600,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPin = !_obscureConfirmPin;
                });
              },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: (value) {
            setState(() {
              _confirmPin = value;
              _errorMessage = '';
            });
          },
          onSubmitted: (value) {
            _handleSubmit();
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isPinValid = _pin.length == 6;
    final isConfirmPinValid = !widget.isSetup || _confirmPin.length == 6;
    final canSubmit = isPinValid && isConfirmPinValid && !_isLoading;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canSubmit ? _handleSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.isSetup ? 'Setup PIN' : 'Verify PIN',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.isSetup) ...[
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text(
              'Skip for now',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (widget.isSetup) {
        await _handleSetup();
      } else {
        await _handleVerification();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSetup() async {
    // Validate PINs match
    if (_pin != _confirmPin) {
      setState(() {
        _errorMessage = 'PINs do not match. Please try again.';
        _isLoading = false;
      });
      return;
    }

    // Setup PIN
    final result = await AuthService.instance.setupPinFallback(_pin);
    
    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      // Show success message
      _showSuccessDialog();
    } else {
      setState(() {
        _errorMessage = result.message;
      });
    }
  }

  Future<void> _handleVerification() async {
    // Verify PIN
    final result = await AuthService.instance.signInWithPin(_pin);
    
    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      // Navigate to main app
      NavigationHelper.goToHome(context);
    } else {
      setState(() {
        _errorMessage = result.message;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('PIN Setup Complete'),
          ],
        ),
        content: const Text(
          'Your PIN has been set up successfully. You can now use it as a fallback for biometric authentication.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous page
            },
            child: const Text(
              'Continue',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

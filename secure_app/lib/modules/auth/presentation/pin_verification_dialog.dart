import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/pin_service.dart';
import '../../../core/widgets/custom_notification.dart';

class PinVerificationDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final Function(String)? onSuccess;
  final VoidCallback? onCancel;

  const PinVerificationDialog({
    super.key,
    required this.title,
    required this.subtitle,
    this.onSuccess,
    this.onCancel,
  });

  @override
  State<PinVerificationDialog> createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<PinVerificationDialog> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  
  bool _isLoading = false;
  String _errorMessage = '';
  String _pin = '';
  bool _obscurePin = true;

  final PinService _pinService = PinService.instance;

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
    // debugPrint('🔐 PIN Dialog: ===== STARTING PIN VERIFICATION =====');
    // debugPrint('🔐 PIN Dialog: PIN received: "$_pin" (length: ${_pin.length})');
    
    if (_pin.length < 4) {
      // debugPrint('❌ PIN Dialog: PIN too short, length: ${_pin.length}');
      setState(() {
        _errorMessage = 'Please enter a valid PIN';
      });
      return;
    }

    // debugPrint('✅ PIN Dialog: PIN length validation passed');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // debugPrint('🔐 PIN Dialog: Calling _pinService.verifyPin("$_pin")');
      final result = await _pinService.verifyPin(_pin);
      // debugPrint('🔐 PIN Dialog: PIN verification completed');
      // debugPrint('🔐 PIN Dialog: PIN verification success: ${result.isSuccess}');
      // debugPrint('🔐 PIN Dialog: PIN verification message: ${result.message}');
      
      if (mounted) {
        if (result.isSuccess) {
          // debugPrint('✅ PIN Dialog: PIN verification successful, calling onSuccess callback');
          context.showSuccessNotification('PIN verified successfully');
          Navigator.of(context).pop();
          widget.onSuccess?.call(_pin);
          // debugPrint('✅ PIN Dialog: onSuccess callback completed');
        } else {
          // debugPrint('❌ PIN Dialog: PIN verification failed, showing error message');
          setState(() {
            _errorMessage = result.message;
          });
        }
      }
    } catch (e) {
      // debugPrint('❌ PIN Dialog: PIN verification error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to verify PIN: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // debugPrint('🔐 PIN Dialog: ===== PIN VERIFICATION COMPLETED =====');
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
                        Text(
                          widget.title,
                          style: const TextStyle(
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

/// Helper function to show PIN verification dialog
Future<void> showPinVerificationDialog({
  required BuildContext context,
  required String title,
  required String subtitle,
  Function(String)? onSuccess,
  VoidCallback? onCancel,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PinVerificationDialog(
      title: title,
      subtitle: subtitle,
      onSuccess: onSuccess,
      onCancel: onCancel,
    ),
  );
}
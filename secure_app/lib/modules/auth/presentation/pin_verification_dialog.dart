import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/auth_service.dart';

class PinVerificationDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onSuccess;
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Icon(
              Icons.security,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            Text(
              widget.subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // PIN Input
            TextField(
              controller: _pinController,
              focusNode: _pinFocusNode,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                hintText: '••••••',
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
                
                // Auto-submit when PIN is complete
                if (value.length == 6) {
                  _handleSubmit();
                }
              },
            ),
            const SizedBox(height: 16),

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
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.of(context).pop();
                      widget.onCancel?.call();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _pin.length == 6 && !_isLoading ? _handleSubmit : null,
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
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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

  Future<void> _handleSubmit() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Verify PIN
      final result = await AuthService.instance.signInWithPin(_pin);
      
      setState(() {
        _isLoading = false;
      });

      if (result.isSuccess) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }
}

/// Helper function to show PIN verification dialog
Future<void> showPinVerificationDialog({
  required BuildContext context,
  required String title,
  required String subtitle,
  VoidCallback? onSuccess,
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

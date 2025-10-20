import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable PIN input field widget used across multiple pages
class PinInputField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final String? Function(String?)? validator;
  final int maxLength;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;
  final ValueChanged<String>? onChanged;

  const PinInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    this.obscureText = true,
    this.onToggleVisibility,
    this.validator,
    this.maxLength = 4,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  State<PinInputField> createState() => _PinInputFieldState();
}

class _PinInputFieldState extends State<PinInputField> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenHeight * 0.018,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        
        // Input field
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.obscureText,
          validator: widget.validator,
          maxLength: widget.maxLength,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onFieldSubmitted: (_) => widget.onSubmitted?.call(),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(widget.maxLength),
          ],
          style: TextStyle(
            color: Colors.white,
            fontSize: screenHeight * 0.02,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.6),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red.withOpacity(0.6),
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red.withOpacity(0.8),
                width: 2,
              ),
            ),
            counterText: '', // Hide character counter
            suffixIcon: widget.onToggleVisibility != null
                ? IconButton(
                    onPressed: widget.onToggleVisibility,
                    icon: Icon(
                      widget.obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}


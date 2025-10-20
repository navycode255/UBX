import 'package:flutter/material.dart';

/// Reusable loading indicator widget used across multiple pages
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? color;
  final bool showMessage;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size,
    this.color,
    this.showMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Loading spinner
        SizedBox(
          width: size ?? 40,
          height: size ?? 40,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Colors.white,
            ),
            strokeWidth: 3,
          ),
        ),
        
        // Loading message
        if (showMessage && message != null) ...[
          SizedBox(height: screenHeight * 0.02),
          Text(
            message!,
            style: TextStyle(
              color: color?.withOpacity(0.8) ?? Colors.white.withOpacity(0.8),
              fontSize: screenHeight * 0.018,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Simple loading container with icon
class SimpleLoadingIndicator extends StatelessWidget {
  final String? message;
  final IconData icon;
  final Color? color;

  const SimpleLoadingIndicator({
    super.key,
    this.message,
    this.icon = Icons.hourglass_empty,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Container(
      width: screenWidth * 0.12,
      height: screenWidth * 0.12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: color ?? Colors.white,
        size: screenWidth * 0.06,
      ),
    );
  }
}



import 'package:flutter/material.dart';

/// Reusable background decorations widget used across multiple pages
class BackgroundDecorations extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final List<Widget>? additionalChildren;

  const BackgroundDecorations({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    this.additionalChildren,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top right decorative element
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
        // Bottom left decorative element
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
        // Additional decorative circles
        Positioned(
          top: screenHeight * 0.2,
          left: screenWidth * 0.1,
          child: Container(
            width: screenWidth * 0.3,
            height: screenWidth * 0.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ),
        // Add any additional children
        if (additionalChildren != null) ...additionalChildren!,
      ],
    );
  }
}



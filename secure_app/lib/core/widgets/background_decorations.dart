import 'package:flutter/material.dart';

class BackgroundDecorations extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;

  const BackgroundDecorations({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Large decorative circles
        Positioned(
          top: -screenHeight * 0.1,
          right: -screenWidth * 0.1,
          child: Container(
            width: screenWidth * 0.6,
            height: screenWidth * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -screenHeight * 0.2,
          left: -screenWidth * 0.2,
          child: Container(
            width: screenWidth * 0.8,
            height: screenWidth * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.03),
            ),
          ),
        ),
        // Medium decorative circles
        Positioned(
          top: screenHeight * 0.3,
          left: -screenWidth * 0.1,
          child: Container(
            width: screenWidth * 0.3,
            height: screenWidth * 0.3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          bottom: screenHeight * 0.1,
          right: -screenWidth * 0.15,
          child: Container(
            width: screenWidth * 0.4,
            height: screenWidth * 0.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ),
        // Small decorative circles
        Positioned(
          top: screenHeight * 0.1,
          left: screenWidth * 0.1,
          child: Container(
            width: screenWidth * 0.15,
            height: screenWidth * 0.15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        Positioned(
          top: screenHeight * 0.6,
          right: screenWidth * 0.2,
          child: Container(
            width: screenWidth * 0.2,
            height: screenWidth * 0.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
        ),
      ],
    );
  }
}

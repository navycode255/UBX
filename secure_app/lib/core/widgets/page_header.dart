import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Reusable page header widget used across multiple pages
class PageHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final Widget? trailing;

  const PageHeader({
    super.key,
    required this.title,
    this.icon,
    this.onBackPressed,
    this.showBackButton = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Row(
      children: [
        // Back button
        if (showBackButton)
          GestureDetector(
            onTap: onBackPressed ?? () => context.pop(),
            child: Container(
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
                Icons.arrow_back,
                color: Colors.white,
                size: screenWidth * 0.06,
              ),
            ),
          ),
        if (showBackButton) SizedBox(width: screenWidth * 0.03),
        // Title
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenHeight * 0.028,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        // Icon or trailing widget
        if (icon != null)
          Container(
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
              color: Colors.white,
              size: screenWidth * 0.06,
            ),
          )
        else if (trailing != null)
          trailing!,
      ],
    );
  }
}

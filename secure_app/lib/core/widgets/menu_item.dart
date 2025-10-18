import 'package:flutter/material.dart';

/// Reusable menu item widget used across multiple pages
class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final Color? subtitleColor;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final bool showDivider;

  const MenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.titleColor,
    this.subtitleColor,
    this.trailing,
    this.padding,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: padding ?? EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.02,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: screenWidth * 0.1,
                  height: screenWidth * 0.1,
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
                    color: iconColor ?? Colors.white,
                    size: screenWidth * 0.05,
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: titleColor ?? Colors.white,
                          fontSize: screenHeight * 0.018,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: subtitleColor ?? Colors.white.withOpacity(0.7),
                            fontSize: screenHeight * 0.014,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Trailing widget or arrow
                trailing ?? Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.6),
                  size: screenWidth * 0.04,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Container(
            margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
      ],
    );
  }
}

/// Specialized menu item for settings
class SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isEnabled;

  const SettingsMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return MenuItem(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: isEnabled ? onTap : null,
      trailing: trailing,
      titleColor: isEnabled ? Colors.white : Colors.white.withOpacity(0.5),
      subtitleColor: isEnabled ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.3),
    );
  }
}

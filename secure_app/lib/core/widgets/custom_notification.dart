import 'dart:ui';
import 'package:flutter/material.dart';

/// Custom notification widget that matches the app's design
/// 
/// Features:
/// - Animated slide-in from top
/// - Matches signin/signup page design
/// - Red theme for errors, green for success
/// - Auto-dismiss after duration
/// - Customizable message and icon
class CustomNotification extends StatefulWidget {
  final String message;
  final NotificationType type;
  final Duration duration;
  final VoidCallback? onDismiss;

  const CustomNotification({
    Key? key,
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  }) : super(key: key);

  @override
  State<CustomNotification> createState() => _CustomNotificationState();
}

class _CustomNotificationState extends State<CustomNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimation();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimation() {
    _animationController.forward();
    
    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _animationController.reverse();
    if (mounted) {
      widget.onDismiss?.call();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.08,
                vertical: screenHeight * 0.01,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.02,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.type == NotificationType.success
                        ? [
                            const Color(0xFF4CAF50).withOpacity(0.15), // Very transparent green
                            const Color(0xFF2E7D32).withOpacity(0.15), // Very transparent darker green
                          ]
                        : [
                            const Color(0xFFD32F2F).withOpacity(0.15), // Very transparent red
                            const Color(0xFFB71C1C).withOpacity(0.15), // Very transparent darker red
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.type == NotificationType.success
                        ? Colors.green // Solid green border
                        : Colors.red, // Solid red border
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.type == NotificationType.success
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: screenWidth * 0.08,
                      height: screenWidth * 0.08,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.type == NotificationType.success
                            ? const Color(0xFF4CAF50).withOpacity(0.2) // Light green background
                            : const Color(0xFFD32F2F).withOpacity(0.2), // Light red background
                        border: Border.all(
                          color: widget.type == NotificationType.success
                              ? const Color(0xFF2E7D32) // Dark green border
                              : const Color(0xFFB71C1C), // Dark red border
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        widget.type == NotificationType.success
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: Colors.white, // White icon
                        size: screenWidth * 0.04,
                      ),
                    ),
                    
                    SizedBox(width: screenWidth * 0.03),
                    
                    // Message
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: Colors.white, // White text
                          fontSize: screenHeight * 0.016,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          decoration: TextDecoration.none, // Remove any underline
                        ),
                      ),
                    ),
                    
                    // Dismiss button
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        width: screenWidth * 0.06,
                        height: screenWidth * 0.06,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.type == NotificationType.success
                              ? const Color(0xFF4CAF50).withOpacity(0.2) // Light green background
                              : const Color(0xFFD32F2F).withOpacity(0.2), // Light red background
                          border: Border.all(
                            color: widget.type == NotificationType.success
                                ? const Color(0xFF2E7D32) // Dark green border
                                : const Color(0xFFB71C1C), // Dark red border
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white, // White close icon
                          size: screenWidth * 0.03,
                        ),
                      ),
                    ),
                  ],
                ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Notification type enum
enum NotificationType {
  success,
  error,
}

/// Custom notification overlay
class CustomNotificationOverlay {
  static OverlayEntry? _overlayEntry;

  /// Show a custom notification
  static void show(
    BuildContext context, {
    required String message,
    required NotificationType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Remove existing notification if any
    hide();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 0,
        right: 0,
        child: CustomNotification(
          message: message,
          type: type,
          duration: duration,
          onDismiss: hide,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Hide the current notification
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

/// Extension methods for easy usage
extension CustomNotificationExtension on BuildContext {
  /// Show success notification
  void showSuccessNotification(String message, {Duration? duration}) {
    CustomNotificationOverlay.show(
      this,
      message: message,
      type: NotificationType.success,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Show error notification
  void showErrorNotification(String message, {Duration? duration}) {
    CustomNotificationOverlay.show(
      this,
      message: message,
      type: NotificationType.error,
      duration: duration ?? const Duration(seconds: 4),
    );
  }
}

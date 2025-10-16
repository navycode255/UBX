import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../router/route_constants.dart';

/// Beautiful profile page with modern design and app theme colors
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // User data - in a real app, this would come from a service
  String userName = 'Jhone Williams';
  String userPhoneNumber = '+60 9876543210';
  String userEmail = 'jhonewilliams@gmail.com';
  bool hasProfilePicture = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async {
        // Handle Android back button
        if (Navigator.of(context).canPop()) {
          context.pop();
          return false;
        } else {
          context.go(RouteConstants.home);
          return false;
        }
      },
      child: Scaffold(
        body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF100C08), // Dark green-black
              Color(0xFF95122C), // Dark red
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles (like sign-in/sign-up pages)
            _buildDecorativeCircles(screenWidth, screenHeight),
            
            SafeArea(
              child: Column(
                children: [
                  // Custom App Bar
                  _buildAppBar(screenWidth),
                  
                  // Profile Content
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(top: screenHeight * 0.02),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Profile Picture Section
                            _buildProfilePictureSection(screenWidth, screenHeight),
                            
                            // User Info Section
                            _buildUserInfoSection(screenWidth, screenHeight),
                            
                            // Menu Sections
                            _buildMenuSections(screenWidth, screenHeight),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Builds decorative circles like in sign-in/sign-up pages
  Widget _buildDecorativeCircles(double screenWidth, double screenHeight) {
    return Stack(
      children: [
        // Large circle - top right
        Positioned(
          top: screenHeight * 0.05,
          right: -screenWidth * 0.1,
          child: Container(
            width: screenWidth * 0.4,
            height: screenWidth * 0.4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
          ),
        ),
        // Medium circle - top right
        Positioned(
          top: screenHeight * 0.1,
          right: screenWidth * 0.1,
          child: Container(
            width: screenWidth * 0.2,
            height: screenWidth * 0.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.03),
                ],
              ),
            ),
          ),
        ),
        // Small circle - top right
        Positioned(
          top: screenHeight * 0.15,
          right: screenWidth * 0.3,
          child: Container(
            width: screenWidth * 0.15,
            height: screenWidth * 0.15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ),
        // Tiny circle - top right
        Positioned(
          top: screenHeight * 0.08,
          right: screenWidth * 0.5,
          child: Container(
            width: screenWidth * 0.1,
            height: screenWidth * 0.1,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.04),
                  Colors.white.withOpacity(0.01),
                ],
              ),
            ),
          ),
        ),
        // Additional circles for more visual interest
        Positioned(
          top: screenHeight * 0.2,
          right: screenWidth * 0.05,
          child: Container(
            width: screenWidth * 0.12,
            height: screenWidth * 0.12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ),
        // Left side circle for balance
        Positioned(
          top: screenHeight * 0.12,
          left: -screenWidth * 0.05,
          child: Container(
            width: screenWidth * 0.18,
            height: screenWidth * 0.18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.07),
                  Colors.white.withOpacity(0.03),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the custom app bar
  Widget _buildAppBar(double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenWidth * 0.03,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // Check if we can pop, otherwise go to home
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go(RouteConstants.home);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          const Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  /// Builds the profile picture section
  Widget _buildProfilePictureSection(double screenWidth, double screenHeight) {
    return Container(
      margin: EdgeInsets.only(top: screenHeight * 0.03),
      child: Stack(
        children: [
          // Profile Picture
          Center(
            child: GestureDetector(
              onTap: () => _showProfilePictureOptions(context),
              child: Container(
                width: screenWidth * 0.35,
                height: screenWidth * 0.35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF95122C),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF95122C).withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: hasProfilePicture
                      ? Image.network(
                          'https://example.com/profile.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderAvatar(screenWidth);
                          },
                        )
                      : _buildPlaceholderAvatar(screenWidth),
                ),
              ),
            ),
          ),
          // Edit Icon
          Positioned(
            bottom: 0,
            right: screenWidth * 0.5 - screenWidth * 0.175 + screenWidth * 0.35 - 20,
            child: GestureDetector(
              onTap: () => _showProfilePictureOptions(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF003447),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds placeholder avatar
  Widget _buildPlaceholderAvatar(double screenWidth) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF100C08),
            Color(0xFF95122C),
          ],
        ),
      ),
      child: const Icon(
        Icons.person,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  /// Builds user information section
  Widget _buildUserInfoSection(double screenWidth, double screenHeight) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.03,
      ),
      child: Column(
        children: [
          Text(
            userName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            userPhoneNumber,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            userEmail,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds menu sections
  Widget _buildMenuSections(double screenWidth, double screenHeight) {
    return Column(
      children: [
        // Account Settings Section
        _buildMenuSection(
          'Account Settings',
          [
            _buildMenuItem(
              icon: Icons.access_time_rounded,
              title: 'Working Hours',
              subtitle: 'Manage your schedule',
              onTap: () => _showComingSoon(context, 'Working Hours'),
            ),
            _buildMenuItem(
              icon: Icons.person_outline_rounded,
              title: 'My Account',
              subtitle: 'Personal information',
              onTap: () => _showComingSoon(context, 'My Account'),
            ),
            _buildMenuItem(
              icon: Icons.phone_outlined,
              title: 'Phone Number',
              subtitle: 'Update contact details',
              onTap: () => _showComingSoon(context, 'Phone Number'),
            ),
            _buildMenuItem(
              icon: Icons.lock_outline_rounded,
              title: 'Change Password',
              subtitle: 'Security settings',
              onTap: () => _showComingSoon(context, 'Change Password'),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds a menu section with title and items
  Widget _buildMenuSection(String title, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF100C08),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  /// Builds a menu item
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF100C08),
                    Color(0xFF95122C),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
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
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }


  /// Shows coming soon dialog
  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF100C08), Color(0xFF95122C)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Coming Soon'),
            ],
          ),
          content: Text('$feature feature is coming soon!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF003447),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Shows profile picture options
  void _showProfilePictureOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Profile Picture',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildBottomSheetItem(
                icon: Icons.camera_alt,
                title: 'Take Photo',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon(context, 'Camera');
                },
              ),
              _buildBottomSheetItem(
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoon(context, 'Gallery');
                },
              ),
              if (hasProfilePicture)
                _buildBottomSheetItem(
                  icon: Icons.delete,
                  title: 'Remove Photo',
                  onTap: () {
                    setState(() {
                      hasProfilePicture = false;
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// Builds bottom sheet item
  Widget _buildBottomSheetItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF003447).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF003447),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
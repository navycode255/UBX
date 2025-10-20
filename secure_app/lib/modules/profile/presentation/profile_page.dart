import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../router/navigation_helper.dart';
import '../../../core/services/image_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/widgets/custom_notification.dart';
import '../data/profile_providers.dart';
import '../data/profile_state.dart';

/// Beautiful profile page with modern design and app theme colors
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _hasInitialized = false;
  

  @override
  void initState() {
    super.initState();
    // Initialize profile data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        ref.read(profileNotifierProvider.notifier).initializeProfile();
        _hasInitialized = true;
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileDataProvider);

    // Listen to error state and show snackbar
    ref.listen<String?>(profileErrorProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        context.showErrorNotification(next);
      }
    });

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Show error state with retry button
    if (profileState.hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: const Color(0xFF8B0000),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => NavigationHelper.pop(context),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8B0000), // Dark red
                Color(0xFF4B0082), // Purple
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load profile',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profileState.error ?? 'Unknown error occurred',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(profileNotifierProvider.notifier).retryLoadProfile();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF95122C),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        body: Container(
          height: screenHeight,
          width: screenWidth,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8B0000), // Dark red
                Color(0xFF4B0082), // Purple
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background decorative elements
              _buildBackgroundDecorations(screenWidth, screenHeight),
              
              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.01,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header section
                      _buildHeader(screenWidth, screenHeight),
                      
                      SizedBox(height: screenHeight * 0.03),
                      
                      // Profile content container with glassmorphism
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: RefreshIndicator(
                          onRefresh: () => ref.read(profileNotifierProvider.notifier).refreshUserData(),
                          child: Column(
                            children: [
                              // Profile Picture Section
                              _buildProfilePictureSection(context, ref, screenWidth, screenHeight, profileState),
                              
                      SizedBox(height: screenHeight * 0.02),
                      
                      // User Stats Cards
                      _buildUserStatsCards(screenWidth, screenHeight, profileState),
                      
                      SizedBox(height: screenHeight * 0.02),
                      
                      // Quick Actions
                      _buildQuickActions(context, ref, screenWidth, screenHeight),
                      
                      SizedBox(height: screenHeight * 0.02),
                      
                      // Account Settings
                      _buildAccountSettings(context, ref, screenWidth, screenHeight),
                              
                              SizedBox(height: screenHeight * 0.02),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }

  /// Build background decorative elements (like sign-in/sign-up pages)
  Widget _buildBackgroundDecorations(double screenWidth, double screenHeight) {
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
      ],
    );
  }

  /// Build header section (like sign-in/sign-up pages)
  Widget _buildHeader(double screenWidth, double screenHeight) {
    return Row(
      children: [
        // Back button
        GestureDetector(
          onTap: () => NavigationHelper.pop(context),
          child: Container(
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
              Icons.arrow_back,
              color: Colors.white,
              size: screenWidth * 0.05,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        // Title
        Expanded(
          child: Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: screenHeight * 0.024,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        // Profile icon (optional)
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
            Icons.person,
            color: Colors.white,
            size: screenWidth * 0.05,
          ),
        ),
      ],
    );
  }


  /// Builds the profile picture section
  Widget _buildProfilePictureSection(BuildContext context, WidgetRef ref, double screenWidth, double screenHeight, ProfileState profileState) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.03),
      child: Column(
        children: [
          // Profile Picture
          Center(
            child: GestureDetector(
              onTap: () => _showProfilePictureOptions(context, ref, profileState),
              child: Container(
                width: screenWidth * 0.2,
                height: screenWidth * 0.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: profileState.hasProfilePicture && profileState.profilePictureFile != null
                      ? Image.file(
                          profileState.profilePictureFile!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderAvatar(screenWidth, profileState.userName);
                          },
                        )
                      : _buildPlaceholderAvatar(screenWidth, profileState.userName),
                ),
              ),
            ),
          ),
          
          // User Name and Email below profile picture
          Container(
            margin: EdgeInsets.only(top: screenHeight * 0.02),
            child: Column(
              children: [
                // User Name
                Text(
                  profileState.userName.isNotEmpty ? profileState.userName : 'User',
                  style: TextStyle(
                    fontSize: screenHeight * 0.022,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.006),
                // User Phone Number (if available)
                if (profileState.userPhoneNumber.isNotEmpty)
                  Column(
                    children: [
                      Text(
                        profileState.userPhoneNumber,
                        style: TextStyle(
                          fontSize: screenHeight * 0.016,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.006),
                    ],
                  ),
                // User Email
                Text(
                  profileState.userEmail.isNotEmpty ? profileState.userEmail : 'user@example.com',
                  style: TextStyle(
                    fontSize: screenHeight * 0.014,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds placeholder avatar
  Widget _buildPlaceholderAvatar(double screenWidth, String userName) {
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
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Build user stats cards
  Widget _buildUserStatsCards(double screenWidth, double screenHeight, ProfileState profileState) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Security Level',
            'High',
            Icons.security,
            const Color(0xFF8B0000),
            screenWidth,
            screenHeight,
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: _buildStatCard(
            'Account Status',
            'Active',
            Icons.check_circle,
            const Color(0xFF4B0082),
            screenWidth,
            screenHeight,
          ),
        ),
      ],
    );
  }

  /// Build individual stat card
  Widget _buildStatCard(String title, String value, IconData icon, Color color, double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          SizedBox(height: screenHeight * 0.008),
          Text(
            value,
            style: TextStyle(
              fontSize: screenHeight * 0.018,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenHeight * 0.003),
          Text(
            title,
            style: TextStyle(
              fontSize: screenHeight * 0.012,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build quick actions section
  Widget _buildQuickActions(BuildContext context, WidgetRef ref, double screenWidth, double screenHeight) {
    return _buildSectionCard(
      'Quick Actions',
      [
        _buildModernMenuItem(
          icon: Icons.phone_outlined,
          title: 'Update Phone',
          subtitle: 'Change your phone number',
          onTap: () => _showPhoneNumberDialog(context),
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        ),
        _buildModernMenuItem(
          icon: Icons.fingerprint,
          title: 'Biometric Settings',
          subtitle: 'Manage fingerprint & face ID',
          onTap: () => NavigationHelper.goToBiometricSettings(context),
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        ),
      ],
      screenWidth,
      screenHeight,
    );
  }

  /// Build account settings section
  Widget _buildAccountSettings(BuildContext context, WidgetRef ref, double screenWidth, double screenHeight) {
    return _buildSectionCard(
      'Account Settings',
      [
        _buildModernMenuItem(
          icon: Icons.person_outline_rounded,
          title: 'My Account',
          subtitle: 'Manage your account details',
          onTap: () => _showComingSoon(context, 'My Account'),
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        ),
        _buildModernMenuItem(
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          subtitle: 'Update your password',
          onTap: () => _showComingSoon(context, 'Change Password'),
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        ),
        _buildModernMenuItem(
          icon: Icons.security,
          title: 'Security Settings',
          subtitle: 'Manage security preferences',
          onTap: () => _showComingSoon(context, 'Security Settings'),
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        ),
      ],
      screenWidth,
      screenHeight,
    );
  }


  /// Build section card with title and items
  Widget _buildSectionCard(String title, List<Widget> items, double screenWidth, double screenHeight) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: screenWidth * 0.02, bottom: screenHeight * 0.012),
            child: Text(
              title,
              style: TextStyle(
                fontSize: screenHeight * 0.018,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  /// Build modern menu item
  Widget _buildModernMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required double screenWidth,
    required double screenHeight,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.01),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenHeight * 0.015,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: screenHeight * 0.016,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.004),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: screenHeight * 0.012,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
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

  /// Shows phone number update dialog with glassmorphism design
  void _showPhoneNumberDialog(BuildContext context) {
    final TextEditingController phoneController = TextEditingController();
    final profileState = ref.read(profileDataProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Pre-fill with current phone number if available
    phoneController.text = profileState.userPhoneNumber;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: screenWidth * 0.85,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8B0000), // Dark red
                  Color(0xFF4B0082), // Purple
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with glassmorphism
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.phone_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Text(
                            'Update Phone Number',
                            style: TextStyle(
                              fontSize: screenHeight * 0.022,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content with glassmorphism
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: TextFormField(
                            controller: phoneController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              labelStyle: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                              hintText: 'Enter your phone number',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.phone,
                                color: Colors.white.withOpacity(0.8),
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Action buttons with glassmorphism
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.015,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: screenHeight * 0.018,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final phoneNumber = phoneController.text.trim();
                                    if (phoneNumber.isNotEmpty) {
                                      Navigator.of(context).pop();
                                      await _updatePhoneNumber(context, phoneNumber);
                                    } else {
                                      context.showErrorNotification('Please enter a phone number');
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.015,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Update',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenHeight * 0.018,
                                      fontWeight: FontWeight.bold,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Updates phone number via API
  Future<void> _updatePhoneNumber(BuildContext context, String phoneNumber) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B0000)),
            strokeWidth: 3,
          ),
        );
      },
    );

    try {
      // Add timeout to prevent hanging
      await Future.delayed(const Duration(milliseconds: 500)); // Small delay to show loading
      
      // Get current user ID
      final authService = AuthService.instance;
      final userId = await authService.getCurrentUserId().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Authentication timeout - please try again');
        },
      );
      
      if (userId == null || userId.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          context.showErrorNotification('User not authenticated');
        }
        return;
      }

      // Update phone number via API with timeout
      final profileService = ProfileService.instance;
      final response = await profileService.updateProfile(
        phoneNumber: phoneNumber,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        if (response.success) {
          // Update the profile state immediately
          ref.read(profileNotifierProvider.notifier).refreshUserData();
          
          // Show success message
          context.showSuccessNotification('Phone number updated successfully!');
        } else {
          // Try to update locally as fallback
          try {
            // Update the profile state anyway to show the change locally
            ref.read(profileNotifierProvider.notifier).updatePhoneNumberLocally(phoneNumber);
            
            context.showSuccessNotification('Phone number updated locally (API failed)');
          } catch (e) {
            context.showErrorNotification('Failed to update phone number: ${response.message}');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        context.showErrorNotification('Error updating phone number: $e');
      }
    }
  }


  /// Shows profile picture options
  void _showProfilePictureOptions(BuildContext context, WidgetRef ref, ProfileState profileState) {
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
                  Navigator.of(context).pop();
                  _pickImage(context, ImageSource.camera, ref);
                },
              ),
              _buildBottomSheetItem(
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(context, ImageSource.gallery, ref);
                },
              ),
              if (profileState.hasProfilePicture)
                _buildBottomSheetItem(
                  icon: Icons.delete,
                  title: 'Remove Photo',
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeProfilePicture(context, ref);
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

  /// Pick image from camera or gallery
  Future<void> _pickImage(BuildContext context, ImageSource source, WidgetRef ref) async {
    try {
      final imageService = ImageService.instance;
      final imageFile = await imageService.pickImage(source: source);
      
      if (imageFile != null) {
        await ref.read(profileNotifierProvider.notifier).uploadProfilePicture(imageFile);
        
        // Show success message
        context.showSuccessNotification('Profile picture updated successfully!');
      }
    } catch (e) {
      context.showErrorNotification('Error: ${e.toString()}');
    }
  }

  /// Remove profile picture
  Future<void> _removeProfilePicture(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(profileNotifierProvider.notifier).removeProfilePicture();
      
      // Show success message
      context.showSuccessNotification('Profile picture removed successfully!');
    } catch (e) {
      context.showErrorNotification('Error: ${e.toString()}');
    }
  }
}

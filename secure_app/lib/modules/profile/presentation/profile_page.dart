import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../router/route_constants.dart';
import '../../../router/navigation_helper.dart';
import '../../../core/services/image_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/api_service.dart';
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
  
  // Debug variables
  bool _showDebugInfo = false;
  String _debugInfo = '';
  List<String> _debugLogs = [];
  String? _lastLoggedState;

  @override
  void initState() {
    super.initState();
    // Initialize profile data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        _addDebugLog('🚀 ProfilePage: Initializing profile data...');
        ref.read(profileNotifierProvider.notifier).initializeProfile();
        _hasInitialized = true;
      }
    });
  }

  /// Add debug log entry
  void _addDebugLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logEntry = '[$timestamp] $message';
    setState(() {
      _debugLogs.add(logEntry);
      _debugInfo = _debugLogs.join('\n');
    });

  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileDataProvider);

    // Debug logging for profile state changes (only when state actually changes)
    final currentState = '${profileState.isLoading}_${profileState.hasError}_${profileState.userName}_${profileState.userEmail}';
    if (_lastLoggedState != currentState) {
      _lastLoggedState = currentState;
      _addDebugLog('📊 Profile State - Loading: ${profileState.isLoading}, HasError: ${profileState.hasError}');
      _addDebugLog('👤 User Data - Name: "${profileState.userName}", Email: "${profileState.userEmail}"');
      if (profileState.hasError) {
        _addDebugLog('❌ Error: ${profileState.error}');
      }
    }

    // Listen to error state and show snackbar
    ref.listen<String?>(profileErrorProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        _addDebugLog('🚨 Error received: $next');
        context.showErrorNotification(next);
      }
    });

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (profileState.isLoading) {
      return Scaffold(
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Simple loading indicator without spinner
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Loading Profile...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
                // Back button
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF8B0000),
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
      );
    }

    // Show error state with retry button
    if (profileState.hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: const Color(0xFF8B0000),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
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
                  // Debug button
                  ElevatedButton.icon(
                    onPressed: () {

                      ref.read(profileNotifierProvider.notifier).initializeProfile();
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Debug Init'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Auth check button
                  ElevatedButton.icon(
                    onPressed: () async {
                      final authService = AuthService.instance;
                      final isLoggedIn = await authService.isLoggedIn();
                      final userId = await authService.getCurrentUserId();
                      final userName = await authService.getCurrentUserName();
                      final userEmail = await authService.getCurrentUserEmail();
                      _addDebugLog('🔐 Auth Status - Logged In: $isLoggedIn');
                      _addDebugLog('🆔 User ID: $userId');
                      _addDebugLog('👤 Stored Name: $userName');
                      _addDebugLog('📧 Stored Email: $userEmail');
                    },
                    icon: const Icon(Icons.security),
                    label: const Text('Check Auth'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Clear credentials button
                  ElevatedButton.icon(
                    onPressed: () async {
                      final authService = AuthService.instance;
                      await authService.clearCredentials();
                      _addDebugLog('🧹 Credentials cleared - please sign in again');
                      // Navigate back to sign in
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear & Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Back button
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
              // Background decorative elements (like sign-in/sign-up pages)
              _buildBackgroundDecorations(screenWidth, screenHeight),
            
              // Main content
            SafeArea(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.08,
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
                            padding: EdgeInsets.all(screenWidth * 0.04),
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
                              
                              // User Info Section
                              _buildUserInfoSection(screenWidth, screenHeight, profileState),
                              
                                    // Account Settings Section (moved near user info if no phone number)
                                    _buildAccountSettingsSection(context, ref, screenWidth, screenHeight, profileState),
                                    
                                    // Other Menu Sections
                                    _buildOtherMenuSections(context, screenWidth, screenHeight),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Debug Toggle Button
                                    Container(
                                      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _showDebugInfo = !_showDebugInfo;
                                              });
                                            },
                                            icon: Icon(_showDebugInfo ? Icons.visibility_off : Icons.bug_report),
                                            label: Text(_showDebugInfo ? 'Hide Debug' : 'Show Debug'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              await _testApiConnection();
                                            },
                                            icon: const Icon(Icons.wifi),
                                            label: const Text('Test API'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            ),
                                          ),
                            ],
                          ),
                        ),
                                    
                                    // Debug Information Panel
                                    if (_showDebugInfo) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.orange, width: 1),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '🐛 Debug Information',
                                              style: TextStyle(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              height: 200,
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.grey, width: 0.5),
                                              ),
                                              child: SingleChildScrollView(
                                                child: Text(
                                                  _debugInfo.isEmpty ? 'No debug information yet...' : _debugInfo,
                                                  style: const TextStyle(
                                                    color: Colors.green,
                                                    fontFamily: 'monospace',
                                                    fontSize: 12,
                                                                                                 ),
                                              ),
                                            ),
                                        )],
                                        ),
                                      ),
                                    ],
                                ],
                              ),
                            ),
                      ),],
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

  /// Build header section (like sign-in/sign-up pages)
  Widget _buildHeader(double screenWidth, double screenHeight) {
    return Row(
      children: [
        // Back button
        GestureDetector(
          onTap: () => context.go(RouteConstants.home),
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
        SizedBox(width: screenWidth * 0.03),
        // Title
        Expanded(
          child: Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: screenHeight * 0.028,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        // Profile icon (optional)
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
            Icons.person,
            color: Colors.white,
            size: screenWidth * 0.06,
          ),
        ),
      ],
    );
  }

  /// Builds the custom app bar
  Widget _buildAppBar(BuildContext context, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenWidth * 0.03,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // Always go to home page
                context.go(RouteConstants.home);
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
          // Home button
          GestureDetector(
            onTap: () {
              context.go(RouteConstants.home);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.home,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the profile picture section
  Widget _buildProfilePictureSection(BuildContext context, WidgetRef ref, double screenWidth, double screenHeight, ProfileState profileState) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.03),
      child: Column(
        children: [
          // Profile Picture with Edit Icon
          Stack(
        children: [
          // Profile Picture
          Center(
            child: GestureDetector(
              onTap: () => _showProfilePictureOptions(context, ref, profileState),
              child: Container(
                    width: screenWidth * 0.25,
                    height: screenWidth * 0.25,
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
              // Camera Icon - positioned on the edge of the profile picture circle
          Positioned(
            bottom: 0,
                right: 0,
            child: GestureDetector(
              onTap: () => _showProfilePictureOptions(context, ref, profileState),
              child: Container(
                    width: 36,
                    height: 36,
                decoration: BoxDecoration(
                      color: const Color(0xFF8B0000),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                      spreadRadius: 1,
                          blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
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
                    fontSize: screenHeight * 0.026,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.008),
                // User Phone Number (if available)
                if (profileState.userPhoneNumber.isNotEmpty)
                  Column(
                    children: [
                      Text(
                        profileState.userPhoneNumber,
                        style: TextStyle(
                          fontSize: screenHeight * 0.020,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.008),
                    ],
                  ),
                // User Email
                Text(
                  profileState.userEmail.isNotEmpty ? profileState.userEmail : 'user@example.com',
                  style: TextStyle(
                    fontSize: screenHeight * 0.018,
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

  /// Builds user information section
  Widget _buildUserInfoSection(double screenWidth, double screenHeight, ProfileState profileState) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.03,
      ),
      child: Column(
        children: [
          // This section is now empty - phone number is only shown in profile picture section
        ],
      ),
    );
  }

  /// Builds account settings section (positioned near user info)
  Widget _buildAccountSettingsSection(BuildContext context, WidgetRef ref, double screenWidth, double screenHeight, ProfileState profileState) {
    return Container(
      margin: EdgeInsets.only(
        top: screenHeight * 0.02,
        bottom: screenHeight * 0.03,
      ),
      child: _buildMenuSection(
          'Account Settings',
          [
            _buildMenuItem(
              icon: Icons.person_outline_rounded,
              title: 'My Account',
            subtitle: '',
              onTap: () => _showComingSoon(context, 'My Account'),
            ),
            _buildMenuItem(
              icon: Icons.phone_outlined,
              title: 'Phone Number',
            subtitle: '',
            onTap: () => _showPhoneNumberDialog(context),
            ),
            _buildMenuItem(
              icon: Icons.lock_outline_rounded,
              title: 'Change Password',
            subtitle: '',
              onTap: () => _showComingSoon(context, 'Change Password'),
            ),
            _buildMenuItem(
              icon: Icons.fingerprint,
              title: 'Biometric Settings',
            subtitle: '',
              onTap: () => NavigationHelper.goToBiometricSettings(context),
            ),
          ],
        screenWidth,
        screenHeight,
      ),
    );
  }

  /// Builds other menu sections
  Widget _buildOtherMenuSections(BuildContext context, double screenWidth, double screenHeight) {
    return Column(
      children: [
        // Add other menu sections here if needed in the future
      ],
    );
  }

  /// Builds a menu section with title and items
  Widget _buildMenuSection(String title, List<Widget> items, double screenWidth, double screenHeight) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
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
                color: Colors.white,
              ),
            ),
          ),
          Container(
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8, top: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
      onTap: onTap,
        borderRadius: BorderRadius.circular(12),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
                width: 40,
                height: 40,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                  size: 20,
              ),
            ),
              const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                        color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                    if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
                color: Colors.white.withOpacity(0.6),
            ),
          ],
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

  /// Shows phone number update dialog
  void _showPhoneNumberDialog(BuildContext context) {
    final TextEditingController phoneController = TextEditingController();
    final profileState = ref.read(profileDataProvider);
    
    // Pre-fill with current phone number if available
    phoneController.text = profileState.userPhoneNumber;

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
                    colors: [Color(0xFF8B0000), Color(0xFF4B0082)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.phone_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Update Phone',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 300,
              maxHeight: 200,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF8B0000)),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
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
                backgroundColor: const Color(0xFF8B0000),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Update'),
            ),
          ],
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B0000)),
              ),
              SizedBox(height: 16),
              Text(
                'Updating phone number...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
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
      final apiService = ApiService();
      final response = await apiService.updateUser(
        userId: userId,
        phoneNumber: phoneNumber,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Update timeout - please check your connection');
        },
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
          _addDebugLog('⚠️ API update failed, trying local update...');
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

  /// Test API connection
  Future<void> _testApiConnection() async {
    try {
      _addDebugLog('🔍 Testing API connection...');
      
      final apiService = ApiService();
      final response = await apiService.healthCheck().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('API connection timeout');
        },
      );
      
      if (response.success) {
        _addDebugLog('✅ API connection successful!');
        context.showSuccessNotification('API connection successful!');
      } else {
        _addDebugLog('❌ API connection failed: ${response.message}');
        context.showErrorNotification('API connection failed: ${response.message}');
      }
    } catch (e) {
      _addDebugLog('❌ API connection error: $e');
      context.showErrorNotification('API connection error: $e');
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
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.camera, ref);
                },
              ),
              _buildBottomSheetItem(
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.gallery, ref);
                },
              ),
              if (profileState.hasProfilePicture)
                _buildBottomSheetItem(
                  icon: Icons.delete,
                  title: 'Remove Photo',
                  onTap: () {
                    Navigator.pop(context);
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

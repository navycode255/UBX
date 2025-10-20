import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/widgets/custom_notification.dart';
import '../../../router/navigation_helper.dart';
import '../../../router/route_constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService.instance;
  final BiometricService _biometricService = BiometricService.instance;
  Map<String, String?> _userData = {};
  bool _isLoading = true;
  bool _isBiometricEnabled = false;
  String _biometricType = 'Biometric';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh biometric status when returning to this page (e.g., from biometric settings)
    _refreshBiometricStatus();
  }

  /// Refresh only biometric status (more efficient than reloading all data)
  Future<void> _refreshBiometricStatus() async {
    try {
      final isBiometricEnabled = await _biometricService.isBiometricLoginEnabled();
      final biometricType = await _biometricService.getPrimaryBiometricType();
      
      if (mounted) {
        setState(() {
          _isBiometricEnabled = isBiometricEnabled;
          _biometricType = biometricType;
        });
      }
    } catch (e) {
      // Silently handle errors for status refresh

    }
  }

  /// Load user data from secure storage
  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getAllUserData();
      final isBiometricEnabled = await _biometricService.isBiometricLoginEnabled();
      final biometricType = await _biometricService.getPrimaryBiometricType();
      
      setState(() {
        _userData = userData;
        _isBiometricEnabled = isBiometricEnabled;
        _biometricType = biometricType;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        context.showErrorNotification('Failed to load user data: ${e.toString()}');
      }
    }
  }

  /// Handle logout
  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.showSuccessNotification('Logged out successfully');
        // Navigate to sign in page
        NavigationHelper.goToSignIn(context);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Logout failed: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

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
        child: Stack(
          children: [
            // Background decorative elements
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
            
            // Main content
            SafeArea(
              child: _isLoading
                  ? Center(
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
                              Icons.dashboard,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'Loading Dashboard...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: screenHeight * 0.018,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.08,
                        vertical: screenHeight * 0.02,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header with profile and logout icons
                          _buildHeader(screenWidth, screenHeight),
                          
                          SizedBox(height: screenHeight * 0.03),
                          
                          // Security status card
                          _buildSecurityStatusCard(screenWidth, screenHeight),
                          
                          SizedBox(height: screenHeight * 0.025),
                          
                          // User info card
                          _buildUserInfoCard(screenWidth, screenHeight),
                          
                          SizedBox(height: screenHeight * 0.025),
                          
                          // Security features card
                          _buildSecurityFeaturesCard(screenWidth, screenHeight),
                          
                          SizedBox(height: screenHeight * 0.025),
                          
                          // Quick actions card
                          _buildQuickActionsCard(screenWidth, screenHeight),
                          
                          SizedBox(height: screenHeight * 0.02),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build header with profile and logout icons
  Widget _buildHeader(double screenWidth, double screenHeight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // App logo and title
        Row(
          children: [
            Container(
              width: screenWidth * 0.12,
              height: screenWidth * 0.12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.security,
                size: screenWidth * 0.06,
                color: Colors.white,
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenHeight * 0.024,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Secure & Protected',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: screenHeight * 0.014,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // Action buttons
        Row(
          children: [
            // Profile button
            GestureDetector(
              onTap: () => context.push(RouteConstants.profile),
              child: Container(
                width: screenWidth * 0.12,
                height: screenWidth * 0.12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: screenWidth * 0.06,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            
            // Logout button
            GestureDetector(
              onTap: _handleLogout,
              child: Container(
                width: screenWidth * 0.12,
                height: screenWidth * 0.12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.logout,
                  size: screenWidth * 0.06,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build security status card
  Widget _buildSecurityStatusCard(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                'Security Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenHeight * 0.022,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          
          // Security indicators
          Row(
            children: [
              Expanded(
                child: _buildSecurityIndicator(
                  'Encryption',
                  'Active',
                  Icons.lock_outline,
                  Colors.green,
                  screenWidth,
                  screenHeight,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: _buildSecurityIndicator(
                  'Biometric',
                  _isBiometricEnabled ? 'Enabled' : 'Disabled',
                  _biometricType.toLowerCase().contains('face') 
                      ? Icons.face 
                      : Icons.fingerprint,
                  _isBiometricEnabled ? Colors.green : Colors.orange,
                  screenWidth,
                  screenHeight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build security indicator
  Widget _buildSecurityIndicator(
    String label,
    String status,
    IconData icon,
    Color statusColor,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: statusColor,
            size: screenWidth * 0.05,
          ),
          SizedBox(height: screenHeight * 0.008),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: screenHeight * 0.012,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: screenHeight * 0.003),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: screenHeight * 0.011,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build user info card
  Widget _buildUserInfoCard(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Colors.white,
                size: screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                'User Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenHeight * 0.022,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          
          // User details
          _buildUserDetail('Name', _userData['name'] ?? 'Not available', screenHeight),
          _buildUserDetail('Email', _userData['email'] ?? 'Not available', screenHeight),
        ],
      ),
    );
  }

  /// Build user detail row
  Widget _buildUserDetail(String label, String value, double screenHeight) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.015),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: screenHeight * 0.014,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: screenHeight * 0.014,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build security features card
  Widget _buildSecurityFeaturesCard(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security_outlined,
                color: Colors.white,
                size: screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                'Security Features',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenHeight * 0.022,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          
          // Feature list
          _buildFeatureItem(
            'Data Encryption',
            'All sensitive data is encrypted at rest',
            Icons.lock_outline,
            Colors.green,
            screenHeight,
          ),
          _buildFeatureItem(
            'Secure Transmission',
            'All API communication uses HTTPS',
            Icons.wifi_protected_setup,
            Colors.blue,
            screenHeight,
          ),
          _buildFeatureItem(
            'Biometric Authentication',
            _isBiometricEnabled 
                ? 'Biometric login is enabled'
                : 'Biometric login is disabled',
            _biometricType.toLowerCase().contains('face') 
                ? Icons.face 
                : Icons.fingerprint,
            _isBiometricEnabled ? Colors.green : Colors.orange,
            screenHeight,
          ),
        ],
      ),
    );
  }

  /// Build feature item
  Widget _buildFeatureItem(
    String title,
    String description,
    IconData icon,
    Color color,
    double screenHeight,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.015),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenHeight * 0.016,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: screenHeight * 0.012,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build quick actions card
  Widget _buildQuickActionsCard(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: Colors.white,
                size: screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenHeight * 0.022,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Profile Settings',
                  Icons.person_outline,
                  () => context.push(RouteConstants.profile),
                  screenWidth,
                  screenHeight,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: _buildActionButton(
                  'Security Settings',
                  Icons.security_outlined,
                  () async {
                    await context.push(RouteConstants.biometricSettings);
                    // Refresh biometric status when returning from settings
                    _refreshBiometricStatus();
                  },
                  screenWidth,
                  screenHeight,
                ),
              ),
            ],
          ),
          
          SizedBox(height: screenHeight * 0.015),
          
          // Debug button
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(
              'App Lockout Debug',
              Icons.bug_report_outlined,
              () => context.go(RouteConstants.home),
              screenWidth,
              screenHeight,
            ),
          ),
        ],
      ),
    );
  }

  /// Build action button
  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
    double screenWidth,
    double screenHeight,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: screenHeight * 0.015,
          horizontal: screenWidth * 0.03,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: screenWidth * 0.05,
            ),
            SizedBox(height: screenHeight * 0.008),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: screenHeight * 0.012,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

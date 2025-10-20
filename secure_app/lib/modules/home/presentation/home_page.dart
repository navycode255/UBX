import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_notification.dart';
import '../../../router/route_constants.dart';
import '../data/home_providers.dart';
import '../data/home_state.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize home data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        ref.read(HomeProviders.homeNotifierProvider.notifier).loadUserData();
        _hasInitialized = true;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh biometric status when returning to this page (e.g., from biometric settings)
    ref.read(HomeProviders.homeNotifierProvider.notifier).refreshBiometricStatus();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(HomeProviders.homeDataProvider);
    final isLoading = ref.watch(HomeProviders.homeLoadingProvider);
    final error = ref.watch(HomeProviders.homeErrorProvider);

    // Listen to error state and show snackbar
    ref.listen<String?>(HomeProviders.homeErrorProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        context.showErrorNotification(next);
      }
    });

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
              child: isLoading && !homeState.hasUserData
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
                          _buildHeader(screenWidth, screenHeight, homeState),
                          
                          SizedBox(height: screenHeight * 0.03),
                          
                          // Security status card
                          _buildSecurityStatusCard(screenWidth, screenHeight, homeState),
                          
                          SizedBox(height: screenHeight * 0.025),
                          
                          // User info card
                          _buildUserInfoCard(screenWidth, screenHeight, homeState),
                          
                          SizedBox(height: screenHeight * 0.025),
                          
                          // Security features card
                          _buildSecurityFeaturesCard(screenWidth, screenHeight, homeState),
                          
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

  /// Handle logout
  Future<void> _handleLogout() async {
    try {
      // Clear home state
      ref.read(HomeProviders.homeNotifierProvider.notifier).state = const HomeState();
      
      // Navigate to sign in
      context.go(RouteConstants.signIn);
    } catch (e) {
      context.showErrorNotification('Logout failed: ${e.toString()}');
    }
  }

  /// Build header with profile and logout icons
  Widget _buildHeader(double screenWidth, double screenHeight, homeState) {
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
  Widget _buildSecurityStatusCard(double screenWidth, double screenHeight, homeState) {
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
                  homeState.isBiometricEnabled ? 'Enabled' : 'Disabled',
                  homeState.biometricType.toLowerCase().contains('face') 
                      ? Icons.face 
                      : Icons.fingerprint,
                  homeState.isBiometricEnabled ? Colors.green : Colors.orange,
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
  Widget _buildUserInfoCard(double screenWidth, double screenHeight, homeState) {
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
          _buildUserDetail('Name', homeState.userName, screenHeight),
          _buildUserDetail('Email', homeState.userEmail, screenHeight),
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
  Widget _buildSecurityFeaturesCard(double screenWidth, double screenHeight, homeState) {
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
                Icons.security,
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
          
          // Security features list
          _buildSecurityFeature(
            'App Lockout',
            'Enabled',
            Icons.lock_clock,
            Colors.green,
            screenHeight,
          ),
          _buildSecurityFeature(
            'Data Encryption',
            'Active',
            Icons.enhanced_encryption,
            Colors.green,
            screenHeight,
          ),
          _buildSecurityFeature(
            'Secure Storage',
            'Protected',
            Icons.storage,
            Colors.green,
            screenHeight,
          ),
        ],
      ),
    );
  }

  /// Build security feature row
  Widget _buildSecurityFeature(
    String feature,
    String status,
    IconData icon,
    Color statusColor,
    double screenHeight,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.012),
      child: Row(
        children: [
          Icon(
            icon,
            color: statusColor,
            size: screenHeight * 0.02,
          ),
          SizedBox(width: screenHeight * 0.015),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: screenHeight * 0.015,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: screenHeight * 0.013,
              fontWeight: FontWeight.bold,
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
                Icons.dashboard,
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
                  'Biometric Settings',
                  Icons.fingerprint,
                  () => context.push(RouteConstants.biometricSettings),
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

  /// Build individual action button
  Widget _buildActionButton(
    String title,
    IconData icon,
    VoidCallback onTap,
    double screenWidth,
    double screenHeight,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenHeight * 0.02),
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
              size: screenWidth * 0.08,
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../constants/supabase.dart';
import '../sign_in.dart';
import 'curtain_preference.dart';
import 'my_order.dart';
import 'my_profile.dart';
import 'support.dart';
import 'ar_measurement_screen.dart';
import 'measurement_guide_screen.dart';
import '../../services/ar_measurement_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? userProfile;
  bool _isLoading = true;

  // Define the theme color for easy reuse
  static const Color primaryRed = Color.fromARGB(255, 158, 19, 17);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('user_profiles')
            .select('*')
            .eq('user_id', user.id)
            .single();

        setState(() {
          userProfile = response;
          _isLoading = false;
        });
      } else {
        // If no user, no need to load, just go to sign in
        _navigateToSignIn();
      }
    } catch (error) {
      debugPrint('Error loading user profile: $error');
      setState(() => _isLoading = false);
      // It's possible the user is not in the profiles table yet, handle gracefully
    }
  }

  void _navigateToSignIn() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GoogleSignInScreen()),
      );
    }
  }

  Future<void> _showMeasurementOptions(BuildContext context) async {
    // Check AR capabilities first
    final arInfo = await ARCapabilityInfo.check();
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Measurement Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select how you\'d like to measure your windows for the perfect curtain fit.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            
            // AR Measurement option
            _buildMeasurementOption(
              icon: Icons.view_in_ar,
              title: 'AR Measurement',
              subtitle: arInfo.isAvailable 
                  ? 'Use your camera to measure windows in AR (Recommended)'
                  : 'Not available on this device',
              isEnabled: arInfo.isAvailable,
              isRecommended: arInfo.isAvailable,
              onTap: arInfo.isAvailable ? () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ARMeasurementScreen(),
                  ),
                );
              } : null,
            ),
            
            const SizedBox(height: 16),
            
            // Manual measurement option
            _buildMeasurementOption(
              icon: Icons.straighten,
              title: 'Manual Guide',
              subtitle: 'Step-by-step guide to measure windows manually',
              isEnabled: true,
              isRecommended: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MeasurementGuideScreen(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Info about AR requirements
            if (!arInfo.isAvailable && arInfo.requirements.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'AR Requirements',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...arInfo.requirements.map((req) => Padding(
                      padding: const EdgeInsets.only(left: 28, bottom: 4),
                      child: Text(
                        '• $req',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 12,
                        ),
                      ),
                    )).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryRed),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required bool isRecommended,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRecommended 
                ? primaryRed 
                : isEnabled 
                    ? Colors.grey.shade300 
                    : Colors.grey.shade200,
            width: isRecommended ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEnabled 
                    ? (isRecommended ? primaryRed : Colors.grey.shade100)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isEnabled 
                    ? (isRecommended ? Colors.white : primaryRed)
                    : Colors.grey.shade400,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isEnabled ? Colors.black87 : Colors.grey.shade500,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isEnabled ? Colors.black54 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (isEnabled)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      _navigateToSignIn();
    } catch (error) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: primaryRed)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Soft off-white background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header
              _buildHeader(),
              const SizedBox(height: 20),

              // Main "Find Your Style" Card
              _buildMainActionCard(context),
              const SizedBox(height: 30),
              
              // Section Title for other actions
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  "Dashboard",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              
              // Secondary Action Cards
              _buildSecondaryActionGrid(context),
              
              // 4. REMOVED the profile details ExpansionTile from here

            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildHeader() {
    String fullName = userProfile?['full_name'] ?? 'There';
    // Get the first name for a more personal touch
    String firstName = fullName.split(' ').first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back,',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                '$firstName!',
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          // Sign Out Button
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: primaryRed, size: 28),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
    );
  }
  
  Widget _buildMainActionCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: primaryRed,
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [primaryRed, primaryRed.withAlpha(204)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryRed.withAlpha(75),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ready to design?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Let\'s find the perfect curtains that match your unique style.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CurtainPreferenceScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Start Designing', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. UPDATED THIS METHOD
  Widget _buildSecondaryActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      childAspectRatio: 1.2, // Adjust card shape
      children: [
        _buildActionCard(
          icon: Icons.shopping_cart_outlined,
          title: 'My Orders',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
            );
          },
        ),
        _buildActionCard(
          icon: Icons.straighten_outlined,
          title: 'Measure Guide',
          onTap: () => _showMeasurementOptions(context),
        ),
        _buildActionCard(
          icon: Icons.person_outline,
          title: 'My Profile',
          onTap: () {
            if (userProfile != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyProfilePage(userProfile: userProfile!),
                ),
              );
            }
          },
        ),
        _buildActionCard(
          icon: Icons.support_agent_outlined,
          title: 'Support',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: primaryRed),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
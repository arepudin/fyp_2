import 'package:flutter/material.dart';
import '../constants/supabase.dart';
import '../screens/sign_in.dart';
import '../screens/curtain_preference.dart';
import '../screens/my_order.dart';
import '../screens/setting.dart';
import '../screens/support.dart';

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
              
              // Profile Details Expansion Tile
              _buildProfileDetails(),

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
            colors: [primaryRed, primaryRed.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryRed.withOpacity(0.3),
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
            // Navigate to the My Orders screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
            );
          },
        ),
        _buildActionCard(
          icon: Icons.straighten_outlined,
          title: 'Measure Guide',
          onTap: () { /* TODO: Navigate to Measurement Guide Page */ },
        ),
        _buildActionCard(
          icon: Icons.settings_outlined,
          title: 'Settings',
          onTap: () {
            /*Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );*/
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
          // side: BorderSide(color: Colors.grey.shade200),
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

  Widget _buildProfileDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Theme(
        // Override the divider color to be transparent
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 8.0),
          leading: const Icon(Icons.person_outline, color: primaryRed),
          title: const Text(
            'My Profile Information',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.email_outlined, 'Email', userProfile?['email']),
                  _buildInfoRow(Icons.phone_outlined, 'Phone', userProfile?['phone_number']),
                  _buildInfoRow(Icons.location_on_outlined, 'Address', userProfile?['address']),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54),
          ),
          Expanded(
            child: Text(
              value ?? 'Not provided',
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
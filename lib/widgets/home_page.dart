import 'package:flutter/material.dart';
import '../constants/supabase.dart';
import '../screens/sign_in.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? userProfile;
  bool _isLoading = true;

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
      }
    } catch (error) {
      debugPrint('Error loading user profile: $error');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GoogleSignInScreen()),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tailormate"),
        backgroundColor: const Color.fromRGBO(36, 95, 117, 1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(36, 95, 117, 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${userProfile?['full_name'] ?? 'User'}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(36, 95, 117, 1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ready to measure, order, and beautify your windows?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.person, 'Name', userProfile?['full_name']),
                    _buildInfoRow(Icons.email, 'Email', userProfile?['email']),
                    _buildInfoRow(Icons.phone, 'Phone', userProfile?['phone_number']),
                    _buildInfoRow(Icons.location_on, 'Address', userProfile?['address']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  Icons.straighten,
                  'Measure Windows',
                  'Start measuring',
                  () {},
                ),
                _buildActionCard(
                  Icons.search,
                  'Browse Curtains',
                  'Find perfect curtains',
                  () {},
                ),
                _buildActionCard(
                  Icons.shopping_cart,
                  'My Orders',
                  'Track your orders',
                  () {},
                ),
                _buildActionCard(
                  Icons.settings,
                  'Settings',
                  'Manage preferences',
                  () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color.fromRGBO(36, 95, 117, 1), size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value ?? 'Not provided',
              style: TextStyle(
                color: value != null ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: const Color.fromRGBO(229, 64, 19, 1),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
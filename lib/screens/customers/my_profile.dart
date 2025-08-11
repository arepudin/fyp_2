import 'package:flutter/material.dart';
import '../../config/theme_config.dart';

class MyProfilePage extends StatelessWidget {
  final Map<String, dynamic> userProfile;

  const MyProfilePage({
    super.key,
    required this.userProfile,
  });

  // Re-using the primary color for consistency
  static const Color primaryRed = ThemeConfig.primaryColor;

  @override
  Widget build(BuildContext context) {
    // Helper to get the initials from the full name for the avatar
    String getInitials(String? name) {
      if (name == null || name.isEmpty) return 'U';
      List<String> names = name.split(" ");
      String initials = "";
      if (names.isNotEmpty) {
        initials += names[0][0];
        if (names.length > 1) {
          initials += names[names.length - 1][0];
        }
      }
      return initials.toUpperCase();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFFF9F9F9),
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: primaryRed.withOpacity(0.1),
                    child: Text(
                      getInitials(userProfile['full_name']),
                      style: const TextStyle(fontSize: 40, color: primaryRed, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userProfile['full_name'] ?? 'User Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                   Text(
                    userProfile['email'] ?? 'No email provided',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            
            // Re-using the info row widget logic for a clean look
            _buildInfoRow(
              Icons.email_outlined, 
              'Email', 
              userProfile['email']
            ),
            _buildInfoRow(
              Icons.phone_outlined, 
              'Phone', 
              userProfile['phone_number']
            ),
            _buildInfoRow(
              Icons.location_on_outlined, 
              'Address', 
              userProfile['address']
            ),
          ],
        ),
      ),
    );
  }

  // A detailed row for displaying profile information
  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: primaryRed, size: 22),
          const SizedBox(width: 20),
          SizedBox(
            width: 80, // Fixed width for labels for good alignment
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not provided',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
// You might need this package to launch URLs/phone/email if you add interactivity later
// import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  // Use the same theme color from your home page
  static const Color primaryRed = Color.fromARGB(255, 158, 19, 17);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Contact Us'),
            
            // --- MODIFICATION START ---
            // Replaced the two clickable cards with one static info card.
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone Support',
                      value: '+60 11-1161 1627',
                    ),
                    const Divider(height: 1),
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email Support',
                      value: 'sabacurtain@gmail.com',
                    ),
                  ],
                ),
              ),
            ),
            // --- MODIFICATION END ---
            
            const SizedBox(height: 30),
            
            _buildSectionHeader('Frequently Asked Questions'),
            _buildFaqTile(
              'What is the process after I order?',
              'Once you submit your design, our team begins production, which typically takes 5-7 business days. We will notify you via email and a push notification as soon as your order is ready for pickup at our shop.',
            ),
            _buildFaqTile(
              'What is your quality and return policy?',
              'To ensure you are 100% satisfied, we do not ship items. You must inspect your custom curtains at our shop during pickup. If you are happy with the quality, you will complete your payment at that time. All sales are final after inspection and payment.',
            ),
            _buildFaqTile(
              'What happens if I find an issue during pickup?',
              'Please bring any defects or concerns to our staff\'s attention immediately during your inspection. We will work with you to correct the issue, which may involve remaking the item. Our goal is for you to be completely happy before you leave the shop.',
            ),
            _buildFaqTile(
              'What payment methods do you accept in-store?',
              'We accept all major credit/debit cards, cash, and mobile payments (Apple Pay, Google Pay) at our physical location.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, color: primaryRed, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
        children: [
          Text(
            answer,
            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          ),
        ],
      ),
    );
  }
}
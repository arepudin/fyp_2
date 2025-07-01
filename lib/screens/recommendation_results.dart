// lib/screens/recommendation_results_screen.dart

import 'package:flutter/material.dart';
import '../constants/supabase.dart';
import './my_order.dart'; // Import the My Orders screen for navigation

class RecommendationResultsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;

  const RecommendationResultsScreen({
    super.key,
    required this.recommendations,
  });
  
  // --- CORE LOGIC TO PLACE THE ORDER ---
  Future<void> _placeOrder({
    required BuildContext context,
    required String curtainId,
    required double width,
    required double height,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    // Step 1: Insert the measurement and get its new ID back.
    final measurementResponse = await supabase.from('measurements').insert({
      'user_id': user.id,
      'window_width': width,
      'window_height': height,
    }).select().single(); // .select().single() is crucial to get the new row back

    final measurementId = measurementResponse['id'];

    // Step 2: Insert the order, linking the new measurement and the curtain.
    await supabase.from('orders').insert({
      'user_id': user.id,
      'curtain_id': curtainId,
      'measurement_id': measurementId,
      // Status defaults to 'Pending' in the database, so we don't need to set it.
    });
  }

  // --- UI DIALOG TO CONFIRM ORDER AND GET MEASUREMENTS ---
  Future<void> _showConfirmationDialog(BuildContext context, Map<String, dynamic> curtain) async {
    final formKey = GlobalKey<FormState>();
    final widthController = TextEditingController();
    final heightController = TextEditingController();
    bool isPlacingOrder = false;

    return showDialog(
      context: context,
      barrierDismissible: !isPlacingOrder, // Prevent dismissing while loading
      builder: (dialogContext) {
        return StatefulBuilder( // Use StatefulBuilder to manage the dialog's own state
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Confirm Your Order', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display the chosen curtain
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(curtain['image_url'], width: 60, height: 60, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              curtain['name'],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30),
                      const Text('Enter Window Size (in cm)', style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 16),
                      // Width TextFormField
                      TextFormField(
                        controller: widthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Width',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.width_full),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter width.';
                          if (double.tryParse(value) == null) return 'Enter a valid number.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Height TextFormField
                      TextFormField(
                        controller: heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Height',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.height),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter height.';
                          if (double.tryParse(value) == null) return 'Enter a valid number.';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isPlacingOrder ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isPlacingOrder ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isPlacingOrder = true);
                      try {
                        await _placeOrder(
                          context: context,
                          curtainId: curtain['id'],
                          width: double.parse(widthController.text),
                          height: double.parse(heightController.text),
                        );
                        
                        // Close dialog and show success message
                        if (!context.mounted) return;
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order placed successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // Navigate to My Orders page
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen()));

                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error placing order: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setDialogState(() => isPlacingOrder = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 158, 19, 17)),
                  child: isPlacingOrder 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('Place Order', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Our Top Picks For You', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: recommendations.isEmpty
          ? const Center(
              child: Text(
                'No matching curtains found.\nTry a different combination!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final item = recommendations[index];
                final curtain = item['data'];
                // Wrap the card with GestureDetector to make it tappable
                return GestureDetector(
                  onTap: () => _showConfirmationDialog(context, curtain),
                  child: _RecommendationCard(
                    curtain: curtain,
                    score: item['score'],
                  ),
                );
              },
            ),
    );
  }
}

// The card widget remains the same
class _RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> curtain;
  final int score;

  const _RecommendationCard({
    required this.curtain,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    const primaryRed = Color.fromARGB(255, 158, 19, 17);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 250,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                curtain['image_url'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent, Colors.transparent, Colors.black.withOpacity(0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.4, 0.6, 1],
                ),
              ),
            ),
          ),
          if (score > 0)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryRed,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)],
                ),
                child: Text(
                  '${((score / 7) * 100).toInt()}% Match',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  curtain['name'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(curtain['material']),
                    const SizedBox(width: 8),
                    _buildInfoChip(curtain['design_pattern']),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}
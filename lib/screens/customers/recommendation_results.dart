import 'package:flutter/material.dart';
import '../../models/curtain_model.dart';
import '../../models/recommendation_model.dart';
import 'curtain_preference.dart';
import '../../constants/supabase.dart';
import 'my_order.dart';
import '../../services/user_interaction.dart';
import 'ar_measurement_screen.dart';
import 'measurement_guide_screen.dart';
import '../../services/ar_measurement_service.dart';

class RecommendationResultsScreen extends StatelessWidget {
  final List<ScoredRecommendation> recommendations;

  const RecommendationResultsScreen({
    super.key,
    required this.recommendations,
  });

  void _findSimilar(BuildContext context, Curtain curtain) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CurtainPreferenceScreen(
          initialPreferences: curtain.preferencesAsMap,
        ),
      ),
    );
  }
  
  Future<void> _placeOrder({
    required BuildContext context,
    required Curtain curtain,
    required double width,
    required double height,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }
    final measurementResponse = await supabase.from('measurements').insert({
      'user_id': user.id,
      'window_width': width,
      'window_height': height,
    }).select().single();

    final measurementId = measurementResponse['id'];
    await supabase.from('orders').insert({
      'user_id': user.id,
      'curtain_id': curtain.id,
      'measurement_id': measurementId,
    });
    
    // Track the order interaction
    await UserInteractionService.trackOrder(curtain.id);
  }

  Future<void> _showConfirmationDialog(BuildContext context, Curtain curtain) async {
    final formKey = GlobalKey<FormState>();
    final widthController = TextEditingController();
    final heightController = TextEditingController();
    bool isPlacingOrder = false;

    return showDialog(
      context: context,
      barrierDismissible: !isPlacingOrder,
      builder: (dialogContext) {
        return StatefulBuilder(
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
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(curtain.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              curtain.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30),
                      Row(
                        children: [
                          const Text('Enter Window Size (in cm)', style: TextStyle(color: Colors.black54)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _showMeasurementOptions(dialogContext, curtain, widthController, heightController),
                            icon: const Icon(Icons.straighten, size: 16),
                            label: const Text('Measure', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: widthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Width', border: OutlineInputBorder(), prefixIcon: Icon(Icons.width_full)),
                        validator: (v) => v == null || v.isEmpty ? 'Please enter width.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Height', border: OutlineInputBorder(), prefixIcon: Icon(Icons.height)),
                        validator: (v) => v == null || v.isEmpty ? 'Please enter height.' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: isPlacingOrder ? null : () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isPlacingOrder ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isPlacingOrder = true);
                      try {
                        await _placeOrder(
                          context: context,
                          curtain: curtain, 
                          width: double.parse(widthController.text),
                          height: double.parse(heightController.text),
                        );
                        if (!context.mounted) return;
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully!'), backgroundColor: Colors.green));
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error placing order: $e'), backgroundColor: Colors.red));
                      } finally {
                        setDialogState(() => isPlacingOrder = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 158, 19, 17)),
                  child: isPlacingOrder ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Place Order', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showMeasurementOptions(
    BuildContext context,
    Curtain curtain,
    TextEditingController widthController,
    TextEditingController heightController,
  ) async {
    // Check AR capabilities first
    final arInfo = await ARCapabilityInfo.check();
    
    if (!context.mounted) return;

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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get precise measurements for your curtains.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            
            // AR Measurement option
            _buildMeasurementOption(
              icon: Icons.view_in_ar,
              title: 'AR Measurement',
              subtitle: arInfo.isAvailable 
                  ? 'Use your camera to measure windows in AR'
                  : 'Not available on this device',
              isEnabled: arInfo.isAvailable,
              isRecommended: arInfo.isAvailable,
              onTap: arInfo.isAvailable ? () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ARMeasurementScreen(
                      onMeasurementsCompleted: (width, height) {
                        widthController.text = width.toStringAsFixed(1);
                        heightController.text = height.toStringAsFixed(1);
                      },
                    ),
                  ),
                );
              } : null,
            ),
            
            const SizedBox(height: 12),
            
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
                    builder: (_) => MeasurementGuideScreen(
                      onMeasurementsEntered: (width, height) {
                        widthController.text = width.toStringAsFixed(1);
                        heightController.text = height.toStringAsFixed(1);
                      },
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color.fromARGB(255, 158, 19, 17)),
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
    const primaryRed = Color.fromARGB(255, 158, 19, 17);
    
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
              padding: const EdgeInsets.all(8),
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
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isEnabled ? Colors.black87 : Colors.grey.shade500,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isEnabled ? Colors.black54 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (isEnabled)
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
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
              child: Text('No matching curtains found.\nTry a different combination!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final recommendation = recommendations[index];
                return _RecommendationCard(
                  recommendation: recommendation,
                  onFindSimilar: () => _findSimilar(context, recommendation.curtain),
                  onOrder: () => _showConfirmationDialog(context, recommendation.curtain),
                );
              },
            ),
    );
  }
}

/// Enhanced Recommendation Card with detailed scoring
class _RecommendationCard extends StatelessWidget {
  final ScoredRecommendation recommendation;
  final VoidCallback onFindSimilar;
  final VoidCallback onOrder;

  const _RecommendationCard({
    required this.recommendation,
    required this.onFindSimilar,
    required this.onOrder,
  });

  @override
  Widget build(BuildContext context) {
    // Track view when card is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserInteractionService.trackView(recommendation.curtain.id);
    });
    
    const primaryRed = Color.fromARGB(255, 158, 19, 17);
    
    final curtain = recommendation.curtain;
    final displayScore = recommendation.displayScore;
    final hasDetailedScores = recommendation.categoryScores.isNotEmpty;

    return Container(
      height: hasDetailedScores ? 300 : 250, // Increased height for detailed view
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        children: [
          // Background Image and Gradient
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                curtain.imageUrl, 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(
                      color: Colors.grey.shade300, 
                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)
                    ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    // FIX: Replaced withOpacity with withAlpha
                    Colors.black.withAlpha(102), // 0.4 opacity
                    Colors.transparent, 
                    Colors.transparent, 
                    Colors.black.withAlpha(204)  // 0.8 opacity
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.3, 0.6, 1],
                ),
              ),
            ),
          ),
          
          // Top-left: Match percentage and Similar button
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Match % Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getScoreColor(displayScore),
                    borderRadius: BorderRadius.circular(12), 
                    boxShadow: [
                      BoxShadow(
                        // FIX: Replaced withOpacity with withAlpha
                        color: Colors.black.withAlpha(128), // 0.5 opacity
                        blurRadius: 4
                      )
                    ]
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasDetailedScores ? Icons.smart_toy : Icons.analytics,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$displayScore% Match', 
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 12
                        )
                      ),
                    ],
                  ),
                ),
                
                // Similar Button
                SizedBox(
                  width: 80,
                  child: OutlinedButton(
                    onPressed: onFindSimilar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      // FIX: Replaced withOpacity with withAlpha
                      backgroundColor: Colors.black.withAlpha(77), // 0.3 opacity
                      side: const BorderSide(color: Colors.white70),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Similar', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),

          // NEW: Detailed scoring breakdown
          if (hasDetailedScores)
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: _buildDetailedScoring(recommendation.categoryScores),
            ),

          // Bottom content
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Curtain name and info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Left side: Name and tags
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            curtain.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 22, 
                              fontWeight: FontWeight.bold, 
                              shadows: [Shadow(blurRadius: 2)]
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: [
                              _buildInfoChip(curtain.material),
                              _buildInfoChip(curtain.designPattern),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Right side: Order button
                    SizedBox(
                      width: 100,
                      child: ElevatedButton(
                        onPressed: onOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Order Now',
                          style: TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
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
    );
  }

  /// NEW: Build detailed scoring breakdown
  Widget _buildDetailedScoring(Map<String, double> categoryScores) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // FIX: Replaced withOpacity with withAlpha
        color: Colors.black.withAlpha(153), // 0.6 opacity
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Match Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...categoryScores.entries.map((entry) {
            final score = (entry.value * 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getCategoryDisplayName(entry.key),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  Text(
                    '$score%',
                    style: TextStyle(
                      color: _getScoreColor(score),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Get display name for category
  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'pattern': return 'Pattern';
      case 'material': return 'Material';
      case 'lightControl': return 'Light Control';
      case 'roomType': return 'Room Type';
      case 'style': return 'Style';
      default: return category;
    }
  }

  /// Get color based on score
  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.yellow;
    return Colors.red;
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        // FIX: Replaced withOpacity with withAlpha
        color: Colors.black.withAlpha(102), // 0.4 opacity
        borderRadius: BorderRadius.circular(8)
      ),
      child: Text(
        text, 
        style: const TextStyle(color: Colors.white, fontSize: 12)
      ),
    );
  }
}
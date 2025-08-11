import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../models/curtain_model.dart';
import '../../models/recommendation_model.dart';
import '../../services/measurement.dart'; // Import measurement service
import '../../utils/measurement_utils.dart'; // Import measurement utils
import 'curtain_preference.dart';
import '../../constants/supabase.dart';
import 'my_order.dart';
import '../../services/user_interaction.dart';
import 'measurement_guide_screen.dart';

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

  // The dialog is now handled by a dedicated stateful widget below.
  Future<void> _showConfirmationDialog(BuildContext context, Curtain curtain) async {
    return showDialog(
      context: context,
      builder: (dialogContext) => _ConfirmOrderDialog(curtain: curtain),
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
              child: Text('No matching curtains found.\nTry a different combination!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final recommendation = recommendations[index];
                return _RecommendationCard(
                  recommendation: recommendation,
                  onFindSimilar: () =>
                      _findSimilar(context, recommendation.curtain),
                  onOrder: () =>
                      _showConfirmationDialog(context, recommendation.curtain),
                );
              },
            ),
    );
  }
}

/// A stateful widget that manages the logic for the order confirmation dialog.
class _ConfirmOrderDialog extends StatefulWidget {
  final Curtain curtain;

  const _ConfirmOrderDialog({required this.curtain});

  @override
  State<_ConfirmOrderDialog> createState() => _ConfirmOrderDialogState();
}

class _ConfirmOrderDialogState extends State<_ConfirmOrderDialog> {
  bool _isLoadingMeasurement = true;
  bool _isPlacingOrder = false;
  Map<String, dynamic>? _latestMeasurement;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLatestMeasurement();
  }

  /// Fetches the measurement data from the service.
  Future<void> _fetchLatestMeasurement() async {
    try {
      final measurement = await MeasurementService.getLatestUserMeasurement();
      if (mounted) {
        setState(() {
          if (measurement == null) {
            _errorMessage = 'No measurement found. Please add a window measurement first.';
          } else {
            _latestMeasurement = measurement;
          }
          _isLoadingMeasurement = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not fetch your measurements.';
          _isLoadingMeasurement = false;
        });
      }
    }
  }

  /// Places the order using the fetched measurement ID.
  Future<void> _placeOrder(String measurementId) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    await supabase.from('orders').insert({
      'user_id': user.id,
      'curtain_id': widget.curtain.id,
      'measurement_id': measurementId,
    });

    await UserInteractionService.trackOrder(widget.curtain.id);
  }

  /// Navigates to the measurement guide screen.
  void _navigateToMeasurementGuide() {
    // First, pop the dialog
    Navigator.of(context).pop();
    // Then push the new screen
    Navigator.push(
      context,
      MaterialPageRoute(
        // We don't need a callback, the dialog will re-fetch when opened again.
        builder: (_) => const MeasurementMethodSelectionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Confirm Your Order', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(widget.curtain.imageUrl,
                      width: 60, height: 60, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.curtain.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            // Dynamic content based on measurement fetch state
            _buildMeasurementContent(),
          ],
        ),
      ),
      actions: _buildActions(),
    );
  }

  /// Builds the main content of the dialog based on the loading/error/success state.
  Widget _buildMeasurementContent() {
    if (_isLoadingMeasurement) {
      return const SizedBox(
        height: 100,
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Fetching latest measurement..."),
          ],
        )),
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      );
    }

    if (_latestMeasurement != null) {
      final width = _latestMeasurement!['window_width'];
      final height = _latestMeasurement!['window_height'];
      final unitName = _latestMeasurement!['unit'] as String;
      // Convert unit string from DB back to enum
      final unit = MeasurementUnit.values.firstWhere(
        (e) => e.name == unitName,
        orElse: () => MeasurementUnit.meters,
      );

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Using your latest saved measurement:',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMeasurementDisplay('Width', width, unit),
                _buildMeasurementDisplay('Height', height, unit),
              ],
            ),
          ),
        ],
      );
    }
    // Fallback case
    return const SizedBox.shrink();
  }

  /// Builds the action buttons for the dialog.
  List<Widget> _buildActions() {
    if (_errorMessage != null) {
      return [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _navigateToMeasurementGuide,
          style: ElevatedButton.styleFrom(backgroundColor: const ThemeConfig.primaryColor),
          child: const Text('Add Measurement', style: TextStyle(color: Colors.white)),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: _isPlacingOrder ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: (_isPlacingOrder || _latestMeasurement == null)
            ? null
            : () async {
                setState(() => _isPlacingOrder = true);
                try {
                  await _placeOrder(_latestMeasurement!['id']);
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Order placed successfully!'),
                      backgroundColor: Colors.green));
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error placing order: $e'),
                      backgroundColor: Colors.red));
                } finally {
                  if (mounted) {
                    setState(() => _isPlacingOrder = false);
                  }
                }
              },
        style: ElevatedButton.styleFrom(backgroundColor: const ThemeConfig.primaryColor),
        child: _isPlacingOrder
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Place Order', style: TextStyle(color: Colors.white)),
      ),
    ];
  }

  /// Helper widget to display a single measurement value (e.g., Width).
  Widget _buildMeasurementDisplay(String label, double value, MeasurementUnit unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(
          MeasurementUtils.formatWithUnit(value, unit),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ],
    );
  }
}

// =========================================================================
// The rest of the file (_RecommendationCard) remains unchanged.
// =========================================================================

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

    const primaryRed = ThemeConfig.primaryColor;

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
                errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child:
                        const Icon(Icons.broken_image, size: 50, color: Colors.grey)),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withAlpha(102), // 0.4 opacity
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withAlpha(204) // 0.8 opacity
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFB71C1C), // deep red
                        Color(0xFFD32F2F), // lighter red
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite, // heart icon, more friendly!
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$displayScore% Match',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                          shadows: [Shadow(blurRadius: 2)],
                        ),
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
                      backgroundColor: Colors.black.withAlpha(77), // 0.3 opacity
                      side: const BorderSide(color: Colors.white70),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child:
                        const Text('Similar', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
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
                                shadows: [Shadow(blurRadius: 2)]),
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

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.black.withAlpha(102), // 0.4 opacity
          borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}
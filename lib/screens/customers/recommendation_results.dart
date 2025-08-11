import 'package:flutter/material.dart';
import 'package:fyp_2/config/app_sizes.dart';
import 'package:fyp_2/config/app_strings.dart';
import 'package:fyp_2/models/curtain_model.dart';
import 'package:fyp_2/models/recommendation_model.dart';
import 'package:fyp_2/services/measurement.dart';
import 'package:fyp_2/utils/measurement_utils.dart';
import 'package:fyp_2/screens/customers/curtain_preference.dart';
import 'package:fyp_2/constants/supabase.dart';
import 'package:fyp_2/screens/customers/my_order.dart';
import 'package:fyp_2/services/user_interaction.dart';
import 'package:fyp_2/screens/customers/manual_measurement.dart';

class RecommendationResultsScreen extends StatelessWidget {
  final List<ScoredRecommendation> recommendations;

  const RecommendationResultsScreen({
    super.key,
    required this.recommendations,
  });

  void _findSimilar(BuildContext context, Curtain curtain) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => CurtainPreferenceScreen(initialPreferences: curtain.preferencesAsMap)),
    );
  }

  Future<void> _showConfirmationDialog(BuildContext context, Curtain curtain) async {
    return showDialog(
      context: context,
      builder: (dialogContext) => _ConfirmOrderDialog(curtain: curtain),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text(AppStrings.topPicksTitle),
        // Style inherited from ThemeConfig
      ),
      body: recommendations.isEmpty
          ? Center(
              child: Text(
                AppStrings.noMatchesFound,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSizes.p16),
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

  Future<void> _fetchLatestMeasurement() async {
    try {
      final measurement = await MeasurementService.getLatestUserMeasurement();
      if (!mounted) return;
      setState(() {
        if (measurement == null) {
          _errorMessage = AppStrings.errorNoMeasurement;
        } else {
          _latestMeasurement = measurement;
        }
        _isLoadingMeasurement = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppStrings.errorFetchMeasurement;
          _isLoadingMeasurement = false;
        });
      }
    }
  }

  Future<void> _placeOrder(String measurementId) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User is not authenticated.');
    await supabase.from('orders').insert({'user_id': user.id, 'curtain_id': widget.curtain.id, 'measurement_id': measurementId});
    await UserInteractionService.trackOrder(widget.curtain.id);
  }

  void _navigateToMeasurementGuide() {
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MeasurementMethodSelectionScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.p20)),
      title: const Text(AppStrings.confirmOrderTitle, style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.p8),
                child: Image.network(widget.curtain.imageUrl, width: AppSizes.p60, height: AppSizes.p60, fit: BoxFit.cover),
              ),
              gapW12,
              Expanded(child: Text(widget.curtain.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
            ],
          ),
          const Divider(height: AppSizes.p30),
          _buildMeasurementContent(),
        ],
      )),
      actions: _buildActions(),
    );
  }

  Widget _buildMeasurementContent() {
    final theme = Theme.of(context);
    if (_isLoadingMeasurement) {
      return const SizedBox(
        height: 100,
        child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(), gapH16, Text(AppStrings.fetchingMeasurement)],
        )),
      );
    }
    if (_errorMessage != null) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
        gapH16,
        Text(_errorMessage!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54)),
      ]);
    }
    if (_latestMeasurement != null) {
      final width = _latestMeasurement!['window_width'];
      final height = _latestMeasurement!['window_height'];
      final unit = MeasurementUnit.values.firstWhere((e) => e.name == _latestMeasurement!['unit'], orElse: () => MeasurementUnit.meters);
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppStrings.usingLatestMeasurement, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54)),
        gapH12,
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppSizes.p12),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildMeasurementDisplay(AppStrings.labelWidth, width, unit),
            _buildMeasurementDisplay(AppStrings.labelHeight, height, unit),
          ]),
        ),
      ]);
    }
    return const SizedBox.shrink();
  }

  List<Widget> _buildActions() {
    final theme = Theme.of(context);
    if (_errorMessage != null) {
      return [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(AppStrings.buttonCancel)),
        ElevatedButton(onPressed: _navigateToMeasurementGuide, child: const Text(AppStrings.buttonAddMeasurement)),
      ];
    }
    return [
      TextButton(onPressed: _isPlacingOrder ? null : () => Navigator.of(context).pop(), child: const Text(AppStrings.buttonCancel)),
      ElevatedButton(
        onPressed: (_isPlacingOrder || _latestMeasurement == null) ? null : () async {
          setState(() => _isPlacingOrder = true);
          try {
            await _placeOrder(_latestMeasurement!['id']);
            if (!mounted) return;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text(AppStrings.orderPlacedSuccess), backgroundColor: Colors.green));
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppStrings.errorPlacingOrder}$e'), backgroundColor: theme.colorScheme.error));
          } finally {
            if (mounted) setState(() => _isPlacingOrder = false);
          }
        },
        child: _isPlacingOrder
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text(AppStrings.buttonPlaceOrder),
      ),
    ];
  }

  Widget _buildMeasurementDisplay(String label, double value, MeasurementUnit unit) {
    final theme = Theme.of(context);
    return Column(children: [
      Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54)),
      gapH4,
      Text(
        MeasurementUtils.formatWithUnit(value, unit),
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
      ),
    ]);
  }
}

class _RecommendationCard extends StatelessWidget {
  final ScoredRecommendation recommendation;
  final VoidCallback onFindSimilar;
  final VoidCallback onOrder;

  const _RecommendationCard({required this.recommendation, required this.onFindSimilar, required this.onOrder});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserInteractionService.trackView(recommendation.curtain.id);
    });

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final curtain = recommendation.curtain;
    final displayScore = recommendation.displayScore;

    return Container(
      height: 300,
      margin: const EdgeInsets.only(bottom: AppSizes.p20),
      child: Stack(children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.p20),
            child: Image.network(
              curtain.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.p20),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.4), Colors.transparent, Colors.transparent, Colors.black.withOpacity(0.8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.3, 0.6, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: AppSizes.p16, left: AppSizes.p16, right: AppSizes.p16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, Color.lerp(primaryColor, Colors.black, 0.2)!], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(AppSizes.p20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(1, 2))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 18),
                  gapW8,
                  Text(
                    '$displayScore${AppStrings.matchSuffix}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5, shadows: [Shadow(blurRadius: 2)]),
                  ),
                ]),
              ),
              SizedBox(
                width: 80,
                child: OutlinedButton(
                  onPressed: onFindSimilar,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black.withOpacity(0.3),
                    side: const BorderSide(color: Colors.white70),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
                  ),
                  child: const Text(AppStrings.buttonSimilar, style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: AppSizes.p16, left: AppSizes.p16, right: AppSizes.p16,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(
                curtain.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2)]),
              ),
              gapH8,
              Wrap(spacing: AppSizes.p8, runSpacing: AppSizes.p4, children: [
                _buildInfoChip(curtain.material),
                _buildInfoChip(curtain.designPattern),
              ]),
            ])),
            gapW12,
            SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: onOrder,
                child: const Text(AppStrings.buttonOrderNow, style: TextStyle(fontSize: 12), textAlign: TextAlign.center),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p10, vertical: AppSizes.p5),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(AppSizes.p8)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}
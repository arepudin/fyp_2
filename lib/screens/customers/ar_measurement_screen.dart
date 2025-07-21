import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../../services/ar_measurement_service.dart';
import '../../utils/measurement_utils.dart';
import 'measurement_guide_screen.dart';

class ARMeasurementScreen extends StatefulWidget {
  final Function(double width, double height)? onMeasurementsCompleted;

  const ARMeasurementScreen({
    super.key,
    this.onMeasurementsCompleted,
  });

  @override
  State<ARMeasurementScreen> createState() => _ARMeasurementScreenState();
}

class _ARMeasurementScreenState extends State<ARMeasurementScreen> {
  ArCoreController? _arCoreController;
  ARMeasurementService? _measurementService;
  bool _isLoading = true;
  String? _errorMessage;
  List<ARPoint> _placedPoints = [];
  WindowMeasurement? _currentMeasurement;
  bool _showInstructions = true;

  static const Color primaryRed = Color.fromARGB(255, 158, 19, 17);

  @override
  void initState() {
    super.initState();
    _checkARCapabilities();
  }

  @override
  void dispose() {
    _measurementService?.dispose();
    _arCoreController?.dispose();
    super.dispose();
  }

  Future<void> _checkARCapabilities() async {
    try {
      final arInfo = await ARCapabilityInfo.check();
      
      if (!arInfo.isAvailable) {
        setState(() {
          _errorMessage = arInfo.errorMessage;
          _isLoading = false;
        });
        return;
      }

      await _initializeAR();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize AR: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeAR() async {
    try {
      _measurementService = ARMeasurementService();
      
      // Listen to measurement updates
      _measurementService!.pointsStream.listen((points) {
        setState(() => _placedPoints = points);
      });
      
      _measurementService!.measurementStream.listen((measurement) {
        setState(() => _currentMeasurement = measurement);
      });

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize AR: $e';
        _isLoading = false;
      });
    }
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    _arCoreController = controller;
    _measurementService?.initialize(controller);
    
    controller.onPlaneTap = _onPlaneTapped;
  }

  void _onPlaneTapped(List<ArCoreHitTestResult> hits) {
    if (hits.isNotEmpty && _placedPoints.length < 4) {
      final hit = hits.first;
      _measurementService?.placePoint(vector.Vector2(0, 0)); // Simplified for demo
    }
  }

  void _switchUnit() {
    _measurementService?.switchUnit();
  }

  void _clearMeasurement() {
    _measurementService?.clearPoints();
    setState(() {
      _currentMeasurement = null;
      _showInstructions = true;
    });
  }

  void _completeMeasurement() {
    if (_currentMeasurement != null) {
      final validation = _measurementService?.validateMeasurement(_currentMeasurement!);
      
      if (validation != null) {
        _showValidationDialog(validation);
        return;
      }

      final storageData = _currentMeasurement!.toStorageFormat();
      widget.onMeasurementsCompleted?.call(
        storageData['window_width']!,
        storageData['window_height']!,
      );
      Navigator.pop(context);
    }
  }

  void _showValidationDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Measurement Warning'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Review'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completeMeasurement();
            },
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  void _switchToManualGuide() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MeasurementGuideScreen(
          onMeasurementsEntered: widget.onMeasurementsCompleted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // AR Camera View
          _buildARView(),
          
          // Instructions overlay
          if (_showInstructions) _buildInstructionsOverlay(),
          
          // Top controls
          _buildTopControls(),
          
          // Bottom controls
          _buildBottomControls(),
          
          // Measurement display
          if (_currentMeasurement != null) _buildMeasurementDisplay(),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: primaryRed),
            const SizedBox(height: 20),
            const Text(
              'Initializing AR Camera...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('AR Measurement'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: primaryRed,
            ),
            const SizedBox(height: 20),
            const Text(
              'AR Not Available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'AR functionality is not available on this device.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _switchToManualGuide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Use Manual Measurement Guide',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryRed),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildARView() {
    return ArCoreView(
      onArCoreViewCreated: _onArCoreViewCreated,
      enableTapRecognizer: true,
    );
  }

  Widget _buildInstructionsOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.straighten,
                size: 48,
                color: primaryRed,
              ),
              const SizedBox(height: 16),
              const Text(
                'AR Window Measurement',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Follow these steps to measure your window:',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ...[
                '1. Point your camera at the window',
                '2. Tap to place the bottom-left corner',
                '3. Tap to place the bottom-right corner',
                '4. Tap to place the top-right corner',
                '5. Tap to place the top-left corner',
              ].map((instruction) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        instruction,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _switchToManualGuide,
                      child: const Text('Use Manual Guide'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _showInstructions = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Start'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
            const Spacer(),
            IconButton(
              onPressed: _switchUnit,
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _measurementService?.currentUnit == MeasurementUnit.meters ? 'M' : 'IN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Points counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Points: ${_placedPoints.length}/4',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              
              // Clear button
              if (_placedPoints.isNotEmpty)
                IconButton(
                  onPressed: _clearMeasurement,
                  icon: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.clear,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              
              const SizedBox(width: 16),
              
              // Complete button
              if (_currentMeasurement != null)
                ElevatedButton(
                  onPressed: _completeMeasurement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Complete',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementDisplay() {
    if (_currentMeasurement == null) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Measurements',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Width',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        MeasurementUtils.formatWithUnit(
                          _currentMeasurement!.width,
                          _currentMeasurement!.unit,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Height',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        MeasurementUtils.formatWithUnit(
                          _currentMeasurement!.height,
                          _currentMeasurement!.unit,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Accuracy: ±${(_measurementService?.getMeasurementAccuracy() ?? 0.01 * 100).toStringAsFixed(0)}cm',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
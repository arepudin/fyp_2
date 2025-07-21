import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import '../../models/measurement_result.dart';
import '../../utils/ar_utils.dart';
import 'measurement_guide_screen.dart';

class ARMeasurementScreen extends StatefulWidget {
  const ARMeasurementScreen({super.key});

  @override
  State<ARMeasurementScreen> createState() => _ARMeasurementScreenState();
}

class _ARMeasurementScreenState extends State<ARMeasurementScreen> {
  ArCoreController? _arCoreController;
  List<Point3D> _placedPoints = [];
  MeasurementUnit _selectedUnit = MeasurementUnit.meters;
  MeasurementResult? _currentMeasurement;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isARSupported = false;

  static const Color primaryRed = Color.fromARGB(255, 158, 19, 17);

  @override
  void initState() {
    super.initState();
    _checkARSupport();
  }

  @override
  void dispose() {
    _arCoreController?.dispose();
    super.dispose();
  }

  Future<void> _checkARSupport() async {
    try {
      // Check camera permission
      final hasPermission = await ARUtils.requestCameraPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Camera permission is required for AR measurement';
          _isLoading = false;
        });
        return;
      }

      // Check AR support
      final isSupported = await ARUtils.isARCoreSupported();
      if (!isSupported) {
        setState(() {
          _errorMessage = 'AR is not supported on this device';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isARSupported = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ARUtils.getARErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    _arCoreController = controller;
    controller.onPlaneDetected = _onPlaneDetected;
    controller.onPlaneTap = _onPlaneTapped;
  }

  void _onPlaneDetected(ArCorePlane plane) {
    // Plane detected - we can start placing points
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Surface detected! Tap to place measurement points.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onPlaneTapped(List<ArCoreHitTestResult> hits) {
    if (hits.isNotEmpty && _placedPoints.length < 4) {
      final hit = hits.first;
      final point = ARUtils.arCorePositionToPoint3D(hit.pose.translation);
      
      setState(() {
        _placedPoints.add(point);
        
        // Add visual marker at the tapped position
        _addMarker(hit.pose);
        
        // Calculate measurement if we have 4 points
        if (_placedPoints.length == 4) {
          _calculateMeasurement();
        }
      });
    }
  }

  void _addMarker(ArCorePose pose) {
    final material = ArCoreMaterial(
      color: primaryRed,
    );

    final sphere = ArCoreSphere(
      materials: [material],
      radius: 0.02, // 2cm sphere
    );

    final node = ArCoreNode(
      shape: sphere,
      position: pose.translation,
    );

    _arCoreController?.addArCoreNode(node);
  }

  void _calculateMeasurement() {
    try {
      final measurement = ARUtils.calculateOptimalMeasurement(
        _placedPoints,
        unit: _selectedUnit,
      );

      if (ARUtils.isMeasurementQualityGood(measurement)) {
        setState(() {
          _currentMeasurement = measurement;
        });
        _showMeasurementResult();
      } else {
        _showMeasurementError('Measurement quality is poor. Please try again with better point placement.');
      }
    } catch (e) {
      _showMeasurementError('Failed to calculate measurement: ${e.toString()}');
    }
  }

  void _showMeasurementResult() {
    if (_currentMeasurement == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Measurement Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Width: ${_currentMeasurement!.formattedWidth}'),
              Text('Height: ${_currentMeasurement!.formattedHeight}'),
              Text('Area: ${_currentMeasurement!.formattedArea}'),
              const SizedBox(height: 16),
              const Text(
                'These measurements will be used for your curtain order.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetMeasurement();
              },
              child: const Text('Measure Again'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(_currentMeasurement);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Use This Measurement'),
            ),
          ],
        );
      },
    );
  }

  void _showMeasurementError(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Measurement Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetMeasurement();
              },
              child: const Text('Try Again'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fallbackToManualGuide();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Use Manual Guide'),
            ),
          ],
        );
      },
    );
  }

  void _resetMeasurement() {
    setState(() {
      _placedPoints.clear();
      _currentMeasurement = null;
    });
    
    // Remove all nodes from AR scene
    _arCoreController?.removeAllNodes();
  }

  void _fallbackToManualGuide() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MeasurementGuideScreen(),
      ),
    );
  }

  void _switchUnit() {
    setState(() {
      _selectedUnit = _selectedUnit == MeasurementUnit.meters 
          ? MeasurementUnit.inches 
          : MeasurementUnit.meters;
      
      // Recalculate if we have a measurement
      if (_currentMeasurement != null) {
        _currentMeasurement = _currentMeasurement!.copyWithUnit(_selectedUnit);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryRed),
              SizedBox(height: 16),
              Text(
                'Initializing AR...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || !_isARSupported) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('AR Measurement'),
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: primaryRed,
                ),
                const SizedBox(height: 24),
                Text(
                  _errorMessage ?? 'AR not supported',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _fallbackToManualGuide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Use Manual Measurement Guide'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // AR View
          ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated,
            enableTapRecognizer: true,
          ),

          // Top overlay with instructions
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(153),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Point ${_placedPoints.length + 1} of 4',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getInstructionText(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Bottom overlay with controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(153),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Unit switcher
                    ElevatedButton(
                      onPressed: _switchUnit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha(51),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_selectedUnit == MeasurementUnit.meters ? 'Meters' : 'Inches'),
                    ),

                    // Reset button
                    ElevatedButton(
                      onPressed: _placedPoints.isNotEmpty ? _resetMeasurement : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha(51),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reset'),
                    ),

                    // Manual guide button
                    ElevatedButton(
                      onPressed: _fallbackToManualGuide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Manual Guide'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Progress indicator
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: index < _placedPoints.length ? primaryRed : Colors.white.withAlpha(102),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInstructionText() {
    switch (_placedPoints.length) {
      case 0:
        return 'Tap on the top-left corner of your window';
      case 1:
        return 'Tap on the top-right corner of your window';
      case 2:
        return 'Tap on the bottom-right corner of your window';
      case 3:
        return 'Tap on the bottom-left corner of your window';
      default:
        return 'Calculating measurement...';
    }
  }
}
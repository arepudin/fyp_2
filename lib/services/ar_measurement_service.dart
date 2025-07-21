import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import '../utils/measurement_utils.dart';

class ARPoint {
  final vector.Vector3 position;
  final DateTime timestamp;
  final String id;

  ARPoint({
    required this.position,
    required this.timestamp,
    required this.id,
  });
}

class WindowMeasurement {
  final double width;
  final double height;
  final MeasurementUnit unit;
  final List<ARPoint> corners;
  final DateTime timestamp;

  WindowMeasurement({
    required this.width,
    required this.height,
    required this.unit,
    required this.corners,
    required this.timestamp,
  });

  /// Convert measurements to storage format (centimeters)
  Map<String, double> toStorageFormat() {
    return {
      'window_width': MeasurementUtils.toStorageUnit(width, unit),
      'window_height': MeasurementUtils.toStorageUnit(height, unit),
    };
  }
}

class ARMeasurementService {
  late ArCoreController _arCoreController;
  final List<ARPoint> _placedPoints = [];
  final StreamController<List<ARPoint>> _pointsController = StreamController<List<ARPoint>>.broadcast();
  final StreamController<WindowMeasurement?> _measurementController = StreamController<WindowMeasurement?>.broadcast();
  
  MeasurementUnit _currentUnit = MeasurementUnit.meters;
  bool _isInitialized = false;

  // Streams
  Stream<List<ARPoint>> get pointsStream => _pointsController.stream;
  Stream<WindowMeasurement?> get measurementStream => _measurementController.stream;

  // Getters
  List<ARPoint> get placedPoints => List.unmodifiable(_placedPoints);
  MeasurementUnit get currentUnit => _currentUnit;
  bool get isInitialized => _isInitialized;
  bool get canMeasure => _placedPoints.length >= 4;

  /// Initialize AR session
  Future<bool> initialize(ArCoreController controller) async {
    try {
      _arCoreController = controller;
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Failed to initialize AR: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Check if ARCore is available on device
  static Future<bool> isARCoreAvailable() async {
    try {
      return await ArCoreController.checkArCoreAvailability();
    } catch (e) {
      print('ARCore availability check failed: $e');
      return false;
    }
  }

  /// Check if ARCore is installed
  static Future<bool> isARCoreInstalled() async {
    try {
      return await ArCoreController.checkIsArCoreInstalled();
    } catch (e) {
      print('ARCore installation check failed: $e');
      return false;
    }
  }

  /// Place a point in AR space
  Future<void> placePoint(vector.Vector2 screenPosition) async {
    if (!_isInitialized || _placedPoints.length >= 4) return;

    try {
      // Perform hit test to get 3D position
      final hitTestResults = await _arCoreController.onNodeTap;
      
      if (hitTestResults.isNotEmpty) {
        final hit = hitTestResults.first;
        final position = vector.Vector3(
          hit.pose.translation.x,
          hit.pose.translation.y,
          hit.pose.translation.z,
        );

        final point = ARPoint(
          position: position,
          timestamp: DateTime.now(),
          id: 'point_${_placedPoints.length}',
        );

        _placedPoints.add(point);
        _addVisualMarker(point);
        _pointsController.add(List.from(_placedPoints));

        // Calculate measurement if we have enough points
        if (_placedPoints.length >= 4) {
          _calculateMeasurement();
        }
      }
    } catch (e) {
      print('Failed to place point: $e');
    }
  }

  /// Add visual marker in AR scene
  void _addVisualMarker(ARPoint point) {
    final node = ArCoreNode(
      shape: ArCoreSphere(
        radius: 0.02, // 2cm sphere
        materials: [
          ArCoreMaterial(
            color: _placedPoints.length < 4 ? const Color(0xFFFF0000) : const Color(0xFF00FF00),
            metallic: 0.0,
          ),
        ],
      ),
      position: vector.Vector3(
        point.position.x,
        point.position.y,
        point.position.z,
      ),
    );

    _arCoreController.addArCoreNode(node);
  }

  /// Calculate window measurements from placed points
  void _calculateMeasurement() {
    if (_placedPoints.length < 4) return;

    try {
      // Assume points are placed in order: bottom-left, bottom-right, top-right, top-left
      final bottomLeft = _placedPoints[0].position;
      final bottomRight = _placedPoints[1].position;
      final topRight = _placedPoints[2].position;
      final topLeft = _placedPoints[3].position;

      // Calculate width (bottom edge)
      final widthMeters = (bottomRight - bottomLeft).length;
      
      // Calculate height (left edge)
      final heightMeters = (topLeft - bottomLeft).length;

      // Convert to current unit
      final width = _currentUnit == MeasurementUnit.meters 
          ? widthMeters 
          : MeasurementUtils.metersToInchesConversion(widthMeters);
      
      final height = _currentUnit == MeasurementUnit.meters 
          ? heightMeters 
          : MeasurementUtils.metersToInchesConversion(heightMeters);

      final measurement = WindowMeasurement(
        width: MeasurementUtils.roundForDisplay(width, _currentUnit),
        height: MeasurementUtils.roundForDisplay(height, _currentUnit),
        unit: _currentUnit,
        corners: List.from(_placedPoints),
        timestamp: DateTime.now(),
      );

      _measurementController.add(measurement);
    } catch (e) {
      print('Failed to calculate measurement: $e');
      _measurementController.add(null);
    }
  }

  /// Switch measurement unit
  void switchUnit() {
    _currentUnit = _currentUnit == MeasurementUnit.meters 
        ? MeasurementUnit.inches 
        : MeasurementUnit.meters;
    
    // Recalculate if we have a measurement
    if (_placedPoints.length >= 4) {
      _calculateMeasurement();
    }
  }

  /// Clear all placed points
  void clearPoints() {
    _placedPoints.clear();
    _pointsController.add([]);
    _measurementController.add(null);
    
    // Clear AR scene (this would need to be implemented based on AR plugin capabilities)
    _clearARScene();
  }

  /// Clear AR scene markers
  void _clearARScene() {
    // Implementation depends on ARCore plugin capabilities
    // This is a placeholder for clearing visual markers
    try {
      // _arCoreController.removeAllNodes(); // If available
    } catch (e) {
      print('Failed to clear AR scene: $e');
    }
  }

  /// Get measurement accuracy estimate
  double getMeasurementAccuracy() {
    if (_placedPoints.length < 4) return 0.0;

    // Calculate based on distance from camera and point placement precision
    // This is a simplified estimate
    double totalDistance = 0.0;
    for (final point in _placedPoints) {
      totalDistance += point.position.length; // Distance from origin (camera)
    }
    
    double averageDistance = totalDistance / _placedPoints.length;
    
    // Accuracy decreases with distance
    // At 1m: ±1cm, at 3m: ±3cm, etc.
    return averageDistance * 0.01; // 1cm per meter
  }

  /// Validate measurement quality
  String? validateMeasurement(WindowMeasurement measurement) {
    // Check if measurements are realistic
    if (!MeasurementUtils.isRealisticWindowMeasurement(
        measurement.width, measurement.height, measurement.unit)) {
      return 'Measurements seem unrealistic for a window. Please try again.';
    }

    // Check measurement accuracy
    final accuracy = getMeasurementAccuracy();
    if (accuracy > 0.05) { // More than 5cm error
      return 'Measurement accuracy may be low due to distance. Try moving closer to the window.';
    }

    // Check for other potential issues
    return MeasurementUtils.getMeasurementWarning(
        measurement.width, measurement.height, measurement.unit);
  }

  /// Dispose resources
  void dispose() {
    _pointsController.close();
    _measurementController.close();
    _placedPoints.clear();
    _isInitialized = false;
  }
}

/// AR Capability Information
class ARCapabilityInfo {
  final bool isSupported;
  final bool isInstalled;
  final String? errorMessage;
  final List<String> requirements;

  ARCapabilityInfo({
    required this.isSupported,
    required this.isInstalled,
    this.errorMessage,
    this.requirements = const [],
  });

  bool get isAvailable => isSupported && isInstalled;

  static Future<ARCapabilityInfo> check() async {
    try {
      final isSupported = await ARMeasurementService.isARCoreAvailable();
      final isInstalled = await ARMeasurementService.isARCoreInstalled();
      
      List<String> requirements = [];
      String? errorMessage;

      if (!isSupported) {
        errorMessage = 'ARCore is not supported on this device';
        requirements.add('Android device with ARCore support');
        requirements.add('Android 7.0 (API level 24) or higher');
      } else if (!isInstalled) {
        errorMessage = 'ARCore is not installed';
        requirements.add('Install ARCore from Google Play Store');
      }

      return ARCapabilityInfo(
        isSupported: isSupported,
        isInstalled: isInstalled,
        errorMessage: errorMessage,
        requirements: requirements,
      );
    } catch (e) {
      return ARCapabilityInfo(
        isSupported: false,
        isInstalled: false,
        errorMessage: 'Failed to check AR capabilities: $e',
        requirements: ['Check device compatibility'],
      );
    }
  }
}
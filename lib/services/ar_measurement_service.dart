import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': [position.x, position.y, position.z],
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ARPoint.fromJson(Map<String, dynamic> json) {
    final pos = json['position'] as List;
    return ARPoint(
      id: json['id'],
      position: vector.Vector3(pos[0], pos[1], pos[2]),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
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
  static const String _unityChannel = 'unity_ar_measurement';
  static const MethodChannel _methodChannel = MethodChannel(_unityChannel);

  UnityWidgetController? _unityController;
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

  /// Initialize Unity AR session
  Future<bool> initialize(UnityWidgetController controller) async {
    try {
      _unityController = controller;
      
      // Set up method channel for Unity communication
      _methodChannel.setMethodCallHandler(_handleUnityMessage);
      
      // Initialize Unity AR scene
      await _sendToUnity('InitializeAR', {
        'planeDetection': true,
        'pointCloud': true,
        'lightEstimation': true,
      });
      
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Failed to initialize Unity AR: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Handle messages from Unity
  Future<void> _handleUnityMessage(MethodCall call) async {
    switch (call.method) {
      case 'onPointPlaced':
        _handlePointPlaced(call.arguments);
        break;
      case 'onARError':
        _handleARError(call.arguments);
        break;
      case 'onPlaneDetected':
        _handlePlaneDetected(call.arguments);
        break;
      default:
        print('Unknown Unity message: ${call.method}');
    }
  }

  /// Handle point placement from Unity
  void _handlePointPlaced(Map<String, dynamic> data) {
    try {
      final point = ARPoint.fromJson(data);
      _placedPoints.add(point);
      _pointsController.add(List.from(_placedPoints));

      // Calculate measurement if we have enough points
      if (_placedPoints.length >= 4) {
        _calculateMeasurement();
      }
    } catch (e) {
      print('Failed to handle point placement: $e');
    }
  }

  /// Handle AR errors from Unity
  void _handleARError(Map<String, dynamic> data) {
    print('Unity AR Error: ${data['message']}');
    // Could emit error events here if needed
  }

  /// Handle plane detection from Unity
  void _handlePlaneDetected(Map<String, dynamic> data) {
    // Plane detection events could be used for UI feedback
    print('Plane detected in Unity');
  }

  /// Send command to Unity
  Future<void> _sendToUnity(String command, Map<String, dynamic> data) async {
    try {
      if (_unityController != null) {
        final message = {
          'command': command,
          'data': data,
        };
        await _methodChannel.invokeMethod('sendToUnity', message);
      }
    } catch (e) {
      print('Failed to send command to Unity: $e');
    }
  }

  /// Check if Unity AR is available on device
  static Future<bool> isUnityARAvailable() async {
    try {
      final result = await _methodChannel.invokeMethod('checkARSupport');
      return result['isSupported'] ?? false;
    } catch (e) {
      print('Unity AR availability check failed: $e');
      return false;
    }
  }

  /// Place a point in AR space (triggered by screen tap)
  Future<void> placePoint(vector.Vector2 screenPosition) async {
    if (!_isInitialized || _placedPoints.length >= 4) return;

    try {
      await _sendToUnity('PlacePoint', {
        'screenX': screenPosition.x,
        'screenY': screenPosition.y,
        'pointIndex': _placedPoints.length,
      });
    } catch (e) {
      print('Failed to place point: $e');
    }
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
    
    // Update Unity with new unit
    _sendToUnity('SetUnit', {
      'unit': _currentUnit == MeasurementUnit.meters ? 'meters' : 'inches'
    });
    
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
    
    // Clear Unity AR scene
    _sendToUnity('ClearPoints', {});
  }

  /// Get measurement accuracy estimate
  double getMeasurementAccuracy() {
    if (_placedPoints.length < 4) return 0.0;

    // Calculate based on distance from camera and point placement precision
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
    _unityController = null;
  }
}

/// AR Capability Information for Unity
class ARCapabilityInfo {
  final bool isSupported;
  final bool isUnityAvailable;
  final String? errorMessage;
  final List<String> requirements;

  ARCapabilityInfo({
    required this.isSupported,
    required this.isUnityAvailable,
    this.errorMessage,
    this.requirements = const [],
  });

  bool get isAvailable => isSupported && isUnityAvailable;

  static Future<ARCapabilityInfo> check() async {
    try {
      final isSupported = await ARMeasurementService.isUnityARAvailable();
      
      List<String> requirements = [];
      String? errorMessage;

      if (!isSupported) {
        errorMessage = 'AR is not supported on this device';
        requirements.addAll([
          'Android device with ARCore support or iOS device with ARKit',
          'Android 7.0 (API level 24) or iOS 11.0 or higher',
          'Unity AR Foundation compatibility',
        ]);
      }

      return ARCapabilityInfo(
        isSupported: isSupported,
        isUnityAvailable: isSupported, // Unity availability tied to AR support
        errorMessage: errorMessage,
        requirements: requirements,
      );
    } catch (e) {
      return ARCapabilityInfo(
        isSupported: false,
        isUnityAvailable: false,
        errorMessage: 'Failed to check AR capabilities: $e',
        requirements: ['Check device compatibility'],
      );
    }
  }
}
import 'dart:io';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/measurement_result.dart';

class ARUtils {
  // Check if device supports ARCore
  static Future<bool> isARCoreSupported() async {
    try {
      if (!Platform.isAndroid) {
        return false;
      }
      
      // Check if ARCore is available on this device
      final isSupported = await ArCoreController.checkArCoreAvailability();
      return isSupported == ArCoreAvailability.supported_installed ||
             isSupported == ArCoreAvailability.supported_not_installed;
    } catch (e) {
      return false;
    }
  }

  // Check and request camera permission
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        final result = await Permission.camera.request();
        return result.isGranted;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Check Android version (ARCore requires Android 7.0+, but we want Android 12+ for better performance)
  static bool isAndroidVersionSupported() {
    if (!Platform.isAndroid) {
      return false;
    }
    
    // This is a simplified check - in a real app you'd want to check the actual Android API level
    // For this implementation, we'll assume the device meets the requirements
    return true;
  }

  // Convert ArCore position to our Point3D
  static Point3D arCorePositionToPoint3D(dynamic position) {
    if (position == null) {
      return const Point3D(0, 0, 0);
    }
    
    // ArCore positions are typically Vector3 objects with x, y, z properties
    return Point3D(
      position.x?.toDouble() ?? 0.0,
      position.y?.toDouble() ?? 0.0,
      position.z?.toDouble() ?? 0.0,
    );
  }

  // Validate that points form a reasonable rectangle
  static bool validateWindowCorners(List<Point3D> corners) {
    if (corners.length != 4) {
      return false;
    }

    // Calculate all distances between consecutive corners
    List<double> distances = [];
    for (int i = 0; i < corners.length; i++) {
      int nextIndex = (i + 1) % corners.length;
      distances.add(MeasurementResult.distance3D(corners[i], corners[nextIndex]));
    }

    // Check if opposite sides are approximately equal (within 10% tolerance)
    double tolerance = 0.1;
    bool widthsMatch = (distances[0] - distances[2]).abs() / distances[0] < tolerance;
    bool heightsMatch = (distances[1] - distances[3]).abs() / distances[1] < tolerance;

    return widthsMatch && heightsMatch;
  }

  // Calculate the best-fit rectangle from 4 points
  static MeasurementResult calculateOptimalMeasurement(
    List<Point3D> rawCorners, {
    MeasurementUnit unit = MeasurementUnit.meters,
  }) {
    if (rawCorners.length != 4) {
      throw ArgumentError('Exactly 4 corner points are required');
    }

    // For simplicity, we'll use the raw corners directly
    // In a production app, you might want to apply smoothing or fitting algorithms
    List<Point3D> optimizedCorners = List.from(rawCorners);

    // Calculate average width and height for more accurate measurements
    double width1 = MeasurementResult.distance3D(optimizedCorners[0], optimizedCorners[1]);
    double width2 = MeasurementResult.distance3D(optimizedCorners[3], optimizedCorners[2]);
    double height1 = MeasurementResult.distance3D(optimizedCorners[0], optimizedCorners[3]);
    double height2 = MeasurementResult.distance3D(optimizedCorners[1], optimizedCorners[2]);

    double avgWidth = (width1 + width2) / 2;
    double avgHeight = (height1 + height2) / 2;

    return MeasurementResult(
      windowCorners: optimizedCorners,
      widthInMeters: avgWidth,
      heightInMeters: avgHeight,
      timestamp: DateTime.now(),
      preferredUnit: unit,
    );
  }

  // Get user-friendly error messages
  static String getARErrorMessage(dynamic error) {
    if (error == null) {
      return 'Unknown AR error occurred';
    }

    String errorStr = error.toString().toLowerCase();

    if (errorStr.contains('permission')) {
      return 'Camera permission is required for AR measurement';
    } else if (errorStr.contains('arcore') || errorStr.contains('unsupported')) {
      return 'AR is not supported on this device. Please use the manual measurement guide instead.';
    } else if (errorStr.contains('camera')) {
      return 'Camera access failed. Please check your camera settings.';
    } else if (errorStr.contains('tracking')) {
      return 'AR tracking lost. Please ensure good lighting and move slowly.';
    } else {
      return 'AR measurement failed. Please try again or use the manual measurement guide.';
    }
  }

  // Check if measurement result meets quality criteria
  static bool isMeasurementQualityGood(MeasurementResult result) {
    if (!result.isValid || !result.isReasonableSize) {
      return false;
    }

    // Check if the window corners form a reasonable shape
    if (!validateWindowCorners(result.windowCorners)) {
      return false;
    }

    // Check for minimum size (30cm x 30cm)
    if (result.widthInMeters < 0.3 || result.heightInMeters < 0.3) {
      return false;
    }

    // Check for maximum reasonable size (5m x 4m)
    if (result.widthInMeters > 5.0 || result.heightInMeters > 4.0) {
      return false;
    }

    return true;
  }

  // Get recommendations based on measurement quality
  static List<String> getMeasurementTips() {
    return [
      'Ensure good lighting for better AR tracking',
      'Move slowly when placing points',
      'Keep the device steady while measuring',
      'Place points at the exact window corners',
      'Make sure the entire window is visible in the camera view',
      'Avoid reflective surfaces that might interfere with AR',
    ];
  }
}
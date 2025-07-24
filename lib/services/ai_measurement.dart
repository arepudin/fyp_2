import 'dart:math';
import 'dart:ui'; // For Flutter's Rect class

import 'package:opencv_dart/opencv_dart.dart' as cv;
import '../utils/measurement_utils.dart'; // Import for MeasurementUnit and utils

// This enum and class remain the same.
enum ReferenceObject {
  a4Paper,
  creditCard,
}

class ReferenceObjectInfo {
  final double width;
  final double height;
  final String displayName;
  final String instructions;

  const ReferenceObjectInfo({
    required this.width,
    required this.height,
    required this.displayName,
    required this.instructions,
  });
}

class AIMeasurementService {
  // This map of reference object data remains the same.
  static const Map<ReferenceObject, ReferenceObjectInfo> _referenceObjects = {
    ReferenceObject.a4Paper: ReferenceObjectInfo(
      width: 21.0,
      height: 29.7,
      displayName: 'A4 Paper',
      instructions: 'Place an A4 paper flat against the wall next to your window',
    ),
    ReferenceObject.creditCard: ReferenceObjectInfo(
      width: 8.56,
      height: 5.398,
      displayName: 'Credit Card',
      instructions: 'Place a credit card flat against the wall next to your window',
    ),
  };

  /// This getter method remains the same.
  static ReferenceObjectInfo getReferenceInfo(ReferenceObject object) {
    return _referenceObjects[object]!;
  }

  // =======================================================================
  // ===             CORRECTED OpenCV-BASED DETECTION METHOD             ===
  // =======================================================================
  static Future<List<Rect>> detectRectangles(String imagePath) async {
    final image = cv.imread(imagePath);
    if (image.isEmpty) {
      print('Error: Could not read image at path: $imagePath');
      return [];
    }

    List<Rect> foundRectangles = [];

    cv.Mat? gray, blurred, edges;
    // The type of contours is a record containing the contours and hierarchy
    (cv.Contours, cv.VecVec4i)? contoursRecord;
    try {
      gray = cv.cvtColor(image, cv.COLOR_BGR2GRAY);
      blurred = cv.gaussianBlur(gray, (5, 5), 0);
      edges = cv.canny(blurred, 50, 150);

      // Store the record returned by findContours
      contoursRecord = cv.findContours(edges, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);

      // Iterate over the first element of the record (contoursRecord.$1)
      for (final contour in contoursRecord.$1) {
        final peri = cv.arcLength(contour, true);
        final approx = cv.approxPolyDP(contour, 0.02 * peri, true);

        // Use .length instead of .rows for VecPoint
        if (approx.length == 4) {
          final area = cv.contourArea(approx);
          if (area > 1000) {
            final rect = cv.boundingRect(contour);
            foundRectangles.add(
              Rect.fromLTWH(
                rect.x.toDouble(),
                rect.y.toDouble(),
                rect.width.toDouble(),
                rect.height.toDouble(),
              ),
            );
          }
        }
        approx.dispose();
      }
      
      return foundRectangles;
    } catch (e) {
      print('Error during OpenCV processing: $e');
      return [];
    } finally {
      image.dispose();
      gray?.dispose();
      blurred?.dispose();
      edges?.dispose();

      // Dispose of the elements within the record, not the record itself
      if (contoursRecord != null) {
        contoursRecord.$1.dispose(); // Dispose the Vec<Mat> of contours
        contoursRecord.$2.dispose(); // Dispose the VecVec4i of hierarchy
      }
    }
  }

  // --- The following helper methods are updated or added ---

  static double calculatePixelToCmRatio(Rect referenceRect, ReferenceObject objectType) {
    final referenceInfo = getReferenceInfo(objectType);
    final rectWidth = referenceRect.width;
    final rectHeight = referenceRect.height;
    final isLandscape = rectWidth > rectHeight;
    double pixelSize, realSize;
    if (isLandscape) {
      pixelSize = rectWidth;
      realSize = max(referenceInfo.width, referenceInfo.height);
    } else {
      pixelSize = rectHeight;
      realSize = max(referenceInfo.width, referenceInfo.height);
    }
    return realSize / pixelSize;
  }

  // Update the return to be in meters instead of centimeters
  static double pixelsToMeters(double pixels, double ratio) {
    return (pixels * ratio) / 100.0; // Convert from cm to meters
  }

  // Add method to convert to user's preferred unit
  static double pixelsToUserUnit(double pixels, double ratio, MeasurementUnit unit) {
    double meters = pixelsToMeters(pixels, ratio);
    if (unit == MeasurementUnit.inches) {
      return MeasurementUtils.metersToInchesConversion(meters);
    }
    return meters;
  }

  // Keep original for backward compatibility but mark as deprecated
  @deprecated
  static double pixelsToCentimeters(double pixels, double ratio) {
    return pixels * ratio;
  }

  static bool isValidReferenceObject(Rect rect, ReferenceObject objectType) {
    final referenceInfo = getReferenceInfo(objectType);
    final rectWidth = rect.width;
    final rectHeight = rect.height;
    if (rectHeight == 0) return false;
    final aspectRatio = rectWidth / rectHeight;
    final expectedAspectRatio = referenceInfo.width / referenceInfo.height;
    final inverseExpectedAspectRatio = referenceInfo.height / referenceInfo.width;
    const tolerance = 0.2;
    return (aspectRatio >= expectedAspectRatio * (1 - tolerance) &&
            aspectRatio <= expectedAspectRatio * (1 + tolerance)) ||
           (aspectRatio >= inverseExpectedAspectRatio * (1 - tolerance) &&
            aspectRatio <= inverseExpectedAspectRatio * (1 + tolerance));
  }
}
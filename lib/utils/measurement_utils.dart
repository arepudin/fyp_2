import 'dart:math';

enum MeasurementUnit { meters, inches }

class MeasurementUtils {
  // Conversion constants
  static const double metersToInches = 39.3701;
  static const double inchesToMeters = 0.0254;
  static const double cmToMeters = 0.01;
  static const double metersToCm = 100.0;
  static const double inchesToCm = 2.54;
  static const double cmToInches = 0.393701;

  /// Convert meters to inches
  static double metersToInchesConversion(double meters) {
    return meters * metersToInches;
  }

  /// Convert inches to meters
  static double inchesToMetersConversion(double inches) {
    return inches * inchesToMeters;
  }

  /// Convert centimeters to meters
  static double centimetersToMeters(double centimeters) {
    return centimeters * cmToMeters;
  }

  /// Convert meters to centimeters
  static double metersToCentimeters(double meters) {
    return meters * metersToCm;
  }

  /// Convert inches to centimeters
  static double inchesToCentimeters(double inches) {
    return inches * inchesToCm;
  }

  /// Convert centimeters to inches
  static double centimetersToInches(double centimeters) {
    return centimeters * cmToInches;
  }

  /// Format measurement value with appropriate precision
  static String formatMeasurement(double value, MeasurementUnit unit) {
    switch (unit) {
      case MeasurementUnit.meters:
        if (value < 1.0) {
          // Show in centimeters for values less than 1 meter
          return '${(value * metersToCm).toStringAsFixed(1)} cm';
        } else {
          return '${value.toStringAsFixed(2)} m';
        }
      case MeasurementUnit.inches:
        return '${value.toStringAsFixed(1)}"';
    }
  }

  /// Convert measurement to storage format (always centimeters)
  static double toStorageUnit(double value, MeasurementUnit unit) {
    switch (unit) {
      case MeasurementUnit.meters:
        return metersToCentimeters(value);
      case MeasurementUnit.inches:
        return inchesToCentimeters(value);
    }
  }

  /// Convert from storage format (centimeters) to display unit
  static double fromStorageUnit(double centimeters, MeasurementUnit unit) {
    switch (unit) {
      case MeasurementUnit.meters:
        return centimetersToMeters(centimeters);
      case MeasurementUnit.inches:
        return centimetersToInches(centimeters);
    }
  }

  /// Calculate distance between two 3D points
  static double calculateDistance(List<double> point1, List<double> point2) {
    if (point1.length != 3 || point2.length != 3) {
      throw ArgumentError('Points must have exactly 3 coordinates (x, y, z)');
    }

    double dx = point2[0] - point1[0];
    double dy = point2[1] - point1[1];
    double dz = point2[2] - point1[2];

    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Validate if measurement seems realistic for a window
  static bool isRealisticWindowMeasurement(double width, double height, MeasurementUnit unit) {
    // Convert to meters for validation
    double widthMeters = unit == MeasurementUnit.meters ? width : inchesToMetersConversion(width);
    double heightMeters = unit == MeasurementUnit.meters ? height : inchesToMetersConversion(height);

    // Realistic window dimensions in meters
    // Width: 0.3m (12") to 5m (16.4 feet)
    // Height: 0.3m (12") to 4m (13.1 feet)
    const double minWindowSize = 0.3; // 30cm
    const double maxWindowWidth = 5.0; // 5 meters
    const double maxWindowHeight = 4.0; // 4 meters

    return widthMeters >= minWindowSize && 
           widthMeters <= maxWindowWidth &&
           heightMeters >= minWindowSize && 
           heightMeters <= maxWindowHeight;
  }

  /// Get measurement accuracy warning
  static String? getMeasurementWarning(double width, double height, MeasurementUnit unit) {
    if (!isRealisticWindowMeasurement(width, height, unit)) {
      return 'These measurements seem unusually large or small for a window. Please double-check your measurements.';
    }

    // Check aspect ratio
    double ratio = width / height;
    if (ratio > 4.0) {
      return 'This window appears very wide. Please confirm the measurements are correct.';
    }
    if (ratio < 0.25) {
      return 'This window appears very tall. Please confirm the measurements are correct.';
    }

    return null; // No warning needed
  }

  /// Convert measurement for display with unit label
  static String formatWithUnit(double value, MeasurementUnit unit) {
    String unitSymbol = unit == MeasurementUnit.meters ? 'm' : 'in';
    return '${value.toStringAsFixed(unit == MeasurementUnit.meters ? 2 : 1)} $unitSymbol';
  }

  /// Get recommended unit based on value
  static MeasurementUnit getRecommendedUnit(double valueInMeters) {
    // Use inches for smaller measurements (< 2 meters)
    return valueInMeters < 2.0 ? MeasurementUnit.inches : MeasurementUnit.meters;
  }

  /// Round to appropriate precision for display
  static double roundForDisplay(double value, MeasurementUnit unit) {
    switch (unit) {
      case MeasurementUnit.meters:
        // Round to nearest centimeter (0.01m)
        return (value * 100).round() / 100;
      case MeasurementUnit.inches:
        // Round to nearest 1/8 inch (0.125")
        return (value * 8).round() / 8;
    }
  }
}
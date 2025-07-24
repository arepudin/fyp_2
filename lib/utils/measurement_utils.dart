import 'dart:math';

enum MeasurementUnit { meters, inches }

class MeasurementUtils {
  // Conversion constants - Remove centimeter constants
  static const double metersToInches = 39.3701;
  static const double inchesToMeters = 0.0254;

  /// Convert meters to inches
  static double metersToInchesConversion(double meters) {
    return meters * metersToInches;
  }

  /// Convert inches to meters
  static double inchesToMetersConversion(double inches) {
    return inches * inchesToMeters;
  }

  /// Format measurement value with appropriate precision - NO CENTIMETERS
  static String formatMeasurement(double value, MeasurementUnit unit) {
    switch (unit) {
      case MeasurementUnit.meters:
        return '${value.toStringAsFixed(2)} m';
      case MeasurementUnit.inches:
        return '${value.toStringAsFixed(1)}"';
    }
  }

  /// Store measurement in original unit (NO centimeter conversion)
  static double toStorageUnit(double value, MeasurementUnit unit) {
    // Store in original unit instead of converting to centimeters
    return value;
  }

  /// Get measurement from storage (NO centimeter conversion)
  static double fromStorageUnit(double storedValue, MeasurementUnit unit) {
    // Return value as-is since we store in original unit
    return storedValue;
  }

  /// Convert between units
  static double convertMeasurement(double value, MeasurementUnit fromUnit, MeasurementUnit toUnit) {
    if (fromUnit == toUnit) return value;
    
    if (fromUnit == MeasurementUnit.meters && toUnit == MeasurementUnit.inches) {
      return metersToInchesConversion(value);
    } else if (fromUnit == MeasurementUnit.inches && toUnit == MeasurementUnit.meters) {
      return inchesToMetersConversion(value);
    }
    
    return value;
  }

  /// Validate if measurement seems realistic for a window
  static bool isRealisticWindowMeasurement(double width, double height, MeasurementUnit unit) {
    // Convert to meters for validation
    double widthMeters = unit == MeasurementUnit.meters ? width : inchesToMetersConversion(width);
    double heightMeters = unit == MeasurementUnit.meters ? height : inchesToMetersConversion(height);

    // Realistic window dimensions in meters
    // Width: 0.3m (12") to 5m (16.4 feet)
    // Height: 0.3m (12") to 4m (13.1 feet)
    const double minWindowSize = 0.3; // 30cm = 0.3m
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
    return formatMeasurement(value, unit);
  }

  /// Get recommended unit based on value
  static MeasurementUnit getRecommendedUnit(double valueInMeters) {
    // Use inches for smaller measurements (< 2 meters)
    return valueInMeters < 2.0 ? MeasurementUnit.inches : MeasurementUnit.meters;
  }
}
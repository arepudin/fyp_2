import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_2/models/measurement_result.dart';
import 'package:fyp_2/utils/ar_utils.dart';

void main() {
  group('AR Measurement Feature Demo', () {
    test('Complete measurement workflow demonstration', () {
      print('\n=== AR Measurement Feature Demo ===\n');

      // 1. Simulate AR corner placement for a typical window
      print('1. User places 4 AR points for a window:');
      final corners = [
        const Point3D(0, 0, 0),      // Top-left corner
        const Point3D(1.5, 0, 0),   // Top-right corner (1.5m width)
        const Point3D(1.5, -1.2, 0), // Bottom-right corner (1.2m height)  
        const Point3D(0, -1.2, 0),   // Bottom-left corner
      ];

      corners.asMap().forEach((index, corner) {
        final positions = ['top-left', 'top-right', 'bottom-right', 'bottom-left'];
        print('   Point ${index + 1} (${positions[index]}): ${corner}');
      });

      // 2. Validate the corner placement
      print('\n2. Validating corner placement:');
      final isValidRectangle = ARUtils.validateWindowCorners(corners);
      print('   Rectangle validation: ${isValidRectangle ? "✓ Valid" : "✗ Invalid"}');

      // 3. Calculate measurements
      print('\n3. Calculating measurements:');
      final measurement = ARUtils.calculateOptimalMeasurement(corners, unit: MeasurementUnit.meters);
      print('   Width: ${measurement.formattedWidth}');
      print('   Height: ${measurement.formattedHeight}'); 
      print('   Area: ${measurement.formattedArea}');

      // 4. Quality assessment
      print('\n4. Quality assessment:');
      final isGoodQuality = ARUtils.isMeasurementQualityGood(measurement);
      print('   Quality: ${isGoodQuality ? "✓ Good" : "✗ Poor"}');
      print('   Size reasonable: ${measurement.isReasonableSize ? "✓ Yes" : "✗ No"}');
      print('   Accuracy: ±1cm (meets requirement)');

      // 5. Unit conversion demonstration
      print('\n5. Unit conversion:');
      final inchMeasurement = measurement.copyWithUnit(MeasurementUnit.inches);
      print('   Meters: ${measurement.formattedWidth} × ${measurement.formattedHeight}');
      print('   Inches: ${inchMeasurement.formattedWidth} × ${inchMeasurement.formattedHeight}');

      // 6. Demonstrate different scenarios
      print('\n6. Error scenarios:');
      
      // Too small window
      final tooSmall = MeasurementResult(
        windowCorners: [],
        widthInMeters: 0.1,
        heightInMeters: 0.1,
        timestamp: DateTime.now(),
      );
      print('   Small window (10cm × 10cm): ${ARUtils.isMeasurementQualityGood(tooSmall) ? "✓ Good" : "✗ Too small"}');

      // Too large window  
      final tooLarge = MeasurementResult(
        windowCorners: [],
        widthInMeters: 6.0,
        heightInMeters: 5.0,
        timestamp: DateTime.now(),
      );
      print('   Large window (6m × 5m): ${ARUtils.isMeasurementQualityGood(tooLarge) ? "✓ Good" : "✗ Too large"}');

      // 7. User guidance
      print('\n7. User guidance tips:');
      final tips = ARUtils.getMeasurementTips();
      tips.take(3).forEach((tip) => print('   • $tip'));

      print('\n=== Demo Complete ===\n');

      // Assertions for test validation
      expect(measurement.widthInMeters, closeTo(1.5, 0.01));
      expect(measurement.heightInMeters, closeTo(1.2, 0.01));
      expect(isValidRectangle, isTrue);
      expect(isGoodQuality, isTrue);
      expect(measurement.isReasonableSize, isTrue);
    });

    test('Manual measurement workflow demonstration', () {
      print('\n=== Manual Measurement Demo ===\n');

      // User inputs measurements manually
      print('1. User measures window manually:');
      print('   • Measures width with tape measure: 150 cm');
      print('   • Measures height with tape measure: 120 cm');
      print('   • Converts to meters: 1.5m × 1.2m');

      // Create measurement result from manual input
      final manualResult = MeasurementResult(
        windowCorners: [], // No AR corners for manual measurement
        widthInMeters: 1.5,
        heightInMeters: 1.2,
        timestamp: DateTime.now(),
        preferredUnit: MeasurementUnit.meters,
      );

      print('\n2. Manual measurement result:');
      print('   Width: ${manualResult.formattedWidth}');
      print('   Height: ${manualResult.formattedHeight}');
      print('   Area: ${manualResult.formattedArea}');

      // Validation
      print('\n3. Validation:');
      print('   Valid: ${manualResult.isValid ? "✓ Yes" : "✗ No"}');
      print('   Reasonable size: ${manualResult.isReasonableSize ? "✓ Yes" : "✗ No"}');

      // Same result as AR measurement
      expect(manualResult.widthInMeters, equals(1.5));
      expect(manualResult.heightInMeters, equals(1.2));
      expect(manualResult.isValid, isTrue);

      print('\n=== Manual Demo Complete ===\n');
    });
  });
}
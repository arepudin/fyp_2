import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_2/utils/ar_utils.dart';
import 'package:fyp_2/models/measurement_result.dart';

void main() {
  group('ARUtils Tests', () {
    test('should validate window corners correctly', () {
      // Arrange - valid rectangle
      final validCorners = [
        const Point3D(0, 0, 0),
        const Point3D(1, 0, 0),
        const Point3D(1, -1, 0),
        const Point3D(0, -1, 0),
      ];

      // Arrange - invalid rectangle (not enough points)
      final invalidCorners = [
        const Point3D(0, 0, 0),
        const Point3D(1, 0, 0),
        const Point3D(1, -1, 0),
      ];

      // Act & Assert
      expect(ARUtils.validateWindowCorners(validCorners), isTrue);
      expect(ARUtils.validateWindowCorners(invalidCorners), isFalse);
    });

    test('should calculate optimal measurement from corners', () {
      // Arrange
      final corners = [
        const Point3D(0, 0, 0),      // top-left
        const Point3D(2, 0, 0),      // top-right (2m width)
        const Point3D(2, -1.5, 0),   // bottom-right (1.5m height)
        const Point3D(0, -1.5, 0),   // bottom-left
      ];

      // Act
      final result = ARUtils.calculateOptimalMeasurement(corners);

      // Assert
      expect(result.widthInMeters, closeTo(2.0, 0.01));
      expect(result.heightInMeters, closeTo(1.5, 0.01));
      expect(result.isValid, isTrue);
    });

    test('should identify good measurement quality', () {
      // Arrange - good measurement
      final goodMeasurement = MeasurementResult(
        windowCorners: [
          const Point3D(0, 0, 0),
          const Point3D(1, 0, 0),
          const Point3D(1, -1, 0),
          const Point3D(0, -1, 0),
        ],
        widthInMeters: 1.0,
        heightInMeters: 1.0,
        timestamp: DateTime.now(),
      );

      // Arrange - bad measurement (too small)
      final badMeasurement = MeasurementResult(
        windowCorners: [],
        widthInMeters: 0.1,
        heightInMeters: 0.1,
        timestamp: DateTime.now(),
      );

      // Act & Assert
      expect(ARUtils.isMeasurementQualityGood(goodMeasurement), isTrue);
      expect(ARUtils.isMeasurementQualityGood(badMeasurement), isFalse);
    });

    test('should provide helpful error messages', () {
      // Test different error scenarios
      expect(ARUtils.getARErrorMessage('camera permission denied'), 
             contains('Camera permission'));
      expect(ARUtils.getARErrorMessage('arcore not supported'), 
             contains('AR is not supported'));
      expect(ARUtils.getARErrorMessage('tracking failed'), 
             contains('AR tracking lost'));
      expect(ARUtils.getARErrorMessage(null), 
             contains('Unknown AR error'));
    });

    test('should provide measurement tips', () {
      // Act
      final tips = ARUtils.getMeasurementTips();

      // Assert
      expect(tips, isNotEmpty);
      expect(tips.length, greaterThan(3));
      expect(tips.any((tip) => tip.contains('lighting')), isTrue);
      expect(tips.any((tip) => tip.contains('slowly')), isTrue);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_2/models/measurement_result.dart';

void main() {
  group('MeasurementResult Tests', () {
    test('should create measurement result from corners', () {
      // Arrange
      final corners = [
        const Point3D(0, 0, 0),      // top-left
        const Point3D(1, 0, 0),      // top-right (1m width)
        const Point3D(1, -1.5, 0),   // bottom-right (1.5m height)
        const Point3D(0, -1.5, 0),   // bottom-left
      ];

      // Act
      final result = MeasurementResult.fromCorners(corners);

      // Assert
      expect(result.widthInMeters, closeTo(1.0, 0.01));
      expect(result.heightInMeters, closeTo(1.5, 0.01));
      expect(result.isValid, isTrue);
      expect(result.isReasonableSize, isTrue);
    });

    test('should convert units correctly', () {
      // Arrange
      final result = MeasurementResult(
        windowCorners: [],
        widthInMeters: 1.0,
        heightInMeters: 1.5,
        timestamp: DateTime.now(),
        preferredUnit: MeasurementUnit.meters,
      );

      // Act
      final inchResult = result.copyWithUnit(MeasurementUnit.inches);

      // Assert
      expect(result.width, equals(1.0));
      expect(result.height, equals(1.5));
      expect(inchResult.width, closeTo(39.3701, 0.01));
      expect(inchResult.height, closeTo(59.0551, 0.01));
    });

    test('should validate reasonable window sizes', () {
      // Test minimum size
      final tooSmall = MeasurementResult(
        windowCorners: [],
        widthInMeters: 0.2,
        heightInMeters: 0.2,
        timestamp: DateTime.now(),
      );
      expect(tooSmall.isReasonableSize, isFalse);

      // Test maximum size
      final tooLarge = MeasurementResult(
        windowCorners: [],
        widthInMeters: 6.0,
        heightInMeters: 5.0,
        timestamp: DateTime.now(),
      );
      expect(tooLarge.isReasonableSize, isFalse);

      // Test reasonable size
      final reasonable = MeasurementResult(
        windowCorners: [],
        widthInMeters: 1.5,
        heightInMeters: 2.0,
        timestamp: DateTime.now(),
      );
      expect(reasonable.isReasonableSize, isTrue);
    });

    test('should format measurements correctly', () {
      // Arrange
      final meterResult = MeasurementResult(
        windowCorners: [],
        widthInMeters: 1.234,
        heightInMeters: 2.567,
        timestamp: DateTime.now(),
        preferredUnit: MeasurementUnit.meters,
      );

      final inchResult = meterResult.copyWithUnit(MeasurementUnit.inches);

      // Assert
      expect(meterResult.formattedWidth, equals('1.23 m'));
      expect(meterResult.formattedHeight, equals('2.57 m'));
      expect(inchResult.formattedWidth, contains('in'));
      expect(inchResult.formattedHeight, contains('in'));
    });

    test('should calculate area correctly', () {
      // Arrange
      final result = MeasurementResult(
        windowCorners: [],
        widthInMeters: 2.0,
        heightInMeters: 1.5,
        timestamp: DateTime.now(),
      );

      // Assert
      expect(result.area, equals(3.0));
      expect(result.formattedArea, equals('3.00 m²'));
    });
  });

  group('Point3D Tests', () {
    test('should serialize and deserialize correctly', () {
      // Arrange
      const point = Point3D(1.5, 2.5, 3.5);

      // Act
      final map = point.toMap();
      final deserializedPoint = Point3D.fromMap(map);

      // Assert
      expect(deserializedPoint.x, equals(point.x));
      expect(deserializedPoint.y, equals(point.y));
      expect(deserializedPoint.z, equals(point.z));
    });
  });
}
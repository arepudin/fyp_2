import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_2/services/ar_measurement_service.dart';
import 'package:fyp_2/utils/measurement_utils.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

void main() {
  group('Unity AR Measurement Service Tests', () {
    test('ARPoint serialization works correctly', () {
      final point = ARPoint(
        position: vector.Vector3(1.0, 2.0, 3.0),
        timestamp: DateTime(2024, 1, 1),
        id: 'test_point',
      );
      
      final json = point.toJson();
      final recreated = ARPoint.fromJson(json);
      
      expect(recreated.id, equals(point.id));
      expect(recreated.position.x, equals(point.position.x));
      expect(recreated.position.y, equals(point.position.y));
      expect(recreated.position.z, equals(point.position.z));
    });
    
    test('ARCapabilityInfo handles unavailable AR correctly', () async {
      // This will fail gracefully in test environment
      final capabilityInfo = await ARCapabilityInfo.check();
      
      // Should not crash and provide fallback info
      expect(capabilityInfo, isNotNull);
      expect(capabilityInfo.requirements, isNotEmpty);
    });
    
    test('WindowMeasurement storage format conversion works', () {
      final measurement = WindowMeasurement(
        width: 1.5,
        height: 2.0,
        unit: MeasurementUnit.meters,
        corners: [],
        timestamp: DateTime.now(),
      );
      
      final storage = measurement.toStorageFormat();
      
      expect(storage['window_width'], equals(150.0)); // 1.5m = 150cm
      expect(storage['window_height'], equals(200.0)); // 2.0m = 200cm
    });
  });
}
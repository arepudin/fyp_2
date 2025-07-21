import 'dart:math';

enum MeasurementUnit { meters, inches }

class Point3D {
  final double x;
  final double y;
  final double z;

  const Point3D(this.x, this.y, this.z);

  @override
  String toString() => 'Point3D($x, $y, $z)';

  Map<String, double> toMap() {
    return {
      'x': x,
      'y': y,
      'z': z,
    };
  }

  factory Point3D.fromMap(Map<String, dynamic> map) {
    return Point3D(
      map['x']?.toDouble() ?? 0.0,
      map['y']?.toDouble() ?? 0.0,
      map['z']?.toDouble() ?? 0.0,
    );
  }
}

class MeasurementResult {
  final List<Point3D> windowCorners;
  final double widthInMeters;
  final double heightInMeters;
  final DateTime timestamp;
  final MeasurementUnit preferredUnit;

  MeasurementResult({
    required this.windowCorners,
    required this.widthInMeters,
    required this.heightInMeters,
    required this.timestamp,
    this.preferredUnit = MeasurementUnit.meters,
  });

  // Convert measurements to preferred unit
  double get width => preferredUnit == MeasurementUnit.meters 
      ? widthInMeters 
      : _metersToInches(widthInMeters);

  double get height => preferredUnit == MeasurementUnit.meters 
      ? heightInMeters 
      : _metersToInches(heightInMeters);

  String get unitSymbol => preferredUnit == MeasurementUnit.meters ? 'm' : 'in';

  String get formattedWidth => preferredUnit == MeasurementUnit.meters
      ? '${width.toStringAsFixed(2)} m'
      : '${width.toStringAsFixed(1)} in';

  String get formattedHeight => preferredUnit == MeasurementUnit.meters
      ? '${height.toStringAsFixed(2)} m'
      : '${height.toStringAsFixed(1)} in';

  // Calculate area
  double get area => width * height;

  String get formattedArea => preferredUnit == MeasurementUnit.meters
      ? '${area.toStringAsFixed(2)} m²'
      : '${area.toStringAsFixed(1)} in²';

  // Validation methods
  bool get isValid => windowCorners.length == 4 && 
                     widthInMeters > 0 && 
                     heightInMeters > 0;

  bool get isReasonableSize => 
      widthInMeters >= 0.3 && widthInMeters <= 5.0 &&  // 30cm to 5m width
      heightInMeters >= 0.3 && heightInMeters <= 4.0;   // 30cm to 4m height

  // Helper methods
  static double _metersToInches(double meters) => meters * 39.3701;
  static double _inchesToMeters(double inches) => inches / 39.3701;

  // Calculate distance between two 3D points
  static double distance3D(Point3D p1, Point3D p2) {
    return sqrt(
      pow(p2.x - p1.x, 2) + 
      pow(p2.y - p1.y, 2) + 
      pow(p2.z - p1.z, 2)
    );
  }

  // Create measurement result from 4 corner points
  factory MeasurementResult.fromCorners(
    List<Point3D> corners, {
    MeasurementUnit unit = MeasurementUnit.meters,
  }) {
    if (corners.length != 4) {
      throw ArgumentError('Exactly 4 corner points are required');
    }

    // Calculate width and height from the corners
    // Assuming corners are ordered: top-left, top-right, bottom-right, bottom-left
    double width = (distance3D(corners[0], corners[1]) + 
                   distance3D(corners[3], corners[2])) / 2;
    double height = (distance3D(corners[0], corners[3]) + 
                    distance3D(corners[1], corners[2])) / 2;

    return MeasurementResult(
      windowCorners: corners,
      widthInMeters: width,
      heightInMeters: height,
      timestamp: DateTime.now(),
      preferredUnit: unit,
    );
  }

  // Copy with different unit
  MeasurementResult copyWithUnit(MeasurementUnit newUnit) {
    return MeasurementResult(
      windowCorners: windowCorners,
      widthInMeters: widthInMeters,
      heightInMeters: heightInMeters,
      timestamp: timestamp,
      preferredUnit: newUnit,
    );
  }

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'windowCorners': windowCorners.map((corner) => corner.toMap()).toList(),
      'widthInMeters': widthInMeters,
      'heightInMeters': heightInMeters,
      'timestamp': timestamp.toIso8601String(),
      'preferredUnit': preferredUnit.toString(),
    };
  }

  factory MeasurementResult.fromMap(Map<String, dynamic> map) {
    return MeasurementResult(
      windowCorners: (map['windowCorners'] as List<dynamic>)
          .map((corner) => Point3D.fromMap(corner))
          .toList(),
      widthInMeters: map['widthInMeters']?.toDouble() ?? 0.0,
      heightInMeters: map['heightInMeters']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
      preferredUnit: MeasurementUnit.values.firstWhere(
        (unit) => unit.toString() == map['preferredUnit'],
        orElse: () => MeasurementUnit.meters,
      ),
    );
  }
}
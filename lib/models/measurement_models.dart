// lib/models/measurement_models.dart

import 'dart:math';

/// Class to represent a point for drawing measurements
class MeasurementPoint {
  final double x;
  final double y;
  
  MeasurementPoint(this.x, this.y);
}

/// Class to represent a measurement line
class MeasurementLine {
  final MeasurementPoint start;
  final MeasurementPoint end;
  final String label;
  
  MeasurementLine(this.start, this.end, this.label);
  
  double get length {
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    return sqrt(dx * dx + dy * dy);
  }
}
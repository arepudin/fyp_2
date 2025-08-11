// lib/screens/customers/widgets/measurement_painters.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fyp_2/services/ai_measurement.dart';
import 'package:fyp_2/utils/measurement_utils.dart';
import '../../../models/measurement_models.dart';

class RectangleOverlayPainter extends CustomPainter {
  final ui.Image imageInfo;
  final List<Rect> rectangles;
  final Rect? selectedRect;
  final Offset? manualSelectionStart;
  final Offset? manualSelectionCurrent;

  RectangleOverlayPainter({
    required this.imageInfo,
    required this.rectangles,
    this.selectedRect,
    this.manualSelectionStart,
    this.manualSelectionCurrent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final imageAspectRatio = imageInfo.width / imageInfo.height;
    final canvasAspectRatio = size.width / size.height;
    double scale;
    Offset offset = Offset.zero;
    if (imageAspectRatio > canvasAspectRatio) {
      scale = size.width / imageInfo.width;
      offset = Offset(0, (size.height - imageInfo.height * scale) / 2);
    } else {
      scale = size.height / imageInfo.height;
      offset = Offset((size.width - imageInfo.width * scale) / 2, 0);
    }
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 3 / scale;

    // 1. Draw all auto-detected rectangles in red.
    paint.color = Colors.red;
    for (final rect in rectangles) {
      // We'll draw the selected one separately in green, so skip it here.
      if (rect != selectedRect) {
        canvas.drawRect(rect, paint);
      }
    }

    // 2. If a reference object has been successfully selected (from auto or manual),
    // draw it on top in green. This is the key fix.
    if (selectedRect != null) {
      paint.color = Colors.green;
      canvas.drawRect(selectedRect!, paint);
    }

    // 3. If a manual drag is currently in progress, draw the dashed blue box.
    if (manualSelectionStart != null && manualSelectionCurrent != null) {
      final rect = Rect.fromPoints(manualSelectionStart!, manualSelectionCurrent!);
      paint.color = Colors.blue;
      final Path path = Path()..addRect(rect);
      final Path dashedPath = dashPath(path, dashArray: CircularIntervalList<double>([10.0, 5.0]));
      canvas.drawPath(dashedPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RectangleOverlayPainter oldDelegate) {
    return oldDelegate.rectangles != rectangles ||
           oldDelegate.selectedRect != selectedRect ||
           oldDelegate.manualSelectionStart != manualSelectionStart ||
           oldDelegate.manualSelectionCurrent != manualSelectionCurrent;
  }
}

class MeasurementPainter extends CustomPainter {
  final ui.Image imageInfo;
  final List<MeasurementLine> measurementLines;
  final double pixelToCmRatio;
  final MeasurementLine? previewLine;
  final MeasurementUnit unit;

  MeasurementPainter({
    required this.imageInfo,
    required this.measurementLines,
    required this.pixelToCmRatio,
    this.previewLine,
    this.unit = MeasurementUnit.meters,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scaling logic
    final imageAspectRatio = imageInfo.width / imageInfo.height;
    final canvasAspectRatio = size.width / size.height;
    double scale;
    Offset offset = Offset.zero;
    if (imageAspectRatio > canvasAspectRatio) {
      scale = size.width / imageInfo.width;
      offset = Offset(0, (size.height - imageInfo.height * scale) / 2);
    } else {
      scale = size.height / imageInfo.height;
      offset = Offset((size.width - imageInfo.width * scale) / 2, 0);
    }
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final linePaint = Paint()..color = Colors.blue..strokeWidth = 4 / scale..strokeCap = StrokeCap.round;
    final textStyle = TextStyle(color: Colors.white, fontSize: 14 / scale, fontWeight: FontWeight.bold, backgroundColor: Colors.black.withOpacity(0.6));
    // Draw committed lines
    for (final line in measurementLines) {
      _drawLineWithLabel(canvas, line, linePaint, textStyle);
    }
    // Draw preview line
    if (previewLine != null) {
      final previewPaint = Paint()..color = Colors.lightBlue.withOpacity(0.8)..strokeWidth = 4 / scale..strokeCap = StrokeCap.round;
      final path = Path()..moveTo(previewLine!.start.x, previewLine!.start.y)..lineTo(previewLine!.end.x, previewLine!.end.y);
      final dashedPath = dashPath(path, dashArray: CircularIntervalList<double>([10.0, 5.0]));
      canvas.drawPath(dashedPath, previewPaint);
      _drawLineWithLabel(canvas, previewLine!, previewPaint, textStyle, isPreview: true);
    }
  }

  void _drawLineWithLabel(Canvas canvas, MeasurementLine line, Paint paint, TextStyle style, {bool isPreview = false}) {
    if (!isPreview) {
      canvas.drawLine(Offset(line.start.x, line.start.y), Offset(line.end.x, line.end.y), paint);
    }
    final measurement = AIMeasurementService.pixelsToUserUnit(line.length, pixelToCmRatio, unit);
    final unitLabel = MeasurementUtils.formatWithUnit(measurement, unit);
    final textSpan = TextSpan(text: '${line.label}: ${measurement.toStringAsFixed(1)} m', style: style);
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    final midX = (line.start.x + line.end.x) / 2;
    final midY = (line.start.y + line.end.y) / 2;
    textPainter.paint(canvas, Offset(midX - textPainter.width / 2, midY - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant MeasurementPainter oldDelegate) =>
      oldDelegate.measurementLines != measurementLines || oldDelegate.previewLine != previewLine;
}

// --- UTILITY FUNCTIONS FOR PAINTERS ---

Path dashPath(Path source, {required CircularIntervalList<double> dashArray}) {
  final Path dest = Path();
  for (final ui.PathMetric metric in source.computeMetrics()) {
    double distance = 0.0;
    bool draw = true;
    while (distance < metric.length) {
      final double len = dashArray.next;
      if (draw) {
        dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
      }
      distance += len;
      draw = !draw;
    }
  }
  return dest;
}

class CircularIntervalList<T> {
  CircularIntervalList(this._values);
  final List<T> _values;
  int _idx = 0;
  T get next {
    if (_idx >= _values.length) _idx = 0;
    return _values[_idx++];
  }
}
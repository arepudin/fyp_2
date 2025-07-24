// lib/screens/customers/widgets/ai_measurement_steps.dart

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fyp_2/services/ai_measurement.dart'; // Ensure this path is correct
import '../../../models/measurement_models.dart'; // Ensure this path is correct
import 'measurement_painters.dart'; // Ensure this path is correct

const Color primaryRed = Color.fromARGB(255, 158, 19, 17);

// --- STEP 1: REFERENCE SELECTION ---
class ReferenceSelectionStep extends StatelessWidget {
  final ReferenceObject selectedReference;
  final ValueChanged<ReferenceObject?> onReferenceChanged;
  
  const ReferenceSelectionStep({
    super.key,
    required this.selectedReference,
    required this.onReferenceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose Reference Object', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Choose a reference object to help us calculate accurate measurements:', style: TextStyle(fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 32),
          ...ReferenceObject.values.map((object) {
            final info = AIMeasurementService.getReferenceInfo(object);
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: RadioListTile<ReferenceObject>(
                value: object,
                groupValue: selectedReference,
                onChanged: onReferenceChanged,
                title: Text(info.displayName),
                subtitle: Text('${info.width}cm × ${info.height}cm'),
                activeColor: primaryRed,
              ),
            );
          }),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Icon(Icons.info_outline, color: Colors.blue), SizedBox(width: 8), Text('Tips for best results:', style: TextStyle(fontWeight: FontWeight.bold))]),
                SizedBox(height: 8),
                Text('• Ensure good, even lighting'),
                Text('• Place object flat against the wall'),
                Text('• Use a contrasting background'),
                Text('• Take photo straight-on (not at an angle)'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// --- STEP 2: CAPTURE IMAGE ---
class CaptureStep extends StatelessWidget {
  final ReferenceObject selectedReference;
  final File? capturedImage;
  final VoidCallback onTakePhoto;
  final VoidCallback onRetakePhoto;

  const CaptureStep({
    super.key,
    required this.selectedReference,
    required this.capturedImage,
    required this.onTakePhoto,
    required this.onRetakePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final referenceInfo = AIMeasurementService.getReferenceInfo(selectedReference);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Position & Capture', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
            child: Text(referenceInfo.instructions),
          ),
          const SizedBox(height: 32),
          if (capturedImage != null) ...[
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(capturedImage!, fit: BoxFit.cover)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onRetakePhoto, icon: const Icon(Icons.camera_alt), label: const Text('Retake Photo')),
          ] else ...[
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, size: 64, color: Colors.grey), SizedBox(height: 16), Text('No photo taken yet', style: TextStyle(color: Colors.grey))]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTakePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// --- STEP 3: SELECT REFERENCE (AI & MANUAL) ---
class DetectionStep extends StatefulWidget {
  final bool isProcessing;
  final String? errorMessage;
  final File? capturedImage;
  final ui.Image? imageInfo;
  final List<Rect> detectedRectangles;
  final Rect? selectedReferenceRect;
  final Offset? manualSelectionStart;
  final Offset? manualSelectionCurrent;
  final Key? gestureDetectorKey;
  
  final VoidCallback onDetectReference;
  final Function(TapUpDetails, BuildContext) onImageTap;
  final Function(DragStartDetails) onManualSelectionStart;
  final Function(DragUpdateDetails) onManualSelectionUpdate;
  final Function(DragEndDetails) onManualSelectionEnd;
  final VoidCallback onClearManualSelectionError;

  const DetectionStep({
    super.key,
    this.gestureDetectorKey,
    required this.isProcessing,
    this.errorMessage,
    this.capturedImage,
    this.imageInfo,
    required this.detectedRectangles,
    this.selectedReferenceRect,
    this.manualSelectionStart,
    this.manualSelectionCurrent,
    required this.onDetectReference,
    required this.onImageTap,
    required this.onManualSelectionStart,
    required this.onManualSelectionUpdate,
    required this.onManualSelectionEnd,
    required this.onClearManualSelectionError,
  });

  @override
  State<DetectionStep> createState() => _DetectionStepState();
}

class _DetectionStepState extends State<DetectionStep> {
  bool _isManualMode = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Select Reference', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (widget.isProcessing)
            const Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text("Analyzing image...")],)))
          else if (_isManualMode)
            _buildManualSelectionUI()
          else
            _buildAutoDetectionUI(),
        ],
      ),
    );
  }

  Widget _buildAutoDetectionUI() {
    return Expanded(
      child: Column(
        children: [
          if (widget.errorMessage != null)
            Text(widget.errorMessage!, style: const TextStyle(color: Colors.red)),
          if (widget.detectedRectangles.isNotEmpty)
            const Text('Tap the correct rectangle outlining your reference object.')
          else
            const Text('Press "Start Detection" to find the reference object.'),
          const SizedBox(height: 8),
          
          Expanded(
            child: (widget.capturedImage == null || widget.imageInfo == null)
                ? const Center(child: Text('Please capture an image first.'))
                : InteractiveViewer(
                    child: GestureDetector(
                      key: widget.gestureDetectorKey,
                      onTapUp: (details) => widget.onImageTap(details, context),
                      child: CustomPaint(
                        foregroundPainter: RectangleOverlayPainter(
                          imageInfo: widget.imageInfo!,
                          rectangles: widget.detectedRectangles,
                          selectedRect: widget.selectedReferenceRect,
                        ),
                        child: Center(child: Image.file(widget.capturedImage!, fit: BoxFit.contain)),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: widget.onDetectReference,
            icon: const Icon(Icons.visibility),
            label: const Text('Start Detection'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _isManualMode = true),
            child: const Text('Or, select manually...'),
          ),
        ],
      ),
    );
  }

  Widget _buildManualSelectionUI() {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Row(children: [Icon(Icons.touch_app, color: Colors.blue), SizedBox(width: 8), Expanded(child: Text('Tap and drag to draw a box around your reference object.'))]),
          ),
          const SizedBox(height: 8),
          if (widget.errorMessage != null)
            Text(widget.errorMessage!, style: const TextStyle(color: Colors.red)),
          
          Expanded(
            child: (widget.capturedImage == null || widget.imageInfo == null)
                ? const Center(child: Text('Please capture an image first.'))
                : InteractiveViewer(
                    child: GestureDetector(
                      key: widget.gestureDetectorKey,
                      onPanStart: widget.onManualSelectionStart,
                      onPanUpdate: widget.onManualSelectionUpdate,
                      onPanEnd: widget.onManualSelectionEnd,
                      child: CustomPaint(
                        foregroundPainter: RectangleOverlayPainter(
                          imageInfo: widget.imageInfo!,
                          rectangles: const [],
                          manualSelectionStart: widget.manualSelectionStart,
                          manualSelectionCurrent: widget.manualSelectionCurrent,
                        ),
                        child: Center(child: Image.file(widget.capturedImage!, fit: BoxFit.contain)),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
           TextButton(
            onPressed: () {
              widget.onClearManualSelectionError();
              setState(() => _isManualMode = false);
            },
            child: const Text('Back to Auto-Detect'),
          ),
        ],
      ),
    );
  }
}

// --- STEP 4: DRAW MEASUREMENTS ---
class MeasurementStep extends StatelessWidget {
  final ui.Image? imageInfo;
  final File? capturedImage;
  final double? pixelToCmRatio;
  final List<MeasurementLine> measurementLines;
  final MeasurementLine? previewLine;
  final Key? gestureDetectorKey;

  final Function(DragStartDetails) onDrawMeasurementStart;
  final Function(DragUpdateDetails) onDrawMeasurementUpdate;
  final Function(DragEndDetails) onDrawMeasurementEnd;
  final VoidCallback onClearMeasurements;

  const MeasurementStep({
    super.key,
    this.gestureDetectorKey,
    this.imageInfo,
    this.capturedImage,
    this.pixelToCmRatio,
    required this.measurementLines,
    this.previewLine,
    required this.onDrawMeasurementStart,
    required this.onDrawMeasurementUpdate,
    required this.onDrawMeasurementEnd,
    required this.onClearMeasurements,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Draw Measurements', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Draw lines for width and height on your window.'),
          const SizedBox(height: 8),
          
          if (pixelToCmRatio != null) ...[
            Expanded(
              child: (capturedImage == null || imageInfo == null)
                  ? const Center(child: Text('Image not available.'))
                  : InteractiveViewer(
                      child: GestureDetector(
                        key: gestureDetectorKey,
                        onPanStart: (details) => onDrawMeasurementStart(details),
                        onPanUpdate: (details) => onDrawMeasurementUpdate(details),
                        onPanEnd: (details) => onDrawMeasurementEnd(details),
                        child: CustomPaint(
                          foregroundPainter: MeasurementPainter(
                            imageInfo: imageInfo!,
                            measurementLines: measurementLines,
                            pixelToCmRatio: pixelToCmRatio!,
                            previewLine: previewLine,
                          ),
                          child: Center(child: Image.file(capturedImage!, fit: BoxFit.contain)),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onClearMeasurements, child: const Text('Clear All Measurements')),
          ] else
            const Expanded(child: Center(child: Text('Please select a valid reference object first.'))),
        ],
      ),
    );
  }
}

// --- STEP 5: REVIEW RESULTS ---
class ResultsStep extends StatelessWidget {
  final List<MeasurementLine> measurementLines;
  final double? pixelToCmRatio;
  final VoidCallback onSubmitMeasurements;

  const ResultsStep({
    super.key,
    required this.measurementLines,
    this.pixelToCmRatio,
    required this.onSubmitMeasurements,
  });

  @override
  Widget build(BuildContext context) {
    double? measuredWidth, measuredHeight;
    if (measurementLines.isNotEmpty && pixelToCmRatio != null) {
      measuredWidth = AIMeasurementService.pixelsToCentimeters(measurementLines[0].length, pixelToCmRatio!);
    }
    if (measurementLines.length >= 2 && pixelToCmRatio != null) {
      measuredHeight = AIMeasurementService.pixelsToCentimeters(measurementLines[1].length, pixelToCmRatio!);
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Review Results', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (measuredWidth != null || measuredHeight != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Measured Dimensions:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (measuredWidth != null)
                    Text('Width: ${measuredWidth.toStringAsFixed(1)} cm', style: const TextStyle(fontSize: 16)),
                  if (measuredHeight != null)
                    Text('Height: ${measuredHeight.toStringAsFixed(1)} cm', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubmitMeasurements,
                style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Use These Measurements'),
              ),
            ),
          ] else
            const Text('Please draw at least one measurement line (width).'),
        ],
      ),
    );
  }
}
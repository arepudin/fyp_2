import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fyp_2/services/ai_measurement.dart'; // Ensure this points to your new OpenCV service
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;

// =========================================================================
// ===               FIX 1: RESTORED HELPER CLASSES                      ===
// =========================================================================
// These classes were removed when the service file was replaced.
// They are needed by AIMeasurementScreen.

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

// =========================================================================

class AIMeasurementScreen extends StatefulWidget {
  final Function(double width, double height)? onMeasurementsEntered;

  const AIMeasurementScreen({
    super.key,
    this.onMeasurementsEntered,
  });

  @override
  State<AIMeasurementScreen> createState() => _AIMeasurementScreenState();
}

class _AIMeasurementScreenState extends State<AIMeasurementScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  ReferenceObject _selectedReference = ReferenceObject.a4Paper;
  File? _capturedImage;
  ui.Image? _imageInfo;

  List<Rect> _detectedRectangles = [];
  Rect? _selectedReferenceRect;
  double? _pixelToCmRatio;

  List<MeasurementLine> _measurementLines = [];
  MeasurementLine? _previewLine;

  bool _isProcessing = false;
  String? _errorMessage;
  bool _isManualSelectionMode = false;
  Offset? _manualSelectionStart;
  Offset? _manualSelectionCurrent;

  static const Color primaryRed = Color.fromARGB(255, 158, 19, 17);

  final List<String> _stepTitles = [
    'Choose Reference Object',
    'Position & Capture',
    'Select Reference',
    'Draw Measurements',
    'Review Results',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadImage(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _capturedImage = file;
      _imageInfo = frame.image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('AI-Assisted Measurement'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildReferenceSelectionStep(),
                _buildCaptureStep(),
                _buildDetectionStep(),
                _buildMeasurementStep(),
                _buildResultsStep(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(_stepTitles.length, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : isActive ? primaryRed : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildReferenceSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_stepTitles[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Choose a reference object to help us calculate accurate measurements:', style: TextStyle(fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 32),
          ...ReferenceObject.values.map((object) {
            final info = AIMeasurementService.getReferenceInfo(object);
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: RadioListTile<ReferenceObject>(
                value: object,
                groupValue: _selectedReference,
                onChanged: (value) => setState(() => _selectedReference = value!),
                title: Text(info.displayName),
                subtitle: Text('${info.width}cm × ${info.height}cm'),
                activeColor: primaryRed,
              ),
            );
          }),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [ Icon(Icons.info_outline, color: Colors.blue), SizedBox(width: 8), Text('Tips for best results:', style: TextStyle(fontWeight: FontWeight.bold))]),
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

  Widget _buildCaptureStep() {
    final referenceInfo = AIMeasurementService.getReferenceInfo(_selectedReference);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_stepTitles[1], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(referenceInfo.instructions),
          ),
          const SizedBox(height: 32),
          if (_capturedImage != null) ...[
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_capturedImage!, fit: BoxFit.cover)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: _retakePhoto, icon: const Icon(Icons.camera_alt), label: const Text('Retake Photo')),
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
                onPressed: _takePhoto,
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

  Widget _buildDetectionStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_stepTitles[2], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_isProcessing)
            const Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text("Analyzing image...")],)))
          else if (_isManualSelectionMode)
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
          if (_errorMessage != null)
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          if (_detectedRectangles.isNotEmpty)
            const Text('Tap the correct rectangle outlining your reference object.')
          else
            const Text('Press "Start Detection" to find the reference object.'),
          const SizedBox(height: 8),
          
          // === FIX 2: ADDED NULL CHECK FOR _imageInfo ===
          Expanded(
            child: (_capturedImage == null || _imageInfo == null)
                ? const Center(child: Text('Please capture an image first.'))
                : InteractiveViewer(
                    child: GestureDetector(
                      onTapUp: (details) => _onImageTap(details, context),
                      child: CustomPaint(
                        foregroundPainter: RectangleOverlayPainter(
                          imageInfo: _imageInfo!,
                          rectangles: _detectedRectangles,
                          selectedRect: _selectedReferenceRect,
                        ),
                        child: Center(child: Image.file(_capturedImage!, fit: BoxFit.contain)),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          // === FIX 3: ADDED EXPLICIT DETECTION BUTTON ===
          ElevatedButton.icon(
            onPressed: _detectReference,
            icon: const Icon(Icons.visibility),
            label: const Text('Start Detection'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() { _isManualSelectionMode = true; _detectedRectangles = []; _selectedReferenceRect = null; }),
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
          if (_errorMessage != null)
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          
          // === FIX 2: ADDED NULL CHECK FOR _imageInfo ===
          Expanded(
            child: (_capturedImage == null || _imageInfo == null)
                ? const Center(child: Text('Please capture an image first.'))
                : InteractiveViewer(
                    child: GestureDetector(
                      onPanStart: _onManualSelectionStart,
                      onPanUpdate: _onManualSelectionUpdate,
                      onPanEnd: _onManualSelectionEnd,
                      child: CustomPaint(
                        foregroundPainter: RectangleOverlayPainter(
                          imageInfo: _imageInfo!,
                          rectangles: const [],
                          manualSelectionStart: _manualSelectionStart,
                          manualSelectionCurrent: _manualSelectionCurrent,
                        ),
                        child: Center(child: Image.file(_capturedImage!, fit: BoxFit.contain)),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
           TextButton(
            onPressed: () => setState(() { _isManualSelectionMode = false; _errorMessage = null; }),
            child: const Text('Back to Auto-Detect'),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_stepTitles[3], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Draw lines for width and height on your window.'),
          const SizedBox(height: 8),
          
          if (_pixelToCmRatio != null) ...[
            // === FIX 2: ADDED NULL CHECK FOR _imageInfo ===
            Expanded(
              child: (_capturedImage == null || _imageInfo == null)
                  ? const Center(child: Text('Image not available.'))
                  : InteractiveViewer(
                      child: GestureDetector(
                        onPanStart: _onDrawMeasurementStart,
                        onPanUpdate: _onDrawMeasurementUpdate,
                        onPanEnd: _onDrawMeasurementEnd,
                        child: CustomPaint(
                          foregroundPainter: MeasurementPainter(
                            imageInfo: _imageInfo!,
                            measurementLines: _measurementLines,
                            pixelToCmRatio: _pixelToCmRatio!,
                            previewLine: _previewLine,
                          ),
                          child: Center(child: Image.file(_capturedImage!, fit: BoxFit.contain)),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _clearMeasurements, child: const Text('Clear All Measurements')),
          ] else
            const Expanded(child: Center(child: Text('Please select a valid reference object first.'))),
        ],
      ),
    );
  }

  Widget _buildResultsStep() {
    double? measuredWidth, measuredHeight;
    if (_measurementLines.isNotEmpty && _pixelToCmRatio != null) {
      measuredWidth = AIMeasurementService.pixelsToCentimeters(_measurementLines[0].length, _pixelToCmRatio!);
    }
    if (_measurementLines.length >= 2 && _pixelToCmRatio != null) {
      measuredHeight = AIMeasurementService.pixelsToCentimeters(_measurementLines[1].length, _pixelToCmRatio!);
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_stepTitles[4], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                onPressed: _submitMeasurements,
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

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, -2))]),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(child: OutlinedButton(onPressed: _previousStep, child: const Text('Previous'))),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed() ? _nextStep : null,
              style: ElevatedButton.styleFrom(backgroundColor: primaryRed, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey.shade400),
              child: Text(_currentStep == _stepTitles.length - 1 ? 'Finish' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  // --- IMPLEMENTATION METHODS ---
  // (Most logic is unchanged, just rearranged calls)
  
  void _resetStateForNewImage() {
    setState(() {
      _imageInfo = null;
      _detectedRectangles.clear();
      _selectedReferenceRect = null;
      _measurementLines.clear();
      _pixelToCmRatio = null;
      _isManualSelectionMode = false;
      _manualSelectionStart = null;
      _manualSelectionCurrent = null;
      _errorMessage = null;
    });
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    
    if (photo != null) {
      _resetStateForNewImage();
      await _loadImage(File(photo.path));
    }
  }

  void _retakePhoto() {
    _resetStateForNewImage();
    setState(() {
      _capturedImage = null;
    });
  }

  Future<void> _detectReference() async {
    if (_capturedImage == null) {
      setState(() => _errorMessage = "Please take a photo first.");
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // Use a compute isolate for heavy processing to avoid freezing the UI
    // final rectangles = await compute(AIMeasurementService.detectRectangles, _capturedImage!.path);
    final rectangles = await AIMeasurementService.detectRectangles(_capturedImage!.path);

    setState(() {
      _detectedRectangles = rectangles;
      if (rectangles.isEmpty) {
        _errorMessage = 'No objects detected. Try adjusting lighting or switch to manual selection.';
      }
      _isProcessing = false;
    });
  }

  Offset _scaleTap(Offset tapPosition, Size widgetSize, ui.Image image) {
    final double imageAspectRatio = image.width / image.height;
    final double widgetAspectRatio = widgetSize.width / widgetSize.height;
    
    if (imageAspectRatio > widgetAspectRatio) {
      final double scale = widgetSize.width / image.width;
      final double blankHeight = (widgetSize.height - image.height * scale) / 2;
      return Offset(tapPosition.dx / scale, (tapPosition.dy - blankHeight) / scale);
    } else {
      final double scale = widgetSize.height / image.height;
      final double blankWidth = (widgetSize.width - image.width * scale) / 2;
      return Offset((tapPosition.dx - blankWidth) / scale, tapPosition.dy / scale);
    }
  }

  void _onImageTap(TapUpDetails details, BuildContext context) {
    if (_imageInfo == null) return;
    final widgetSize = context.size!;
    final scaledTap = _scaleTap(details.localPosition, widgetSize, _imageInfo!);

    Rect? tappedRect;
    for (final rect in _detectedRectangles) {
      if (rect.contains(scaledTap)) {
        tappedRect = rect;
        break;
      }
    }

    if (tappedRect != null) {
      if (AIMeasurementService.isValidReferenceObject(tappedRect, _selectedReference)) {
        setState(() {
          _selectedReferenceRect = tappedRect;
          _pixelToCmRatio = AIMeasurementService.calculatePixelToCmRatio(tappedRect!, _selectedReference);
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = "The selected object's shape doesn't match a ${_selectedReference.name}.";
          _selectedReferenceRect = null;
          _pixelToCmRatio = null;
        });
      }
    }
  }

  void _onManualSelectionStart(DragStartDetails details) {
    if (_imageInfo == null) return;
    final widgetSize = (context.findRenderObject() as RenderBox).size;
    final scaledTap = _scaleTap(details.localPosition, widgetSize, _imageInfo!);
    setState(() {
      _manualSelectionStart = scaledTap;
      _manualSelectionCurrent = scaledTap;
      _errorMessage = null;
    });
  }

  void _onManualSelectionUpdate(DragUpdateDetails details) {
    if (_imageInfo == null || _manualSelectionStart == null) return;
    final widgetSize = (context.findRenderObject() as RenderBox).size;
    final scaledTap = _scaleTap(details.localPosition, widgetSize, _imageInfo!);
    setState(() => _manualSelectionCurrent = scaledTap);
  }

  void _onManualSelectionEnd(DragEndDetails details) {
    if (_manualSelectionStart != null && _manualSelectionCurrent != null) {
      final rect = Rect.fromPoints(_manualSelectionStart!, _manualSelectionCurrent!);
      if (AIMeasurementService.isValidReferenceObject(rect, _selectedReference)) {
        setState(() {
          _selectedReferenceRect = rect;
          _pixelToCmRatio = AIMeasurementService.calculatePixelToCmRatio(rect, _selectedReference);
          _isManualSelectionMode = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = "The drawn box's shape doesn't match a ${_selectedReference.name}. Please try again.";
          _manualSelectionStart = null;
          _manualSelectionCurrent = null;
        });
      }
    }
  }

  void _onDrawMeasurementStart(DragStartDetails details) {
    if (_imageInfo == null) return;
    final widgetSize = (context.findRenderObject() as RenderBox).size;
    final scaledTap = _scaleTap(details.localPosition, widgetSize, _imageInfo!);
    final startPoint = MeasurementPoint(scaledTap.dx, scaledTap.dy);
    setState(() => _previewLine = MeasurementLine(startPoint, startPoint, '...'));
  }
  
  void _onDrawMeasurementUpdate(DragUpdateDetails details) {
    if (_imageInfo == null || _previewLine == null) return;
    final widgetSize = (context.findRenderObject() as RenderBox).size;
    final scaledTap = _scaleTap(details.localPosition, widgetSize, _imageInfo!);
    final endPoint = MeasurementPoint(scaledTap.dx, scaledTap.dy);
    setState(() => _previewLine = MeasurementLine(_previewLine!.start, endPoint, '...'));
  }
  
  void _onDrawMeasurementEnd(DragEndDetails details) {
    if (_previewLine != null && _previewLine!.length > 10) {
      final lineNumber = _measurementLines.length;
      final label = lineNumber == 0 ? 'Width' : lineNumber == 1 ? 'Height' : 'Line ${lineNumber + 1}';
      _measurementLines.add(MeasurementLine(_previewLine!.start, _previewLine!.end, label));
    }
    setState(() => _previewLine = null);
  }

  void _clearMeasurements() => setState(() => _measurementLines.clear());

  void _submitMeasurements() {
    if (_measurementLines.isNotEmpty && _pixelToCmRatio != null) {
      final width = AIMeasurementService.pixelsToCentimeters(_measurementLines[0].length, _pixelToCmRatio!);
      final height = _measurementLines.length >= 2 ? AIMeasurementService.pixelsToCentimeters(_measurementLines[1].length, _pixelToCmRatio!) : 0.0;
      widget.onMeasurementsEntered?.call(width, height);
      Navigator.pop(context);
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: return true;
      case 1: return _capturedImage != null;
      case 2: return _selectedReferenceRect != null;
      case 3: return _measurementLines.isNotEmpty;
      case 4: return true;
      default: return false;
    }
  }

  void _nextStep() {
    if (_currentStep < _stepTitles.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _submitMeasurements();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }
}

// --- PAINTERS AND UTILS (NO CHANGES NEEDED HERE) ---

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
    for (final rect in rectangles) {
      paint.color = rect == selectedRect ? Colors.green : Colors.red;
      canvas.drawRect(rect, paint);
    }
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

  MeasurementPainter({
    required this.imageInfo,
    required this.measurementLines,
    required this.pixelToCmRatio,
    this.previewLine,
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

    final linePaint = Paint()..color = Colors.blue..strokeWidth = 4 / scale..strokeCap = StrokeCap.round;
    final textStyle = TextStyle(color: Colors.white, fontSize: 14 / scale, fontWeight: FontWeight.bold, backgroundColor: Colors.black.withOpacity(0.6));
    for (final line in measurementLines) {
      _drawLineWithLabel(canvas, line, linePaint, textStyle);
    }
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
    final measurement = AIMeasurementService.pixelsToCentimeters(line.length, pixelToCmRatio);
    final textSpan = TextSpan(text: '${line.label}: ${measurement.toStringAsFixed(1)} cm', style: style);
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    final midX = (line.start.x + line.end.x) / 2;
    final midY = (line.start.y + line.end.y) / 2;
    textPainter.paint(canvas, Offset(midX - textPainter.width / 2, midY - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant MeasurementPainter oldDelegate) => oldDelegate.measurementLines != measurementLines || oldDelegate.previewLine != previewLine;
}

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
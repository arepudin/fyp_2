// lib/screens/customers/ai_measurement_screen.dart

import 'package:flutter/material.dart';
import 'package:fyp_2/services/ai_measurement.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../../models/measurement_models.dart';
import '../../services/measurement.dart';
import '../../utils/measurement_utils.dart';
import 'ai_measurement_steps.dart';
import '../../config/theme_config.dart';

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
  final GlobalKey _gestureDetectorKey = GlobalKey();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final List<String> _stepTitles = [
    'Choose Reference Object', 'Position & Capture', 'Select Reference',
    'Draw Measurements', 'Review Results',
  ];

  ReferenceObject _selectedReference = ReferenceObject.a4Paper;
  File? _capturedImage;
  ui.Image? _imageInfo;
  
  List<Rect> _detectedRectangles = [];
  Rect? _selectedReferenceRect;
  double? _pixelToCmRatio;

  List<MeasurementLine> _measurementLines = [];
  MeasurementLine? _previewLine;
  bool _isSaving = false;
  MeasurementUnit _preferredUnit = MeasurementUnit.meters;

  Offset? _manualSelectionStart;
  Offset? _manualSelectionCurrent;

  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ... (build methods and other logic remain the same as previous correct version) ...
  // The key change is in _submitMeasurements

  void _submitMeasurements() async {
    if (_measurementLines.isNotEmpty && _pixelToCmRatio != null) {
      final width = AIMeasurementService.pixelsToUserUnit(
        _measurementLines[0].length,
        _pixelToCmRatio!,
        _preferredUnit,
      );
      final height = _measurementLines.length >= 2
          ? AIMeasurementService.pixelsToUserUnit(
              _measurementLines[1].length,
              _pixelToCmRatio!,
              _preferredUnit,
            )
          : 0.0;

      setState(() => _isSaving = true);

      try {
        // --- THIS IS THE FIX ---
        // Pass the required 'unit' parameter to the service.
        await MeasurementService.saveMeasurement(
          width: width,
          height: height,
          unit: _preferredUnit, // <-- FIX: Provide the measurement unit
          notes: 'AI-assisted measurement',
        );
        // -------------------------

        widget.onMeasurementsEntered?.call(width, height);

        if (mounted) {
          _showSuccessDialog(width, height);
        }
      } catch (e) {
        if (mounted) {
          _showErrorDialog(e.toString(), width, height);
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  // --- The rest of the file remains the same as the previous version ---
  // (build, _showSuccessDialog, _showErrorDialog, navigation, etc.)
  @override
  Widget build(BuildContext context) {
    const Color primaryRed = ThemeConfig.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('AI-Assisted Measurement'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildProgressIndicator(primaryRed),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ReferenceSelectionStep(
                        selectedReference: _selectedReference,
                        onReferenceChanged: (value) =>
                            setState(() => _selectedReference = value!)),
                    CaptureStep(
                        selectedReference: _selectedReference,
                        capturedImage: _capturedImage,
                        onTakePhoto: _takePhoto,
                        onRetakePhoto: _retakePhoto),
                    DetectionStep(
                      gestureDetectorKey: _gestureDetectorKey,
                      isProcessing: _isProcessing,
                      errorMessage: _errorMessage,
                      capturedImage: _capturedImage,
                      imageInfo: _imageInfo,
                      detectedRectangles: _detectedRectangles,
                      selectedReferenceRect: _selectedReferenceRect,
                      manualSelectionStart: _manualSelectionStart,
                      manualSelectionCurrent: _manualSelectionCurrent,
                      onDetectReference: _detectReference,
                      onImageTap: _onImageTap,
                      onManualSelectionStart: _onManualSelectionStart,
                      onManualSelectionUpdate: _onManualSelectionUpdate,
                      onManualSelectionEnd: _onManualSelectionEnd,
                      onClearManualSelectionError: () =>
                          setState(() => _errorMessage = null),
                    ),
                    MeasurementStep(
                      gestureDetectorKey: _gestureDetectorKey,
                      imageInfo: _imageInfo,
                      capturedImage: _capturedImage,
                      pixelToCmRatio: _pixelToCmRatio,
                      measurementLines: _measurementLines,
                      previewLine: _previewLine,
                      onDrawMeasurementStart: _onDrawMeasurementStart,
                      onDrawMeasurementUpdate: _onDrawMeasurementUpdate,
                      onDrawMeasurementEnd: _onDrawMeasurementEnd,
                      onClearMeasurements: _clearMeasurements,
                    ),
                    ResultsStep(
                      measurementLines: _measurementLines,
                      pixelToCmRatio: _pixelToCmRatio,
                      onSubmitMeasurements: _submitMeasurements,
                      preferredUnit: _preferredUnit,
                    ),
                  ],
                ),
              ),
              _buildNavigationButtons(primaryRed),
            ],
          ),
          if (_isSaving)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Saving measurement...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // (All other methods like _buildProgressIndicator, _loadImage, etc., are unchanged)
  Widget _buildProgressIndicator(Color primaryRed) {
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
                color: isCompleted
                    ? Colors.green
                    : isActive
                        ? primaryRed
                        : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationButtons(Color primaryRed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, -2))
          ]),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
                child:
                    OutlinedButton(onPressed: _previousStep, child: const Text('Previous'))),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade400),
              child: Text(
                  _currentStep == _stepTitles.length - 1 ? 'Finish' : 'Next'),
            ),
          ),
        ],
      ),
    );
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

  void _resetStateForNewImage() {
    setState(() {
      _imageInfo = null;
      _detectedRectangles.clear();
      _selectedReferenceRect = null;
      _measurementLines.clear();
      _pixelToCmRatio = null;
      _manualSelectionStart = null;
      _manualSelectionCurrent = null;
      _errorMessage = null;
    });
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);

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

    final rectangles =
        await AIMeasurementService.detectRectangles(_capturedImage!.path);

    setState(() {
      _detectedRectangles = rectangles;
      if (rectangles.isEmpty) {
        _errorMessage =
            'No objects detected. Try adjusting lighting or switch to manual selection.';
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
      return Offset(
          tapPosition.dx / scale, (tapPosition.dy - blankHeight) / scale);
    } else {
      final double scale = widgetSize.height / image.height;
      final double blankWidth = (widgetSize.width - image.width * scale) / 2;
      return Offset(
          (tapPosition.dx - blankWidth) / scale, tapPosition.dy / scale);
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
      if (AIMeasurementService.isValidReferenceObject(
          tappedRect, _selectedReference)) {
        setState(() {
          _selectedReferenceRect = tappedRect;
          _pixelToCmRatio = AIMeasurementService.calculatePixelToCmRatio(
              tappedRect!, _selectedReference);
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage =
              "The selected object's shape doesn't match a ${_selectedReference.name}.";
          _selectedReferenceRect = null;
          _pixelToCmRatio = null;
        });
      }
    }
  }

  void _onManualSelectionStart(DragStartDetails details) {
    if (_imageInfo == null) return;
    final RenderBox renderBox =
        _gestureDetectorKey.currentContext!.findRenderObject() as RenderBox;
    final widgetSize = renderBox.size;
    final scaledTap = _scaleTap(details.localPosition, widgetSize, _imageInfo!);
    setState(() {
      _selectedReferenceRect = null;
      _pixelToCmRatio = null;
      _manualSelectionStart = scaledTap;
      _manualSelectionCurrent = scaledTap;
      _errorMessage = null;
    });
  }

  void _onManualSelectionUpdate(DragUpdateDetails details) {
    if (_imageInfo == null || _manualSelectionStart == null) return;
    final RenderBox renderBox =
        _gestureDetectorKey.currentContext!.findRenderObject() as RenderBox;
    final widgetSize = renderBox.size;
    final scaledTap = _scaleTap(details.localPosition, widgetSize, _imageInfo!);
    setState(() => _manualSelectionCurrent = scaledTap);
  }

  void _onManualSelectionEnd(DragEndDetails details) {
    if (_manualSelectionStart != null && _manualSelectionCurrent != null) {
      final rect =
          Rect.fromPoints(_manualSelectionStart!, _manualSelectionCurrent!);

      setState(() {
        _manualSelectionStart = null;
        _manualSelectionCurrent = null;

        if (AIMeasurementService.isValidReferenceObject(
            rect, _selectedReference)) {
          _selectedReferenceRect = rect;
          _pixelToCmRatio = AIMeasurementService.calculatePixelToCmRatio(
              rect, _selectedReference);
          _errorMessage = null;
        } else {
          _errorMessage =
              "The drawn box's shape doesn't match a ${_selectedReference.name}. Please try again.";
          _selectedReferenceRect = null;
        }
      });
    }
  }

  void _onDrawMeasurementStart(DragStartDetails details) {
    if (_imageInfo == null) return;
    final RenderBox renderBox =
        _gestureDetectorKey.currentContext!.findRenderObject() as RenderBox;
    final widgetSize = renderBox.size;
    final scaledTap = _scaleTap(details.localPosition, widgetSize, _imageInfo!);
    final startPoint = MeasurementPoint(scaledTap.dx, scaledTap.dy);
    setState(() => _previewLine = MeasurementLine(startPoint, startPoint, '...'));
  }

  void _onDrawMeasurementUpdate(DragUpdateDetails details) {
    if (_imageInfo == null || _previewLine == null) return;
    final RenderBox renderBox =
        _gestureDetectorKey.currentContext!.findRenderObject() as RenderBox;
    final widgetSize = renderBox.size;
    final scaledTap = _scaleTap(details.localPosition, widgetSize, _imageInfo!);
    final endPoint = MeasurementPoint(scaledTap.dx, scaledTap.dy);
    setState(() =>
        _previewLine = MeasurementLine(_previewLine!.start, endPoint, '...'));
  }

  void _onDrawMeasurementEnd(DragEndDetails details) {
    if (_previewLine != null && _previewLine!.length > 10) {
      final lineNumber = _measurementLines.length;
      final label = lineNumber == 0
          ? 'Width'
          : lineNumber == 1
              ? 'Height'
              : 'Line ${lineNumber + 1}';
      setState(() {
        _measurementLines.add(
            MeasurementLine(_previewLine!.start, _previewLine!.end, label));
        _previewLine = null;
      });
    } else {
      setState(() => _previewLine = null);
    }
  }

  void _clearMeasurements() => setState(() => _measurementLines.clear());

  void _showSuccessDialog(double width, double height) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Measurement Saved'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your measurement has been saved successfully!'),
            const SizedBox(height: 16),
            Text('Width: ${MeasurementUtils.formatWithUnit(width, _preferredUnit)}'),
            if (height > 0)
              Text('Height: ${MeasurementUtils.formatWithUnit(height, _preferredUnit)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pop(context); 
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error, double width, double height) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Failed'),
        content: Text('Failed to save measurement: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitMeasurements(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
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
      if (_currentStep == 3 && _measurementLines.isNotEmpty && _pixelToCmRatio != null) {
        final widthInMeters = AIMeasurementService.pixelsToMeters(_measurementLines[0].length, _pixelToCmRatio!);
        setState(() {
          _preferredUnit = MeasurementUtils.getRecommendedUnit(widthInMeters);
        });
      }

      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    } else {
      _submitMeasurements();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    }
  }
}
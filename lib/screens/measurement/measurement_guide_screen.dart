import 'package:flutter/material.dart';
import '../../models/measurement_result.dart';

class MeasurementGuideScreen extends StatefulWidget {
  const MeasurementGuideScreen({super.key});

  @override
  State<MeasurementGuideScreen> createState() => _MeasurementGuideScreenState();
}

class _MeasurementGuideScreenState extends State<MeasurementGuideScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  
  int _currentPage = 0;
  MeasurementUnit _selectedUnit = MeasurementUnit.meters;

  static const Color primaryRed = Color.fromARGB(255, 158, 19, 17);

  final List<GuideStep> _guideSteps = [
    GuideStep(
      title: 'Welcome to Window Measurement',
      description: 'This guide will help you accurately measure your window dimensions for the perfect curtain fit.',
      imagePath: 'lib/asset/measurement_guide/measurement_step1.png',
      tips: ['Get a measuring tape or ruler', 'Ensure good lighting', 'Have someone help if needed'],
    ),
    GuideStep(
      title: 'Measure Window Width',
      description: 'Measure the width of your window frame from the inside edges.',
      imagePath: 'lib/asset/measurement_guide/measurement_step2.png',
      tips: [
        'Measure at the top, middle, and bottom',
        'Use the smallest measurement',
        'Measure inside the window frame',
        'Round down to the nearest centimeter'
      ],
    ),
    GuideStep(
      title: 'Measure Window Height',
      description: 'Measure the height of your window frame from top to bottom.',
      imagePath: 'lib/asset/measurement_guide/measurement_step3.png',
      tips: [
        'Measure on both left and right sides',
        'Use the smallest measurement',
        'Measure from top of frame to sill',
        'Include any trim or molding'
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _guideSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showManualInputDialog();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showManualInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Enter Measurements'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Unit: '),
                      DropdownButton<MeasurementUnit>(
                        value: _selectedUnit,
                        onChanged: (MeasurementUnit? newValue) {
                          if (newValue != null) {
                            setDialogState(() {
                              _selectedUnit = newValue;
                            });
                          }
                        },
                        items: MeasurementUnit.values.map((unit) {
                          return DropdownMenuItem<MeasurementUnit>(
                            value: unit,
                            child: Text(unit == MeasurementUnit.meters ? 'Meters' : 'Inches'),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _widthController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Width (${_selectedUnit == MeasurementUnit.meters ? 'm' : 'in'})',
                      border: const OutlineInputBorder(),
                      hintText: 'Enter window width',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Height (${_selectedUnit == MeasurementUnit.meters ? 'm' : 'in'})',
                      border: const OutlineInputBorder(),
                      hintText: 'Enter window height',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => _saveMeasurement(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveMeasurement(BuildContext dialogContext) {
    final widthText = _widthController.text.trim();
    final heightText = _heightController.text.trim();

    if (widthText.isEmpty || heightText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both width and height')),
      );
      return;
    }

    final width = double.tryParse(widthText);
    final height = double.tryParse(heightText);

    if (width == null || height == null || width <= 0 || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid positive numbers')),
      );
      return;
    }

    // Convert to meters if necessary
    final widthInMeters = _selectedUnit == MeasurementUnit.meters 
        ? width 
        : width / 39.3701;
    final heightInMeters = _selectedUnit == MeasurementUnit.meters 
        ? height 
        : height / 39.3701;

    // Create measurement result
    final result = MeasurementResult(
      windowCorners: [], // No corners for manual measurement
      widthInMeters: widthInMeters,
      heightInMeters: heightInMeters,
      timestamp: DateTime.now(),
      preferredUnit: _selectedUnit,
    );

    // Close dialog and return result
    Navigator.of(dialogContext).pop();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Measurement Guide'),
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(_guideSteps.length, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < _guideSteps.length - 1 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: index <= _currentPage ? primaryRed : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemCount: _guideSteps.length,
              itemBuilder: (context, index) {
                final step = _guideSteps[index];
                return _buildGuideStep(step);
              },
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: _previousPage,
                    child: const Text('Previous'),
                  )
                else
                  const SizedBox(width: 80),
                
                Text(
                  '${_currentPage + 1} of ${_guideSteps.length}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),

                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_currentPage < _guideSteps.length - 1 ? 'Next' : 'Enter Measurements'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(GuideStep step) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryRed,
            ),
          ),
          const SizedBox(height: 16),

          // Image
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                step.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.straighten, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Measurement Guide Image',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Description
          Text(
            step.description,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),

          // Tips
          const Text(
            'Tips:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...step.tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: primaryRed, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class GuideStep {
  final String title;
  final String description;
  final String imagePath;
  final List<String> tips;

  GuideStep({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.tips,
  });
}
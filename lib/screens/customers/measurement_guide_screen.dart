import 'package:flutter/material.dart';
import '../../utils/measurement_utils.dart';

class MeasurementGuideScreen extends StatefulWidget {
  final Function(double width, double height)? onMeasurementsEntered;

  const MeasurementGuideScreen({
    super.key,
    this.onMeasurementsEntered,
  });

  @override
  State<MeasurementGuideScreen> createState() => _MeasurementGuideScreenState();
}

class _MeasurementGuideScreenState extends State<MeasurementGuideScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  
  int _currentPage = 0;
  MeasurementUnit _selectedUnit = MeasurementUnit.meters;
  String? _validationError;

  static const Color primaryRed = Color.fromARGB(255, 158, 19, 17);

  final List<MeasurementStep> _measurementSteps = [
    MeasurementStep(
      title: 'Prepare Your Tools',
      description: 'You\'ll need a measuring tape or ruler for accurate measurements.',
      imagePath: null, // Will use icon instead
      tips: [
        'Use a metal measuring tape for best accuracy',
        'Have someone help you hold the tape steady',
        'Ensure the tape is straight and not sagging',
      ],
    ),
    MeasurementStep(
      title: 'Measure Window Width',
      description: 'Measure the width of your window from the inside edge of the frame.',
      imagePath: null, // Will use icon instead
      tips: [
        'Measure at the top, middle, and bottom',
        'Use the smallest measurement to ensure proper fit',
        'Include the window frame in your measurement',
      ],
    ),
    MeasurementStep(
      title: 'Measure Window Height',
      description: 'Measure the height from the top to the bottom of the window frame.',
      imagePath: null, // Will use icon instead
      tips: [
        'Measure at the left, center, and right sides',
        'Use the smallest measurement for proper fit',
        'Measure from frame to frame, not glass to glass',
      ],
    ),
    MeasurementStep(
      title: 'Record Your Measurements',
      description: 'Enter your measurements below and double-check for accuracy.',
      imagePath: null, // Will use icon instead
      tips: [
        'Round to the nearest centimeter or 1/8 inch',
        'Double-check your measurements before proceeding',
        'Consider adding 2-4 inches for overlap if desired',
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
    if (_currentPage < _measurementSteps.length - 1) {
      setState(() => _currentPage++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _validateAndSubmit() {
    setState(() => _validationError = null);

    final widthText = _widthController.text.trim();
    final heightText = _heightController.text.trim();

    if (widthText.isEmpty || heightText.isEmpty) {
      setState(() => _validationError = 'Please enter both width and height measurements');
      return;
    }

    final width = double.tryParse(widthText);
    final height = double.tryParse(heightText);

    if (width == null || height == null) {
      setState(() => _validationError = 'Please enter valid numbers for measurements');
      return;
    }

    if (width <= 0 || height <= 0) {
      setState(() => _validationError = 'Measurements must be greater than zero');
      return;
    }

    // Validate realistic measurements
    if (!MeasurementUtils.isRealisticWindowMeasurement(width, height, _selectedUnit)) {
      setState(() => _validationError = 'These measurements seem unrealistic for a window. Please double-check.');
      return;
    }

    // Check for warnings
    final warning = MeasurementUtils.getMeasurementWarning(width, height, _selectedUnit);
    if (warning != null) {
      _showWarningDialog(width, height, warning);
      return;
    }

    _submitMeasurements(width, height);
  }

  void _showWarningDialog(double width, double height, String warning) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Measurement Warning'),
        content: Text(warning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Review'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitMeasurements(width, height);
            },
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  void _submitMeasurements(double width, double height) {
    if (widget.onMeasurementsEntered != null) {
      // Convert to storage format (centimeters)
      final widthCm = MeasurementUtils.toStorageUnit(width, _selectedUnit);
      final heightCm = MeasurementUtils.toStorageUnit(height, _selectedUnit);
      widget.onMeasurementsEntered!(widthCm, heightCm);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Window Measurement Guide'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          // Main content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _measurementSteps.length,
              itemBuilder: (context, index) {
                if (index == _measurementSteps.length - 1) {
                  return _buildMeasurementInputPage();
                } else {
                  return _buildGuidePage(_measurementSteps[index]);
                }
              },
            ),
          ),
          
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(_measurementSteps.length, (index) {
          final isActive = index <= _currentPage;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? primaryRed : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGuidePage(MeasurementStep step) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Placeholder for measurement illustration
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(
              Icons.image_outlined,
              size: 64,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Tips:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryRed,
            ),
          ),
          const SizedBox(height: 12),
          
          ...step.tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 20,
                  color: primaryRed,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMeasurementInputPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Your Measurements',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          // Unit selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Measurement Unit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<MeasurementUnit>(
                        title: const Text('Meters'),
                        value: MeasurementUnit.meters,
                        groupValue: _selectedUnit,
                        activeColor: primaryRed,
                        onChanged: (value) => setState(() => _selectedUnit = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<MeasurementUnit>(
                        title: const Text('Inches'),
                        value: MeasurementUnit.inches,
                        groupValue: _selectedUnit,
                        activeColor: primaryRed,
                        onChanged: (value) => setState(() => _selectedUnit = value!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Width input
          _buildMeasurementInput(
            'Window Width',
            _widthController,
            'Enter width in ${_selectedUnit == MeasurementUnit.meters ? 'meters' : 'inches'}',
          ),
          const SizedBox(height: 16),
          
          // Height input
          _buildMeasurementInput(
            'Window Height',
            _heightController,
            'Enter height in ${_selectedUnit == MeasurementUnit.meters ? 'meters' : 'inches'}',
          ),
          
          if (_validationError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _validationError!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeasurementInput(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: primaryRed),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryRed),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Previous'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentPage == _measurementSteps.length - 1
                  ? _validateAndSubmit
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_currentPage == _measurementSteps.length - 1 ? 'Submit' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}

class MeasurementStep {
  final String title;
  final String description;
  final String? imagePath;
  final List<String> tips;

  MeasurementStep({
    required this.title,
    required this.description,
    this.imagePath,
    required this.tips,
  });
}
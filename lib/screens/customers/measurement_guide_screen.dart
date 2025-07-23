import 'package:flutter/material.dart';

// ASSUMPTION: You have these files in your project. Adjust the path if needed.
import '../../utils/measurement_utils.dart'; // Contains MeasurementUnit, utils
import 'ai_measurement_screen.dart';       // Contains AIMeasurementScreen

// -----------------------------------------------------------------------------
// SCREEN 1: The Main Selection Hub
// This screen allows the user to choose between AI and Manual measurement.
// -----------------------------------------------------------------------------
class MeasurementMethodSelectionScreen extends StatelessWidget {
  final Function(double width, double height)? onMeasurementsEntered;

  const MeasurementMethodSelectionScreen({
    super.key,
    this.onMeasurementsEntered,
  });

  static const Color primaryRed = Color.fromARGB(255, 158, 19, 17);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Window Measurement'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Your Measurement Method',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select the method that works best for you:',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            
            // AI Measurement Option
            _buildMeasurementMethodCard(
              context: context,
              icon: Icons.camera_alt,
              title: 'AI-Assisted Measurement',
              subtitle: 'Use your camera for quick, accurate results',
              badge: 'NEW',
              onTap: () => _openAIMeasurement(context),
              isRecommended: true,
            ),
            
            const SizedBox(height: 16),
            
            // Manual Measurement Option
            _buildMeasurementMethodCard(
              context: context,
              icon: Icons.straighten,
              title: 'Manual Measurement',
              subtitle: 'Follow our guide using a measuring tape',
              onTap: () => _openManualMeasurement(context),
            ),
            
            const SizedBox(height: 32),
            
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementMethodCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
    bool isRecommended = false,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isRecommended 
                ? Border.all(color: primaryRed, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: primaryRed),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Why accurate measurements matter:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text('• Ensures a perfect fit for your windows'),
          Text('• Reduces the need for returns or exchanges'),
          Text('• Saves time and provides better results'),
        ],
      ),
    );
  }

  void _openAIMeasurement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AIMeasurementScreen(
          onMeasurementsEntered: onMeasurementsEntered,
        ),
      ),
    );
  }

  void _openManualMeasurement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManualMeasurementGuideScreen(
          onMeasurementsEntered: onMeasurementsEntered,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SCREEN 2: The Step-by-Step Manual Measurement Guide
// This is the detailed PageView guide for taking measurements with a tape.
// -----------------------------------------------------------------------------
class ManualMeasurementGuideScreen extends StatefulWidget {
  final Function(double width, double height)? onMeasurementsEntered;

  const ManualMeasurementGuideScreen({
    super.key,
    this.onMeasurementsEntered,
  });

  @override
  State<ManualMeasurementGuideScreen> createState() => _ManualMeasurementGuideScreenState();
}

class _ManualMeasurementGuideScreenState extends State<ManualMeasurementGuideScreen> {
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
      tips: [
        'Use a metal measuring tape for best accuracy.',
        'Have someone help you hold the tape steady.',
        'Ensure the tape is straight and not sagging.',
      ],
    ),
    MeasurementStep(
      title: 'Measure Window Width',
      description: 'Measure the width of your window from the inside edge of the frame to the other.',
      tips: [
        'Measure at the top, middle, and bottom.',
        'Use the smallest measurement to ensure a proper fit.',
        'Include the window frame in your measurement.',
      ],
    ),
    MeasurementStep(
      title: 'Measure Window Height',
      description: 'Measure the height from the top to the bottom of the window frame.',
      tips: [
        'Measure at the left, center, and right sides.',
        'Use the smallest measurement for a proper fit.',
        'Measure from frame to frame, not glass to glass.',
      ],
    ),
    MeasurementStep(
      title: 'Record Your Measurements',
      description: 'Enter your measurements below and double-check for accuracy.',
      tips: [
        'Round to the nearest centimeter or 1/8 inch.',
        'Double-check your measurements before proceeding.',
        'Consider adding extra length for the curtain rod placement.',
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
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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

  void _validateAndSubmit() {
    setState(() => _validationError = null);

    final widthText = _widthController.text.trim();
    final heightText = _heightController.text.trim();

    if (widthText.isEmpty || heightText.isEmpty) {
      setState(() => _validationError = 'Please enter both width and height.');
      return;
    }

    final width = double.tryParse(widthText);
    final height = double.tryParse(heightText);

    if (width == null || height == null) {
      setState(() => _validationError = 'Please enter valid numbers.');
      return;
    }

    if (width <= 0 || height <= 0) {
      setState(() => _validationError = 'Measurements must be greater than zero.');
      return;
    }

    if (!MeasurementUtils.isRealisticWindowMeasurement(width, height, _selectedUnit)) {
      setState(() => _validationError = 'These measurements seem unrealistic. Please double-check.');
      return;
    }

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
      final widthCm = MeasurementUtils.toStorageUnit(width, _selectedUnit);
      final heightCm = MeasurementUtils.toStorageUnit(height, _selectedUnit);
      widget.onMeasurementsEntered!(widthCm, heightCm);
    }
    // Pop twice to return from the guide and the selection screen
    // Or adjust based on your desired navigation flow
    int popCount = 0;
    Navigator.of(context).popUntil((_) => popCount++ >= 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Manual Measurement Guide'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _measurementSteps.length,
              itemBuilder: (context, index) {
                return (index == _measurementSteps.length - 1)
                  ? _buildMeasurementInputPage()
                  : _buildGuidePage(_measurementSteps[index]);
              },
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }
  
  // All the _build... helper widgets from your second file go here
  // (_buildProgressIndicator, _buildGuidePage, _buildMeasurementInputPage, etc.)
  
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(_measurementSteps.length, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index <= _currentPage ? primaryRed : Colors.grey.shade300,
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
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Icon(Icons.straighten_outlined, size: 64, color: Colors.grey)),
          ),
          const SizedBox(height: 20),
          Text(step.description, style: const TextStyle(fontSize: 16, height: 1.5)),
          const SizedBox(height: 24),
          const Text('Tips:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryRed)),
          const SizedBox(height: 12),
          ...step.tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 20, color: primaryRed),
                const SizedBox(width: 12),
                Expanded(child: Text(tip, style: const TextStyle(fontSize: 14, height: 1.4))),
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
          const Text('Enter Your Measurements', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
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
                const Text('Measurement Unit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: RadioListTile<MeasurementUnit>(title: const Text('Meters'), value: MeasurementUnit.meters, groupValue: _selectedUnit, activeColor: primaryRed, onChanged: (v) => setState(() => _selectedUnit = v!))),
                    Expanded(child: RadioListTile<MeasurementUnit>(title: const Text('Inches'), value: MeasurementUnit.inches, groupValue: _selectedUnit, activeColor: primaryRed, onChanged: (v) => setState(() => _selectedUnit = v!))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildMeasurementInput('Window Width', _widthController, 'e.g., 1.5 for meters, 60 for inches'),
          const SizedBox(height: 16),
          _buildMeasurementInput('Window Height', _heightController, 'e.g., 2.1 for meters, 84 for inches'),
          if (_validationError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_validationError!, style: TextStyle(color: Colors.red.shade700))),
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
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryRed)),
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
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, -2))],
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
              onPressed: _currentPage == _measurementSteps.length - 1 ? _validateAndSubmit : _nextPage,
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

// -----------------------------------------------------------------------------
// HELPER MODEL CLASS for the Manual Guide
// -----------------------------------------------------------------------------
class MeasurementStep {
  final String title;
  final String description;
  final List<String> tips;

  MeasurementStep({
    required this.title,
    required this.description,
    required this.tips,
  });
}
// lib/screens/customers/manual_measurement_screen.dart

import 'package:flutter/material.dart';
import '../../utils/measurement_utils.dart';
import 'ai_measurement_screen.dart';
import '../../services/measurement.dart';
import '../../config/theme_config.dart';

// --- MeasurementMethodSelectionScreen remains the same ---
class MeasurementMethodSelectionScreen extends StatelessWidget {
  final Function(double width, double height)? onMeasurementsEntered;

  const MeasurementMethodSelectionScreen({
    super.key,
    this.onMeasurementsEntered,
  });

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
                fontSize: 28,
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
            _buildMeasurementMethodCard(
              context: context,
              icon: Icons.camera_alt_outlined,
              title: 'AI-Assisted Measurement',
              subtitle: 'Use your camera for quick, accurate results',
              onTap: () => _openAIMeasurement(context),
              isRecommended: true,
            ),
            const SizedBox(height: 16),
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isRecommended
                ? Border.all(color: ThemeConfig.primaryColor, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ThemeConfig.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: ThemeConfig.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
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
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.grey, size: 16),
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

// --- ManualMeasurementGuideScreen starts here ---
class ManualMeasurementGuideScreen extends StatefulWidget {
  final Function(double width, double height)? onMeasurementsEntered;

  const ManualMeasurementGuideScreen({
    super.key,
    this.onMeasurementsEntered,
  });

  @override
  State<ManualMeasurementGuideScreen> createState() =>
      _ManualMeasurementGuideScreenState();
}

class _ManualMeasurementGuideScreenState
    extends State<ManualMeasurementGuideScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _currentPage = 0;
  MeasurementUnit _selectedUnit = MeasurementUnit.meters;
  bool _isSaving = false;

  final List<MeasurementStep> _measurementSteps = [
    MeasurementStep(
      title: 'Prepare Your Tools',
      description:
          'You\'ll need a measuring tape or ruler for accurate measurements.',
      tips: [
        'Use a metal measuring tape for best accuracy.',
        'Have someone help you hold the tape steady.',
        'Ensure the tape is straight and not sagging.',
      ],
      imageAsset: 'asset/measure_tape.png',
    ),
    MeasurementStep(
      title: 'Measure Window Width',
      description:
          'Measure the width of your window from the inside edge of the frame to the other.',
      tips: [
        'Measure at the top, middle, and bottom.',
        'Use the smallest measurement to ensure a proper fit.',
        'Include the window frame in your measurement.',
      ],
      imageAsset: 'asset/Width.png',
    ),
    MeasurementStep(
      title: 'Measure Window Height',
      description:
          'Measure the height from the top to the bottom of the window frame.',
      tips: [
        'Measure at the left, center, and right sides.',
        'Use the smallest measurement for a proper fit.',
        'Measure from frame to frame, not glass to glass.',
      ],
      imageAsset: 'asset/Height.png',
    ),
    MeasurementStep(
      title: 'Record Your Measurements',
      description:
          'Enter your measurements below and double-check for accuracy.',
      tips: [
        'Round to the nearest centimeter or 1/8 inch.',
        'Double-check your measurements before proceeding.',
        'Consider adding extra length for the curtain rod placement.',
      ],
      // This asset path is now unused by the UI but kept for model consistency
      imageAsset: 'asset/guide_step4_record.png',
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final width = double.tryParse(_widthController.text.trim());
    final height = double.tryParse(_heightController.text.trim());

    if (width == null || height == null) {
      return;
    }

    final warning =
        MeasurementUtils.getMeasurementWarning(width, height, _selectedUnit);
    if (warning != null) {
      _showWarningDialog(width, height, warning);
      return;
    }

    _submitMeasurements(width, height);
  }

  void _submitMeasurements(double width, double height) async {
    setState(() => _isSaving = true);
    try {
      await MeasurementService.saveMeasurement(
        width: width,
        height: height,
        unit: _selectedUnit,
        notes: 'Manual measurement',
      );

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
            Text(
                'Width: ${MeasurementUtils.formatWithUnit(width, _selectedUnit)}'),
            Text(
                'Height: ${MeasurementUtils.formatWithUnit(height, _selectedUnit)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              int popCount = 0;
              Navigator.of(context).popUntil((_) => popCount++ >= 2);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
              _submitMeasurements(width, height);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
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
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemCount: _measurementSteps.length,
              itemBuilder: (context, index) {
                final step = _measurementSteps[index];
                return index == _measurementSteps.length - 1
                    ? _buildMeasurementInputPage(step)
                    : _buildGuidePage(step);
              },
            ),
          ),
        ],
      ),
      bottomSheet: _buildNavigationButtons(),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(_measurementSteps.length, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(
                  right: index < _measurementSteps.length - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color:
                    index <= _currentPage ? ThemeConfig.primaryColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGuidePage(MeasurementStep step) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      children: [
        Text(
          step.title,
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87),
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            step.imageAsset,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(step.description,
            style: const TextStyle(fontSize: 16, height: 1.5)),
        const SizedBox(height: 24),
        const Text('Tips:',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: ThemeConfig.primaryColor)),
        const SizedBox(height: 12),
        ...step.tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, size: 22, color: ThemeConfig.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(tip,
                          style:
                              const TextStyle(fontSize: 15, height: 1.4))),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildMeasurementInputPage(MeasurementStep step) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
        children: [
          Text(step.title,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 24),
          // --- IMAGE BOX REMOVED FROM THIS PAGE ---
          Text(step.description,
              style: const TextStyle(fontSize: 16, height: 1.5)),
          const SizedBox(height: 24),
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
                const Text('Measurement Unit',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                        child: RadioListTile<MeasurementUnit>(
                            title: const Text('Meters'),
                            contentPadding: EdgeInsets.zero,
                            value: MeasurementUnit.meters,
                            groupValue: _selectedUnit,
                            activeColor: ThemeConfig.primaryColor,
                            onChanged: (v) =>
                                setState(() => _selectedUnit = v!))),
                    Expanded(
                        child: RadioListTile<MeasurementUnit>(
                            title: const Text('Inches'),
                            contentPadding: EdgeInsets.zero,
                            value: MeasurementUnit.inches,
                            groupValue: _selectedUnit,
                            activeColor: ThemeConfig.primaryColor,
                            onChanged: (v) =>
                                setState(() => _selectedUnit = v!))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildMeasurementInput('Window Width', _widthController),
          const SizedBox(height: 16),
          _buildMeasurementInput('Window Height', _heightController),
        ],
      ),
    );
  }

  Widget _buildMeasurementInput(
      String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              hintText: _selectedUnit == MeasurementUnit.meters
                  ? 'e.g., 1.5'
                  : 'e.g., 60',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: ThemeConfig.primaryColor, width: 2)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400))),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a value.';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeConfig.primaryColor,
                  side: const BorderSide(color: ThemeConfig.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Previous',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentPage == _measurementSteps.length - 1
                  ? (_isSaving ? null : _validateAndSubmit)
                  : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      _currentPage == _measurementSteps.length - 1
                          ? 'Submit'
                          : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper model class for the guide steps
class MeasurementStep {
  final String title;
  final String description;
  final List<String> tips;
  final String imageAsset;

  MeasurementStep({
    required this.title,
    required this.description,
    required this.tips,
    required this.imageAsset,
  });
}
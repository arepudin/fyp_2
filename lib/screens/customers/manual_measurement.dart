import 'package:flutter/material.dart';
import 'package:fyp_2/config/app_sizes.dart';
import 'package:fyp_2/config/app_strings.dart';
import 'package:fyp_2/utils/measurement_utils.dart';
import 'package:fyp_2/screens/customers/ai_measurement_screen.dart';
import 'package:fyp_2/services/measurement.dart';

class MeasurementMethodSelectionScreen extends StatelessWidget {
  final Function(double width, double height)? onMeasurementsEntered;

  const MeasurementMethodSelectionScreen({super.key, this.onMeasurementsEntered});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.windowMeasurementTitle)),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.chooseMethodTitle, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            gapH16,
            Text(AppStrings.chooseMethodSubtitle, style: textTheme.bodyLarge?.copyWith(color: Colors.black54)),
            gapH32,
            _buildMeasurementMethodCard(context: context, icon: Icons.camera_alt_outlined, title: AppStrings.aiMethodTitle, subtitle: AppStrings.aiMethodSubtitle, onTap: () => _openAIMeasurement(context), isRecommended: true),
            gapH16,
            _buildMeasurementMethodCard(context: context, icon: Icons.straighten, title: AppStrings.manualMethodTitle, subtitle: AppStrings.manualMethodSubtitle, onTap: () => _openManualMeasurement(context)),
            gapH32,
            _buildInfoCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementMethodCard({ required BuildContext context, required IconData icon, required String title, required String subtitle, required VoidCallback onTap, bool isRecommended = false}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.p16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.p16),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.p20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppSizes.p16), border: isRecommended ? Border.all(color: theme.colorScheme.primary, width: 2) : null),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.p12),
              decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSizes.p12)),
              child: Icon(icon, size: 32, color: theme.colorScheme.primary),
            ),
            gapW16,
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                gapH4,
                Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54)),
              ]),
            ),
            gapW8,
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ]),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(AppSizes.p12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          gapW8,
          Text(AppStrings.infoCardTitle, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        gapH8,
        const Text(AppStrings.infoCardPoint1),
        const Text(AppStrings.infoCardPoint2),
        const Text(AppStrings.infoCardPoint3),
      ]),
    );
  }

  void _openAIMeasurement(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AIMeasurementScreen(onMeasurementsEntered: onMeasurementsEntered)));
  }

  void _openManualMeasurement(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ManualMeasurementGuideScreen(onMeasurementsEntered: onMeasurementsEntered)));
  }
}

class ManualMeasurementGuideScreen extends StatefulWidget {
  final Function(double width, double height)? onMeasurementsEntered;
  const ManualMeasurementGuideScreen({super.key, this.onMeasurementsEntered});

  @override
  State<ManualMeasurementGuideScreen> createState() => _ManualMeasurementGuideScreenState();
}

class _ManualMeasurementGuideScreenState extends State<ManualMeasurementGuideScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _currentPage = 0;
  MeasurementUnit _selectedUnit = MeasurementUnit.meters;
  bool _isSaving = false;

  final List<MeasurementStep> _measurementSteps = [
    MeasurementStep(title: AppStrings.step1Title, description: AppStrings.step1Desc, tips: [AppStrings.step1Tip1, AppStrings.step1Tip2, AppStrings.step1Tip3], imageAsset: 'asset/measure_tape.png'),
    MeasurementStep(title: AppStrings.step2Title, description: AppStrings.step2Desc, tips: [AppStrings.step2Tip1, AppStrings.step2Tip2, AppStrings.step2Tip3], imageAsset: 'asset/Width.png'),
    MeasurementStep(title: AppStrings.step3Title, description: AppStrings.step3Desc, tips: [AppStrings.step3Tip1, AppStrings.step3Tip2, AppStrings.step3Tip3], imageAsset: 'asset/Height.png'),
    MeasurementStep(title: AppStrings.step4Title, description: AppStrings.step4Desc, tips: [AppStrings.step4Tip1, AppStrings.step4Tip2, AppStrings.step4Tip3], imageAsset: 'asset/guide_step4_record.png'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _navigatePage(bool next) {
    if (next && _currentPage < _measurementSteps.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else if (!next && _currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _validateAndSubmit() {
    if (!_formKey.currentState!.validate()) return;
    final width = double.tryParse(_widthController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    if (width == null || height == null) return;
    final warning = MeasurementUtils.getMeasurementWarning(width, height, _selectedUnit);
    if (warning != null) {
      _showWarningDialog(width, height, warning);
    } else {
      _submitMeasurements(width, height);
    }
  }

  Future<void> _submitMeasurements(double width, double height) async {
    setState(() => _isSaving = true);
    try {
      await MeasurementService.saveMeasurement(width: width, height: height, unit: _selectedUnit, notes: 'Manual measurement');
      widget.onMeasurementsEntered?.call(width, height);
      if (mounted) _showSuccessDialog(width, height);
    } catch (e) {
      if (mounted) _showErrorDialog(e.toString(), width, height);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessDialog(double width, double height) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text(AppStrings.savedDialogTitle),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(AppStrings.savedDialogContent),
        gapH16,
        Text('${AppStrings.labelWindowWidth}: ${MeasurementUtils.formatWithUnit(width, _selectedUnit)}'),
        Text('${AppStrings.labelWindowHeight}: ${MeasurementUtils.formatWithUnit(height, _selectedUnit)}'),
      ]),
      actions: [TextButton(onPressed: () {
        int popCount = 0;
        Navigator.of(context).popUntil((_) => popCount++ >= 2);
      }, child: const Text(AppStrings.ok))],
    ));
  }

  void _showWarningDialog(double width, double height, String warning) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text(AppStrings.warningDialogTitle),
      content: Text(warning),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.review)),
        TextButton(onPressed: () {
          Navigator.pop(context);
          _submitMeasurements(width, height);
        }, child: const Text(AppStrings.continueAnyway)),
      ],
    ));
  }

  void _showErrorDialog(String error, double width, double height) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text(AppStrings.errorDialogTitle),
      content: Text('${AppStrings.errorDialogContent}$error'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.buttonCancel)),
        TextButton(onPressed: () {
          Navigator.pop(context);
          _submitMeasurements(width, height);
        }, child: const Text(AppStrings.retry)),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.manualGuideTitle)),
      body: Column(children: [
        _buildProgressIndicator(),
        Expanded(child: PageView.builder(
          controller: _pageController,
          onPageChanged: (page) => setState(() => _currentPage = page),
          itemCount: _measurementSteps.length,
          itemBuilder: (context, index) {
            final step = _measurementSteps[index];
            return index == _measurementSteps.length - 1 ? _buildMeasurementInputPage(step) : _buildGuidePage(step);
          },
        )),
      ]),
      bottomSheet: _buildNavigationButtons(),
    );
  }

  Widget _buildProgressIndicator() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p16),
      child: Row(children: List.generate(_measurementSteps.length, (index) {
        return Expanded(child: Container(
          height: 4,
          margin: EdgeInsets.only(right: index < _measurementSteps.length - 1 ? AppSizes.p4 : 0),
          decoration: BoxDecoration(color: index <= _currentPage ? primaryColor : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
        ));
      })),
    );
  }

  Widget _buildGuidePage(MeasurementStep step) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final primaryColor = theme.colorScheme.primary;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSizes.p24, 0, AppSizes.p24, 100),
      children: [
        Text(step.title, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        gapH24,
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.p12),
          child: Image.asset(step.imageAsset, height: 200, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(height: 200, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 64, color: Colors.grey))),
          ),
        ),
        gapH24,
        Text(step.description, style: textTheme.bodyLarge?.copyWith(height: 1.5)),
        gapH24,
        Text(AppStrings.labelTips, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: primaryColor)),
        gapH12,
        ...step.tips.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.p10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.check_circle, size: 22, color: primaryColor),
            gapW12,
            Expanded(child: Text(tip, style: textTheme.bodyMedium?.copyWith(height: 1.4))),
          ]),
        )),
      ],
    );
  }

  Widget _buildMeasurementInputPage(MeasurementStep step) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final primaryColor = theme.colorScheme.primary;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSizes.p24, 0, AppSizes.p24, 100),
        children: [
          Text(step.title, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          gapH24,
          Text(step.description, style: textTheme.bodyLarge?.copyWith(height: 1.5)),
          gapH24,
          Container(
            padding: const EdgeInsets.all(AppSizes.p16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSizes.p12), border: Border.all(color: Colors.grey.shade300)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppStrings.labelUnit, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              gapH8,
              Row(children: [
                Expanded(child: RadioListTile<MeasurementUnit>(title: const Text(AppStrings.unitMeters), contentPadding: EdgeInsets.zero, value: MeasurementUnit.meters, groupValue: _selectedUnit, activeColor: primaryColor, onChanged: (v) => setState(() => _selectedUnit = v!))),
                Expanded(child: RadioListTile<MeasurementUnit>(title: const Text(AppStrings.unitInches), contentPadding: EdgeInsets.zero, value: MeasurementUnit.inches, groupValue: _selectedUnit, activeColor: primaryColor, onChanged: (v) => setState(() => _selectedUnit = v!))),
              ]),
            ]),
          ),
          const SizedBox(height: AppSizes.p20),
          _buildMeasurementInput(AppStrings.labelWindowWidth, _widthController),
          gapH16,
          _buildMeasurementInput(AppStrings.labelWindowHeight, _heightController),
        ],
      ),
    );
  }

  Widget _buildMeasurementInput(String label, TextEditingController controller) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      gapH8,
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(hintText: _selectedUnit == MeasurementUnit.meters ? AppStrings.hintMeters : AppStrings.hintInches),
        validator: (v) {
          if (v == null || v.isEmpty) return AppStrings.errorEnterValue;
          if (double.tryParse(v) == null) return AppStrings.errorValidNumber;
          return null;
        },
      ),
    ]);
  }

  Widget _buildNavigationButtons() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, -2))]),
      child: Row(children: [
        if (_currentPage > 0)
          Expanded(child: OutlinedButton(
            onPressed: () => _navigatePage(false),
            style: theme.outlinedButtonTheme.style?.copyWith(padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14))),
            child: const Text(AppStrings.previous),
          )),
        if (_currentPage > 0) gapW16,
        Expanded(child: ElevatedButton(
          onPressed: _currentPage == _measurementSteps.length - 1 ? (_isSaving ? null : _validateAndSubmit) : () => _navigatePage(true),
          style: theme.elevatedButtonTheme.style?.copyWith(padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14))),
          child: _isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_currentPage == _measurementSteps.length - 1 ? AppStrings.submit : AppStrings.next),
        )),
      ]),
    );
  }
}

class MeasurementStep {
  final String title;
  final String description;
  final List<String> tips;
  final String imageAsset;
  MeasurementStep({required this.title, required this.description, required this.tips, required this.imageAsset});
}
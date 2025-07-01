// lib/screens/curtain_preference_screen.dart

import 'package:flutter/material.dart';
import '../screens/recommendation_results.dart';
import '../constants/supabase.dart';

class CurtainPreferenceScreen extends StatefulWidget {
  const CurtainPreferenceScreen({super.key});

  @override
  State<CurtainPreferenceScreen> createState() =>
      _CurtainPreferenceScreenState();
}

class _CurtainPreferenceScreenState extends State<CurtainPreferenceScreen> {
  // State variables to hold user's choices
  String _selectedPattern = 'Solid';
  String _selectedMaterial = 'Cotton';
  String _selectedLightControl = 'Light Filtering';

  bool _isLoading = false;

  // Options for the selectors
  final List<String> _patterns = ['Solid', 'Floral', 'Geometric', 'Striped', 'Abstract'];
  final List<String> _materials = ['Cotton', 'Linen', 'Velvet', 'Sheer', 'Polyester'];
  final List<String> _lightControls = ['Blackout', 'Room Darkening', 'Light Filtering'];

  Future<void> _findMyCurtains() async {
    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('curtains')
          .select()
          .eq('in_stock', true);

      final List<dynamic> allCurtains = response as List;

      final userPreferences = {
        'design_pattern': _selectedPattern,
        'material': _selectedMaterial,
        'light_control': _selectedLightControl,
      };

      final scoredCurtains = allCurtains.map((curtain) {
        int score = 0;
        if (curtain['design_pattern'] == userPreferences['design_pattern']) score += 3;
        if (curtain['material'] == userPreferences['material']) score += 2;
        if (curtain['light_control'] == userPreferences['light_control']) score += 2;
        return {'score': score, 'data': curtain};
      }).toList();

      scoredCurtains.sort((a, b) => b['score'].compareTo(a['score']));

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecommendationResultsScreen(
              recommendations: scoredCurtains,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finding curtains: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryRed = Color.fromARGB(255, 158, 19, 17);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Design Your Curtain', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us your style.',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select one option from each category to find the perfect match.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 40),

            // --- Preference Selectors ---
            _PreferenceSelector(
              title: 'Design Pattern',
              options: _patterns,
              selectedValue: _selectedPattern,
              onSelected: (value) => setState(() => _selectedPattern = value),
            ),
            const SizedBox(height: 30),
            _PreferenceSelector(
              title: 'Material',
              options: _materials,
              selectedValue: _selectedMaterial,
              onSelected: (value) => setState(() => _selectedMaterial = value),
            ),
            const SizedBox(height: 30),
            _PreferenceSelector(
              title: 'Light Control',
              options: _lightControls,
              selectedValue: _selectedLightControl,
              onSelected: (value) => setState(() => _selectedLightControl = value),
            ),
            const SizedBox(height: 50),

            // --- Find Button ---
            ElevatedButton(
              onPressed: _isLoading ? null : _findMyCurtains,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                shadowColor: primaryRed.withOpacity(0.4),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'FIND MY CURTAINS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Widget for the "Pill" selectors
class _PreferenceSelector extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _PreferenceSelector({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const primaryRed = Color.fromARGB(255, 158, 19, 17);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((option) {
              final bool isSelected = selectedValue == option;
              return GestureDetector(
                onTap: () => onSelected(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryRed : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isSelected ? primaryRed : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: primaryRed.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ] : [],
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        )
      ],
    );
  }
}
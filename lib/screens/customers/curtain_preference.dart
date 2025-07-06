// lib/screens/curtain_preference_screen.dart

import 'package:flutter/material.dart';
import '../../constants/app_constant.dart'; // Import the new enum
import '../../models/curtain_model.dart';
import 'recommendation_results.dart';
import '../../constants/supabase.dart';

class ScoredRecommendation {
  final int score;
  final Curtain curtain;
  final int maxPossibleScore; // Keep this field, it's important

  ScoredRecommendation({
    required this.score,
    required this.curtain,
    required this.maxPossibleScore,
  });
}

class CurtainPreferenceScreen extends StatefulWidget {
  final Map<String, String>? initialPreferences;
   const CurtainPreferenceScreen({super.key, this.initialPreferences});

  @override
  State<CurtainPreferenceScreen> createState() =>
      _CurtainPreferenceScreenState();
}

class _CurtainPreferenceScreenState extends State<CurtainPreferenceScreen> {
  // --- State variables ---
  late String _selectedPattern;
  late String _selectedMaterial;
  late String _selectedLightControl;
  late String _selectedRoomType;
  late String _selectedStyle;
  bool _isLoading = false;

  // --- NEW: State for "Must-Haves" ---
  final Map<PreferenceCategory, bool> _mustHaves = {
    PreferenceCategory.pattern: false,
    PreferenceCategory.material: false,
    PreferenceCategory.lightControl: false,
    PreferenceCategory.roomType: false,
    PreferenceCategory.style: false,
  };

  // --- Preference Options ---
  final List<String> _patterns = ['Textured', 'Pebbled', 'Twill', 'Crackled', 'Striated', 'Dobby'];
  final List<String> _materials = ['Cotton', 'Linen', 'Velvet', 'Sheer', 'Polyester'];
  final List<String> _lightControls = ['Blackout', 'Room Darkening', 'Light Filtering'];
  final List<String> _roomTypes = ['Living Room', 'Bedroom', 'Kitchen', 'Office'];
  final List<String> _styles = ['Modern', 'Traditional', 'Minimalist'];

  @override
  void initState() {
    super.initState();
    final prefs = widget.initialPreferences;

    // Set defaults first
    _selectedPattern = _patterns.first;
    _selectedMaterial = _materials.first;
    _selectedLightControl = _lightControls.first;
    _selectedRoomType = _roomTypes.first;
    _selectedStyle = _styles.first;

    // If initial preferences were passed, override the defaults
    if (prefs != null) {
      _selectedPattern = prefs['design_pattern'] ?? _selectedPattern;
      _selectedMaterial = prefs['material'] ?? _selectedMaterial;
      _selectedLightControl = prefs['light_control'] ?? _selectedLightControl;
      _selectedRoomType = prefs['room_type'] ?? _selectedRoomType;
      _selectedStyle = prefs['style'] ?? _selectedStyle;
    }
  }
  
  Future<void> _findMyCurtains() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await supabase.from('curtains').select().eq('in_stock', true);
      final List<dynamic> allCurtainsData = response as List;
      final List<Curtain> allCurtains = allCurtainsData
          .map((data) => Curtain.fromMap(data as Map<String, dynamic>))
          .toList();

      final userPreferences = {
        'design_pattern': _selectedPattern,
        'material': _selectedMaterial,
        'light_control': _selectedLightControl,
        'room_type': _selectedRoomType,
        'style': _selectedStyle,
      };

      // Define weights for our scoring
      const int mustHaveScore = 10;
      const int regularScore = 2;
      
      // DYNAMICALLY calculate the maximum possible score based on selections
      final int maxPossibleScore = 
          (_mustHaves[PreferenceCategory.pattern]! ? mustHaveScore : regularScore) +
          (_mustHaves[PreferenceCategory.material]! ? mustHaveScore : regularScore) +
          (_mustHaves[PreferenceCategory.lightControl]! ? mustHaveScore : regularScore) +
          (_mustHaves[PreferenceCategory.roomType]! ? mustHaveScore : regularScore) +
          (_mustHaves[PreferenceCategory.style]! ? mustHaveScore : regularScore);

      final scoredCurtains = <ScoredRecommendation>[];

      for (final curtain in allCurtains) {
        int currentScore = 0;
        bool meetsAllMustHaves = true;

        // Check Pattern
        if (_mustHaves[PreferenceCategory.pattern]!) {
          if (curtain.designPattern != userPreferences['design_pattern']) {
            meetsAllMustHaves = false;
          } else {
            currentScore += mustHaveScore;
          }
        } else if (curtain.designPattern == userPreferences['design_pattern']) {
          currentScore += regularScore;
        }
        
        // ... (repeat for all other categories) ...
        if (_mustHaves[PreferenceCategory.material]!) {
          if (curtain.material != userPreferences['material']) {
            meetsAllMustHaves = false;
          } else {
            currentScore += mustHaveScore;
          }
        } else if (curtain.material == userPreferences['material']) {
          currentScore += regularScore;
        }

        if (_mustHaves[PreferenceCategory.lightControl]!) {
          if (curtain.lightControl != userPreferences['light_control']) {
            meetsAllMustHaves = false;
          } else {
            currentScore += mustHaveScore;
          }
        } else if (curtain.lightControl == userPreferences['light_control']) {
          currentScore += regularScore;
        }

        if (_mustHaves[PreferenceCategory.roomType]!) {
          if (curtain.roomType != userPreferences['room_type']) {
            meetsAllMustHaves = false;
          } else {
            currentScore += mustHaveScore;
          }
        } else if (curtain.roomType == userPreferences['room_type']) {
          currentScore += regularScore;
        }
        
        if (_mustHaves[PreferenceCategory.style]!) {
          if (curtain.style != userPreferences['style']) {
            meetsAllMustHaves = false;
          } else {
            currentScore += mustHaveScore;
          }
        } else if (curtain.style == userPreferences['style']) {
          currentScore += regularScore;
        }
        
        if (meetsAllMustHaves && currentScore > 0) {
          scoredCurtains.add(ScoredRecommendation(
            score: currentScore,
            curtain: curtain,
            maxPossibleScore: maxPossibleScore,
          ));
        }
      }

      scoredCurtains.sort((a, b) => b.score.compareTo(a.score));

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

  void _toggleMustHave(PreferenceCategory category) {
    setState(() {
      _mustHaves[category] = !_mustHaves[category]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    // UI part to build selectors...
    // (This part is long, so I'll show the changes)
    return Scaffold(
      appBar: AppBar(title: const Text('Design Your Curtain', style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tell us your style.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Select your preferences. Tap the star to mark a "Must-Have".', style: TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 40),

            _PreferenceSelector(
              title: 'Design Pattern',
              options: _patterns,
              selectedValue: _selectedPattern,
              onSelected: (value) => setState(() => _selectedPattern = value),
              isMustHave: _mustHaves[PreferenceCategory.pattern]!,
              onToggleMustHave: () => _toggleMustHave(PreferenceCategory.pattern),
            ),
            const SizedBox(height: 30),
            _PreferenceSelector(
              title: 'Material',
              options: _materials,
              selectedValue: _selectedMaterial,
              onSelected: (value) => setState(() => _selectedMaterial = value),
              isMustHave: _mustHaves[PreferenceCategory.material]!,
              onToggleMustHave: () => _toggleMustHave(PreferenceCategory.material),
            ),
            const SizedBox(height: 30),
            _PreferenceSelector(
              title: 'Light Control',
              options: _lightControls,
              selectedValue: _selectedLightControl,
              onSelected: (value) => setState(() => _selectedLightControl = value),
              isMustHave: _mustHaves[PreferenceCategory.lightControl]!,
              onToggleMustHave: () => _toggleMustHave(PreferenceCategory.lightControl),
            ),
            const SizedBox(height: 30),
            _PreferenceSelector(
              title: 'Room Type',
              options: _roomTypes,
              selectedValue: _selectedRoomType,
              onSelected: (value) => setState(() => _selectedRoomType = value),
              isMustHave: _mustHaves[PreferenceCategory.roomType]!,
              onToggleMustHave: () => _toggleMustHave(PreferenceCategory.roomType),
            ),
            const SizedBox(height: 30),
            _PreferenceSelector(
              title: 'Style',
              options: _styles,
              selectedValue: _selectedStyle,
              onSelected: (value) => setState(() => _selectedStyle = value),
              isMustHave: _mustHaves[PreferenceCategory.style]!,
              onToggleMustHave: () => _toggleMustHave(PreferenceCategory.style),
            ),
            const SizedBox(height: 50),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _findMyCurtains,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 158, 19, 17),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('FIND MY CURTAINS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceSelector extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;
  final bool isMustHave;
  final VoidCallback onToggleMustHave;

  const _PreferenceSelector({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    required this.isMustHave,
    required this.onToggleMustHave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            IconButton(
              icon: Icon(isMustHave ? Icons.star : Icons.star_border, color: isMustHave ? Colors.amber[600] : Colors.grey),
              onPressed: onToggleMustHave,
              tooltip: 'Mark as Must-Have',
            )
          ],
        ),
        const SizedBox(height: 4),
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
                    color: isSelected ? const Color.fromARGB(255, 158, 19, 17) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: isSelected ? const Color.fromARGB(255, 158, 19, 17) : Colors.grey.shade300, width: 1.5),
                  ),
                  child: Text(option, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
        )
      ],
    );
  }
}
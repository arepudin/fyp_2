// lib/screens/curtain_preference_screen.dart
import '../../config/theme_config.dart';

import 'package:flutter/material.dart';
import '../../models/curtain_model.dart';
import '../../models/recommendation_model.dart';
import '../../services/cbf_engine.dart';
import '../../services/user_interaction.dart';
import 'recommendation_results.dart';
import '../../constants/supabase.dart';

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
  bool _isLoading = false;



  // --- NEW: State for "Must-Haves" ---
  final Map<String, bool> _mustHaves = {
    'pattern': false,
    'material': false,
    'lightControl': false,
    'roomType': false,
  };

  // --- NEW: Category weights for content-based filtering ---
  final Map<String, double> _categoryWeights = {
    'pattern': 0.25,
    'material': 0.3,
    'lightControl': 0.3,
    'roomType': 0.15,
  };

  // --- Preference Options ---
  final List<String> _patterns = ['Stripes', 'Solid/Plain', 'Geometric', 'Floral', 'Damask', 'Polka Dots'];
  final List<String> _materials = ['Cotton', 'Linen', 'Velvet', 'Sheer', 'Polyester'];
  final List<String> _lightControls = ['Blackout', 'Dimout', 'Light Filtering'];
  final List<String> _roomTypes = ['Living Room', 'Bedroom', 'Kitchen', 'Office'];

  // --- NEW: Content-based recommendation engine ---
  final ContentBasedRecommendationEngine _recommendationEngine = ContentBasedRecommendationEngine();

  @override
  void initState() {
    super.initState();
    final prefs = widget.initialPreferences;

    // Set defaults first
    _selectedPattern = _patterns.first;
    _selectedMaterial = _materials.first;
    _selectedLightControl = _lightControls.first;
    _selectedRoomType = _roomTypes.first;

    // If initial preferences were passed, override the defaults
    if (prefs != null) {
      _selectedPattern = prefs['design_pattern'] ?? _selectedPattern;
      _selectedMaterial = prefs['material'] ?? _selectedMaterial;
      _selectedLightControl = prefs['light_control'] ?? _selectedLightControl;
      _selectedRoomType = prefs['room_type'] ?? _selectedRoomType;
    }
  }
  
  /// NEW: Enhanced recommendation algorithm with content-based filtering
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
      };

      // Use content-based filtering
      List<ScoredRecommendation> scoredCurtains = await _generateContentBasedRecommendations(
        allCurtains, 
        userPreferences
      );

      // Track the search
      await UserInteractionService.trackSearch(userPreferences, scoredCurtains.length);

      // Sort by score (descending)
      scoredCurtains.sort((a, b) => b.displayScore.compareTo(a.displayScore));

      // Limit to top 20 recommendations
      scoredCurtains = scoredCurtains.take(20).toList();

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

  /// NEW: Generate content-based recommendations
  Future<List<ScoredRecommendation>> _generateContentBasedRecommendations(
    List<Curtain> allCurtains,
    Map<String, dynamic> userPreferences,
  ) async {
    final scoredCurtains = <ScoredRecommendation>[];

    for (final curtain in allCurtains) {
      // Calculate weighted similarity score
      double similarityScore = _recommendationEngine.calculateWeightedScore(
        userPreferences,
        curtain,
        _mustHaves,
        _categoryWeights,
      );

      // Skip if similarity is too low or must-have constraints not met
      if (similarityScore < 0.1) continue;

      // Calculate category breakdown
      Map<String, double> categoryScores = {
        'pattern': _recommendationEngine.calculatePatternSimilarity(
          userPreferences['design_pattern'], 
          curtain.designPattern
        ),
        'material': _recommendationEngine.calculateMaterialSimilarity(
          userPreferences['material'], 
          curtain.material
        ),
        'lightControl': _recommendationEngine.calculateLightControlSimilarity(
          userPreferences['light_control'], 
          curtain.lightControl
        ),
        'roomType': _recommendationEngine.calculateRoomTypeSimilarity(
          userPreferences['room_type'], 
          curtain.roomType
        ),
      };

      // Convert to display score (0-100)
      int displayScore = (similarityScore * 100).round();

      scoredCurtains.add(ScoredRecommendation(
        curtain: curtain,
        score: displayScore,
        maxPossibleScore: 100,
        similarityScore: similarityScore,
        categoryScores: categoryScores,
      ));
    }

    return scoredCurtains;
  }



  void _toggleMustHave(String category) {
    setState(() {
      _mustHaves[category] = !_mustHaves[category]!;
    });
  }

  /// NEW: Update category weight
  void _updateCategoryWeight(String category, double weight) {
    setState(() {
      _categoryWeights[category] = weight;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            const Text('Tell us your style.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Select your preferences. Tap the star to mark a "Must-Have".',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 40),

            _PreferenceSelector(
              title: 'Design Pattern',
              options: _patterns,
              selectedValue: _selectedPattern,
              onSelected: (value) => setState(() => _selectedPattern = value),
              isMustHave: _mustHaves['pattern']!,
              onToggleMustHave: () => _toggleMustHave('pattern'),
              weight: _categoryWeights['pattern']!,
              onWeightChanged: (weight) => _updateCategoryWeight('pattern', weight),
            ),
            const SizedBox(height: 30),
            _PreferenceSelector(
              title: 'Material',
              options: _materials,
              selectedValue: _selectedMaterial,
              onSelected: (value) => setState(() => _selectedMaterial = value),
              isMustHave: _mustHaves['material']!,
              onToggleMustHave: () => _toggleMustHave('material'),
              weight: _categoryWeights['material']!,
              onWeightChanged: (weight) => _updateCategoryWeight('material', weight),
            ),
            const SizedBox(height: 30),
            _PreferenceSelector(
              title: 'Light Control',
              options: _lightControls,
              selectedValue: _selectedLightControl,
              onSelected: (value) => setState(() => _selectedLightControl = value),
              isMustHave: _mustHaves['lightControl']!,
              onToggleMustHave: () => _toggleMustHave('lightControl'),
              weight: _categoryWeights['lightControl']!,
              onWeightChanged: (weight) => _updateCategoryWeight('lightControl', weight),
            ),
            const SizedBox(height: 30),
            _PreferenceSelector(
              title: 'Room Type',
              options: _roomTypes,
              selectedValue: _selectedRoomType,
              onSelected: (value) => setState(() => _selectedRoomType = value),
              isMustHave: _mustHaves['roomType']!,
              onToggleMustHave: () => _toggleMustHave('roomType'),
              weight: _categoryWeights['roomType']!,
              onWeightChanged: (weight) => _updateCategoryWeight('roomType', weight),
            ),
            const SizedBox(height: 50),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _findMyCurtains,
              style: ElevatedButton.styleFrom(
                backgroundColor: const ThemeConfig.primaryColor,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'FIND MY CURTAINS',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// NEW: Enhanced Preference Selector with weight adjustment
class _PreferenceSelector extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;
  final bool isMustHave;
  final VoidCallback onToggleMustHave;
  final double weight;
  final ValueChanged<double> onWeightChanged;

  const _PreferenceSelector({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    required this.isMustHave,
    required this.onToggleMustHave,
    required this.weight,
    required this.onWeightChanged,
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
            Row(
              children: [
                // Weight indicator for content-based filtering
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(weight * 100).round()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(isMustHave ? Icons.star : Icons.star_border, color: isMustHave ? Colors.amber[600] : Colors.grey),
                  onPressed: onToggleMustHave,
                  tooltip: 'Mark as Must-Have',
                ),
              ],
            ),
          ],
        ),
        
        // Weight slider for content-based filtering
        Slider(
          value: weight,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          label: '${(weight * 100).round()}%',
          onChanged: onWeightChanged,
          activeColor: const ThemeConfig.primaryColor,
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
                    color: isSelected ? const ThemeConfig.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: isSelected ? const ThemeConfig.primaryColor : Colors.grey.shade300, width: 1.5),
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
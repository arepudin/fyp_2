// lib/screens/curtain_preference_screen.dart

import 'package:flutter/material.dart';
import '../../models/curtain_model.dart';
import '../../models/recommendation_model.dart';
import '../../services/cbf_engine.dart';
import '../../services/user_interaction.dart'; // Added import
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
  late String _selectedStyle;
  bool _isLoading = false;

  // --- NEW: Content-based filtering toggle ---
  bool _useContentBasedFiltering = true;

  // --- NEW: State for "Must-Haves" ---
  final Map<String, bool> _mustHaves = {
    'pattern': false,
    'material': false,
    'lightControl': false,
    'roomType': false,
    'style': false,
  };

  // --- NEW: Category weights for content-based filtering ---
  final Map<String, double> _categoryWeights = {
    'pattern': 0.2,
    'material': 0.25,
    'lightControl': 0.25,
    'roomType': 0.15,
    'style': 0.15,
  };

  // --- Preference Options ---
  final List<String> _patterns = ['Textured', 'Pebbled', 'Twill', 'Crackled', 'Striated', 'Dobby'];
  final List<String> _materials = ['Cotton', 'Linen', 'Velvet', 'Sheer', 'Polyester'];
  final List<String> _lightControls = ['Blackout', 'Room Darkening', 'Light Filtering'];
  final List<String> _roomTypes = ['Living Room', 'Bedroom', 'Kitchen', 'Office'];
  final List<String> _styles = ['Modern', 'Traditional', 'Minimalist'];

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
        'style': _selectedStyle,
      };

      List<ScoredRecommendation> scoredCurtains;

      if (_useContentBasedFiltering) {
        // Use content-based filtering
        scoredCurtains = await _generateContentBasedRecommendations(
          allCurtains, 
          userPreferences
        );
      } else {
        // Use original rule-based algorithm
        scoredCurtains = _generateRuleBasedRecommendations(
          allCurtains, 
          userPreferences
        );
      }

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
        'style': _recommendationEngine.calculateStyleSimilarity(
          userPreferences['style'], 
          curtain.style
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

  /// Original rule-based recommendation algorithm (kept for comparison)
  List<ScoredRecommendation> _generateRuleBasedRecommendations(
    List<Curtain> allCurtains,
    Map<String, dynamic> userPreferences,
  ) {
    // Define weights for scoring
    const int mustHaveScore = 10;
    const int regularScore = 2;
    
    // Calculate the maximum possible score based on selections
    final int maxPossibleScore = 
        (_mustHaves['pattern']! ? mustHaveScore : regularScore) +
        (_mustHaves['material']! ? mustHaveScore : regularScore) +
        (_mustHaves['lightControl']! ? mustHaveScore : regularScore) +
        (_mustHaves['roomType']! ? mustHaveScore : regularScore) +
        (_mustHaves['style']! ? mustHaveScore : regularScore);

    final scoredCurtains = <ScoredRecommendation>[];

    for (final curtain in allCurtains) {
      int currentScore = 0;
      bool meetsAllMustHaves = true;

      // Check Pattern
      if (_mustHaves['pattern']!) {
        if (curtain.designPattern != userPreferences['design_pattern']) {
          meetsAllMustHaves = false;
        } else {
          currentScore += mustHaveScore;
        }
      } else if (curtain.designPattern == userPreferences['design_pattern']) {
        currentScore += regularScore;
      }
      
      // Check Material
      if (_mustHaves['material']!) {
        if (curtain.material != userPreferences['material']) {
          meetsAllMustHaves = false;
        } else {
          currentScore += mustHaveScore;
        }
      } else if (curtain.material == userPreferences['material']) {
        currentScore += regularScore;
      }

      // Check Light Control
      if (_mustHaves['lightControl']!) {
        if (curtain.lightControl != userPreferences['light_control']) {
          meetsAllMustHaves = false;
        } else {
          currentScore += mustHaveScore;
        }
      } else if (curtain.lightControl == userPreferences['light_control']) {
        currentScore += regularScore;
      }

      // Check Room Type
      if (_mustHaves['roomType']!) {
        if (curtain.roomType != userPreferences['room_type']) {
          meetsAllMustHaves = false;
        } else {
          currentScore += mustHaveScore;
        }
      } else if (curtain.roomType == userPreferences['room_type']) {
        currentScore += regularScore;
      }
      
      // Check Style
      if (_mustHaves['style']!) {
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
        actions: [
          // NEW: Algorithm toggle button
          IconButton(
            icon: Icon(_useContentBasedFiltering ? Icons.smart_toy : Icons.rule),
            onPressed: () {
              setState(() {
                _useContentBasedFiltering = !_useContentBasedFiltering;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_useContentBasedFiltering 
                    ? 'Switched to Content-Based Filtering' 
                    : 'Switched to Rule-Based Filtering'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tell us your style.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select your preferences. Tap the star to mark a "Must-Have".',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
                // NEW: Algorithm indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _useContentBasedFiltering ? Colors.blue : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _useContentBasedFiltering ? 'Smart' : 'Basic',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
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
              onWeightChanged: _useContentBasedFiltering ? (weight) => _updateCategoryWeight('pattern', weight) : null,
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
              onWeightChanged: _useContentBasedFiltering ? (weight) => _updateCategoryWeight('material', weight) : null,
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
              onWeightChanged: _useContentBasedFiltering ? (weight) => _updateCategoryWeight('lightControl', weight) : null,
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
              onWeightChanged: _useContentBasedFiltering ? (weight) => _updateCategoryWeight('roomType', weight) : null,
            ),
            const SizedBox(height: 30),
            _PreferenceSelector(
              title: 'Style',
              options: _styles,
              selectedValue: _selectedStyle,
              onSelected: (value) => setState(() => _selectedStyle = value),
              isMustHave: _mustHaves['style']!,
              onToggleMustHave: () => _toggleMustHave('style'),
              weight: _categoryWeights['style']!,
              onWeightChanged: _useContentBasedFiltering ? (weight) => _updateCategoryWeight('style', weight) : null,
            ),
            const SizedBox(height: 50),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _findMyCurtains,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 158, 19, 17),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _useContentBasedFiltering ? 'FIND MY CURTAINS (SMART)' : 'FIND MY CURTAINS (BASIC)',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
  final ValueChanged<double>? onWeightChanged;

  const _PreferenceSelector({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    required this.isMustHave,
    required this.onToggleMustHave,
    required this.weight,
    this.onWeightChanged,
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
                // NEW: Weight indicator for content-based filtering
                if (onWeightChanged != null)
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
        
        // NEW: Weight slider for content-based filtering
        if (onWeightChanged != null)
          Slider(
            value: weight,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            label: '${(weight * 100).round()}%',
            onChanged: onWeightChanged,
            activeColor: const Color.fromARGB(255, 158, 19, 17),
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
import 'curtain_model.dart';

class ScoredRecommendation {
  final Curtain curtain;
  final int score;
  final int maxPossibleScore;
  final double similarityScore; // New field for content-based similarity
  final Map<String, double> categoryScores; // New field for breakdown

  ScoredRecommendation({
    required this.curtain,
    required this.score,
    required this.maxPossibleScore,
    this.similarityScore = 0.0,
    this.categoryScores = const {},
  });
  
  /// Calculate match percentage
  int get matchPercentage => maxPossibleScore > 0 
      ? ((score / maxPossibleScore) * 100).round()
      : 0;
  
  /// Get similarity percentage
  int get similarityPercentage => (similarityScore * 100).round();
  
  /// Get the higher of the two scores for display
  int get displayScore => similarityPercentage > matchPercentage 
      ? similarityPercentage 
      : matchPercentage;
}
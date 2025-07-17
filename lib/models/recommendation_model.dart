import 'curtain_model.dart';

class ScoredRecommendation {
  final Curtain curtain;
  final int score;
  final int maxPossibleScore;
  final double similarityScore; // Content-based similarity score
  final Map<String, double> categoryScores; // Category breakdown

  ScoredRecommendation({
    required this.curtain,
    required this.score,
    required this.maxPossibleScore,
    this.similarityScore = 0.0,
    this.categoryScores = const {},
  });
  
  /// Get similarity percentage from content-based filtering
  int get similarityPercentage => (similarityScore * 100).round();
  
  /// Display score is now always the similarity percentage
  int get displayScore => similarityPercentage;
}
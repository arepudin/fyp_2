// lib/models/recommendation_model.dart
import 'curtain_model.dart';

class ScoredRecommendation {
  final Curtain curtain;
  final int score;

  ScoredRecommendation({required this.curtain, required this.score});
}
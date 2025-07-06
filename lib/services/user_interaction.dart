import '../constants/supabase.dart';

class UserInteractionService {
  static Future<void> trackInteraction({
    required String curtainId,
    required String interactionType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('user_interactions').insert({
        'user_id': user.id,
        'curtain_id': curtainId,
        'interaction_type': interactionType,
        'interaction_data': additionalData,
      });
    } catch (e) {
      print('Error tracking interaction: $e');
    }
  }

  static Future<void> trackView(String curtainId) async {
    await trackInteraction(
      curtainId: curtainId,
      interactionType: 'view',
      additionalData: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  static Future<void> trackOrder(String curtainId) async {
    await trackInteraction(
      curtainId: curtainId,
      interactionType: 'order',
      additionalData: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  static Future<void> trackSearch(Map<String, dynamic> searchCriteria, int resultsCount) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('search_history').insert({
        'user_id': user.id,
        'search_preferences': searchCriteria,
        'results_count': resultsCount,
      });
    } catch (e) {
      print('Error tracking search: $e');
    }
  }
}
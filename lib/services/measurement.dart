import 'package:fyp_2/utils/measurement_utils.dart';
import '../constants/supabase.dart';

class MeasurementService {
  /// Save measurement to Supabase database
  static Future<String?> saveMeasurement({
    required double width,
    required double height,
    required MeasurementUnit unit,
    String? notes,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase.from('measurements').insert({
        'user_id': user.id,
        'window_width': width,
        'window_height': height,
        'unit': unit.name,
        'created_at': DateTime.now().toIso8601String(),
        'notes': notes ?? '',
      }).select();

      if (response.isNotEmpty) {
        return response.first['id'] as String;
      } else {
        throw Exception('Failed to save measurement');
      }
    } catch (e) {
      print('Error saving measurement: $e');
      rethrow;
    }
  }

  /// Get all measurements for the current user
  static Future<List<Map<String, dynamic>>> getUserMeasurements() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase
          .from('measurements')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching measurements: $e');
      rethrow;
    }
  }

  /// Delete a measurement
  static Future<void> deleteMeasurement(String measurementId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await supabase
          .from('measurements')
          .delete()
          .eq('id', measurementId)
          .eq('user_id', user.id);
    } catch (e) {
      print('Error deleting measurement: $e');
      rethrow;
    }
  }
}
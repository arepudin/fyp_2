// lib/services/measurement_service.dart
import '../utils/measurement_utils.dart';
import '../constants/supabase.dart';

class MeasurementService {

  static Future<String?> saveMeasurement({
    required double width,
    required double height,
    required MeasurementUnit unit,
    String? notes,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Cannot save measurement.');
      }

      // Perform the insert operation into the 'measurements' table.
      // The .select() at the end returns the newly inserted row.
      final response = await supabase.from('measurements').insert({
        'user_id': user.id,
        'window_width': width,
        'window_height': height,
        'unit': unit.name, // Saves the unit as a string, e.g., 'meters' or 'inches'
        'created_at': DateTime.now().toIso8601String(),
        'notes': notes ?? '', // Use provided notes or an empty string
      }).select();
      
      // Supabase returns a list of inserted rows. If it's not empty, the insert was successful.
      if (response.isNotEmpty) {
        // Assuming the 'id' column is a UUID string, which is common.
        return response.first['id'] as String;
      } else {
        // This case might occur if RLS (Row Level Security) prevents the insert
        // or if there's an issue with the insert operation itself.
        throw Exception('Failed to save measurement: No data returned after insert.');
      }
    } catch (e) {
      // Catch and print any errors during the process for easier debugging.
      print('Error saving measurement to Supabase: $e');
      // Re-throw the exception so the UI layer can handle it (e.g., show an error dialog).
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserMeasurements() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Cannot fetch measurements.');
      }

      // Fetch all columns from 'measurements' where user_id matches the current user.
      final response = await supabase
          .from('measurements')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
          

      // The response is already a List<dynamic>, so we cast it to the expected type.
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching measurements from Supabase: $e');
      rethrow;
    }
  }

  /// Deletes a specific measurement from the Supabase 'measurements' table.
  ///
  /// Requires the [measurementId] of the record to be deleted.
  /// The operation will only succeed if the measurement's 'user_id' matches
  /// the currently authenticated user's ID, which is a crucial security check.
  /// Throws an exception if the user is not authenticated or if the delete fails.
  static Future<void> deleteMeasurement(String measurementId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Cannot delete measurement.');
      }

      // Perform the delete operation.
      // The second .eq() ensures users can only delete their own records.
      await supabase
          .from('measurements')
          .delete()
          .eq('id', measurementId)
          .eq('user_id', user.id);
          
    } catch (e) {
      print('Error deleting measurement from Supabase: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getLatestUserMeasurement() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated.');
      }

      // Fetch the latest record by ordering by creation date and limiting to one.
      // .maybeSingle() is a convenient Supabase function that returns the single
      // row or null if no rows are found, preventing errors.
      final response = await supabase
          .from('measurements')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching latest measurement: $e');
      rethrow;
    }
  }
}
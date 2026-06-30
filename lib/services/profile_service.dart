import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create user profile if it doesn't exist
  Future<void> ensureUserProfile(String userId, String username) async {
    try {
      // Check if profile exists
      final existing = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        // Create profile
        await _supabase.from('user_profiles').insert({
          'user_id': userId,
          'username': username,
          'full_name': username,
          'created_at': DateTime.now().toIso8601String(),
        });
        print('✅ User profile created for: $userId');
      }
    } catch (e) {
      print('Error ensuring user profile: $e');
      // Don't throw - we want the app to continue working
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? username,
    String? fullName,
    String? bio,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final data = {
        if (username != null) 'username': username,
        if (fullName != null) 'full_name': fullName,
        if (bio != null) 'bio': bio,
        if (preferences != null) 'preferences': preferences,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('user_profiles').update(data).eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
}

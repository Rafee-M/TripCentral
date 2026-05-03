import 'package:supabase_flutter/supabase_flutter.dart';

/// Facade Pattern: Simple wrapper around complex Supabase auth & profile operations.
/// Singleton Pattern: Only one instance required across the app to manage settings.
class SettingsService {
  static final SettingsService _instance = SettingsService._internal();

  factory SettingsService() {
    return _instance;
  }

  SettingsService._internal();

  final _supabase = Supabase.instance.client;

  /// Fetches the current user's profile data from public.profiles
  Future<Map<String, dynamic>> getCurrentProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Updates the user's display name after verifying their password
  Future<void> updateDisplayName({required String newName, required String currentPassword}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not authenticated or missing email');
      }

      // 1. Verify password by re-authenticating
      await _supabase.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );

      // 2. Update the display name in public.profiles.
      // RLS policy "User updates own profile" ensures this is secure.
      await _supabase
          .from('profiles')
          .update({'display_name': newName.trim()})
          .eq('id', user.id);

    } catch (e) {
      rethrow;
    }
  }

  /// Logs out the user
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}


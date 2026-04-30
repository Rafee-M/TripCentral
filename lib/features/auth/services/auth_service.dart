import 'package:supabase_flutter/supabase_flutter.dart';

/// Facade/Singleton Service encapsulating Supabase Auth interactions.
class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Validates uniquely chosen usernames before signup
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _supabase.rpc(
        'is_username_available',
        params: {'p_username': username},
      );
      return response as bool;
    } on PostgrestException {
      rethrow;
    }
  }

  /// Logs in an existing user
  Future<AuthResponse> login(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw Exception('Unexpected error during login');
    }
  }

  /// Signs up a newly registering user
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      final isAvailable = await isUsernameAvailable(username);
      if (!isAvailable) {
        throw const AuthException('Username is already taken.');
      }

      return await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'display_name': displayName,
        },
      );
    } on PostgrestException {
      // Re-throw Supabase DB specific exceptions so the UI can detect them properly
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw Exception('Unexpected error during signup');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}


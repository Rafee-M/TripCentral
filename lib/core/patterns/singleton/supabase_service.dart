import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // 1. Private named constructor
  SupabaseService._privateConstructor();

  // 2. Single internal instance
  static final SupabaseService _instance = SupabaseService._privateConstructor();

  // 3. Factory constructor to return the instance
  factory SupabaseService() {
    return _instance;
  }

  // 4. Convenience getter
  static SupabaseService get instance => _instance;

  // Configuration constants
  static const String _url = 'https://fippkhwnmizpsdwstruo.supabase.co';
  static const String _anonKey = 'sb_publishable_NCuzb_qNV_NZ6A6Mls357w_qyyuCkwj';

  /// Initializes the Supabase client
  Future<void> initialize() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
    );
  }

  /// Exposed getter to access the Supabase client directly
  SupabaseClient get client => Supabase.instance.client;
}


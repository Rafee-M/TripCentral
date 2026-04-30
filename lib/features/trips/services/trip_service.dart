import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trip_central/shared/models/trip_list.dart';

/// Facade Pattern: Simple wrapper around complex Supabase structures
/// Singleton Pattern: Only one instance required across the app
class TripService {
  static final TripService _instance = TripService._internal();

  factory TripService() {
    return _instance;
  }

  TripService._internal();

  final _supabase = Supabase.instance.client;

  /// Fetches simple list of all accessible trips for the current user
  Future<List<TripList>> getUpcomingTrips() async {
    try {
      final response = await _supabase
          .from('trip_lists')
          .select()
          .isFilter('deleted_at', null) // Only fetch active trips
          .order('start_date', ascending: true);

      final data = response as List<dynamic>;
      return data.map((json) => TripList.fromJson(json as Map<String, dynamic>)).toList();
    } on PostgrestException {
      // Re-throw standardized Exceptions for the UI to handle gracefully
      rethrow;
    }
  }

  /// Builders Pattern conceptually: Assemble payload from modular variables to store in DB
  Future<TripList> createTrip({
    required String title,
    String? description,
    bool isPublic = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User is not authenticated');
      }

      final payload = <String, dynamic>{
        'owner_id': userId,
        'title': title,
        'is_public': isPublic,
      };

      if (description != null && description.trim().isNotEmpty) {
        payload['description'] = description.trim();
      }

      if (startDate != null) {
        payload['start_date'] = startDate.toIso8601String().split('T').first;
      }
      
      if (endDate != null) {
        payload['end_date'] = endDate.toIso8601String().split('T').first;
      }

      // Workaround for Supabase RLS "new row violates row-level security":
      // The SELECT policy checks `can_access_trip` which is a STABLE function. 
      // In Postgres, STABLE functions cannot see changes from the current statement.
      // So `.select()` returning immediately after insert evaluates to false locally and blocks the insert!
      // Fix: We do the INSERT without a returning select.
      await _supabase.from('trip_lists').insert(payload);

      // Now query it separately since the transaction has committed.
      final response = await _supabase
          .from('trip_lists')
          .select()
          .eq('owner_id', userId)
          .eq('title', title)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      return TripList.fromJson(response);
    } on PostgrestException {
      // Intercept errors transparently
      rethrow;
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

abstract class TripDiscoveryFilterStrategy {
  Future<List<Map<String, dynamic>>> fetchTrips({
    required SupabaseClient supabase,
    required String? userId,
    required String query,
  });
}

class PublicTripFilterStrategy implements TripDiscoveryFilterStrategy {
  @override
  Future<List<Map<String, dynamic>>> fetchTrips({
    required SupabaseClient supabase,
    required String? userId,
    required String query,
  }) async {
    var req = supabase
        .from('trip_lists')
        .select(
          'id, owner_id, title, cover_image_url, start_date, is_public, created_at',
        )
        .eq('is_public', true)
        .isFilter('deleted_at', null);

    final trimmedQuery = query.trim();
    if (trimmedQuery.isNotEmpty) {
      req = req.ilike('title', '%$trimmedQuery%');
    }

    final result = await req;
    return (result as List<dynamic>).cast<Map<String, dynamic>>();
  }
}

class OwnTripFilterStrategy implements TripDiscoveryFilterStrategy {
  @override
  Future<List<Map<String, dynamic>>> fetchTrips({
    required SupabaseClient supabase,
    required String? userId,
    required String query,
  }) async {
    if (userId == null) {
      return <Map<String, dynamic>>[];
    }

    var req = supabase
        .from('trip_lists')
        .select(
          'id, owner_id, title, cover_image_url, start_date, is_public, created_at',
        )
        .eq('owner_id', userId)
        .isFilter('deleted_at', null);

    final trimmedQuery = query.trim();
    if (trimmedQuery.isNotEmpty) {
      req = req.ilike('title', '%$trimmedQuery%');
    }

    final result = await req;
    return (result as List<dynamic>).cast<Map<String, dynamic>>();
  }
}

class InvitedTripFilterStrategy implements TripDiscoveryFilterStrategy {
  @override
  Future<List<Map<String, dynamic>>> fetchTrips({
    required SupabaseClient supabase,
    required String? userId,
    required String query,
  }) async {
    if (userId == null) {
      return <Map<String, dynamic>>[];
    }

    final collaborators = await supabase
        .from('trip_list_collaborators')
        .select('trip_list_id')
        .eq('user_id', userId);

    final ids = (collaborators as List<dynamic>)
        .map((e) => e['trip_list_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();

    if (ids.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    var req = supabase
        .from('trip_lists')
        .select(
          'id, owner_id, title, cover_image_url, start_date, is_public, created_at',
        )
        .inFilter('id', ids)
        .isFilter('deleted_at', null);

    final trimmedQuery = query.trim();
    if (trimmedQuery.isNotEmpty) {
      req = req.ilike('title', '%$trimmedQuery%');
    }

    final result = await req;
    return (result as List<dynamic>).cast<Map<String, dynamic>>();
  }
}

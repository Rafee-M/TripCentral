import 'package:supabase_flutter/supabase_flutter.dart';

import '../../adapters/trip_discovery_adapter.dart';
import '../../models/discover_trip_card.dart';
import 'trip_discovery_filter_strategy.dart';
import 'trip_discovery_sort_strategy.dart';
import 'trip_discovery_service_types.dart';

class TripDiscoveryService {
  TripDiscoveryService._();

  static final TripDiscoveryService _instance = TripDiscoveryService._();

  factory TripDiscoveryService() => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;

  final Map<TripDiscoveryFilter, TripDiscoveryFilterStrategy>
  _filterStrategies = <TripDiscoveryFilter, TripDiscoveryFilterStrategy>{
    TripDiscoveryFilter.public: PublicTripFilterStrategy(),
    TripDiscoveryFilter.own: OwnTripFilterStrategy(),
    TripDiscoveryFilter.invited: InvitedTripFilterStrategy(),
  };

  final Map<TripDiscoverySort, TripDiscoverySortStrategy> _sortStrategies =
      <TripDiscoverySort, TripDiscoverySortStrategy>{
        TripDiscoverySort.title: TitleSortStrategy(),
        TripDiscoverySort.date: DateSortStrategy(),
        TripDiscoverySort.rating: RatingSortStrategy(),
      };

  Future<List<DiscoverTripCard>> searchTripLists({
    required TripDiscoveryFilter filter,
    required TripDiscoverySort sort,
    required String query,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      final rawTrips = await _filterStrategies[filter]!.fetchTrips(
        supabase: _supabase,
        userId: userId,
        query: query,
      );

      if (rawTrips.isEmpty) {
        return <DiscoverTripCard>[];
      }

      final tripIds = rawTrips.map((e) => e['id'].toString()).toList();

      final ratingsByTripId = await _fetchRatingsByTripId(tripIds);
      final locationsByTripId = await _fetchLocationsByTripId(tripIds);

      final cards = rawTrips
          .map(
            (trip) => TripDiscoveryAdapter.fromDatabase(
              trip: trip,
              ratingsByTripId: ratingsByTripId,
              locationsByTripId: locationsByTripId,
            ),
          )
          .toList();

      final safeSort = filter == TripDiscoveryFilter.public
          ? sort
          : _fallbackSort(sort);

      return _sortStrategies[safeSort]!.sort(cards);
    } on PostgrestException {
      rethrow;
    }
  }

  TripDiscoverySort _fallbackSort(TripDiscoverySort sort) {
    if (sort == TripDiscoverySort.rating) {
      return TripDiscoverySort.date;
    }
    return sort;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchRatingsByTripId(
    List<String> tripIds,
  ) async {
    if (tripIds.isEmpty) {
      return <String, Map<String, dynamic>>{};
    }

    final res = await _supabase
        .from('trip_list_avg_ratings')
        .select('trip_list_id, avg_rating, review_count')
        .inFilter('trip_list_id', tripIds);

    final rows = (res as List<dynamic>).cast<Map<String, dynamic>>();

    return <String, Map<String, dynamic>>{
      for (final row in rows) row['trip_list_id'].toString(): row,
    };
  }

  Future<Map<String, List<String>>> _fetchLocationsByTripId(
    List<String> tripIds,
  ) async {
    if (tripIds.isEmpty) {
      return <String, List<String>>{};
    }

    final res = await _supabase
        .from('trip_locations')
        .select('trip_list_id, name, order_index')
        .inFilter('trip_list_id', tripIds)
        .order('order_index', ascending: true);

    final rows = (res as List<dynamic>).cast<Map<String, dynamic>>();

    final map = <String, List<String>>{};

    for (final row in rows) {
      final id = row['trip_list_id'].toString();
      final name = (row['name'] ?? '').toString().trim();
      if (name.isEmpty) {
        continue;
      }
      final list = map.putIfAbsent(id, () => <String>[]);
      if (list.length < 3) {
        list.add(name);
      }
    }

    return map;
  }

  /// Submit or update a rating for a public trip.
  /// RLS enforces: user can only rate public trips they don't own.
  /// Returns the review ID on success.
  Future<String> submitRating({
    required String tripListId,
    required int rating,
    String? reviewText,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User is not authenticated');
      }

      if (rating < 1 || rating > 5) {
        throw ArgumentError('Rating must be between 1 and 5');
      }

      // Upsert: insert new review or update existing one
      final res = await _supabase
          .from('trip_list_reviews')
          .upsert({
            'trip_list_id': tripListId,
            'reviewer_id': userId,
            'rating': rating,
            'review_text': reviewText?.trim(),
          }, onConflict: 'trip_list_id, reviewer_id')
          .select('id');

      if (res.isEmpty) {
        throw Exception('Failed to submit rating');
      }

      return (res.first as Map<String, dynamic>)['id'].toString();
    } on PostgrestException catch (e) {
      // RLS violations will come through as PostgrestException
      if (e.code == '42501') {
        throw Exception(
          'Cannot rate this trip (must be public and not your own)',
        );
      }
      throw Exception('Error submitting rating: ${e.message}');
    }
  }
}

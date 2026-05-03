import 'package:supabase_flutter/supabase_flutter.dart';

import '../../adapters/trip_discovery_adapter.dart';
import '../../models/discover_trip_card.dart';
import '../../../../shared/models/trip_review.dart';
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
      final myReviewsByTripId = await _fetchMyReviewsByTripId(tripIds);
      final locationsByTripId = await _fetchLocationsByTripId(tripIds);

      final cards = rawTrips
          .map(
            (trip) => TripDiscoveryAdapter.fromDatabase(
              trip: trip,
              ratingsByTripId: ratingsByTripId,
              myReviewsByTripId: myReviewsByTripId,
              locationsByTripId: locationsByTripId,
              currentUserId: userId,
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

  Future<Map<String, Map<String, dynamic>>> _fetchMyReviewsByTripId(
    List<String> tripIds,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || tripIds.isEmpty) {
      return <String, Map<String, dynamic>>{};
    }

    final res = await _supabase
        .from('trip_list_reviews')
        .select('trip_list_id, rating, review_text')
        .eq('reviewer_id', userId)
        .inFilter('trip_list_id', tripIds);

    final rows = (res as List<dynamic>).cast<Map<String, dynamic>>();

    return <String, Map<String, dynamic>>{
      for (final row in rows) row['trip_list_id'].toString(): row,
    };
  }

  Future<List<TripReview>> getTripReviews({required String tripListId}) async {
    try {
      final reviewsRes = await _supabase
          .from('trip_list_reviews')
          .select(
            'id, trip_list_id, reviewer_id, rating, review_text, created_at, updated_at',
          )
          .eq('trip_list_id', tripListId)
          .order('created_at', ascending: false);

      final reviewRows = (reviewsRes as List<dynamic>)
          .cast<Map<String, dynamic>>();
      if (reviewRows.isEmpty) {
        return <TripReview>[];
      }

      final reviewerIds = reviewRows
          .map((row) => row['reviewer_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      final profilesRes = await _supabase
          .from('profiles')
          .select('id, username, display_name, avatar_url')
          .inFilter('id', reviewerIds);

      final profileRows = (profilesRes as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final profilesById = <String, Map<String, dynamic>>{
        for (final row in profileRows) row['id'].toString(): row,
      };

      return reviewRows.map((row) {
        final reviewer = profilesById[row['reviewer_id']?.toString()];
        return TripReview.fromJson({
          ...row,
          'reviewer_username': reviewer?['username'],
          'reviewer_display_name': reviewer?['display_name'],
          'reviewer_avatar_url': reviewer?['avatar_url'],
        });
      }).toList();
    } on PostgrestException {
      rethrow;
    }
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

      return res.first['id'].toString();
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

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

  /// Fetches simple list of all accessible trips for the current user (only owned or collaborated)
  Future<List<TripList>> getUpcomingTrips() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // 1. Fetch trips owned by the user
      final ownedResponse = await _supabase
          .from('trip_lists')
          .select()
          .eq('owner_id', userId)
          .isFilter('deleted_at', null);

      // 2. Fetch trips where the user is a collaborator
      final collabResponse = await _supabase
          .from('trip_list_collaborators')
          .select('trip_lists(*)')
          .eq('user_id', userId);

      final List<TripList> trips = [];
      final Set<String> addedIds = {};

      // Helper to add unique trips
      void addTrip(Map<String, dynamic> json) {
        if (json['deleted_at'] == null && !addedIds.contains(json['id'])) {
          addedIds.add(json['id']);
          trips.add(TripList.fromJson(json));
        }
      }

      // Process owned trips
      for (var json in (ownedResponse as List<dynamic>)) {
        addTrip(json as Map<String, dynamic>);
      }

      // Process collaborated trips
      for (var row in (collabResponse as List<dynamic>)) {
        final tripListsObj = row['trip_lists'];
        if (tripListsObj != null) {
          // trip_lists could be a single object or an array depending on exactly how postgrest returns the 1:1 join
          if (tripListsObj is Map<String, dynamic>) {
             addTrip(tripListsObj);
          } else if (tripListsObj is List) {
             for (var t in tripListsObj) {
               addTrip(t as Map<String, dynamic>);
             }
          }
        }
      }

      // Sort by start_date ascending natively
      trips.sort((a, b) {
        if (a.startDate == null && b.startDate == null) return 0;
        if (a.startDate == null) return 1;
        if (b.startDate == null) return -1;
        return a.startDate!.compareTo(b.startDate!);
      });

      return trips;
    } on PostgrestException {
      // Re-throw standardized Exceptions for the UI to handle gracefully
      rethrow;
    }
  }

  /// Fetches pending invitations for the current user
  Future<List<Map<String, dynamic>>> getPendingInvitations() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final res = await _supabase
          .from('trip_list_invitations')
          .select('id, status, trip_list_id, trip_lists(title), profiles!invited_by(display_name, username)')
          .eq('invited_user_id', userId)
          .eq('status', 'pending');

      return List<Map<String, dynamic>>.from(res);
    } on PostgrestException {
      rethrow;
    }
  }

  /// Accepts a trip invitation using the RPC
  Future<bool> acceptInvitation(String inviteId) async {
    try {
      final res = await _supabase.rpc('accept_invitation', params: {'p_invitation_id': inviteId});
      return res != null && res['success'] == true;
    } on PostgrestException {
      rethrow;
    }
  }

  /// Traditional Builder Pattern Implementation: Creates trip using a built payload
  Future<TripList> createTrip(TripBuilder builder) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User is not authenticated');
      }

      final payload = builder.build(userId);

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
          .eq('title', payload['title'])
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

/// Builder Class to construct Trip Payloads step-by-step
class TripBuilder {
  String? _title;
  String? _description;
  bool _isPublic = false;
  DateTime? _startDate;
  DateTime? _endDate;

  TripBuilder setTitle(String title) {
    _title = title;
    return this;
  }

  TripBuilder setDescription(String? description) {
    _description = description;
    return this;
  }

  TripBuilder setIsPublic(bool isPublic) {
    _isPublic = isPublic;
    return this;
  }

  TripBuilder setStartDate(DateTime? startDate) {
    _startDate = startDate;
    return this;
  }

  TripBuilder setEndDate(DateTime? endDate) {
    _endDate = endDate;
    return this;
  }

  Map<String, dynamic> build(String userId) {
    if (_title == null || _title!.trim().isEmpty) {
      throw Exception('Title is required');
    }

    final payload = <String, dynamic>{
      'owner_id': userId,
      'title': _title!.trim(),
      'is_public': _isPublic,
    };

    if (_description != null && _description!.trim().isNotEmpty) {
      payload['description'] = _description!.trim();
    }

    if (_startDate != null) {
      payload['start_date'] = _startDate!.toIso8601String().split('T').first;
    }

    if (_endDate != null) {
      payload['end_date'] = _endDate!.toIso8601String().split('T').first;
    }

    return payload;
  }
}

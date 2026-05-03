import '../models/discover_trip_card.dart';

class TripDiscoveryAdapter {
  static DiscoverTripCard fromDatabase({
    required Map<String, dynamic> trip,
    required Map<String, Map<String, dynamic>> ratingsByTripId,
    required Map<String, List<String>> locationsByTripId,
  }) {
    final tripId = trip['id'].toString();
    final rating = ratingsByTripId[tripId];

    final avg = rating?['avg_rating'];
    final avgRating = avg is num ? avg.toDouble() : null;

    final count = rating?['review_count'];
    final reviewCount = count is num ? count.toInt() : 0;

    return DiscoverTripCard(
      id: tripId,
      title: (trip['title'] ?? 'Untitled Trip').toString(),
      coverImageUrl: trip['cover_image_url']?.toString(),
      startDate: trip['start_date'] != null
          ? DateTime.tryParse(trip['start_date'].toString())
          : null,
      isPublic: trip['is_public'] == true,
      averageRating: avgRating,
      reviewCount: reviewCount,
      locationNames: locationsByTripId[tripId] ?? const <String>[],
    );
  }
}

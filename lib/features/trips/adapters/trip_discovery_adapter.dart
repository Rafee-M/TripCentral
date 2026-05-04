import '../models/discover_trip_card.dart';

class TripDiscoveryAdapter {
  static DiscoverTripCard fromDatabase({
    required Map<String, dynamic> trip,
    required Map<String, Map<String, dynamic>> ratingsByTripId,
    required Map<String, Map<String, dynamic>> myReviewsByTripId,
    required Map<String, List<String>> locationsByTripId,
    required String? currentUserId,
  }) {
    final tripId = trip['id'].toString();
    final rating = ratingsByTripId[tripId];
    final myReview = myReviewsByTripId[tripId];
    final ownerId = (trip['owner_id'] ?? '').toString();

    final avg = rating?['avg_rating'];
    final avgRating = avg is num ? avg.toDouble() : null;

    final count = rating?['review_count'];
    final reviewCount = count is num ? count.toInt() : 0;

    final myRatingValue = myReview?['rating'];
    final myRating = myRatingValue is num ? myRatingValue.toInt() : null;
    final myReviewText = myReview?['review_text']?.toString().trim();

    return DiscoverTripCard(
      id: tripId,
      ownerId: ownerId,
      title: (trip['title'] ?? 'Untitled Trip').toString(),
      coverImageUrl: trip['cover_image_url']?.toString(),
      startDate: trip['start_date'] != null
          ? DateTime.tryParse(trip['start_date'].toString())
          : null,
      isPublic: trip['is_public'] == true,
      averageRating: avgRating,
      reviewCount: reviewCount,
      locationNames: locationsByTripId[tripId] ?? const <String>[],
      isOwnedByCurrentUser:
          currentUserId != null &&
          currentUserId.isNotEmpty &&
          currentUserId == ownerId,
      myRating: myRating,
      myReviewText: myReviewText?.isEmpty == true ? null : myReviewText,
    );
  }
}

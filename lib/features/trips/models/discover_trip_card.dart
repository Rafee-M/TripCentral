class DiscoverTripCard {
  final String id;
  final String ownerId;
  final String title;
  final String? coverImageUrl;
  final DateTime? startDate;
  final bool isPublic;
  final double? averageRating;
  final int reviewCount;
  final List<String> locationNames;
  final bool isOwnedByCurrentUser;
  final int? myRating;
  final String? myReviewText;

  DiscoverTripCard({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.coverImageUrl,
    required this.startDate,
    required this.isPublic,
    required this.averageRating,
    required this.reviewCount,
    required this.locationNames,
    required this.isOwnedByCurrentUser,
    required this.myRating,
    required this.myReviewText,
  });

  bool get hasMyReview => myRating != null;
}

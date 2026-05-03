class DiscoverTripCard {
  final String id;
  final String title;
  final String? coverImageUrl;
  final DateTime? startDate;
  final bool isPublic;
  final double? averageRating;
  final int reviewCount;
  final List<String> locationNames;

  DiscoverTripCard({
    required this.id,
    required this.title,
    required this.coverImageUrl,
    required this.startDate,
    required this.isPublic,
    required this.averageRating,
    required this.reviewCount,
    required this.locationNames,
  });
}

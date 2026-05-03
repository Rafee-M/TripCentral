class TripReview {
  final String id;
  final String tripListId;
  final String reviewerId;
  final int rating;
  final String? reviewText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String reviewerUsername;
  final String? reviewerDisplayName;
  final String? reviewerAvatarUrl;

  TripReview({
    required this.id,
    required this.tripListId,
    required this.reviewerId,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
    required this.updatedAt,
    required this.reviewerUsername,
    required this.reviewerDisplayName,
    required this.reviewerAvatarUrl,
  });

  factory TripReview.fromJson(Map<String, dynamic> json) {
    return TripReview(
      id: json['id'].toString(),
      tripListId: json['trip_list_id'].toString(),
      reviewerId: json['reviewer_id'].toString(),
      rating: (json['rating'] as num).toInt(),
      reviewText: (json['review_text']?.toString().trim().isEmpty ?? true)
          ? null
          : json['review_text'].toString().trim(),
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
      reviewerUsername: (json['reviewer_username'] ?? 'user').toString(),
      reviewerDisplayName: json['reviewer_display_name']?.toString(),
      reviewerAvatarUrl: json['reviewer_avatar_url']?.toString(),
    );
  }

  String get displayName {
    final name = reviewerDisplayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return reviewerUsername;
  }
}

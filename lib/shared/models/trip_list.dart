
class TripList {
  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final bool isPublic;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripList({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description,
    this.coverImageUrl,
    required this.isPublic,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory Pattern to seamlessly deserialize database payloads into strict Dart Objects
  factory TripList.fromJson(Map<String, dynamic> json) {
    return TripList(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'cover_image_url': coverImageUrl,
      'is_public': isPublic,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
    };
  }
}


import '../../models/discover_trip_card.dart';

abstract class TripDiscoverySortStrategy {
  List<DiscoverTripCard> sort(List<DiscoverTripCard> cards);
}

class TitleSortStrategy implements TripDiscoverySortStrategy {
  @override
  List<DiscoverTripCard> sort(List<DiscoverTripCard> cards) {
    cards.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return cards;
  }
}

class DateSortStrategy implements TripDiscoverySortStrategy {
  @override
  List<DiscoverTripCard> sort(List<DiscoverTripCard> cards) {
    cards.sort((a, b) {
      final aDate = a.startDate;
      final bDate = b.startDate;

      if (aDate == null && bDate == null) return a.title.compareTo(b.title);
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return cards;
  }
}

class RatingSortStrategy implements TripDiscoverySortStrategy {
  @override
  List<DiscoverTripCard> sort(List<DiscoverTripCard> cards) {
    cards.sort((a, b) {
      final aRating = a.averageRating ?? 0;
      final bRating = b.averageRating ?? 0;
      return bRating.compareTo(aRating);
    });
    return cards;
  }
}

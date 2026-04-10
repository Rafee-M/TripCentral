class DiscoverySpot {
  const DiscoverySpot({
    required this.name,
    required this.city,
    required this.popularity,
    required this.recencyDays,
    required this.distanceKm,
  });

  final String name;
  final String city;
  final int popularity;
  final int recencyDays;
  final double distanceKm;
}

abstract class DiscoveryStrategy {
  String get name;

  List<DiscoverySpot> order(List<DiscoverySpot> spots);
}

class PopularFirstStrategy implements DiscoveryStrategy {
  const PopularFirstStrategy();

  @override
  String get name => 'Popular first';

  @override
  List<DiscoverySpot> order(List<DiscoverySpot> spots) {
    final sorted = List<DiscoverySpot>.of(spots);
    sorted.sort((left, right) => right.popularity.compareTo(left.popularity));
    return sorted;
  }
}

class RecentFirstStrategy implements DiscoveryStrategy {
  const RecentFirstStrategy();

  @override
  String get name => 'Recently saved';

  @override
  List<DiscoverySpot> order(List<DiscoverySpot> spots) {
    final sorted = List<DiscoverySpot>.of(spots);
    sorted.sort((left, right) => left.recencyDays.compareTo(right.recencyDays));
    return sorted;
  }
}

class NearbyFirstStrategy implements DiscoveryStrategy {
  const NearbyFirstStrategy();

  @override
  String get name => 'Nearby first';

  @override
  List<DiscoverySpot> order(List<DiscoverySpot> spots) {
    final sorted = List<DiscoverySpot>.of(spots);
    sorted.sort((left, right) => left.distanceKm.compareTo(right.distanceKm));
    return sorted;
  }
}

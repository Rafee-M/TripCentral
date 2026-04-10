import '../strategy/discovery_strategy.dart';

class TripDataFacade {
  const TripDataFacade();

  static const List<DiscoverySpot> _sampleSpots = <DiscoverySpot>[
    DiscoverySpot(
      name: 'Cox\'s Bazar Sea Drive',
      city: 'Cox\'s Bazar',
      popularity: 98,
      recencyDays: 3,
      distanceKm: 6.4,
    ),
    DiscoverySpot(
      name: 'Lalbagh Fort',
      city: 'Dhaka',
      popularity: 86,
      recencyDays: 11,
      distanceKm: 2.1,
    ),
    DiscoverySpot(
      name: 'Ahsan Manzil',
      city: 'Dhaka',
      popularity: 81,
      recencyDays: 7,
      distanceKm: 1.8,
    ),
    DiscoverySpot(
      name: 'Sajek Valley Viewpoint',
      city: 'Rangamati',
      popularity: 95,
      recencyDays: 1,
      distanceKm: 12.3,
    ),
    DiscoverySpot(
      name: 'Ratargul Swamp Forest',
      city: 'Sylhet',
      popularity: 74,
      recencyDays: 5,
      distanceKm: 4.7,
    ),
  ];

  List<DiscoverySpot> featuredSpots(DiscoveryStrategy strategy) {
    return strategy.order(_sampleSpots);
  }

  List<DiscoverySpot> searchSpots(String query) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return List<DiscoverySpot>.of(_sampleSpots);
    }

    return _sampleSpots.where((spot) {
      return spot.name.toLowerCase().contains(normalizedQuery) ||
          spot.city.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  String buildTripSummary(DiscoverySpot spot) {
    return 'Use this facade to combine Google Maps data, Supabase trip lists, and collaborator notes for ${spot.name}.';
  }
}

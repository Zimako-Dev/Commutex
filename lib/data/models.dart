
enum LocationType {
  rank,
  township,
  suburb,
  cityCenter,
  mall,
}

class Location {
  final String id;
  final String name;
  final LocationType type;
  // Simplified coordinates for mock distance calc (0-100 grid)
  final double x; 
  final double y;

  const Location({
    required this.id,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
  });
}

class TripResult {
  final Location start;
  final Location end;
  final List<Location> stops;
  final double distanceKm;
  final double totalFare;
  final double durationMinutes;
  final Map<String, double> breakdown; // 'Base Fare', 'Distance', 'Traffic'

  TripResult({
    required this.start,
    required this.end,
    this.stops = const [],
    required this.distanceKm,
    required this.totalFare,
    required this.durationMinutes,
    required this.breakdown,
  });
}

class SavedRoute {
  final String id;
  final String name;
  final String startId;
  final String endId;
  final double lastFare;

  SavedRoute({
    required this.id,
    required this.name,
    required this.startId,
    required this.endId,
    required this.lastFare,
  });
}

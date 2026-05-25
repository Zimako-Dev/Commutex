import 'dart:math';
import '../data/models.dart';
import '../data/mock_data.dart';

class FareCalculatorService {
  
  // Singleton pattern
  static final FareCalculatorService _instance = FareCalculatorService._internal();
  factory FareCalculatorService() => _instance;
  FareCalculatorService._internal();

  /// Calculate trip details between two points
  TripResult calculateTrip(Location start, Location end, {List<Location> stops = const [], bool isPeak = false}) {
    double totalDistance = 0;
    Location current = start;
    
    // Calculate segments including stops
    List<Location> allPoints = [...stops, end];
    
    for (var point in allPoints) {
      totalDistance += _getDistance(current, point);
      current = point;
    }

    // Pricing Logic
    double base = MockData.baseFare;
    // Add base fare for each stop if it's a multi-trip (simplification: +50% base for each stop)
    if (stops.isNotEmpty) {
      base += (stops.length * (MockData.baseFare * 0.5));
    }

    double distanceCost = totalDistance * MockData.costPerKm;
    
    double subtotal = base + distanceCost;
    double trafficCost = 0;

    if (isPeak) {
      trafficCost = subtotal * (MockData.trafficSurgePeak - 1.0);
    }

    double total = subtotal + trafficCost;
    
    // Duration estimation: 2 mins per km + 5 mins per stop + traffic
    double duration = (totalDistance * 2.0) + (stops.length * 5.0);
    if (isPeak) duration *= 1.5;

    return TripResult(
      start: start,
      end: end,
      stops: stops,
      distanceKm: double.parse(totalDistance.toStringAsFixed(1)),
      totalFare: double.parse(total.toStringAsFixed(2)),
      durationMinutes: duration.ceilToDouble(),
      breakdown: {
        'Base Fare': double.parse(base.toStringAsFixed(2)),
        'Distance Charge': double.parse(distanceCost.toStringAsFixed(2)),
        if (trafficCost > 0) 'Traffic Surge': double.parse(trafficCost.toStringAsFixed(2)),
      },
    );
  }

  double _getDistance(Location a, Location b) {
    // Euclidean distance on grid
    double dx = a.x - b.x;
    double dy = a.y - b.y;
    double dist = sqrt(dx*dx + dy*dy);
    
    // Scale factor: 1 unit = 1.5 km (Approximation)
    return dist * 1.5;
  }

  List<Location> searchLocations(String query) {
    if (query.isEmpty) return [];
    return MockData.locations.where((loc) => 
      loc.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
}

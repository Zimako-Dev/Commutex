import 'models.dart';

class MockData {
  static const List<Location> locations = [
    // Johannesburg
    Location(id: 'jhb_cbd', name: 'JHB CBD (Bree Taxi Rank)', type: LocationType.rank, x: 50, y: 50),
    Location(id: 'sandton', name: 'Sandton City', type: LocationType.mall, x: 55, y: 58),
    Location(id: 'soweto', name: 'Soweto (Bara)', type: LocationType.township, x: 40, y: 40),
    Location(id: 'rosebank', name: 'Rosebank', type: LocationType.suburb, x: 52, y: 55),
    Location(id: 'midrand', name: 'Midrand (Mall of Africa)', type: LocationType.mall, x: 60, y: 65),
    Location(id: 'alex', name: 'Alexandra', type: LocationType.township, x: 56, y: 56),
    
    // Pretoria
    Location(id: 'pta_cbd', name: 'Pretoria CBD', type: LocationType.cityCenter, x: 70, y: 80),
    Location(id: 'menlyn', name: 'Menlyn Park', type: LocationType.mall, x: 75, y: 78),
    Location(id: 'mamelodi', name: 'Mamelodi', type: LocationType.township, x: 80, y: 80),
    
    // Cape Town
    Location(id: 'ct_cbd', name: 'Cape Town Station', type: LocationType.rank, x: 20, y: 10),
    Location(id: 'khayelitsha', name: 'Khayelitsha', type: LocationType.township, x: 25, y: 8),
    Location(id: 'bellville', name: 'Bellville', type: LocationType.suburb, x: 23, y: 12),
    
    // Durban
    Location(id: 'dbn_cbd', name: 'Durban CBD', type: LocationType.rank, x: 90, y: 30),
    Location(id: 'umhlanga', name: 'Umhlanga', type: LocationType.suburb, x: 92, y: 35),
    Location(id: 'umlazi', name: 'Umlazi', type: LocationType.township, x: 88, y: 25),
  ];

  static const double baseFare = 15.0; // R15 base
  static const double costPerKm = 12.0; // R12 per km
  static const double trafficSurgePeak = 1.3; // 30% surge
}

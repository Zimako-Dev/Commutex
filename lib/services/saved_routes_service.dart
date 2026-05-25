import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a saved/bookmarked route a commuter wants to keep handy.
class SavedRouteItem {
  final String id;
  final String name; // e.g. "Home → Work"
  final String from;
  final String to;
  final List<String> stops;
  final double fare;
  final double distanceKm;
  final int durationMin;
  final String category; // "Daily Commute", "Favorite", "Weekend", "Errands"
  final bool isFavorite;
  final DateTime createdAt;
  final int useCount;

  SavedRouteItem({
    required this.id,
    required this.name,
    required this.from,
    required this.to,
    this.stops = const [],
    required this.fare,
    required this.distanceKm,
    required this.durationMin,
    this.category = 'Favorite',
    this.isFavorite = false,
    required this.createdAt,
    this.useCount = 0,
  });

  SavedRouteItem copyWith({
    String? name,
    String? from,
    String? to,
    List<String>? stops,
    double? fare,
    double? distanceKm,
    int? durationMin,
    String? category,
    bool? isFavorite,
    int? useCount,
  }) =>
      SavedRouteItem(
        id: id,
        name: name ?? this.name,
        from: from ?? this.from,
        to: to ?? this.to,
        stops: stops ?? this.stops,
        fare: fare ?? this.fare,
        distanceKm: distanceKm ?? this.distanceKm,
        durationMin: durationMin ?? this.durationMin,
        category: category ?? this.category,
        isFavorite: isFavorite ?? this.isFavorite,
        createdAt: createdAt,
        useCount: useCount ?? this.useCount,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'from': from,
        'to': to,
        'stops': stops,
        'fare': fare,
        'distanceKm': distanceKm,
        'durationMin': durationMin,
        'category': category,
        'isFavorite': isFavorite,
        'createdAt': createdAt.toIso8601String(),
        'useCount': useCount,
      };

  static SavedRouteItem? fromJson(Map<String, dynamic> j) {
    try {
      return SavedRouteItem(
        id: j['id'] as String,
        name: j['name'] as String,
        from: j['from'] as String,
        to: j['to'] as String,
        stops: (j['stops'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        fare: (j['fare'] as num).toDouble(),
        distanceKm: (j['distanceKm'] as num).toDouble(),
        durationMin: (j['durationMin'] as num).toInt(),
        category: j['category'] as String? ?? 'Favorite',
        isFavorite: j['isFavorite'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        useCount: (j['useCount'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('SavedRouteItem.fromJson failed: $e');
      return null;
    }
  }
}

class SavedRoutesService extends ChangeNotifier {
  static const _kKey = 'saved_routes_v1';
  static final SavedRoutesService instance = SavedRoutesService._();
  SavedRoutesService._();

  List<SavedRouteItem> _items = [];
  bool _loaded = false;
  bool get loaded => _loaded;
  List<SavedRouteItem> get items => List.unmodifiable(_items);

  List<String> get categories {
    final s = _items.map((e) => e.category).toSet().toList();
    s.sort();
    return s;
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) {
        _items = _seed();
        await _persist();
      } else {
        final list = jsonDecode(raw) as List;
        _items = list
            .map((e) => SavedRouteItem.fromJson(e as Map<String, dynamic>))
            .whereType<SavedRouteItem>()
            .toList();
        if (_items.isEmpty) {
          _items = _seed();
          await _persist();
        }
      }
    } catch (e) {
      debugPrint('SavedRoutesService load failed: $e');
      _items = _seed();
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, jsonEncode(_items.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('SavedRoutesService persist failed: $e');
    }
  }

  Future<void> add(SavedRouteItem item) async {
    _items.insert(0, item);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> update(SavedRouteItem item) async {
    final i = _items.indexWhere((e) => e.id == item.id);
    if (i == -1) return;
    _items[i] = item;
    notifyListeners();
    await _persist();
  }

  Future<void> toggleFavorite(String id) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) return;
    _items[i] = _items[i].copyWith(isFavorite: !_items[i].isFavorite);
    notifyListeners();
    await _persist();
  }

  Future<void> incrementUse(String id) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i == -1) return;
    _items[i] = _items[i].copyWith(useCount: _items[i].useCount + 1);
    notifyListeners();
    await _persist();
  }

  List<SavedRouteItem> _seed() {
    final now = DateTime.now();
    return [
      SavedRouteItem(
        id: 'seed_1',
        name: 'Home → Work',
        from: 'Soweto (Bara)',
        to: 'JHB CBD (Bree Taxi Rank)',
        fare: 25,
        distanceKm: 18.4,
        durationMin: 35,
        category: 'Daily Commute',
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 12)),
        useCount: 42,
      ),
      SavedRouteItem(
        id: 'seed_2',
        name: 'Work → Mall',
        from: 'Sandton City',
        to: 'Mall of Africa',
        fare: 30,
        distanceKm: 22.0,
        durationMin: 28,
        category: 'Weekend',
        createdAt: now.subtract(const Duration(days: 5)),
        useCount: 6,
      ),
      SavedRouteItem(
        id: 'seed_3',
        name: 'Visit Gogo',
        from: 'Alexandra',
        to: 'Mamelodi',
        stops: const ['Pretoria CBD'],
        fare: 60,
        distanceKm: 48.5,
        durationMin: 75,
        category: 'Family',
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 30)),
        useCount: 11,
      ),
      SavedRouteItem(
        id: 'seed_4',
        name: 'Gym Run',
        from: 'Rosebank',
        to: 'Sandton City',
        fare: 12,
        distanceKm: 6.2,
        durationMin: 12,
        category: 'Errands',
        createdAt: now.subtract(const Duration(days: 2)),
        useCount: 18,
      ),
    ];
  }
}

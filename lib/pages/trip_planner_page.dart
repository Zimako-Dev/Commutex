import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../data/models.dart';
import '../services/fare_service.dart';
import '../widgets/modern_widgets.dart';
import '../widgets/location_picker.dart';
import '../theme.dart';
import '../nav.dart';

enum TripType { oneWay, roundTrip }

class TripPlannerPage extends StatefulWidget {
  const TripPlannerPage({super.key});

  @override
  State<TripPlannerPage> createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends State<TripPlannerPage> {
  Location? startLocation;
  Location? endLocation;
  List<Location?> stops = [];

  TripType tripType = TripType.oneWay;
  bool isPeakHour = false;
  int passengers = 1;
  TimeOfDay? departureTime;
  DateTime? departureDate;

  void _addStop() {
    if (stops.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum 5 stops allowed")),
      );
      return;
    }
    setState(() => stops.add(null));
  }

  void _removeStop(int index) => setState(() => stops.removeAt(index));

  void _updateStop(int index, Location loc) =>
      setState(() => stops[index] = loc);

  void _reorderStop(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = stops.removeAt(oldIndex);
      stops.insert(newIndex, item);
    });
  }

  void _swapStartEnd() {
    setState(() {
      final tmp = startLocation;
      startLocation = endLocation;
      endLocation = tmp;
    });
  }

  void _pickDepartureTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: departureTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        departureTime = picked;
        // Auto-detect peak hour (7-9am, 4-7pm)
        final h = picked.hour;
        isPeakHour = (h >= 7 && h <= 9) || (h >= 16 && h <= 19);
      });
    }
  }

  void _pickDepartureDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: departureDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => departureDate = picked);
  }

  TripResult? get _livePreview {
    if (startLocation == null || endLocation == null) return null;
    final validStops = stops.whereType<Location>().toList();
    var result = FareCalculatorService().calculateTrip(
      startLocation!,
      endLocation!,
      stops: validStops,
      isPeak: isPeakHour,
    );
    if (tripType == TripType.roundTrip) {
      result = TripResult(
        start: result.start,
        end: result.end,
        stops: result.stops,
        distanceKm: double.parse((result.distanceKm * 2).toStringAsFixed(1)),
        totalFare: double.parse((result.totalFare * 2).toStringAsFixed(2)),
        durationMinutes: result.durationMinutes * 2,
        breakdown: result.breakdown
            .map((k, v) => MapEntry(k, double.parse((v * 2).toStringAsFixed(2)))),
      );
    }
    return result;
  }

  void _planTrip() {
    final result = _livePreview;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Start and End locations are required")),
      );
      return;
    }
    context.push(AppRoutes.results, extra: result);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _livePreview;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Planner"),
        actions: [
          IconButton(
            tooltip: "Save Route",
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: preview == null
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Route saved to favorites")),
                    );
                  },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ───── Live Trip Hero ─────
            _TripHeroCard(preview: preview, passengers: passengers, tripType: tripType),

            const SizedBox(height: AppSpacing.md),

            // ───── Trip Type Toggle ─────
            _TripTypeToggle(
              value: tripType,
              onChanged: (v) => setState(() => tripType = v),
            ),

            const SizedBox(height: AppSpacing.md),

            // ───── Route Builder ─────
            SleekCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.alt_route, size: 20),
                      const SizedBox(width: 8),
                      Text("Your Route",
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        tooltip: "Swap start & destination",
                        icon: const Icon(Icons.swap_vert),
                        onPressed: _swapStartEnd,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Start
                  _RoutePoint(
                    color: Colors.green,
                    icon: Icons.trip_origin,
                    child: LocationPicker(
                      label: "Pickup",
                      value: startLocation,
                      onChanged: (loc) => setState(() => startLocation = loc),
                      icon: Icons.my_location,
                    ),
                  ),

                  // Reorderable stops
                  if (stops.isNotEmpty)
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorder: _reorderStop,
                      children: [
                        for (int i = 0; i < stops.length; i++)
                          Padding(
                            key: ValueKey('stop_$i'),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: _RoutePoint(
                              color: Colors.orange,
                              icon: Icons.adjust,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: LocationPicker(
                                      label: "Stop ${i + 1}",
                                      value: stops[i],
                                      onChanged: (loc) => _updateStop(i, loc),
                                      icon: Icons.place_outlined,
                                    ),
                                  ),
                                  ReorderableDragStartListener(
                                    index: i,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(Icons.drag_handle, color: Colors.grey),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                    onPressed: () => _removeStop(i),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),

                  // Add stop
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addStop,
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: Text("Add Stop  (${stops.length}/5)"),
                    ),
                  ),

                  // End
                  _RoutePoint(
                    color: Colors.red,
                    icon: Icons.flag,
                    isLast: true,
                    child: LocationPicker(
                      label: "Destination",
                      value: endLocation,
                      onChanged: (loc) => setState(() => endLocation = loc),
                      icon: Icons.flag_outlined,
                    ),
                  ),
                ],
              ),
            ),

            // ───── Schedule & Options ─────
            SleekCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 20),
                      const SizedBox(width: 8),
                      Text("Schedule & Options",
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _OptionTile(
                          icon: Icons.calendar_today,
                          label: "Date",
                          value: departureDate == null
                              ? "Today"
                              : "${departureDate!.day}/${departureDate!.month}",
                          onTap: _pickDepartureDate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _OptionTile(
                          icon: Icons.access_time,
                          label: "Departure",
                          value: departureTime?.format(context) ?? "Now",
                          onTap: _pickDepartureTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Peak hour
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      Icons.local_fire_department,
                      color: isPeakHour ? Colors.orange : Colors.grey,
                    ),
                    title: const Text("Peak Hour Surge"),
                    subtitle: Text(
                      isPeakHour
                          ? "+50% surge applied"
                          : "Off-peak — standard fare",
                      style: TextStyle(
                        color: isPeakHour ? Colors.orange : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    value: isPeakHour,
                    onChanged: (v) => setState(() => isPeakHour = v),
                  ),

                  const Divider(height: 24),

                  // Passengers stepper
                  Row(
                    children: [
                      const Icon(Icons.people_alt_outlined),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text("Passengers (split fare)",
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      _Stepper(
                        value: passengers,
                        min: 1,
                        max: 14,
                        onChanged: (v) => setState(() => passengers = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ───── Smart suggestions ─────
            if (preview != null) _SmartSuggestions(preview: preview),

            const SizedBox(height: AppSpacing.md),

            // ───── CTA ─────
            PrimaryButton(
              label: preview == null
                  ? "Add Pickup & Destination"
                  : "View Detailed Breakdown",
              fullWidth: true,
              icon: Icons.arrow_forward,
              onPressed: preview == null ? null : _planTrip,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Hero card
// ─────────────────────────────────────────────────────────────────────────────
class _TripHeroCard extends StatelessWidget {
  final TripResult? preview;
  final int passengers;
  final TripType tripType;

  const _TripHeroCard({
    required this.preview,
    required this.passengers,
    required this.tripType,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = preview != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: SmartColors.primaryLight.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SmartColors.primaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.route, color: SmartColors.primaryLight, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                tripType == TripType.roundTrip ? "Round Trip" : "One-Way Trip",
                style: const TextStyle(
                  color: Colors.white70,
                  letterSpacing: 0.5,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (hasData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 8),
                      SizedBox(width: 6),
                      Text("LIVE",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            hasData ? "R ${preview!.totalFare.toStringAsFixed(2)}" : "R 0.00",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ).animate(key: ValueKey(preview?.totalFare)).fadeIn(duration: 250.ms),
          const SizedBox(height: 4),
          Text(
            hasData
                ? "≈ R ${(preview!.totalFare / passengers).toStringAsFixed(2)} per person (×$passengers)"
                : "Enter your route to see live fare",
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _HeroMetric(
                icon: Icons.straighten,
                label: "Distance",
                value: hasData ? "${preview!.distanceKm} km" : "—",
              ),
              _HeroDivider(),
              _HeroMetric(
                icon: Icons.timer_outlined,
                label: "Duration",
                value: hasData ? "${preview!.durationMinutes.toInt()} min" : "—",
              ),
              _HeroDivider(),
              _HeroMetric(
                icon: Icons.location_on_outlined,
                label: "Stops",
                value: hasData ? "${preview!.stops.length}" : "0",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: Colors.white12);
}

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _HeroMetric({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Icon(icon, color: SmartColors.primaryLight, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Route point row (timeline-style)
// ─────────────────────────────────────────────────────────────────────────────
class _RoutePoint extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Widget child;
  final bool isLast;
  const _RoutePoint({
    required this.color,
    required this.icon,
    required this.child,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 28),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: child,
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trip type toggle (One-way / Round-trip)
// ─────────────────────────────────────────────────────────────────────────────
class _TripTypeToggle extends StatelessWidget {
  final TripType value;
  final ValueChanged<TripType> onChanged;
  const _TripTypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? SmartColors.darkSurfaceVariant : SmartColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: TripType.values.map((t) {
          final selected = t == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? SmartColors.primaryLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t == TripType.oneWay ? Icons.arrow_forward : Icons.sync_alt,
                      size: 16,
                      color: selected ? Colors.black : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t == TripType.oneWay ? "One-Way" : "Round Trip",
                      style: TextStyle(
                        color: selected ? Colors.black : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Option tile (date/time chips)
// ─────────────────────────────────────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? SmartColors.darkSurfaceVariant : SmartColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: SmartColors.primaryLight),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stepper widget
// ─────────────────────────────────────────────────────────────────────────────
class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? SmartColors.darkSurfaceVariant : SmartColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          IconButton(
            iconSize: 18,
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 24,
            child: Text("$value",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          IconButton(
            iconSize: 18,
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Smart suggestions banner
// ─────────────────────────────────────────────────────────────────────────────
class _SmartSuggestions extends StatelessWidget {
  final TripResult preview;
  const _SmartSuggestions({required this.preview});

  String get _tip {
    if (preview.distanceKm > 30) {
      return "Long trip — consider splitting fare with passengers to save.";
    }
    if (preview.stops.length >= 3) {
      return "Tip: Multiple stops increase cost. Reorder for the shortest path.";
    }
    if (preview.totalFare > 100) {
      return "Travelling off-peak could save up to 33% on this route.";
    }
    return "Save this route for quick access later.";
  }

  IconData get _icon {
    if (preview.distanceKm > 30) return Icons.group;
    if (preview.stops.length >= 3) return Icons.alt_route;
    if (preview.totalFare > 100) return Icons.savings;
    return Icons.lightbulb_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: SmartColors.primaryLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: SmartColors.primaryLight.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SmartColors.primaryLight.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: SmartColors.primaryLight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Smart Tip",
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: SmartColors.primaryLight)),
                const SizedBox(height: 2),
                Text(_tip, style: const TextStyle(fontSize: 13, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

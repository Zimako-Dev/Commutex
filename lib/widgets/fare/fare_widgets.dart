import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smarttaxi/data/mock_data.dart';
import 'package:smarttaxi/data/models.dart';
import 'package:smarttaxi/services/fare_service.dart';
import 'package:smarttaxi/widgets/home/home_widgets.dart';
import 'package:smarttaxi/widgets/onboarding/onboarding_heroes.dart';
import 'package:smarttaxi/widgets/onboarding/onboarding_scene.dart';

const fareBlue = Color(0xFF5AA9FF);

const _cities = {
  'Johannesburg': ['jhb_cbd', 'sandton', 'soweto', 'rosebank', 'midrand', 'alex'],
  'Pretoria': ['pta_cbd', 'menlyn', 'mamelodi'],
  'Cape Town': ['ct_cbd', 'khayelitsha', 'bellville'],
  'Durban': ['dbn_cbd', 'umhlanga', 'umlazi'],
};

String cityOf(Location l) => _cities.entries.firstWhere((e) => e.value.contains(l.id), orElse: () => const MapEntry('', [])).key;

String typeLabel(LocationType t) => switch (t) {
      LocationType.rank => 'Taxi rank',
      LocationType.township => 'Township',
      LocationType.suburb => 'Suburb',
      LocationType.cityCenter => 'City centre',
      LocationType.mall => 'Mall',
    };

IconData typeIcon(LocationType t) => switch (t) {
      LocationType.rank => Icons.local_taxi_rounded,
      LocationType.township => Icons.home_work_rounded,
      LocationType.suburb => Icons.holiday_village_rounded,
      LocationType.cityCenter => Icons.location_city_rounded,
      LocationType.mall => Icons.shopping_bag_rounded,
    };

Color typeColor(LocationType t) => switch (t) {
      LocationType.rank => OnbPalette.gold,
      LocationType.township => OnbPalette.teal,
      LocationType.suburb => homeViolet,
      LocationType.cityCenter => fareBlue,
      LocationType.mall => homeRose,
    };

/// "JHB CBD (Bree Taxi Rank)" → "JHB CBD".
String shortName(String name) => name.split(' (').first;

String rand(double v) => 'R${v.toStringAsFixed(2)}';

// ═══════════════════════════════════════════════════════════════════════════
// Live fare hero
// ═══════════════════════════════════════════════════════════════════════════

class FareHeroCard extends StatelessWidget {
  const FareHeroCard({
    super.key,
    required this.pal,
    required this.trip,
    required this.passengers,
    required this.tipPercent,
    required this.peak,
    required this.autoPeak,
  });

  final OnbPalette pal;
  final TripResult? trip;
  final int passengers;
  final double tipPercent;
  final bool peak;
  final bool autoPeak;

  @override
  Widget build(BuildContext context) {
    final t = trip;
    final fare = t?.totalFare ?? 0;
    final tip = fare * tipPercent / 100;
    final total = fare + tip;
    final each = passengers > 0 ? total / passengers : total;
    final peakColor = peak ? OnbPalette.ember : homeTealText(pal);

    return GlassPanel(
      pal: pal,
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      glow: OnbPalette.gold.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'LIVE ESTIMATE',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.8, color: homeAccentText(pal)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: peakColor.withValues(alpha: 0.12),
                  border: Border.all(color: peakColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: peakColor)),
                    const SizedBox(width: 6),
                    Text(
                      '${peak ? 'Peak +30%' : 'Off-peak'}${autoPeak ? ' · auto' : ''}',
                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: peakColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, if (current != null) current],
            ),
            child: t == null
                ? Column(
                    key: const ValueKey('empty'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('R —', style: GoogleFonts.outfit(fontSize: 50, fontWeight: FontWeight.w700, height: 1.1, color: pal.muted)),
                      const SizedBox(height: 4),
                      Text(
                        'Choose a pickup and destination to see your fare.',
                        style: GoogleFonts.inter(fontSize: 13.5, color: pal.muted),
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('fare'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: total),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            rand(v),
                            style: GoogleFonts.outfit(
                              fontSize: 50,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              letterSpacing: -1.5,
                              color: pal.text,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          style: GoogleFonts.inter(fontSize: 13.5, color: pal.muted),
                          children: [
                            if (passengers > 1) ...[
                              TextSpan(
                                text: '${rand(each)} each',
                                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: homeAccentText(pal)),
                              ),
                              TextSpan(text: ' · split $passengers ways'),
                            ] else
                              const TextSpan(text: 'Total for your trip'),
                            if (tip > 0) TextSpan(text: ' · incl. ${rand(tip)} tip'),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Metric(pal: pal, icon: Icons.straighten_rounded, value: t == null ? '—' : '${t.distanceKm} km', label: 'Distance'),
              _Metric(pal: pal, icon: Icons.schedule_rounded, value: t == null ? '—' : '${t.durationMinutes.round()} min', label: 'Travel time'),
              _Metric(pal: pal, icon: Icons.more_vert_rounded, value: t == null ? '—' : '${t.stops.length}', label: 'Stops'),
            ],
          ),
          if (t != null) ...[
            const SizedBox(height: 16),
            FareComposition(pal: pal, trip: t, tip: tip),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.pal, required this.icon, required this.value, required this.label});

  final OnbPalette pal;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: pal.muted),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: pal.text)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: pal.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stacked bar showing what the fare is made of.
class FareComposition extends StatelessWidget {
  const FareComposition({super.key, required this.pal, required this.trip, required this.tip});

  final OnbPalette pal;
  final TripResult trip;
  final double tip;

  @override
  Widget build(BuildContext context) {
    final parts = <(String, double, Color)>[
      ('Base', trip.breakdown['Base Fare'] ?? 0, OnbPalette.gold),
      ('Distance', trip.breakdown['Distance Charge'] ?? 0, homeViolet),
      if ((trip.breakdown['Traffic Surge'] ?? 0) > 0) ('Peak surge', trip.breakdown['Traffic Surge']!, OnbPalette.ember),
      if (tip > 0) ('Tip', tip, OnbPalette.teal),
    ];
    final total = parts.fold<double>(0, (a, b) => a + b.$2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth - (parts.length - 1) * 3;
          return Row(
            children: [
              for (var i = 0; i < parts.length; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  height: 10,
                  width: total == 0 ? 0 : w * parts[i].$2 / total,
                  decoration: BoxDecoration(color: parts[i].$3, borderRadius: BorderRadius.circular(5)),
                ),
              ],
            ],
          );
        }),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final p in parts)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: p.$3, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(p.$1, style: GoogleFonts.inter(fontSize: 12, color: pal.muted)),
                  const SizedBox(width: 4),
                  Text(rand(p.$2), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: pal.text)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Journey builder
// ═══════════════════════════════════════════════════════════════════════════

enum StopKind { pickup, stop, destination }

class JourneyStopRow extends StatelessWidget {
  const JourneyStopRow({
    super.key,
    required this.pal,
    required this.kind,
    required this.location,
    required this.onTap,
    this.index = 0,
    this.onRemove,
    this.dragHandle,
  });

  final OnbPalette pal;
  final StopKind kind;
  final Location? location;
  final VoidCallback onTap;
  final int index;
  final VoidCallback? onRemove;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final (dot, label, hint) = switch (kind) {
      StopKind.pickup => (OnbPalette.teal, 'PICKUP', 'Where are you starting?'),
      StopKind.stop => (OnbPalette.gold, 'STOP ${index + 1}', 'Add a stop on the way'),
      StopKind.destination => (OnbPalette.ember, 'DESTINATION', 'Where are you going?'),
    };
    final loc = location;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Center(
              child: Container(
                width: kind == StopKind.stop ? 12 : 16,
                height: kind == StopKind.stop ? 12 : 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pal.surface,
                  border: Border.all(color: dot, width: kind == StopKind.stop ? 3 : 4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              button: true,
              label: loc == null ? hint : '$label: ${loc.name}. Tap to change',
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  height: 62,
                  padding: const EdgeInsets.only(left: 10, right: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: pal.glass,
                    border: Border.all(color: loc == null ? pal.stroke : dot.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: (loc == null ? pal.muted : typeColor(loc.type)).withValues(alpha: 0.14),
                        ),
                        child: Icon(
                          loc == null ? Icons.search_rounded : typeIcon(loc.type),
                          size: 20,
                          color: loc == null ? pal.muted : typeColor(loc.type),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: pal.muted)),
                            const SizedBox(height: 2),
                            Text(
                              loc?.name ?? hint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: loc == null ? FontWeight.w500 : FontWeight.w600,
                                color: loc == null ? pal.muted : pal.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onRemove != null)
                        IconButton(
                          tooltip: 'Remove stop',
                          visualDensity: VisualDensity.compact,
                          onPressed: onRemove,
                          icon: Icon(Icons.close_rounded, size: 19, color: pal.muted),
                        )
                      else
                        Icon(Icons.chevron_right_rounded, color: pal.muted),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (dragHandle != null) dragHandle!,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Location search sheet
// ═══════════════════════════════════════════════════════════════════════════

Future<Location?> showLocationSheet(
  BuildContext context, {
  required String title,
  Location? current,
  Location? other,
}) {
  return showModalBottomSheet<Location>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _LocationSheet(title: title, current: current, other: other),
  );
}

class _LocationSheet extends StatefulWidget {
  const _LocationSheet({required this.title, this.current, this.other});

  final String title;
  final Location? current;
  final Location? other;

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matches(Location l, String q) {
    if (q.isEmpty) return true;
    final s = q.toLowerCase();
    return l.name.toLowerCase().contains(s) || cityOf(l).toLowerCase().contains(s) || typeLabel(l.type).toLowerCase().contains(s);
  }

  @override
  Widget build(BuildContext context) {
    final pal = OnbPalette(Theme.of(context).brightness == Brightness.light ? 1 : 0);
    final q = _query.text.trim();
    final media = MediaQuery.of(context);
    final results = MockData.locations.where((l) => _matches(l, q)).toList();
    final other = widget.other;
    if (other != null) {
      results.sort((a, b) => FareCalculatorService().calculateTrip(other, a).distanceKm.compareTo(FareCalculatorService().calculateTrip(other, b).distanceKm));
    }
    // Group by city when browsing; flat list (nearest first) when searching or when a reference point exists.
    final grouped = q.isEmpty && other == null;
    const none = InputBorder.none;

    Widget row(Location l) {
      final same = other != null && other.id == l.id;
      final selected = widget.current?.id == l.id;
      final km = other == null || same ? null : FareCalculatorService().calculateTrip(other, l).distanceKm;
      return Opacity(
        opacity: same ? 0.4 : 1,
        child: Semantics(
          button: !same,
          label: '${l.name}, ${typeLabel(l.type)} in ${cityOf(l)}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: same
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context, l);
                  },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: selected ? OnbPalette.gold.withValues(alpha: 0.12) : pal.glass,
                border: Border.all(color: selected ? OnbPalette.gold.withValues(alpha: 0.6) : pal.stroke),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), color: typeColor(l.type).withValues(alpha: 0.15)),
                    child: Icon(typeIcon(l.type), size: 21, color: typeColor(l.type)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: pal.text)),
                        Text('${typeLabel(l.type)} · ${cityOf(l)}', style: GoogleFonts.inter(fontSize: 12, color: pal.muted)),
                      ],
                    ),
                  ),
                  if (same)
                    Text('Already chosen', style: GoogleFonts.inter(fontSize: 11.5, color: pal.muted))
                  else if (selected)
                    Icon(Icons.check_circle_rounded, color: homeAccentText(pal), size: 20)
                  else if (km != null)
                    Text('$km km', style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w700, color: pal.muted)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final children = <Widget>[];
    if (results.isEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.wrong_location_outlined, size: 40, color: pal.muted),
            const SizedBox(height: 10),
            Text('No places match "$q"', style: GoogleFonts.inter(fontSize: 14, color: pal.muted)),
          ],
        ),
      ));
    } else if (grouped) {
      for (final city in _cities.keys) {
        final inCity = results.where((l) => cityOf(l) == city).toList();
        if (inCity.isEmpty) continue;
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(city.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: pal.muted)),
        ));
        children.addAll(inCity.map(row));
      }
    } else {
      if (other != null && q.isEmpty) {
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            'NEAREST TO ${shortName(other.name).toUpperCase()}',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: pal.muted),
          ),
        ));
      }
      children.addAll(results.map(row));
    }

    return Container(
      height: media.size.height * 0.86,
      margin: EdgeInsets.only(bottom: media.viewInsets.bottom),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: Color.lerp(const Color(0xFF17161B), const Color(0xFFFFFAF2), pal.day),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: pal.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: pal.faint, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(widget.title, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: pal.text)),
          const SizedBox(height: 12),
          Container(
            height: 52,
            padding: const EdgeInsets.only(left: 14, right: 4),
            decoration: BoxDecoration(
              color: pal.glass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: OnbPalette.gold.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: pal.muted, size: 21),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _query,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) {
                      final pick = results.where((l) => other == null || l.id != other.id).firstOrNull;
                      if (pick != null) Navigator.pop(context, pick);
                    },
                    cursorColor: OnbPalette.gold,
                    style: GoogleFonts.inter(fontSize: 15, color: pal.text),
                    decoration: InputDecoration(
                      hintText: 'Search ranks, townships, malls…',
                      hintStyle: GoogleFonts.inter(fontSize: 15, color: pal.muted),
                      filled: false,
                      isDense: true,
                      border: none,
                      enabledBorder: none,
                      focusedBorder: none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (q.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: () => setState(_query.clear),
                    icon: Icon(Icons.close_rounded, color: pal.muted, size: 20),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: 20 + media.padding.bottom),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Options
// ═══════════════════════════════════════════════════════════════════════════

class FareSegmented<T> extends StatelessWidget {
  const FareSegmented({super.key, required this.pal, required this.values, required this.labels, required this.selected, required this.onChanged});

  final OnbPalette pal;
  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final i = values.indexOf(selected);
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: pal.glass,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: pal.stroke),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth / values.length;
        return Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              left: w * i,
              top: 0,
              bottom: 0,
              width: w,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: const LinearGradient(colors: [OnbPalette.goldBright, OnbPalette.gold]),
                ),
              ),
            ),
            Row(
              children: [
                for (var k = 0; k < values.length; k++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: k == i,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onChanged(values[k]);
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: k == i ? OnbPalette.ink : pal.muted,
                            ),
                            child: Text(labels[k]),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

/// A 15-seat minibus seat map; the first [riders] seats light up.
class SeatMap extends StatelessWidget {
  const SeatMap({super.key, required this.pal, required this.riders, required this.onChanged, this.seats = 15});

  final OnbPalette pal;
  final int riders;
  final int seats;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const perRow = 5;
    final rows = (seats / perRow).ceil();
    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Padding(
            padding: EdgeInsets.only(bottom: r < rows - 1 ? 8 : 0),
            child: Row(
              children: [
                for (var c = 0; c < perRow; c++) ...[
                  if (c > 0) SizedBox(width: c == 2 ? 18 : 8), // aisle after the second seat
                  Expanded(child: _seat(r * perRow + c)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _seat(int i) {
    if (i >= seats) return const SizedBox.shrink();
    final on = i < riders;
    return Semantics(
      button: true,
      label: '${i + 1} ${i == 0 ? 'rider' : 'riders'}',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(i + 1);
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 160 + i * 10),
          height: 36,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(8)),
            color: on ? OnbPalette.gold : pal.glass,
            border: Border.all(color: on ? OnbPalette.goldBright : pal.stroke),
          ),
          child: Icon(Icons.event_seat_rounded, size: 17, color: on ? OnbPalette.ink : pal.muted),
        ),
      ),
    );
  }
}

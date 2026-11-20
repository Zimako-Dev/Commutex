import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../nav.dart';
import 'result_page.dart' show FareQuote;
import '../services/fare_service.dart';
import '../services/saved_routes_service.dart';
import '../widgets/fare/fare_widgets.dart';
import '../widgets/home/home_widgets.dart';
import '../widgets/onboarding/onboarding_heroes.dart';
import '../widgets/onboarding/onboarding_scene.dart';

/// Optional route to pre-fill the estimator with (from saved or popular routes).
class FarePrefill {
  const FarePrefill({required this.from, required this.to, this.stops = const []});

  final String from;
  final String to;
  final List<String> stops;
}

enum _Pricing { auto, offPeak, peak }

class _StopSlot {
  _StopSlot(this.id, [this.location]);

  final int id;
  Location? location;
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key, this.prefill});

  final FarePrefill? prefill;

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  static const _maxStops = 10;
  static const _tips = [0.0, 5.0, 10.0, 15.0];
  static const _quick = [
    ('CBD → Soweto', 'jhb_cbd', 'soweto'),
    ('Sandton → Alex', 'sandton', 'alex'),
    ('PTA → Mamelodi', 'pta_cbd', 'mamelodi'),
    ('CT → Khayelitsha', 'ct_cbd', 'khayelitsha'),
    ('Durban → Umlazi', 'dbn_cbd', 'umlazi'),
  ];

  Location? _start;
  Location? _end;
  final List<_StopSlot> _stops = [];
  int _nextStopId = 0;
  _Pricing _pricing = _Pricing.auto;
  int _riders = 1;
  double _tip = 0;
  double _swapTurns = 0;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p != null) {
      _start = _match(p.from);
      _end = _match(p.to);
      for (final s in p.stops) {
        final l = _match(s);
        if (l != null) _stops.add(_StopSlot(_nextStopId++, l));
      }
    }
  }

  /// Finds the closest known place for a saved or popular route name.
  static Location? _match(String name) {
    final n = name.toLowerCase().trim();
    if (n.isEmpty) return null;
    for (final l in MockData.locations) {
      if (l.name.toLowerCase() == n) return l;
    }
    for (final l in MockData.locations) {
      final ln = l.name.toLowerCase();
      if (ln.contains(n) || n.contains(shortName(ln))) return l;
    }
    return null;
  }

  bool get _peak => switch (_pricing) {
        _Pricing.auto => RushStatus.at(DateTime.now()).peak,
        _Pricing.offPeak => false,
        _Pricing.peak => true,
      };

  TripResult? get _trip {
    if (_start == null || _end == null) return null;
    return FareCalculatorService().calculateTrip(
      _start!,
      _end!,
      stops: _stops.map((s) => s.location).whereType<Location>().toList(),
      isPeak: _peak,
    );
  }

  Future<void> _pick({required StopKind kind, int stopIndex = 0}) async {
    final (title, current, other) = switch (kind) {
      StopKind.pickup => ('Where are you starting?', _start, _end),
      StopKind.destination => ('Where are you going?', _end, _start),
      StopKind.stop => ('Add a stop', _stops[stopIndex].location, _start),
    };
    final picked = await showLocationSheet(context, title: title, current: current, other: other);
    if (picked == null || !mounted) return;
    setState(() {
      switch (kind) {
        case StopKind.pickup:
          _start = picked;
        case StopKind.destination:
          _end = picked;
        case StopKind.stop:
          _stops[stopIndex].location = picked;
      }
    });
  }

  Future<void> _addStop() async {
    if (_stops.length >= _maxStops) return;
    HapticFeedback.selectionClick();
    setState(() => _stops.add(_StopSlot(_nextStopId++)));
    await _pick(kind: StopKind.stop, stopIndex: _stops.length - 1);
    // Drop the stop again if nothing was chosen.
    if (mounted && _stops.isNotEmpty && _stops.last.location == null) {
      setState(() => _stops.removeLast());
    }
  }

  void _swap() {
    HapticFeedback.lightImpact();
    setState(() {
      final t = _start;
      _start = _end;
      _end = t;
      _swapTurns += 0.5;
    });
  }

  void _applyQuick((String, String, String) q) {
    HapticFeedback.selectionClick();
    setState(() {
      _start = MockData.locations.firstWhere((l) => l.id == q.$2);
      _end = MockData.locations.firstWhere((l) => l.id == q.$3);
      _stops.clear();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _start = null;
      _end = null;
      _stops.clear();
      _riders = 1;
      _tip = 0;
      _pricing = _Pricing.auto;
    });
  }

  void _openBreakdown() {
    final trip = _trip;
    if (trip == null) {
      _pick(kind: _start == null ? StopKind.pickup : StopKind.destination);
      return;
    }
    HapticFeedback.mediumImpact();
    context.push(AppRoutes.results, extra: FareQuote(trip: trip, riders: _riders, tipPercent: _tip));
  }

  Future<void> _save() async {
    final trip = _trip;
    if (trip == null) {
      _pick(kind: _start == null ? StopKind.pickup : StopKind.destination);
      return;
    }
    final svc = SavedRoutesService.instance;
    await svc.load();
    final stops = trip.stops.map((s) => s.name).toList();
    final exists = svc.items.any((e) => e.from == trip.start.name && e.to == trip.end.name && e.stops.join('|') == stops.join('|'));
    if (exists) {
      _toast('This route is already in your saved routes', icon: Icons.bookmark_rounded);
      return;
    }
    HapticFeedback.mediumImpact();
    await svc.add(SavedRouteItem(
      id: 'r_${DateTime.now().microsecondsSinceEpoch}',
      name: '${shortName(trip.start.name)} → ${shortName(trip.end.name)}',
      from: trip.start.name,
      to: trip.end.name,
      stops: stops,
      fare: trip.totalFare,
      distanceKm: trip.distanceKm,
      durationMin: trip.durationMinutes.round(),
      category: 'Favorite',
      createdAt: DateTime.now(),
    ));
    if (mounted) setState(() {});
    _toast('Saved to your routes', icon: Icons.bookmark_added_rounded, action: SnackBarAction(
      label: 'VIEW',
      textColor: OnbPalette.goldBright,
      onPressed: () => context.push(AppRoutes.saved),
    ));
  }

  bool get _isSaved {
    final trip = _trip;
    if (trip == null) return false;
    final stops = trip.stops.map((s) => s.name).join('|');
    return SavedRoutesService.instance.items.any((e) => e.from == trip.start.name && e.to == trip.end.name && e.stops.join('|') == stops);
  }

  void _toast(String message, {IconData icon = Icons.info_outline_rounded, SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1D1C22),
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 96),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0x26FFFFFF))),
          action: action,
          persist: false,
          content: Row(
            children: [
              Icon(icon, color: OnbPalette.gold, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: GoogleFonts.inter(fontSize: 13.5, color: Colors.white))),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final trip = _trip;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: isLight ? 1 : 0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
      builder: (context, day, _) {
        final pal = OnbPalette(day);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: day > 0.5 ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: pal.scrim,
            body: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(child: CustomPaint(painter: OnboardingScenePainter(time: 0, day: day, intro: 1))),
                ),
                LayoutBuilder(builder: (context, c) {
                  final side = c.maxWidth > 600 ? (c.maxWidth - 560) / 2 : 20.0;
                  return ListView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: EdgeInsets.fromLTRB(side, MediaQuery.paddingOf(context).top + 72, side, 130),
                    children: _content(pal, trip),
                  );
                }),
                Positioned(left: 0, right: 0, top: 0, child: _header(pal)),
                Positioned(left: 0, right: 0, bottom: 0, child: _bottomBar(pal, trip)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _circle(OnbPalette pal, IconData icon, String tip, VoidCallback onTap, {Color? color}) => Semantics(
        button: true,
        label: tip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: pal.glass, border: Border.all(color: pal.stroke)),
            child: Icon(icon, size: 21, color: color ?? pal.text),
          ),
        ),
      );

  Widget _header(OnbPalette pal) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 10, 20, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pal.scrim, pal.scrim, pal.scrim.withValues(alpha: 0)],
          stops: const [0, 0.78, 1],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Row(
            children: [
              _circle(pal, Icons.arrow_back_rounded, 'Back', () => context.canPop() ? context.pop() : context.go(AppRoutes.home)),
              Expanded(
                child: Text(
                  'Fare estimator',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w700, color: pal.text),
                ),
              ),
              _circle(pal, Icons.restart_alt_rounded, 'Start over', _reset),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(OnbPalette pal, TripResult? trip) {
    var i = 0;
    Widget enter(Widget w) =>
        w.animate().fadeIn(delay: (40 + (i++) * 60).ms, duration: 450.ms).slideY(begin: 0.08, curve: Curves.easeOutCubic);

    return [
      enter(FareHeroCard(
        pal: pal,
        trip: trip,
        passengers: _riders,
        tipPercent: _tip,
        peak: _peak,
        autoPeak: _pricing == _Pricing.auto,
      )),
      const SizedBox(height: 16),
      enter(_journeyCard(pal)),
      const SizedBox(height: 14),
      enter(_quickRoutes(pal)),
      const SizedBox(height: 22),
      enter(Text('Ride options', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: pal.text))),
      const SizedBox(height: 12),
      enter(_ridersCard(pal, trip)),
      const SizedBox(height: 12),
      enter(_tipCard(pal, trip)),
      const SizedBox(height: 12),
      enter(_pricingCard(pal)),
      const SizedBox(height: 14),
      enter(Text(
        'Estimates use R15 base, R12 per km and a 30% peak surge. Confirm the fare with your driver.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: 11.5, height: 1.5, color: pal.muted),
      )),
    ];
  }

  Widget _journeyCard(OnbPalette pal) {
    return GlassPanel(
      pal: pal,
      radius: 26,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 0, 6),
            child: Row(
              children: [
                Text('Your journey', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: pal.text)),
                const Spacer(),
                Semantics(
                  button: true,
                  label: 'Swap pickup and destination',
                  child: GestureDetector(
                    onTap: _swap,
                    child: AnimatedRotation(
                      turns: _swapTurns,
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [OnbPalette.goldBright, OnbPalette.gold]),
                        ),
                        child: const Icon(Icons.swap_vert_rounded, color: OnbPalette.ink, size: 21),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              // The dashed spine connecting every point of the journey.
              Positioned(
                left: 13,
                top: 34,
                bottom: 34,
                child: CustomPaint(size: const Size(2, double.infinity), painter: _SpinePainter(color: pal.faint)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  JourneyStopRow(pal: pal, kind: StopKind.pickup, location: _start, onTap: () => _pick(kind: StopKind.pickup)),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: _stops.length,
                    proxyDecorator: (child, _, __) => Material(color: Colors.transparent, child: child),
                    onReorderItem: (oldIndex, newIndex) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        final s = _stops.removeAt(oldIndex);
                        _stops.insert(newIndex, s);
                      });
                    },
                    itemBuilder: (context, k) {
                      final slot = _stops[k];
                      return JourneyStopRow(
                        key: ValueKey(slot.id),
                        pal: pal,
                        kind: StopKind.stop,
                        index: k,
                        location: slot.location,
                        onTap: () => _pick(kind: StopKind.stop, stopIndex: k),
                        onRemove: () {
                          HapticFeedback.selectionClick();
                          setState(() => _stops.removeAt(k));
                        },
                        dragHandle: _stops.length > 1
                            ? ReorderableDragStartListener(
                                index: k,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(Icons.drag_indicator_rounded, color: pal.muted),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                  if (_stops.length < _maxStops)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Center(
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: pal.surface, border: Border.all(color: pal.stroke)),
                                child: Icon(Icons.add_rounded, size: 14, color: homeAccentText(pal)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _addStop,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              child: Text(
                                'Add a stop  ·  ${_stops.length}/$_maxStops',
                                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: homeAccentText(pal)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  JourneyStopRow(pal: pal, kind: StopKind.destination, location: _end, onTap: () => _pick(kind: StopKind.destination)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickRoutes(OnbPalette pal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'POPULAR ROUTES',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: pal.muted),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _quick.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, k) {
              final q = _quick[k];
              final active = _start?.id == q.$2 && _end?.id == q.$3;
              return GestureDetector(
                onTap: () => _applyQuick(q),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: active ? OnbPalette.gold.withValues(alpha: 0.16) : pal.glass,
                    border: Border.all(color: active ? OnbPalette.gold : pal.stroke),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 16, color: homeAccentText(pal)),
                      const SizedBox(width: 6),
                      Text(q.$1, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: pal.text)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _optionCard(OnbPalette pal, {required IconData icon, required Color color, required String title, required String subtitle, Widget? trailing, Widget? body}) {
    return GlassPanel(
      pal: pal,
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: color.withValues(alpha: 0.15)),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: pal.text)),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(subtitle, key: ValueKey(subtitle), style: GoogleFonts.inter(fontSize: 12.5, color: pal.muted)),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          if (body != null) ...[const SizedBox(height: 14), body],
        ],
      ),
    );
  }

  Widget _ridersCard(OnbPalette pal, TripResult? trip) {
    Widget step(IconData icon, String tip, bool enabled, VoidCallback onTap) => Semantics(
          button: true,
          label: tip,
          enabled: enabled,
          child: GestureDetector(
            onTap: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    onTap();
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? OnbPalette.gold.withValues(alpha: 0.18) : pal.glass,
                border: Border.all(color: enabled ? OnbPalette.gold.withValues(alpha: 0.6) : pal.stroke),
              ),
              child: Icon(icon, size: 18, color: enabled ? homeAccentText(pal) : pal.muted),
            ),
          ),
        );
    final total = trip == null ? null : trip.totalFare * (1 + _tip / 100);
    return _optionCard(
      pal,
      icon: Icons.groups_rounded,
      color: OnbPalette.gold,
      title: 'Split the fare',
      subtitle: _riders == 1
          ? 'Just you'
          : total == null
              ? '$_riders riders'
              : '$_riders riders · ${rand(total / _riders)} each',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          step(Icons.remove_rounded, 'Fewer riders', _riders > 1, () => setState(() => _riders--)),
          SizedBox(
            width: 34,
            child: Text(
              '$_riders',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: pal.text),
            ),
          ),
          step(Icons.add_rounded, 'More riders', _riders < 15, () => setState(() => _riders++)),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SeatMap(pal: pal, riders: _riders, onChanged: (v) => setState(() => _riders = v)),
          const SizedBox(height: 8),
          Text('Tap a seat to set how many are riding · 15-seater', style: GoogleFonts.inter(fontSize: 11.5, color: pal.muted)),
        ],
      ),
    );
  }

  Widget _tipCard(OnbPalette pal, TripResult? trip) {
    final amount = trip == null ? null : trip.totalFare * _tip / 100;
    return _optionCard(
      pal,
      icon: Icons.volunteer_activism_rounded,
      color: OnbPalette.teal,
      title: 'Tip the driver',
      subtitle: _tip == 0 ? 'No tip' : amount == null ? '${_tip.round()}% of the fare' : '${_tip.round()}% · ${rand(amount)}',
      body: FareSegmented<double>(
        pal: pal,
        values: _tips,
        labels: const ['None', '5%', '10%', '15%'],
        selected: _tip,
        onChanged: (v) => setState(() => _tip = v),
      ),
    );
  }

  Widget _pricingCard(OnbPalette pal) {
    final rush = RushStatus.at(DateTime.now());
    final subtitle = switch (_pricing) {
      _Pricing.auto => rush.peak
          ? 'Auto: peak hour now (ends in ${rush.countdown})'
          : 'Auto: off-peak now (peak in ${rush.countdown})',
      _Pricing.offPeak => 'Standard fares, no surge',
      _Pricing.peak => 'Peak hours add a 30% surge',
    };
    return _optionCard(
      pal,
      icon: Icons.schedule_rounded,
      color: _peak ? OnbPalette.ember : homeViolet,
      title: 'When are you riding?',
      subtitle: subtitle,
      body: FareSegmented<_Pricing>(
        pal: pal,
        values: _Pricing.values,
        labels: const ['Now (auto)', 'Off-peak', 'Peak'],
        selected: _pricing,
        onChanged: (v) => setState(() => _pricing = v),
      ),
    );
  }

  Widget _bottomBar(OnbPalette pal, TripResult? trip) {
    final ready = trip != null;
    final saved = _isSaved;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [pal.scrim.withValues(alpha: 0), pal.scrim.withValues(alpha: 0.92), pal.scrim],
          stops: const [0, 0.35, 1],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: saved ? 'Route already saved' : 'Save this route',
                child: GestureDetector(
                  onTap: _save,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: saved ? OnbPalette.gold.withValues(alpha: 0.18) : pal.glassStrong,
                      border: Border.all(color: saved ? OnbPalette.gold : pal.stroke),
                    ),
                    child: Icon(
                      saved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                      color: saved ? homeAccentText(pal) : pal.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  button: true,
                  label: ready ? 'See the full fare breakdown' : 'Choose a route',
                  child: GestureDetector(
                    onTap: _openBreakdown,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 58,
                      padding: const EdgeInsets.only(left: 22, right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(29),
                        gradient: ready
                            ? const LinearGradient(colors: [OnbPalette.goldBright, OnbPalette.gold, OnbPalette.ember])
                            : null,
                        color: ready ? null : pal.glassStrong,
                        border: Border.all(color: ready ? Colors.transparent : pal.stroke),
                        boxShadow: [
                          if (ready)
                            BoxShadow(color: OnbPalette.gold.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8), spreadRadius: -2),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              ready ? 'See full breakdown' : (_start == null ? 'Choose a pickup' : 'Choose a destination'),
                              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: ready ? OnbPalette.ink : pal.text),
                            ),
                          ),
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ready ? OnbPalette.ink : OnbPalette.gold.withValues(alpha: 0.2),
                            ),
                            child: Icon(
                              ready ? Icons.receipt_long_rounded : Icons.search_rounded,
                              size: 20,
                              color: ready ? OnbPalette.goldBright : homeAccentText(pal),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpinePainter extends CustomPainter {
  _SpinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var y = 0.0; y < size.height; y += 8) {
      canvas.drawLine(Offset(1, y), Offset(1, (y + 4).clamp(0, size.height)), p);
    }
  }

  @override
  bool shouldRepaint(covariant _SpinePainter old) => old.color != color;
}

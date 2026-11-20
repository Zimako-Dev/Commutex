import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';
import '../nav.dart';
import '../services/fare_service.dart';
import '../services/saved_routes_service.dart';
import '../widgets/fare/fare_widgets.dart';
import '../widgets/home/home_widgets.dart';
import '../widgets/onboarding/onboarding_heroes.dart';
import '../widgets/onboarding/onboarding_scene.dart';

/// Everything the breakdown needs: the trip plus how it is being paid for.
class FareQuote {
  const FareQuote({required this.trip, this.riders = 1, this.tipPercent = 0});

  final TripResult trip;
  final int riders;
  final double tipPercent;

  double get fare => trip.totalFare;
  double get tip => fare * tipPercent / 100;
  double get total => fare + tip;
  double get each => riders > 0 ? total / riders : total;
  double get surge => trip.breakdown['Traffic Surge'] ?? 0;
  bool get peak => surge > 0;
}

/// South African notes and coins, largest first.
const _denominations = [200.0, 100.0, 50.0, 20.0, 10.0, 5.0, 2.0, 1.0];

List<double> _changeFor(double amount) {
  var left = amount;
  final out = <double>[];
  for (final d in _denominations) {
    while (left >= d - 0.001) {
      out.add(d);
      left -= d;
    }
  }
  return out;
}

class ResultPage extends StatefulWidget {
  const ResultPage({super.key, required this.quote});

  final FareQuote quote;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final DateTime _when = DateTime.now();

  FareQuote get q => widget.quote;
  TripResult get trip => widget.quote.trip;

  List<Location> get _points => [trip.start, ...trip.stops, trip.end];

  bool get _saved {
    final stops = trip.stops.map((s) => s.name).join('|');
    return SavedRoutesService.instance.items.any((e) => e.from == trip.start.name && e.to == trip.end.name && e.stops.join('|') == stops);
  }

  @override
  void initState() {
    super.initState();
    SavedRoutesService.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  String _shareText() {
    final b = StringBuffer()
      ..writeln('🚕 SmartTaxi fare estimate')
      ..writeln('From: ${trip.start.name}');
    if (trip.stops.isNotEmpty) b.writeln('Via: ${trip.stops.map((s) => s.name).join(' → ')}');
    b
      ..writeln('To: ${trip.end.name}')
      ..writeln('Distance: ${trip.distanceKm.toStringAsFixed(1)} km · about ${trip.durationMinutes.round()} min')
      ..writeln('Fare: ${rand(q.fare)}${q.peak ? ' (peak hour)' : ''}');
    if (q.tip > 0) b.writeln('Tip (${q.tipPercent.round()}%): ${rand(q.tip)}');
    b.writeln('Total: ${rand(q.total)}');
    if (q.riders > 1) b.writeln('Split ${q.riders} ways: ${rand(q.each)} each');
    b.write('Estimated with SmartTaxi 🇿🇦');
    return b.toString();
  }

  Future<void> _shareWhatsApp() async {
    HapticFeedback.selectionClick();
    final text = _shareText();
    try {
      final native = Uri(scheme: 'whatsapp', host: 'send', queryParameters: {'text': text});
      if (!kIsWeb && await canLaunchUrl(native)) {
        await launchUrl(native, mode: LaunchMode.externalApplication);
        return;
      }
      final ok = await launchUrl(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'), mode: LaunchMode.externalApplication);
      if (!ok) _toast("Couldn't open WhatsApp", icon: Icons.error_outline_rounded);
    } catch (e) {
      debugPrint('WhatsApp share error: $e');
      _toast("Couldn't open WhatsApp", icon: Icons.error_outline_rounded);
    }
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _shareText()));
    HapticFeedback.selectionClick();
    _toast('Fare details copied', icon: Icons.content_copy_rounded);
  }

  Future<void> _save() async {
    final svc = SavedRoutesService.instance;
    await svc.load();
    if (_saved) {
      _toast('Already in your saved routes', icon: Icons.bookmark_rounded);
      return;
    }
    HapticFeedback.mediumImpact();
    await svc.add(SavedRouteItem(
      id: 'r_${DateTime.now().microsecondsSinceEpoch}',
      name: '${shortName(trip.start.name)} → ${shortName(trip.end.name)}',
      from: trip.start.name,
      to: trip.end.name,
      stops: trip.stops.map((s) => s.name).toList(),
      fare: trip.totalFare,
      distanceKm: trip.distanceKm,
      durationMin: trip.durationMinutes.round(),
      category: 'Favorite',
      createdAt: DateTime.now(),
    ));
    if (!mounted) return;
    setState(() {});
    _toast(
      'Saved to your routes',
      icon: Icons.bookmark_added_rounded,
      action: SnackBarAction(label: 'VIEW', textColor: OnbPalette.goldBright, onPressed: () => context.push(AppRoutes.saved)),
    );
  }

  void _toast(String message, {required IconData icon, SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1D1C22),
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 96),
          action: action,
          persist: false,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0x26FFFFFF))),
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
                  var i = 0;
                  Widget enter(Widget w) =>
                      w.animate().fadeIn(delay: (60 + (i++) * 80).ms, duration: 500.ms).slideY(begin: 0.08, curve: Curves.easeOutCubic);
                  return ListView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: EdgeInsets.fromLTRB(side, MediaQuery.paddingOf(context).top + 72, side, 130),
                    children: [
                      enter(_receipt(pal)),
                      const SizedBox(height: 24),
                      enter(_title(pal, 'Your route')),
                      enter(_route(pal)),
                      const SizedBox(height: 24),
                      enter(_title(pal, 'Where your money goes')),
                      enter(_composition(pal)),
                      const SizedBox(height: 24),
                      enter(_title(pal, 'Cost breakdown')),
                      enter(_lineItems(pal)),
                      const SizedBox(height: 24),
                      enter(_title(pal, 'Smart tips')),
                      enter(_tips(pal)),
                      const SizedBox(height: 16),
                      enter(Text(
                        'This is an estimate. Confirm the fare with your driver before you ride.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 11.5, color: pal.muted),
                      )),
                    ],
                  );
                }),
                Positioned(left: 0, right: 0, top: 0, child: _header(pal)),
                Positioned(left: 0, right: 0, bottom: 0, child: _actions(pal)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _circle(OnbPalette pal, IconData icon, String tip, VoidCallback onTap, {bool active = false}) => Semantics(
        button: true,
        label: tip,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? OnbPalette.gold.withValues(alpha: 0.18) : pal.glass,
              border: Border.all(color: active ? OnbPalette.gold : pal.stroke),
            ),
            child: Icon(icon, size: 21, color: active ? homeAccentText(pal) : pal.text),
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
                  'Fare breakdown',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w700, color: pal.text),
                ),
              ),
              _circle(pal, Icons.content_copy_rounded, 'Copy fare details', _copy),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(OnbPalette pal, String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Text(text, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: pal.text)),
      );

  // ── Receipt ─────────────────────────────────────────────────────────────

  Widget _receipt(OnbPalette pal) {
    const top = 214.0;
    final peakColor = q.peak ? OnbPalette.ember : homeTealText(pal);
    final label = GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: pal.muted);
    Widget stat(String l, String v) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l, style: label),
              const SizedBox(height: 3),
              Text(v, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: pal.text)),
            ],
          ),
        );

    return CustomPaint(
      painter: _ReceiptPainter(pal: pal, notchY: top),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: top,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'TOTAL ESTIMATE',
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
                        child: Text(
                          q.peak ? 'Peak +30%' : 'Off-peak',
                          style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: peakColor),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: q.total),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        rand(v),
                        style: GoogleFonts.outfit(
                          fontSize: 54,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.6,
                          height: 1.05,
                          color: pal.text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (q.riders > 1)
                    Text.rich(
                      TextSpan(
                        style: GoogleFonts.inter(fontSize: 13.5, color: pal.muted),
                        children: [
                          TextSpan(
                            text: '${rand(q.each)} each',
                            style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: homeAccentText(pal)),
                          ),
                          TextSpan(text: ' · ${q.riders} riders${q.tip > 0 ? ' · incl. tip' : ''}'),
                        ],
                      ),
                    )
                  else
                    Text(
                      q.tip > 0 ? 'Including a ${rand(q.tip)} tip' : 'For one rider',
                      style: GoogleFonts.inter(fontSize: 13.5, color: pal.muted),
                    ),
                  const Spacer(),
                  Text(
                    'Estimated ${DateFormat('EEE d MMM · HH:mm').format(_when)}',
                    style: GoogleFonts.jetBrainsMono(fontSize: 11.5, color: pal.muted),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: Row(
              children: [
                stat('DISTANCE', '${trip.distanceKm} km'),
                stat('TIME', '${trip.durationMinutes.round()} min'),
                stat('STOPS', '${trip.stops.length}'),
                stat('RIDERS', '${q.riders}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Route ───────────────────────────────────────────────────────────────

  Widget _route(OnbPalette pal) {
    final points = _points;
    final svc = FareCalculatorService();
    return GlassPanel(
      pal: pal,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(14, 16, 16, 6),
      child: Column(
        children: [
          for (var i = 0; i < points.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 42,
                    child: Column(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            color: typeColor(points[i].type).withValues(alpha: 0.15),
                            border: Border.all(
                              color: (i == 0
                                      ? OnbPalette.teal
                                      : i == points.length - 1
                                          ? OnbPalette.ember
                                          : OnbPalette.gold)
                                  .withValues(alpha: 0.7),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(typeIcon(points[i].type), size: 20, color: typeColor(points[i].type)),
                        ),
                        if (i < points.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [pal.stroke, pal.faint],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: i < points.length - 1 ? 8 : 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            i == 0 ? 'PICKUP' : i == points.length - 1 ? 'DESTINATION' : 'STOP $i',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: pal.muted),
                          ),
                          const SizedBox(height: 2),
                          Text(points[i].name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: pal.text)),
                          Text('${typeLabel(points[i].type)} · ${cityOf(points[i])}', style: GoogleFonts.inter(fontSize: 12, color: pal.muted)),
                          if (i < points.length - 1) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                color: pal.glass,
                                border: Border.all(color: pal.stroke),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.south_rounded, size: 13, color: pal.muted),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${svc.calculateTrip(points[i], points[i + 1]).distanceKm} km',
                                    style: GoogleFonts.jetBrainsMono(fontSize: 11.5, fontWeight: FontWeight.w700, color: pal.muted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Composition donut ───────────────────────────────────────────────────

  List<(String, double, Color)> get _parts => [
        ('Base fare', trip.breakdown['Base Fare'] ?? 0, OnbPalette.gold),
        ('Distance', trip.breakdown['Distance Charge'] ?? 0, homeViolet),
        if (q.surge > 0) ('Peak surge', q.surge, OnbPalette.ember),
        if (q.tip > 0) ('Tip', q.tip, OnbPalette.teal),
      ];

  Widget _composition(OnbPalette pal) {
    final parts = _parts;
    final total = parts.fold<double>(0, (a, b) => a + b.$2);
    return GlassPanel(
      pal: pal,
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 128,
            height: 128,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => CustomPaint(
                painter: _DonutPainter(parts: parts, progress: t, track: pal.faint),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(total == 0 ? 0 : (trip.breakdown['Distance Charge'] ?? 0) / total * 100).round()}%',
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: pal.text)),
                      Text('distance', style: GoogleFonts.inter(fontSize: 11, color: pal.muted)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final p in parts)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: p.$3, borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 8),
                        Expanded(child: Text(p.$1, style: GoogleFonts.inter(fontSize: 13, color: pal.text))),
                        Text(
                          '${(total == 0 ? 0 : p.$2 / total * 100).round()}%',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: pal.muted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Line items ──────────────────────────────────────────────────────────

  Widget _lineItems(OnbPalette pal) {
    final base = trip.breakdown['Base Fare'] ?? 0;
    final distance = trip.breakdown['Distance Charge'] ?? 0;
    Widget line(String title, String detail, double amount, {Color? color, bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(fontSize: strong ? 16 : 14.5, fontWeight: strong ? FontWeight.w700 : FontWeight.w600, color: pal.text),
                    ),
                    if (detail.isNotEmpty) Text(detail, style: GoogleFonts.inter(fontSize: 12, color: pal.muted)),
                  ],
                ),
              ),
              Text(
                rand(amount),
                style: (strong ? GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700) : GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w700))
                    .copyWith(color: color ?? pal.text),
              ),
            ],
          ),
        );
    Widget rule({bool dashed = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: dashed
              ? CustomPaint(size: const Size(double.infinity, 1), painter: _DashPainter(color: pal.faint))
              : Container(height: 1, color: pal.stroke),
        );

    return GlassPanel(
      pal: pal,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line('Base fare', trip.stops.isEmpty ? 'Flat boarding fee' : 'R15 + R7.50 for each of ${trip.stops.length} stop${trip.stops.length == 1 ? '' : 's'}', base),
          line('Distance', '${trip.distanceKm} km × R12', distance),
          if (q.surge > 0) line('Peak surge', '30% during rush hour', q.surge, color: OnbPalette.ember),
          if (q.tip > 0) ...[
            rule(dashed: true),
            line('Fare', '', q.fare),
            line('Driver tip', '${q.tipPercent.round()}% of the fare', q.tip, color: homeTealText(pal)),
          ],
          rule(),
          line('Total', '', q.total, color: homeAccentText(pal), strong: true),
          if (q.riders > 1) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: OnbPalette.gold.withValues(alpha: 0.12),
                border: Border.all(color: OnbPalette.gold.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.groups_rounded, color: homeAccentText(pal), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Split ${q.riders} ways', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: pal.text)),
                  ),
                  Text('${rand(q.each)} each', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: homeAccentText(pal))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Tips ────────────────────────────────────────────────────────────────

  Widget _tips(OnbPalette pal) {
    final rush = RushStatus.at(DateTime.now());
    final pay = q.each.ceilToDouble();
    final change = _changeFor(pay);
    Widget tip(IconData icon, Color color, String title, String body, {Widget? extra}) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.12), pal.glass]),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: color.withValues(alpha: 0.18)),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: pal.text)),
                    const SizedBox(height: 3),
                    Text(body, style: GoogleFonts.inter(fontSize: 12.5, height: 1.45, color: pal.muted)),
                    if (extra != null) ...[const SizedBox(height: 10), extra],
                  ],
                ),
              ),
            ],
          ),
        );

    return Column(
      children: [
        if (q.peak)
          tip(
            Icons.savings_rounded,
            OnbPalette.teal,
            'Save ${rand(q.surge)} by riding off-peak',
            rush.peak
                ? 'Peak hour ends in ${rush.countdown}. Off-peak this trip costs ${rand(q.fare - q.surge)}.'
                : 'Right now is off-peak, so you can ride at the standard fare of ${rand(q.fare - q.surge)}.',
          )
        else
          tip(
            Icons.check_circle_outline_rounded,
            OnbPalette.teal,
            "You're paying standard fares",
            rush.peak
                ? "It's peak hour right now, so expect about ${rand(q.fare * 1.3)} if you leave immediately."
                : 'Peak hour starts in ${rush.countdown}, when this trip would cost about ${rand(q.fare * 1.3)}.',
          ),
        tip(
          Icons.payments_rounded,
          OnbPalette.gold,
          'Have exact change: ${rand(pay)}${q.riders > 1 ? ' each' : ''}',
          'Rounded up to the nearest rand. Pass it forward in notes and coins like this:',
          extra: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final d in change)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(d >= 10 ? 6 : 99),
                    color: d >= 10 ? OnbPalette.teal.withValues(alpha: 0.15) : OnbPalette.gold.withValues(alpha: 0.18),
                    border: Border.all(color: d >= 10 ? OnbPalette.teal.withValues(alpha: 0.5) : OnbPalette.gold.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    'R${d.toStringAsFixed(0)}',
                    style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w700, color: pal.text),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Widget _actions(OnbPalette pal) {
    final saved = _saved;
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
                    child: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined, color: saved ? homeAccentText(pal) : pal.text),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Share fare on WhatsApp',
                  child: GestureDetector(
                    onTap: _shareWhatsApp,
                    child: Container(
                      height: 58,
                      padding: const EdgeInsets.only(left: 22, right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(29),
                        gradient: const LinearGradient(colors: [OnbPalette.goldBright, OnbPalette.gold, OnbPalette.ember]),
                        boxShadow: [
                          BoxShadow(color: OnbPalette.gold.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8), spreadRadius: -2),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              q.riders > 1 ? 'Share with your group' : 'Share on WhatsApp',
                              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: OnbPalette.ink),
                            ),
                          ),
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: OnbPalette.ink),
                            child: const Icon(Icons.ios_share_rounded, size: 20, color: OnbPalette.goldBright),
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

class _ReceiptPainter extends CustomPainter {
  _ReceiptPainter({required this.pal, required this.notchY});

  final OnbPalette pal;
  final double notchY;

  @override
  void paint(Canvas canvas, Size size) {
    const r = 12.0;
    final body = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(28)));
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, notchY), radius: r))
      ..addOval(Rect.fromCircle(center: Offset(size.width, notchY), radius: r));
    final path = Path.combine(PathOperation.difference, body, notches);
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.5 * (1 - pal.day) + 0.12), 12, false);
    final rect = Offset.zero & size;
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(const Color(0xFF2A2416), const Color(0xFFFFFFFF), pal.day)!,
            Color.lerp(const Color(0xFF18171C), const Color(0xFFFFF5E4), pal.day)!,
          ],
        ).createShader(rect),
    );
    canvas.save();
    canvas.clipPath(path);
    canvas.drawCircle(
      Offset(size.width * 0.15, 0),
      size.width * 0.7,
      Paint()
        ..shader = RadialGradient(colors: [OnbPalette.gold.withValues(alpha: 0.22), OnbPalette.gold.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: Offset(size.width * 0.15, 0), radius: size.width * 0.7)),
    );
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = OnbPalette.gold.withValues(alpha: 0.35),
    );
    final dash = Paint()
      ..color = pal.faint
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var x = 20.0; x < size.width - 20; x += 9) {
      canvas.drawLine(Offset(x, notchY), Offset(math.min(x + 4, size.width - 20), notchY), dash);
    }
  }

  @override
  bool shouldRepaint(covariant _ReceiptPainter old) => old.pal.day != pal.day;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.parts, required this.progress, required this.track});

  final List<(String, double, Color)> parts;
  final double progress;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 10;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..color = track,
    );
    final total = parts.fold<double>(0, (a, b) => a + b.$2);
    if (total <= 0) return;
    const gap = 0.05;
    var start = -math.pi / 2;
    final sweepAll = math.pi * 2 * progress;
    for (final p in parts) {
      final sweep = math.pi * 2 * p.$2 / total;
      final visible = math.min(sweep, math.max(0.0, sweepAll - (start + math.pi / 2)));
      if (visible > gap) {
        canvas.drawArc(
          rect,
          start + gap / 2,
          visible - gap,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 16
            ..strokeCap = StrokeCap.butt
            ..color = p.$3,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.progress != progress || old.track != track;
}

class _DashPainter extends CustomPainter {
  _DashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + 4, size.width), 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => old.color != color;
}

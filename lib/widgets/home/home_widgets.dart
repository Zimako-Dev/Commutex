import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smarttaxi/services/saved_routes_service.dart';
import 'package:smarttaxi/widgets/onboarding/onboarding_heroes.dart';
import 'package:smarttaxi/widgets/onboarding/onboarding_scene.dart';

const homeDanger = Color(0xFFFF5A5F);
const homeViolet = Color(0xFF9B87FF);
const homeRose = Color(0xFFFF6D8A);

double _interval(double t, double begin, double end, [Curve curve = Curves.easeOutCubic]) {
  if (t <= begin) return 0;
  if (t >= end) return 1;
  return curve.transform((t - begin) / (end - begin));
}

Color homeTealText(OnbPalette pal) => Color.lerp(OnbPalette.teal, const Color(0xFF0B8A63), pal.day)!;

Color homeAccentText(OnbPalette pal) => Color.lerp(OnbPalette.goldBright, const Color(0xFFB36B00), pal.day)!;

/// Plays a 0→1 animation once when first built.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.builder, this.duration = const Duration(milliseconds: 1400)});

  final Widget Function(BuildContext context, double t) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      builder: (context, v, _) => builder(context, v),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════════════════

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.pal,
    required this.greeting,
    required this.dateLabel,
    required this.scrolled,
    required this.time,
    required this.onAvatar,
    required this.onSos,
    required this.onBell,
  });

  final OnbPalette pal;
  final String greeting;
  final String dateLabel;
  final bool scrolled;
  final ValueListenable<double> time;
  final VoidCallback onAvatar;
  final VoidCallback onSos;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.fromLTRB(20, top + 10, 20, 12),
      decoration: BoxDecoration(
        color: scrolled ? pal.scrim.withValues(alpha: 0.94) : pal.scrim.withValues(alpha: 0),
        border: Border(bottom: BorderSide(color: scrolled ? pal.stroke : Colors.transparent)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'Account menu',
                child: GestureDetector(
                  onTap: onAvatar,
                  child: Container(
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [OnbPalette.goldBright, OnbPalette.ember, OnbPalette.gold, OnbPalette.goldBright],
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: pal.surface),
                      alignment: Alignment.center,
                      child: Text(
                        'C',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: homeAccentText(pal)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateLabel.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                        color: homeAccentText(pal),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: pal.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SosPill(time: time, onTap: onSos),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Notifications',
                child: GestureDetector(
                  onTap: onBell,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pal.glass,
                      border: Border.all(color: pal.stroke),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded, size: 21, color: pal.text),
                        Positioned(
                          top: 11,
                          right: 12,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(color: OnbPalette.gold, shape: BoxShape.circle),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return content;
  }
}

class _SosPill extends StatelessWidget {
  const _SosPill({required this.time, required this.onTap});

  final ValueListenable<double> time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Emergency help',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: homeDanger.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: homeDanger.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TickBuilder(
                valueListenable: time,
                builder: (context, t, _) {
                  final p = 0.5 + 0.5 * math.sin(t * 4);
                  return Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: homeDanger,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: homeDanger.withValues(alpha: 0.4 + 0.6 * p), blurRadius: 3 + 6 * p)],
                    ),
                  );
                },
              ),
              const SizedBox(width: 7),
              Text(
                'SOS',
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: homeDanger),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// "Where to?" command bar
// ═══════════════════════════════════════════════════════════════════════════

class WhereToBar extends StatelessWidget {
  const WhereToBar({super.key, required this.pal, required this.onTap, required this.shortcuts, required this.onShortcut});

  final OnbPalette pal;
  final VoidCallback onTap;
  final List<SavedRouteItem> shortcuts;
  final ValueChanged<SavedRouteItem> onShortcut;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: 'Where to? Open fare estimator',
          child: GestureDetector(
            onTap: onTap,
            child: GlassPanel(
              pal: pal,
              radius: 24,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              glow: OnbPalette.gold.withValues(alpha: 0.12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [OnbPalette.goldBright, OnbPalette.ember],
                      ),
                    ),
                    child: const Icon(Icons.search_rounded, color: OnbPalette.ink, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Where to today?',
                          style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w700, color: pal.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Get your fare before you ride',
                          style: GoogleFonts.inter(fontSize: 12.5, color: pal.muted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: pal.glass, border: Border.all(color: pal.stroke)),
                    child: Icon(Icons.arrow_forward_rounded, size: 19, color: pal.text),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (shortcuts.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: shortcuts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final s = shortcuts[i];
                final color = routeCategoryColor(s.category);
                return GestureDetector(
                  onTap: () => onShortcut(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: pal.glass,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: pal.stroke),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(routeCategoryIcon(s.category), size: 15, color: color),
                        const SizedBox(width: 6),
                        Text(
                          s.name,
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: pal.text),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

Color routeCategoryColor(String category) => switch (category) {
      'Daily Commute' => OnbPalette.teal,
      'Weekend' => homeViolet,
      'Family' => homeRose,
      'Errands' => OnbPalette.gold,
      _ => OnbPalette.gold,
    };

IconData routeCategoryIcon(String category) => switch (category) {
      'Daily Commute' => Icons.work_outline_rounded,
      'Weekend' => Icons.celebration_outlined,
      'Family' => Icons.favorite_border_rounded,
      'Errands' => Icons.shopping_bag_outlined,
      'Favorite' => Icons.star_outline_rounded,
      _ => Icons.place_outlined,
    };

// ═══════════════════════════════════════════════════════════════════════════
// Rush-hour radar
// ═══════════════════════════════════════════════════════════════════════════

/// Peak windows match the fare rules used across the app (06–09 and 16–19).
class RushStatus {
  RushStatus._(this.peak, this.until);

  final bool peak;
  final Duration until;

  static bool _inPeak(double h) => (h >= 6 && h < 9) || (h >= 16 && h < 19);

  factory RushStatus.at(DateTime now) {
    final h = now.hour + now.minute / 60 + now.second / 3600;
    const edges = [6.0, 9.0, 16.0, 19.0, 30.0];
    final next = edges.firstWhere((e) => e > h);
    return RushStatus._(_inPeak(h), Duration(minutes: ((next - h) * 60).ceil()));
  }

  String get countdown {
    final hrs = until.inHours;
    final mins = until.inMinutes % 60;
    if (hrs == 0) return '$mins min';
    return mins == 0 ? '${hrs}h' : '${hrs}h ${mins}m';
  }
}

class RushHourCard extends StatelessWidget {
  const RushHourCard({super.key, required this.pal, required this.now, required this.time});

  final OnbPalette pal;
  final DateTime now;
  final ValueListenable<double> time;

  @override
  Widget build(BuildContext context) {
    final status = RushStatus.at(now);
    final color = status.peak ? OnbPalette.ember : OnbPalette.teal;
    final nowFrac = (now.hour + now.minute / 60) / 24;
    return GlassPanel(
      pal: pal,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TickBuilder(
                valueListenable: time,
                builder: (context, t, _) {
                  final q = (t * 0.8) % 1.0;
                  return SizedBox(
                    width: 26,
                    height: 26,
                    child: CustomPaint(painter: _PulseDotPainter(color: color, q: q)),
                  );
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.peak ? 'Peak hours now' : 'Off-peak now',
                      style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: pal.text),
                    ),
                    Text(
                      status.peak ? 'Fares carry a 30% surge' : 'Standard fares, no surge',
                      style: GoogleFonts.inter(fontSize: 12.5, color: pal.muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    status.peak ? 'ENDS IN' : 'PEAK IN',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: pal.muted),
                  ),
                  Text(
                    status.countdown,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: status.peak ? OnbPalette.ember : homeTealText(pal),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 38,
            child: TickBuilder(
              valueListenable: time,
              builder: (context, t, _) => CustomPaint(
                painter: _DayTimelinePainter(nowFrac: nowFrac, pal: pal, time: t, peak: status.peak),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDotPainter extends CustomPainter {
  _PulseDotPainter({required this.color, required this.q});

  final Color color;
  final double q;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(
      c,
      4 + q * 9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: (1 - q) * 0.7),
    );
    canvas.drawCircle(c, 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PulseDotPainter old) => old.q != q || old.color != color;
}

class _DayTimelinePainter extends CustomPainter {
  _DayTimelinePainter({required this.nowFrac, required this.pal, required this.time, required this.peak});

  final double nowFrac;
  final OnbPalette pal;
  final double time;
  final bool peak;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const y = 10.0;
    final track = RRect.fromRectAndRadius(Rect.fromLTWH(0, y - 4, w, 8), const Radius.circular(4));
    canvas.drawRRect(track, Paint()..color = pal.faint);

    for (final seg in const [(6.0, 9.0), (16.0, 19.0)]) {
      final r = Rect.fromLTWH(w * seg.$1 / 24, y - 4, w * (seg.$2 - seg.$1) / 24, 8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(4)),
        Paint()..shader = const LinearGradient(colors: [OnbPalette.gold, OnbPalette.ember]).createShader(r),
      );
    }

    // Elapsed part of the day.
    final elapsed = Rect.fromLTWH(0, y - 1, w * nowFrac, 2);
    canvas.drawRect(elapsed, Paint()..color = pal.text.withValues(alpha: 0.35));

    final color = peak ? OnbPalette.ember : OnbPalette.teal;
    final x = w * nowFrac;
    final q = (time * 0.8) % 1.0;
    canvas.drawCircle(
      Offset(x, y),
      7 + q * 9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = color.withValues(alpha: (1 - q) * 0.6),
    );
    canvas.drawCircle(Offset(x, y), 7, Paint()..color = color);
    canvas.drawCircle(Offset(x, y), 2.8, Paint()..color = Colors.white);

    for (final h in const [0, 6, 12, 18, 24]) {
      final tp = TextPainter(
        text: TextSpan(
          text: h.toString().padLeft(2, '0'),
          style: GoogleFonts.jetBrainsMono(fontSize: 10, color: pal.muted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final lx = (w * h / 24 - tp.width / 2).clamp(0.0, w - tp.width);
      tp.paint(canvas, Offset(lx, size.height - tp.height));
    }
  }

  @override
  bool shouldRepaint(covariant _DayTimelinePainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Spend card: budget ring + 7-day bars + stats
// ═══════════════════════════════════════════════════════════════════════════

class SpendCard extends StatelessWidget {
  const SpendCard({
    super.key,
    required this.pal,
    required this.daily,
    required this.dayLabels,
    required this.budget,
    required this.trips,
    required this.km,
    required this.saved,
  });

  final OnbPalette pal;
  final List<double> daily;
  final List<String> dayLabels;
  final double budget;
  final int trips;
  final double km;
  final double saved;

  @override
  Widget build(BuildContext context) {
    final spent = daily.fold<double>(0, (a, b) => a + b);
    final progress = (spent / budget).clamp(0.0, 1.0);
    return GlassPanel(
      pal: pal,
      radius: 28,
      padding: const EdgeInsets.all(18),
      glow: OnbPalette.gold.withValues(alpha: 0.14),
      child: _Reveal(
        duration: const Duration(milliseconds: 1600),
        builder: (context, t) {
          final ring = _interval(t, 0.05, 0.75, Curves.easeOutCubic);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 112,
                    height: 112,
                    child: CustomPaint(
                      painter: _RingPainter(progress: progress * ring, pal: pal),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(progress * ring * 100).round()}%',
                              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: pal.text),
                            ),
                            Text('of budget', style: GoogleFonts.inter(fontSize: 11, color: pal.muted)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LAST 7 DAYS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                            color: homeAccentText(pal),
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'R${(spent * ring).toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                              height: 1.05,
                              color: pal.text,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text.rich(
                          TextSpan(
                            style: GoogleFonts.inter(fontSize: 12.5, color: pal.muted),
                            children: [
                              TextSpan(
                                text: 'R${(budget - spent).clamp(0, budget).toStringAsFixed(2)} left',
                                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: homeTealText(pal)),
                              ),
                              TextSpan(text: ' of your R${budget.toStringAsFixed(0)} weekly budget'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 104,
                child: _SpendBars(values: daily, labels: dayLabels, t: t, pal: pal),
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: pal.stroke),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MiniStat(pal: pal, icon: Icons.airport_shuttle_rounded, value: '$trips', label: 'Trips', color: OnbPalette.gold),
                  _MiniStat(pal: pal, icon: Icons.route_rounded, value: '${km.round()} km', label: 'Distance', color: homeViolet),
                  _MiniStat(pal: pal, icon: Icons.savings_outlined, value: 'R${saved.round()}', label: 'Saved', color: OnbPalette.teal),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.pal, required this.icon, required this.value, required this.label, required this.color});

  final OnbPalette pal;
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: color.withValues(alpha: 0.15)),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: pal.text),
                ),
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: pal.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendBars extends StatelessWidget {
  const _SpendBars({required this.values, required this.labels, required this.t, required this.pal});

  final List<double> values;
  final List<String> labels;
  final double t;
  final OnbPalette pal;

  @override
  Widget build(BuildContext context) {
    final maxV = values.reduce(math.max);
    final today = values.length - 1;
    return LayoutBuilder(builder: (context, c) {
      const labelH = 18.0;
      const valueH = 18.0;
      final maxBar = c.maxHeight - labelH - valueH - 4;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: valueH,
                    child: i == today
                        ? Opacity(
                            opacity: _interval(t, 0.7, 1),
                            child: Text(
                              'R${values[i].round()}',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: homeAccentText(pal)),
                            ),
                          )
                        : null,
                  ),
                  Container(
                    width: 20,
                    height: math.max(4, maxBar * values[i] / maxV * _interval(t, 0.15 + i * 0.05, 0.65 + i * 0.05, Curves.easeOutBack)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      gradient: i == today
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [OnbPalette.goldBright, OnbPalette.ember],
                            )
                          : LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [pal.text.withValues(alpha: 0.28), pal.text.withValues(alpha: 0.08)],
                            ),
                      boxShadow: [
                        if (i == today) BoxShadow(color: OnbPalette.gold.withValues(alpha: 0.45), blurRadius: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: labelH,
                    child: Text(
                      labels[i],
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: i == today ? FontWeight.w700 : FontWeight.w500,
                        color: i == today ? homeAccentText(pal) : pal.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.pal});

  final double progress;
  final OnbPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = pal.faint,
    );
    if (progress <= 0) return;
    final sweep = progress * math.pi * 2;
    final shader = const SweepGradient(
      colors: [OnbPalette.goldBright, OnbPalette.gold, OnbPalette.ember, OnbPalette.goldBright],
      stops: [0, 0.45, 0.85, 1],
      transform: GradientRotation(-math.pi / 2),
    ).createShader(rect);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = OnbPalette.gold.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );
    final end = c + Offset(math.cos(-math.pi / 2 + sweep), math.sin(-math.pi / 2 + sweep)) * r;
    canvas.drawCircle(end, 3.4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress || old.pal.day != pal.day;
}

// ═══════════════════════════════════════════════════════════════════════════
// Bento feature grid
// ═══════════════════════════════════════════════════════════════════════════

class FeatureBento extends StatelessWidget {
  const FeatureBento({
    super.key,
    required this.pal,
    required this.time,
    required this.savedCount,
    required this.onFare,
    required this.onPlanner,
    required this.onSaved,
    required this.onAi,
  });

  final OnbPalette pal;
  final ValueListenable<double> time;
  final int savedCount;
  final VoidCallback onFare;
  final VoidCallback onPlanner;
  final VoidCallback onSaved;
  final VoidCallback onAi;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    return Column(
      children: [
        SizedBox(
          height: 212,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _FareTile(onTap: onFare, time: time)),
              const SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _PlannerTile(pal: pal, time: time, onTap: onPlanner)),
                    const SizedBox(height: gap),
                    Expanded(child: _SavedTile(pal: pal, count: savedCount, onTap: onSaved)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: gap),
        _AiTile(pal: pal, time: time, onTap: onAi),
      ],
    );
  }
}

class _Tappable extends StatefulWidget {
  const _Tappable({required this.onTap, required this.child, required this.label});

  final VoidCallback onTap;
  final Widget child;
  final String label;

  @override
  State<_Tappable> createState() => _TappableState();
}

class _TappableState extends State<_Tappable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

class _FareTile extends StatelessWidget {
  const _FareTile({required this.onTap, required this.time});

  final VoidCallback onTap;
  final ValueListenable<double> time;

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      label: 'Fare estimator',
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [OnbPalette.goldBright, OnbPalette.gold, OnbPalette.ember],
            stops: [0, 0.55, 1],
          ),
          boxShadow: [
            BoxShadow(color: OnbPalette.gold.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 12), spreadRadius: -4),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                bottom: -46,
                child: Text(
                  'R',
                  style: GoogleFonts.outfit(
                    fontSize: 190,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: OnbPalette.ink.withValues(alpha: 0.09),
                  ),
                ),
              ),
              Positioned.fill(
                child: TickBuilder(
                  valueListenable: time,
                  builder: (context, t, _) => CustomPaint(painter: _TileSheenPainter(time: t)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: OnbPalette.ink.withValues(alpha: 0.12),
                      ),
                      child: const Icon(Icons.calculate_rounded, color: OnbPalette.ink, size: 24),
                    ),
                    const Spacer(),
                    Text(
                      'Fare\nestimator',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        letterSpacing: -0.6,
                        color: OnbPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Know it before you ride',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: OnbPalette.ink.withValues(alpha: 0.7)),
                          ),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(color: OnbPalette.ink, shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_forward_rounded, size: 16, color: OnbPalette.goldBright),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileSheenPainter extends CustomPainter {
  _TileSheenPainter({required this.time});

  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final x = ((time * 0.18) % 1.8 - 0.4) * size.width;
    canvas.save();
    canvas.translate(x, size.height / 2);
    canvas.rotate(0.45);
    final band = Rect.fromCenter(center: Offset.zero, width: 70, height: size.height * 3);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.28), Colors.white.withValues(alpha: 0)],
        ).createShader(band),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TileSheenPainter old) => old.time != time;
}

class _PlannerTile extends StatelessWidget {
  const _PlannerTile({required this.pal, required this.time, required this.onTap});

  final OnbPalette pal;
  final ValueListenable<double> time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      label: 'Trip planner',
      onTap: onTap,
      child: GlassPanel(
        pal: pal,
        radius: 24,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              width: 96,
              height: 44,
              child: TickBuilder(
                valueListenable: time,
                builder: (context, t, _) => CustomPaint(painter: _MiniRoutePainter(time: t, pal: pal)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.alt_route_rounded, size: 22, color: OnbPalette.teal),
                const Spacer(),
                Text('Trip planner', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: pal.text)),
                Text('Multi-stop', style: GoogleFonts.inter(fontSize: 11.5, color: pal.muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniRoutePainter extends CustomPainter {
  _MiniRoutePainter({required this.time, required this.pal});

  final double time;
  final OnbPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final a = Offset(w * 0.12, h * 0.78);
    final b = Offset(w * 0.55, h * 0.45);
    final c = Offset(w * 0.9, h * 0.15);
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(w * 0.2, h * 0.35, b.dx, b.dy)
      ..quadraticBezierTo(w * 0.9, h * 0.55, c.dx, c.dy);
    final metric = path.computeMetrics().first;
    final phase = (time * 18) % 10;
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = OnbPalette.teal.withValues(alpha: 0.75);
    for (var d = -phase; d < metric.length; d += 10) {
      final s = math.max(0.0, d);
      final e = math.min(metric.length, d + 5);
      if (e > s) canvas.drawPath(metric.extractPath(s, e), dash);
    }
    for (final (p, col) in [(a, OnbPalette.teal), (b, OnbPalette.gold), (c, OnbPalette.ember)]) {
      canvas.drawCircle(p, 7, Paint()..color = col.withValues(alpha: 0.25));
      canvas.drawCircle(p, 4, Paint()..color = col);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniRoutePainter old) => old.time != time;
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({required this.pal, required this.count, required this.onTap});

  final OnbPalette pal;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Tappable(
      label: 'Saved routes',
      onTap: onTap,
      child: GlassPanel(
        pal: pal,
        radius: 24,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.bookmark_rounded, size: 22, color: homeRose),
                  const Spacer(),
                  Text('Saved routes', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: pal.text)),
                  Text('Your library', style: GoogleFonts.inter(fontSize: 11.5, color: pal.muted)),
                ],
              ),
            ),
            Text(
              '$count',
              style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.w700, height: 1, color: pal.text.withValues(alpha: 0.9)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiTile extends StatelessWidget {
  const _AiTile({required this.pal, required this.time, required this.onTap});

  final OnbPalette pal;
  final ValueListenable<double> time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bubble = Color.lerp(const Color(0x1AFFFFFF), const Color(0xFFFFFFFF), pal.day)!;
    return _Tappable(
      label: 'Chat with Kaya, your AI co-pilot',
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(const Color(0xFF241F3D), const Color(0xFFEDE8FF), pal.day)!,
              Color.lerp(const Color(0xFF15131C), const Color(0xFFFFF4E2), pal.day)!,
            ],
          ),
          border: Border.all(color: homeViolet.withValues(alpha: 0.35)),
          boxShadow: [BoxShadow(color: homeViolet.withValues(alpha: 0.18), blurRadius: 30, spreadRadius: -6)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [homeViolet, Color(0xFF6A5BFF)]),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, size: 17, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text('Ask Kaya', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: pal.text)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ask about fares, routes, ranks and staying safe on the road.',
                    style: GoogleFonts.inter(fontSize: 12.5, height: 1.45, color: pal.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // A tiny animated chat preview.
            SizedBox(
              width: 132,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: OnbPalette.gold,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      'Bree to Soweto?',
                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: OnbPalette.ink),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: bubble,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                          bottomRight: Radius.circular(14),
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                      child: TickBuilder(
                        valueListenable: time,
                        builder: (context, t, _) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < 3; i++)
                              Container(
                                width: 6,
                                height: 6,
                                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: homeViolet.withValues(alpha: 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 6 - i * 0.9))),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section header
// ═══════════════════════════════════════════════════════════════════════════

class HomeSection extends StatelessWidget {
  const HomeSection({super.key, required this.pal, required this.title, this.action, this.onAction});

  final OnbPalette pal;
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: pal.text),
            ),
          ),
          if (action != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action!,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: homeAccentText(pal)),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 18, color: homeAccentText(pal)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Saved routes carousel (live data from SavedRoutesService)
// ═══════════════════════════════════════════════════════════════════════════

class SavedRoutesCarousel extends StatelessWidget {
  const SavedRoutesCarousel({super.key, required this.pal, required this.items, required this.onOpen, required this.onEmpty});

  final OnbPalette pal;
  final List<SavedRouteItem> items;
  final ValueChanged<SavedRouteItem> onOpen;
  final VoidCallback onEmpty;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return GestureDetector(
        onTap: onEmpty,
        child: GlassPanel(
          pal: pal,
          radius: 22,
          child: Row(
            children: [
              const Icon(Icons.bookmark_add_outlined, color: OnbPalette.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Save the routes you ride often to plan them in one tap.',
                  style: GoogleFonts.inter(fontSize: 13, color: pal.muted),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 206,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _SavedRouteCard(item: items[i], pal: pal, onTap: () => onOpen(items[i])),
      ),
    );
  }
}

class _SavedRouteCard extends StatelessWidget {
  const _SavedRouteCard({required this.item, required this.pal, required this.onTap});

  final SavedRouteItem item;
  final OnbPalette pal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = routeCategoryColor(item.category);
    return _Tappable(
      label: '${item.name}, ${item.from} to ${item.to}',
      onTap: onTap,
      child: SizedBox(
        width: 228,
        child: GlassPanel(
          pal: pal,
          radius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      item.category,
                      style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
                    ),
                  ),
                  const Spacer(),
                  if (item.isFavorite) const Icon(Icons.star_rounded, size: 18, color: OnbPalette.gold),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: pal.text),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(width: 7, height: 7, decoration: const BoxDecoration(color: OnbPalette.teal, shape: BoxShape.circle)),
                        Expanded(child: Container(width: 1.4, color: pal.stroke)),
                        Container(width: 7, height: 7, decoration: const BoxDecoration(color: OnbPalette.ember, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.from, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12.5, color: pal.muted)),
                          Text(item.to, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12.5, color: pal.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R${item.fare.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, height: 1, color: homeAccentText(pal)),
                  ),
                  const Spacer(),
                  Icon(Icons.replay_rounded, size: 13, color: pal.muted),
                  const SizedBox(width: 3),
                  Text('${item.useCount}× ridden', style: GoogleFonts.inter(fontSize: 11, color: pal.muted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Popular routes leaderboard
// ═══════════════════════════════════════════════════════════════════════════

class PopularRoute {
  const PopularRoute(this.from, this.to, this.fare, this.minutes, this.trend);

  final String from;
  final String to;
  final int fare;
  final int minutes;

  /// 1 = fares trending up, -1 = down, 0 = steady.
  final int trend;
}

class PopularRoutesPanel extends StatelessWidget {
  const PopularRoutesPanel({super.key, required this.pal, required this.routes, required this.onTap});

  final OnbPalette pal;
  final List<PopularRoute> routes;
  final ValueChanged<PopularRoute> onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      pal: pal,
      radius: 24,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < routes.length; i++) ...[
            if (i > 0) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Container(height: 1, color: pal.stroke)),
            _PopularRow(rank: i + 1, route: routes[i], pal: pal, onTap: () => onTap(routes[i])),
          ],
        ],
      ),
    );
  }
}

class _PopularRow extends StatelessWidget {
  const _PopularRow({required this.rank, required this.route, required this.pal, required this.onTap});

  final int rank;
  final PopularRoute route;
  final OnbPalette pal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (route.trend) {
      1 => (Icons.trending_up_rounded, OnbPalette.ember, 'Fares up'),
      -1 => (Icons.trending_down_rounded, homeTealText(pal), 'Fares down'),
      _ => (Icons.trending_flat_rounded, pal.muted, 'Steady'),
    };
    return Semantics(
      button: true,
      label: '${route.from} to ${route.to}, R${route.fare}, $label',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  rank.toString().padLeft(2, '0'),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: rank == 1 ? homeAccentText(pal) : pal.muted,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: pal.text),
                        children: [
                          TextSpan(text: route.from),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.east_rounded, size: 14, color: pal.muted),
                            ),
                          ),
                          TextSpan(text: route.to),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 12, color: pal.muted),
                        const SizedBox(width: 4),
                        Text('${route.minutes} min', style: GoogleFonts.inter(fontSize: 11.5, color: pal.muted)),
                        const SizedBox(width: 10),
                        Icon(icon, size: 14, color: color),
                        const SizedBox(width: 3),
                        Text(label, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                'R${route.fare}',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: pal.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tips carousel
// ═══════════════════════════════════════════════════════════════════════════

class CommuterTip {
  const CommuterTip(this.icon, this.title, this.body, this.color);

  final IconData icon;
  final String title;
  final String body;
  final Color color;
}

class TipsCarousel extends StatefulWidget {
  const TipsCarousel({super.key, required this.pal, required this.tips});

  final OnbPalette pal;
  final List<CommuterTip> tips;

  @override
  State<TipsCarousel> createState() => _TipsCarouselState();
}

class _TipsCarouselState extends State<TipsCarousel> {
  final _pc = PageController(viewportFraction: 0.9);
  int _index = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = widget.pal;
    return Column(
      children: [
        SizedBox(
          height: 128,
          child: PageView.builder(
            controller: _pc,
            padEnds: false,
            itemCount: widget.tips.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final tip = widget.tips[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GlassPanel(
                  pal: pal,
                  radius: 22,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: tip.color.withValues(alpha: 0.15),
                        ),
                        child: Icon(tip.icon, color: tip.color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tip.title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: pal.text)),
                            const SizedBox(height: 4),
                            Text(
                              tip.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 12.5, height: 1.45, color: pal.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.tips.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: i == _index ? OnbPalette.gold : pal.faint,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Recent journeys timeline
// ═══════════════════════════════════════════════════════════════════════════

class RecentTrip {
  const RecentTrip(this.from, this.to, this.fare, this.when);

  final String from;
  final String to;
  final double fare;
  final String when;
}

class RecentTimeline extends StatelessWidget {
  const RecentTimeline({super.key, required this.pal, required this.trips});

  final OnbPalette pal;
  final List<RecentTrip> trips;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      pal: pal,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          for (var i = 0; i < trips.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 22,
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(top: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == 0 ? OnbPalette.gold : pal.surface,
                            border: Border.all(color: i == 0 ? OnbPalette.goldBright : pal.muted, width: 2),
                          ),
                        ),
                        if (i < trips.length - 1)
                          Expanded(child: Container(width: 1.6, margin: const EdgeInsets.symmetric(vertical: 4), color: pal.stroke)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${trips[i].from} → ${trips[i].to}',
                                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: pal.text),
                                ),
                                const SizedBox(height: 2),
                                Text(trips[i].when, style: GoogleFonts.inter(fontSize: 12, color: pal.muted)),
                              ],
                            ),
                          ),
                          Text(
                            'R${trips[i].fare.toStringAsFixed(2)}',
                            style: GoogleFonts.jetBrainsMono(fontSize: 13.5, fontWeight: FontWeight.w700, color: pal.text),
                          ),
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
}

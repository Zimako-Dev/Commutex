import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smarttaxi/services/theme_provider.dart';

import 'onboarding_scene.dart';

const _tau = math.pi * 2;

double _interval(double t, double begin, double end, [Curve curve = Curves.easeOutCubic]) {
  if (t <= begin) return 0;
  if (t >= end) return 1;
  return curve.transform((t - begin) / (end - begin));
}

/// Frosted panel used by every hero.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.pal,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
    this.glow,
  });

  final OnbPalette pal;
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [pal.glassStrong, pal.glass],
        ),
        border: Border.all(color: pal.stroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06 + 0.26 * (1 - pal.day)),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          if (glow != null) BoxShadow(color: glow!, blurRadius: 44, spreadRadius: -6),
        ],
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 1 · WELCOME — a glowing taxi core with South African places orbiting in 3D
// ═══════════════════════════════════════════════════════════════════════════

class OrbitHero extends StatelessWidget {
  const OrbitHero({super.key, required this.time, required this.pal});

  final double time;
  final OnbPalette pal;

  static const _places = [
    'Soweto',
    'Sandton',
    'Umlazi',
    'Khayelitsha',
    'Mamelodi',
    'Bellville',
    'Alexandra',
    'Umhlanga',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final s = math.min(c.maxWidth, c.maxHeight * 1.2);
      final core = s * 0.3;
      final back = <(double, Widget)>[];
      final front = <(double, Widget)>[];

      for (var i = 0; i < _places.length; i++) {
        final a = time * 0.3 + i * _tau / _places.length;
        final z = math.sin(a);
        final depth = (z + 1) / 2;
        final x = math.cos(a) * s * 0.36;
        final y = z * s * 0.17 + math.sin(time * 0.9 + i) * 4;
        final chip = Transform.translate(
          offset: Offset(x, y),
          child: Transform.scale(
            scale: 0.68 + 0.36 * depth,
            child: _PlaceChip(
              name: _places[i],
              pal: pal,
              color: i.isEven ? OnbPalette.gold : OnbPalette.teal,
              opacity: 0.25 + 0.75 * depth,
            ),
          ),
        );
        (z < 0 ? back : front).add((z, chip));
      }
      back.sort((a, b) => a.$1.compareTo(b.$1));
      front.sort((a, b) => a.$1.compareTo(b.$1));

      return SizedBox(
        width: c.maxWidth,
        height: c.maxHeight,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            CustomPaint(size: Size(s, s), painter: _OrbitPainter(time: time, core: core)),
            ...back.map((e) => e.$2),
            Transform.translate(
              offset: Offset(0, math.sin(time * 1.3) * 5),
              child: RepaintBoundary(child: _TaxiCore(size: core)),
            ),
            ...front.map((e) => e.$2),
          ],
        ),
      );
    });
  }
}

class _TaxiCore extends StatelessWidget {
  const _TaxiCore({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.4),
          colors: [Color(0xFFFFF0B3), OnbPalette.goldBright, OnbPalette.gold, OnbPalette.ember],
          stops: [0, 0.25, 0.65, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: OnbPalette.gold.withValues(alpha: 0.55),
            blurRadius: 60,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: OnbPalette.ember.withValues(alpha: 0.35),
            blurRadius: 90,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.12,
            left: size * 0.2,
            child: Container(
              width: size * 0.32,
              height: size * 0.16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0.7), Colors.white.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          Icon(Icons.local_taxi_rounded, size: size * 0.46, color: OnbPalette.ink),
        ],
      ),
    );
  }
}

class _PlaceChip extends StatelessWidget {
  const _PlaceChip({required this.name, required this.pal, required this.color, this.opacity = 1});

  final String name;
  final OnbPalette pal;
  final Color color;
  final double opacity;

  Color _a(Color c) => c.withValues(alpha: c.a * opacity);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _a(pal.glassStrong),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _a(pal.stroke)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _a(color), shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            name,
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: _a(pal.text)),
          ),
        ],
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({required this.time, required this.core});

  final double time;
  final double core;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final s = size.width;

    canvas.drawCircle(
      c,
      s * 0.42,
      Paint()
        ..shader = RadialGradient(
          colors: [OnbPalette.gold.withValues(alpha: 0.22), OnbPalette.gold.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: s * 0.42)),
    );

    // Sonar pulses radiating from the core.
    for (var j = 0; j < 3; j++) {
      final q = (time * 0.32 + j / 3) % 1.0;
      canvas.drawCircle(
        c,
        core / 2 + q * s * 0.4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = OnbPalette.goldBright.withValues(alpha: (1 - q) * 0.32),
      );
    }

    // Tilted orbit rings with travelling sparks.
    for (var k = 0; k < 3; k++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-0.2 + k * 0.2 + math.sin(time * 0.2 + k) * 0.03);
      final r = Rect.fromCenter(center: Offset.zero, width: s * (0.6 + k * 0.15), height: s * (0.18 + k * 0.07));
      canvas.drawOval(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = OnbPalette.gold.withValues(alpha: 0.32 - k * 0.07),
      );
      final a = time * (0.7 - k * 0.17) + k * 2;
      final spark = Offset(math.cos(a) * r.width / 2, math.sin(a) * r.height / 2);
      canvas.drawCircle(spark, 7, Paint()..color = OnbPalette.goldBright.withValues(alpha: 0.18));
      canvas.drawCircle(spark, 2.6, Paint()..color = OnbPalette.goldBright);
      canvas.restore();
    }

    // Rotating sweep halo hugging the core.
    final halo = Rect.fromCircle(center: c, radius: core / 2 + 9);
    canvas.drawCircle(
      c,
      core / 2 + 9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = SweepGradient(
          colors: [
            OnbPalette.goldBright.withValues(alpha: 0),
            OnbPalette.goldBright,
            OnbPalette.goldBright.withValues(alpha: 0),
          ],
          stops: const [0, 0.2, 0.42],
          transform: GradientRotation(time * 1.6),
        ).createShader(halo),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// 2 · FARES — a floating 3D fare card with a slot-machine odometer
// ═══════════════════════════════════════════════════════════════════════════

class FareHero extends StatelessWidget {
  const FareHero({super.key, required this.time, required this.pal, required this.active});

  final double time;
  final OnbPalette pal;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = math.min(c.maxWidth * 0.86, 330.0);
      return Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(active),
            tween: Tween(begin: 0, end: active ? 1 : 0),
            duration: const Duration(milliseconds: 2200),
            builder: (context, t, _) {
              final m = Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateX(0.1 * math.sin(time * 0.8))
                ..rotateY(-0.16 * math.sin(time * 0.55));
              return Transform(
                alignment: Alignment.center,
                transform: m,
                child: SizedBox(width: w, child: _FareCard(t: t, time: time, pal: pal)),
              );
            },
          ),
        ],
      );
    });
  }
}

class _FareCard extends StatelessWidget {
  const _FareCard({required this.t, required this.time, required this.pal});

  final double t;
  final double time;
  final OnbPalette pal;

  @override
  Widget build(BuildContext context) {
    final small = GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: pal.text);
    const rows = [
      ('Base fare', 'R15.00'),
      ('Distance · 2.5 km', 'R30.00'),
      ('Peak surge +30%', 'R13.50'),
    ];
    return Stack(
      children: [
        RepaintBoundary(
          child: GlassPanel(
            pal: pal,
            radius: 28,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            glow: OnbPalette.gold.withValues(alpha: 0.22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _Dot(color: OnbPalette.teal),
                    const SizedBox(width: 6),
                    Text('Rosebank', style: small),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.east_rounded, size: 14, color: pal.muted),
                    ),
                    Text('Sandton', style: small),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: OnbPalette.ember.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: OnbPalette.ember.withValues(alpha: 0.45)),
                      ),
                      child: Text(
                        'PEAK',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: OnbPalette.ember,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'ESTIMATED FARE',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                    color: pal.muted,
                  ),
                ),
                const SizedBox(height: 2),
                _Odometer(value: '58.50', t: t, pal: pal),
                const SizedBox(height: 12),
                Container(height: 1, color: pal.stroke),
                const SizedBox(height: 10),
                for (var i = 0; i < rows.length; i++)
                  _BreakdownRow(
                    label: rows[i].$1,
                    value: rows[i].$2,
                    reveal: _interval(t, 0.4 + i * 0.1, 0.7 + i * 0.1),
                    pal: pal,
                  ),
                const SizedBox(height: 12),
                Builder(builder: (context) {
                  final r = _interval(t, 0.78, 1, Curves.easeOutBack);
                  return Opacity(
                    opacity: r.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.9 + 0.1 * r,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: OnbPalette.gold.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: OnbPalette.gold.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.groups_rounded, size: 18, color: OnbPalette.gold),
                            const SizedBox(width: 8),
                            Text('Split 3 ways', style: small),
                            const Spacer(),
                            Text(
                              'R19.50 each',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color.lerp(OnbPalette.goldBright, const Color(0xFFB36B00), pal.day),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: CustomPaint(painter: _SheenPainter(time: time, strength: 0.09)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: 8)],
        ),
      );
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.label, required this.value, required this.reveal, required this.pal});

  final String label;
  final String value;
  final double reveal;
  final OnbPalette pal;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: reveal,
      child: Transform.translate(
        offset: Offset(0, (1 - reveal) * 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 13, color: pal.muted)),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: pal.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Odometer extends StatelessWidget {
  const _Odometer({required this.value, required this.t, required this.pal});

  final String value;
  final double t;
  final OnbPalette pal;

  @override
  Widget build(BuildContext context) {
    const fontSize = 46.0;
    const lineH = 54.0;
    final style = GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      height: 1,
      color: pal.text,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final chars = value.split('');
    var digitIndex = 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [OnbPalette.goldBright, OnbPalette.ember],
          ).createShader(r),
          child: Text('R', style: style.copyWith(color: Colors.white)),
        ),
        const SizedBox(width: 4),
        for (final ch in chars)
          if (ch == '.')
            Text('.', style: style)
          else
            _RollingDigit(
              digit: int.parse(ch),
              t: _interval(t, 0.04 + (digitIndex++) * 0.07, 0.55 + (digitIndex - 1) * 0.07),
              style: style,
              height: lineH,
              width: fontSize * 0.6,
            ),
      ],
    );
  }
}

class _RollingDigit extends StatelessWidget {
  const _RollingDigit({
    required this.digit,
    required this.t,
    required this.style,
    required this.height,
    required this.width,
  });

  final int digit;
  final double t;
  final TextStyle style;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final pos = t * (20 + digit);
    final frac = pos % 10;
    return SizedBox(
      width: width,
      height: height,
      child: ShaderMask(
        // Fade top/bottom edges so digits appear to roll on a drum.
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
          stops: [0, 0.22, 0.78, 1],
        ).createShader(r),
        blendMode: BlendMode.dstIn,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: -frac * height,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  for (var n = 0; n <= 10; n++)
                    SizedBox(
                      height: height,
                      child: Center(child: Text('${n % 10}', style: style)),
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

class _SheenPainter extends CustomPainter {
  _SheenPainter({required this.time, required this.strength});

  final double time;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final x = ((time * 0.22) % 1.6 - 0.3) * size.width;
    canvas.save();
    canvas.translate(x, size.height / 2);
    canvas.rotate(0.45);
    final band = Rect.fromCenter(center: Offset.zero, width: 90, height: size.height * 3);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: strength),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SheenPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// 3 · PLANNER — a tilted 3D city map where the route draws itself
// ═══════════════════════════════════════════════════════════════════════════

class RouteHero extends StatelessWidget {
  const RouteHero({super.key, required this.time, required this.pal, required this.active});

  final double time;
  final OnbPalette pal;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = math.min(c.maxWidth * 0.86, 340.0);
      final h = math.min(w * 0.95, c.maxHeight * 0.95);
      final side = (c.maxWidth - w) / 2;
      return TweenAnimationBuilder<double>(
        key: ValueKey(active),
        tween: Tween(begin: 0, end: active ? 1 : 0),
        duration: const Duration(milliseconds: 2800),
        builder: (context, t, _) {
          final draw = _interval(t, 0.05, 0.8, Curves.easeInOutCubic);
          final night = 1 - pal.day;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0011)
                  ..rotateX(0.6)
                  ..rotateZ(-0.05 + 0.025 * math.sin(time * 0.4)),
                child: Container(
                  width: w,
                  height: h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(const Color(0xFF1D1C22), const Color(0xFFFFFCF5), pal.day)!,
                        Color.lerp(const Color(0xFF111015), const Color(0xFFFFEED3), pal.day)!,
                      ],
                    ),
                    border: Border.all(color: pal.stroke, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1 + 0.4 * night),
                        blurRadius: 50,
                        offset: const Offset(0, 30),
                      ),
                      BoxShadow(
                        color: OnbPalette.teal.withValues(alpha: 0.12),
                        blurRadius: 60,
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: CustomPaint(painter: _MapPainter(draw: draw, time: time, pal: pal)),
                  ),
                ),
              ),
              Positioned(
                top: c.maxHeight * 0.04,
                right: side,
                child: Opacity(
                  opacity: _interval(t, 0.75, 0.95),
                  child: Transform.translate(
                    offset: Offset(0, math.sin(time * 1.4) * 4),
                    child: RepaintBoundary(
                        child: _InfoChip(icon: Icons.schedule_rounded, text: '42 min · 3 stops', pal: pal)),
                  ),
                ),
              ),
              Positioned(
                bottom: c.maxHeight * 0.06,
                left: side,
                child: Opacity(
                  opacity: _interval(t, 0.82, 1),
                  child: Transform.translate(
                    offset: Offset(0, math.cos(time * 1.2) * 4),
                    child: RepaintBoundary(
                      child: _InfoChip(
                        icon: Icons.drag_indicator_rounded,
                        text: 'Drag to reorder',
                        pal: pal,
                        accent: OnbPalette.teal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text, required this.pal, this.accent = OnbPalette.gold});

  final IconData icon;
  final String text;
  final OnbPalette pal;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      pal: pal,
      radius: 99,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: pal.text)),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.draw, required this.time, required this.pal});

  final double draw;
  final double time;
  final OnbPalette pal;

  static const _labels = ['Bara', 'Bree Rank', 'Rosebank', 'Sandton'];

  // Laying out text is costly; reuse label layouts across frames.
  static final Map<String, TextPainter> _labelCache = {};

  static TextPainter _label(String text, Color color) {
    final key = '$text|${color.toARGB32()}';
    return _labelCache.putIfAbsent(
      key,
      () => TextPainter(
        text: TextSpan(
          text: text,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
  }

  static const _pts = [Offset(0.14, 0.8), Offset(0.37, 0.5), Offset(0.65, 0.66), Offset(0.86, 0.2)];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final day = pal.day;

    // Grid.
    final grid = Paint()
      ..color = Color.lerp(const Color(0x10FFFFFF), const Color(0x0F1B1408), day)!
      ..strokeWidth = 1;
    for (var x = 0.0; x < w; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
    }
    for (var y = 0.0; y < h; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    // City blocks.
    final rnd = math.Random(4);
    final block = Paint()..color = Color.lerp(const Color(0x0DFFFFFF), const Color(0x0D1B1408), day)!;
    for (var i = 0; i < 16; i++) {
      final r = Rect.fromLTWH(
          rnd.nextDouble() * w, rnd.nextDouble() * h, 24 + rnd.nextDouble() * 50, 18 + rnd.nextDouble() * 36);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), block);
    }

    // River.
    final river = Path()
      ..moveTo(-10, h * 0.32)
      ..quadraticBezierTo(w * 0.45, h * 0.02, w + 10, h * 0.48);
    canvas.drawPath(
      river,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3FA9F5).withValues(alpha: 0.12),
    );

    // Main roads.
    final road = Paint()
      ..strokeWidth = 7
      ..color = Color.lerp(const Color(0x0FFFFFFF), const Color(0x121B1408), day)!;
    canvas.drawLine(Offset(0, h * 0.62), Offset(w, h * 0.55), road);
    canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.44, h), road);

    // Route path (built segment-by-segment so we know where each stop sits).
    final pts = _pts.map((p) => Offset(p.dx * w, p.dy * h)).toList();
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    final cum = <double>[0];
    var total = 0.0;
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final c1 = Offset((a.dx + b.dx) / 2, a.dy);
      final c2 = Offset((a.dx + b.dx) / 2, b.dy);
      final seg = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, b.dx, b.dy);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, b.dx, b.dy);
      total += seg.computeMetrics().first.length;
      cum.add(total);
    }
    final metric = path.computeMetrics().first;
    final len = metric.length;

    // Ghost dashed route.
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = pal.faint;
    for (var d = 0.0; d < len; d += 12) {
      canvas.drawPath(metric.extractPath(d, math.min(d + 6, len)), dash);
    }

    // Drawn route.
    final drawnLen = len * draw;
    if (drawnLen > 0) {
      final drawn = metric.extractPath(0, drawnLen);
      canvas.drawPath(
        drawn,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..color = OnbPalette.gold.withValues(alpha: 0.18),
      );
      canvas.drawPath(
        drawn,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(
            colors: [OnbPalette.teal, OnbPalette.gold, OnbPalette.ember],
          ).createShader(Offset.zero & size),
      );
    }

    // Pins.
    for (var i = 0; i < pts.length; i++) {
      final reveal = ((drawnLen - cum[i]) / (len * 0.08)).clamp(0.0, 1.0);
      if (reveal <= 0) continue;
      final scale = Curves.elasticOut.transform(reveal);
      final color = i == 0
          ? OnbPalette.teal
          : i == pts.length - 1
              ? OnbPalette.ember
              : OnbPalette.gold;
      final p = pts[i];
      final q = (time * 0.8 + i * 0.3) % 1.0;
      canvas.drawCircle(
        p,
        10 + q * 16,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: (1 - q) * 0.5 * reveal),
      );
      canvas.drawCircle(p, 13 * scale, Paint()..color = color.withValues(alpha: 0.25));
      canvas.drawCircle(p, 8.5 * scale, Paint()..color = color);
      canvas.drawCircle(p, 3.4 * scale, Paint()..color = Colors.white);

      final tp = _label(_labels[i], pal.text.withValues(alpha: 0.92 * (reveal * 10).round() / 10));
      final labelRect = Rect.fromCenter(
        center: p + Offset(0, -24 - 6 * (1 - reveal)),
        width: tp.width + 14,
        height: tp.height + 8,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(99)),
        Paint()..color = pal.surface.withValues(alpha: 0.8 * reveal),
      );
      tp.paint(canvas, labelRect.center - Offset(tp.width / 2, tp.height / 2));
    }

    // The taxi: rides the tip while drawing, then loops the finished route.
    if (drawnLen > 0) {
      final looping = draw >= 1;
      final headOffset = looping ? ((time * 0.16) % 1.0) * len : drawnLen;
      for (var k = 14; k >= 1; k--) {
        final off = headOffset - k * 7;
        if (off < 0) continue;
        final tan = metric.getTangentForOffset(off);
        if (tan == null) continue;
        canvas.drawCircle(
          tan.position,
          6 * (1 - k / 15),
          Paint()..color = OnbPalette.goldBright.withValues(alpha: 0.5 * (1 - k / 15)),
        );
      }
      final head = metric.getTangentForOffset(headOffset);
      if (head != null) {
        canvas.drawCircle(head.position, 16, Paint()..color = OnbPalette.goldBright.withValues(alpha: 0.14));
        canvas.drawCircle(head.position, 11, Paint()..color = OnbPalette.goldBright.withValues(alpha: 0.22));
        canvas.drawCircle(head.position, 6.5, Paint()..color = OnbPalette.goldBright);
        canvas.drawCircle(head.position, 2.6, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// 4 · OFFLINE — radar sweep behind a fanned stack of saved routes
// ═══════════════════════════════════════════════════════════════════════════

class OfflineHero extends StatelessWidget {
  const OfflineHero({super.key, required this.time, required this.pal, required this.active});

  final double time;
  final OnbPalette pal;
  final bool active;

  static const _routes = [
    ('Home → Work', 'Soweto → Bree Rank', 'R25', Icons.home_rounded, OnbPalette.teal),
    ('Visit Gogo', 'Alexandra → Mamelodi', 'R60', Icons.favorite_rounded, Color(0xFFFF6D8A)),
    ('Gym Run', 'Rosebank → Sandton', 'R12', Icons.fitness_center_rounded, Color(0xFF9B87FF)),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = math.min(c.maxWidth * 0.8, 300.0);
      final gap = math.min(78.0, c.maxHeight * 0.2);
      return TweenAnimationBuilder<double>(
        key: ValueKey(active),
        tween: Tween(begin: 0, end: active ? 1 : 0),
        duration: const Duration(milliseconds: 1500),
        builder: (context, t, _) {
          final spread = _interval(t, 0, 0.8, Curves.easeOutBack);
          Widget card(int i) {
            final d = (i - 1).toDouble();
            return Transform.translate(
              offset: Offset(d * 16 * spread, d * gap * spread + math.sin(time * 1.1 + i) * 4),
              child: Transform.rotate(
                angle: d * 0.07 * spread,
                child: RepaintBoundary(
                    child: SizedBox(width: w, child: _SavedCard(data: _routes[i], pal: pal, front: i == 1))),
              ),
            );
          }

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: CustomPaint(painter: _RadarPainter(time: time, pal: pal))),
              card(0),
              card(2),
              card(1),
              Transform.translate(
                offset: Offset(w / 2 - 8, -gap * spread - 34),
                child: Transform.scale(
                  scale: _interval(t, 0.45, 0.9, Curves.elasticOut),
                  child: const RepaintBoundary(child: _OfflineBadge()),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: _interval(t, 0.3, 0.8),
                  child: _StatusPill(time: time, pal: pal),
                ),
              ),
            ],
          );
        },
      );
    });
  }
}

class _SavedCard extends StatelessWidget {
  const _SavedCard({required this.data, required this.pal, required this.front});

  final (String, String, String, IconData, Color) data;
  final OnbPalette pal;
  final bool front;

  @override
  Widget build(BuildContext context) {
    final (name, route, fare, icon, color) = data;
    return GlassPanel(
      pal: pal,
      radius: 20,
      padding: const EdgeInsets.all(14),
      glow: front ? color.withValues(alpha: 0.18) : null,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: pal.text)),
                const SizedBox(height: 3),
                Text(
                  route,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: pal.muted),
                ),
              ],
            ),
          ),
          Text(
            fare,
            style: GoogleFonts.outfit(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color.lerp(OnbPalette.goldBright, const Color(0xFFB36B00), pal.day),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [OnbPalette.goldBright, OnbPalette.ember],
        ),
        boxShadow: [
          BoxShadow(color: OnbPalette.gold.withValues(alpha: 0.55), blurRadius: 24),
        ],
      ),
      child: const Icon(Icons.offline_pin_rounded, color: OnbPalette.ink, size: 30),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.time, required this.pal});

  final double time;
  final OnbPalette pal;

  @override
  Widget build(BuildContext context) {
    final pulse = 0.5 + 0.5 * math.sin(time * 4);
    return GlassPanel(
      pal: pal,
      radius: 99,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 15, color: pal.muted),
          const SizedBox(width: 6),
          Text(
            'No signal',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: pal.muted,
              decoration: TextDecoration.lineThrough,
              decorationColor: pal.muted,
            ),
          ),
          Container(width: 1, height: 14, margin: const EdgeInsets.symmetric(horizontal: 10), color: pal.stroke),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: OnbPalette.teal,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: OnbPalette.teal.withValues(alpha: 0.4 + 0.6 * pulse), blurRadius: 4 + 8 * pulse),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Still works',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: pal.text),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.time, required this.pal});

  final double time;
  final OnbPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(const Offset(0, 10));
    final maxR = size.shortestSide * 0.58;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = pal.faint;
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(c, maxR * i / 3, ring);
    }
    canvas.drawCircle(
      c,
      maxR,
      Paint()
        ..shader = SweepGradient(
          colors: [
            OnbPalette.gold.withValues(alpha: 0),
            OnbPalette.gold.withValues(alpha: 0.22),
            OnbPalette.gold.withValues(alpha: 0),
          ],
          stops: const [0, 0.14, 0.15],
          transform: GradientRotation(time * 0.9),
        ).createShader(Rect.fromCircle(center: c, radius: maxR)),
    );
    for (var j = 0; j < 3; j++) {
      final q = (time * 0.28 + j / 3) % 1.0;
      canvas.drawCircle(
        c,
        30 + q * maxR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFF9B87FF).withValues(alpha: (1 - q) * 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// 5 · THEME — sun/moon orb above three live phone previews
// ═══════════════════════════════════════════════════════════════════════════

class ThemeHero extends StatelessWidget {
  const ThemeHero({super.key, required this.time, required this.pal, required this.themeDay});

  final double time;
  final OnbPalette pal;

  /// 0 = dark selected, 1 = light selected (animated).
  final double themeDay;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    const options = [
      (ThemeMode.light, 'Light', Icons.light_mode_rounded),
      (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
      (ThemeMode.system, 'Auto', Icons.brightness_auto_rounded),
    ];
    return LayoutBuilder(builder: (context, c) {
      final orbH = math.min(110.0, c.maxHeight * 0.3);
      final phoneW = math.min(math.min(c.maxWidth * 0.25, (c.maxHeight - orbH - 60) / 2.1), 108.0).clamp(54.0, 108.0);
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: c.maxWidth,
            height: orbH,
            child: CustomPaint(painter: _CelestialPainter(day: themeDay, time: time)),
          ),
          const SizedBox(height: 14),
          RepaintBoundary(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final o in options)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _PhoneOption(
                      mode: o.$1,
                      label: o.$2,
                      icon: o.$3,
                      width: phoneW,
                      selected: provider.themeMode == o.$1,
                      pal: pal,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        provider.setThemeMode(o.$1);
                      },
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

class _PhoneOption extends StatelessWidget {
  const _PhoneOption({
    required this.mode,
    required this.label,
    required this.icon,
    required this.width,
    required this.selected,
    required this.pal,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final IconData icon;
  final double width;
  final bool selected;
  final OnbPalette pal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = 20 * width / 100;
    final labelColor = selected ? Color.lerp(OnbPalette.gold, const Color(0xFFB36B00), pal.day)! : pal.muted;
    Widget screen;
    if (mode == ThemeMode.system) {
      screen = Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _MiniUiPainter(light: true))),
          Positioned.fill(
            child: ClipPath(
              clipper: _DiagonalClipper(),
              child: const CustomPaint(painter: _MiniUiPainter(light: false)),
            ),
          ),
        ],
      );
    } else {
      screen = CustomPaint(painter: _MiniUiPainter(light: mode == ThemeMode.light));
    }

    return Semantics(
      button: true,
      selected: selected,
      label: '$label theme',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.07 : 0.9,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: selected ? 1 : 0.72,
            duration: const Duration(milliseconds: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: width,
                      height: width * 2.05,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0B10),
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(
                          color: selected ? OnbPalette.goldBright : pal.stroke,
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: [
                          if (selected)
                            BoxShadow(
                              color: OnbPalette.gold.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: -2,
                            )
                          else
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius - 4),
                        child: SizedBox.expand(child: screen),
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: AnimatedScale(
                        scale: selected ? 1 : 0,
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.elasticOut,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: OnbPalette.goldBright,
                            boxShadow: [BoxShadow(color: OnbPalette.gold.withValues(alpha: 0.6), blurRadius: 10)],
                          ),
                          child: const Icon(Icons.check_rounded, size: 16, color: OnbPalette.ink),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: labelColor),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: labelColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// A tiny sketch of the SmartTaxi home screen.
class _MiniUiPainter extends CustomPainter {
  const _MiniUiPainter({required this.light});

  final bool light;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bg = light ? const Color(0xFFF8F9FA) : const Color(0xFF121212);
    final card = light ? Colors.white : const Color(0xFF1E1E1E);
    final line = light ? const Color(0x1F000000) : const Color(0x26FFFFFF);
    final strong = light ? const Color(0xCC222222) : const Color(0xE6FFFFFF);

    canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    // Dynamic-island notch.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, h * 0.035), width: w * 0.32, height: h * 0.022),
        const Radius.circular(10),
      ),
      Paint()..color = Colors.black,
    );
    // Header.
    canvas.drawCircle(Offset(w * 0.17, h * 0.11), w * 0.075, Paint()..color = OnbPalette.gold);
    RRect bar(double x, double y, double bw, double bh) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, bw, bh), Radius.circular(bh));
    canvas.drawRRect(bar(w * 0.29, h * 0.09, w * 0.32, h * 0.018), Paint()..color = strong);
    canvas.drawRRect(bar(w * 0.29, h * 0.12, w * 0.2, h * 0.013), Paint()..color = line);

    // Gold stats card.
    final hero = Rect.fromLTWH(w * 0.08, h * 0.17, w * 0.84, h * 0.19);
    canvas.drawRRect(
      RRect.fromRectAndRadius(hero, Radius.circular(w * 0.08)),
      Paint()
        ..shader = LinearGradient(
          colors: light ? const [OnbPalette.goldBright, OnbPalette.gold] : const [Color(0xFF3A2C08), Color(0xFF1E1A10)],
        ).createShader(hero),
    );
    canvas.drawRRect(
      bar(hero.left + w * 0.07, hero.top + hero.height * 0.25, w * 0.4, h * 0.022),
      Paint()..color = light ? const Color(0xCC1B1408) : OnbPalette.goldBright,
    );
    canvas.drawRRect(
      bar(hero.left + w * 0.07, hero.top + hero.height * 0.55, w * 0.55, h * 0.014),
      Paint()..color = light ? const Color(0x661B1408) : const Color(0x55FFFFFF),
    );

    // Quick-action tiles.
    final gap = w * 0.04;
    final tile = (w * 0.84 - gap * 3) / 4;
    for (var i = 0; i < 4; i++) {
      final r = Rect.fromLTWH(w * 0.08 + i * (tile + gap), h * 0.4, tile, tile);
      canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(tile * 0.28)), Paint()..color = card);
      canvas.drawCircle(r.center, tile * 0.18, Paint()..color = OnbPalette.gold.withValues(alpha: 0.85));
    }

    // List rows.
    for (var i = 0; i < 3; i++) {
      final r = Rect.fromLTWH(w * 0.08, h * (0.55 + i * 0.12), w * 0.84, h * 0.095);
      canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(w * 0.06)), Paint()..color = card);
      canvas.drawCircle(Offset(r.left + r.height * 0.5, r.center.dy), r.height * 0.22, Paint()..color = line);
      canvas.drawRRect(bar(r.left + r.height, r.top + r.height * 0.3, w * 0.38, h * 0.014), Paint()..color = strong);
      canvas.drawRRect(bar(r.left + r.height, r.top + r.height * 0.58, w * 0.24, h * 0.011), Paint()..color = line);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniUiPainter old) => old.light != light;
}

/// Sun with rotating rays (day) cross-fading into a crescent moon (night).
class _CelestialPainter extends CustomPainter {
  _CelestialPainter({required this.day, required this.time});

  final double day;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final night = 1 - day;
    final r = math.min(32.0, size.height * 0.3);
    final c = Offset(size.width / 2, size.height * (0.58 - 0.08 * day) + math.sin(time * 1.1) * 3);

    final glowColor = Color.lerp(const Color(0xFFFFE3B0), OnbPalette.gold, day)!;
    canvas.drawCircle(
      c,
      r * 3.2,
      Paint()
        ..shader = RadialGradient(
          colors: [glowColor.withValues(alpha: 0.4), glowColor.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: r * 3.2)),
    );

    // Sun.
    if (day > 0.01) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(time * 0.25);
      final ray = Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = OnbPalette.gold.withValues(alpha: 0.85 * day);
      for (var k = 0; k < 12; k++) {
        final a = k * _tau / 12;
        final len = r * 0.5 + math.sin(time * 2 + k) * r * 0.14;
        final dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(dir * (r * 1.32), dir * (r * 1.32 + len), ray);
      }
      canvas.restore();
      final disk = Rect.fromCircle(center: c, radius: r);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: [
              const Color(0xFFFFF3C4).withValues(alpha: day),
              OnbPalette.goldBright.withValues(alpha: day),
              OnbPalette.ember.withValues(alpha: day),
            ],
            stops: const [0, 0.45, 1],
          ).createShader(disk),
      );
    }

    // Moon.
    if (night > 0.01) {
      final moon = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: c, radius: r)),
        Path()..addOval(Rect.fromCircle(center: c + Offset(r * 0.48, -r * 0.28), radius: r * 0.88)),
      );
      canvas.drawPath(moon, Paint()..color = const Color(0xFFF4F1E6).withValues(alpha: night));
    }
  }

  @override
  bool shouldRepaint(covariant _CelestialPainter old) => true;
}

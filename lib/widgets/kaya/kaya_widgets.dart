import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smarttaxi/widgets/home/home_widgets.dart';
import 'package:smarttaxi/widgets/onboarding/onboarding_scene.dart';

const kayaViolet = Color(0xFF8B7BFF);
const kayaPink = Color(0xFFFF7AC6);

// ═══════════════════════════════════════════════════════════════════════════
// The orb: Kaya's living avatar
// ═══════════════════════════════════════════════════════════════════════════

/// A glowing sphere with colour currents swirling inside it. It spins faster
/// and ripples while Kaya is thinking.
class KayaOrb extends StatelessWidget {
  const KayaOrb({super.key, required this.size, required this.time, this.thinking = false, this.glow = true, this.still = false});

  final double size;
  final ValueListenable<double> time;
  final bool thinking;
  final bool glow;

  /// Draw a single frame instead of animating (used for avatars in the thread).
  final bool still;

  @override
  Widget build(BuildContext context) {
    if (still) {
      return RepaintBoundary(
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _OrbPainter(time: 1.3, energy: 0, glow: glow)),
        ),
      );
    }
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: thinking ? 1 : 0),
          duration: const Duration(milliseconds: 600),
          builder: (context, energy, _) => TickBuilder(
            valueListenable: time,
            builder: (context, t, _) => CustomPaint(painter: _OrbPainter(time: t, energy: energy, glow: glow)),
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.time, required this.energy, required this.glow});

  final double time;
  final double energy;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 * (glow ? 0.78 : 1);
    final speed = 1 + energy * 2.2;
    final t = time * speed;

    if (glow) {
      final pulse = 0.5 + 0.5 * math.sin(time * (1.6 + energy * 3));
      canvas.drawCircle(
        c,
        r * 1.28,
        Paint()
          ..shader = RadialGradient(
            colors: [
              kayaViolet.withValues(alpha: 0.35 + 0.2 * pulse + 0.15 * energy),
              OnbPalette.gold.withValues(alpha: 0.12),
              Colors.transparent,
            ],
            stops: const [0.55, 0.78, 1],
          ).createShader(Rect.fromCircle(center: c, radius: r * 1.28)),
      );
      // Ripples while thinking.
      for (var i = 0; i < 2; i++) {
        final q = (time * 0.9 + i * 0.5) % 1.0;
        canvas.drawCircle(
          c,
          r * (1 + q * 0.28),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = kayaViolet.withValues(alpha: (1 - q) * 0.6 * energy),
        );
      }
    }

    final sphere = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    canvas.save();
    canvas.clipPath(sphere);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.2, 0.3),
          colors: [Color(0xFF2A1F5C), Color(0xFF120E26)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Colour currents.
    void blob(Color color, double orbit, double phase, double rate, double size) {
      final a = t * rate + phase;
      final p = c + Offset(math.cos(a), math.sin(a * 1.3)) * r * orbit;
      canvas.drawCircle(
        p,
        r * size,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: p, radius: r * size)),
      );
    }

    blob(kayaViolet, 0.45, 0, 0.9, 1.05);
    blob(OnbPalette.goldBright, 0.5, 2.1, -0.7, 0.85);
    blob(kayaPink.withValues(alpha: 0.85), 0.42, 4.2, 1.15, 0.7);
    blob(OnbPalette.teal.withValues(alpha: 0.7), 0.55, 1.2, -1.3, 0.55);

    // Glass highlight.
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(-r * 0.28, -r * 0.42), width: r * 0.95, height: r * 0.5),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.restore();

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, r * 0.04)
        ..shader = SweepGradient(
          colors: [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.5)],
          transform: GradientRotation(time * 0.6),
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => old.time != time || old.energy != energy;
}

// ═══════════════════════════════════════════════════════════════════════════
// Lightweight markdown: **bold**, # headings, bullet and numbered lists
// ═══════════════════════════════════════════════════════════════════════════

class KayaMarkdown extends StatelessWidget {
  const KayaMarkdown({super.key, required this.text, required this.pal});

  final String text;
  final OnbPalette pal;

  static final _bullet = RegExp(r'^\s*[-•*]\s+(.*)$');
  static final _numbered = RegExp(r'^\s*(\d+)[.)]\s+(.*)$');
  static final _heading = RegExp(r'^\s*#{1,4}\s+(.*)$');

  List<InlineSpan> _spans(String line, TextStyle base) {
    final bold = base.copyWith(fontWeight: FontWeight.w700, color: pal.text);
    final parts = line.split('**');
    return [
      for (var i = 0; i < parts.length; i++)
        if (parts[i].isNotEmpty) TextSpan(text: parts[i], style: i.isOdd ? bold : base),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.inter(fontSize: 14.5, height: 1.55, color: pal.text.withValues(alpha: 0.92));
    final accent = homeAccentText(pal);
    final children = <Widget>[];
    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        if (children.isNotEmpty) children.add(const SizedBox(height: 8));
        continue;
      }
      final h = _heading.firstMatch(line);
      final b = _bullet.firstMatch(line);
      final n = _numbered.firstMatch(line);
      if (h != null) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text.rich(TextSpan(children: _spans(h.group(1)!, GoogleFonts.outfit(fontSize: 16.5, fontWeight: FontWeight.w700, color: pal.text)))),
        ));
      } else if (b != null) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 9, right: 10, left: 2),
                decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
              ),
              Expanded(child: Text.rich(TextSpan(children: _spans(b.group(1)!, base)))),
            ],
          ),
        ));
      } else if (n != null) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Text('${n.group(1)}.', style: base.copyWith(fontWeight: FontWeight.w700, color: accent)),
              ),
              Expanded(child: Text.rich(TextSpan(children: _spans(n.group(2)!, base)))),
            ],
          ),
        ));
      } else {
        children.add(Text.rich(TextSpan(children: _spans(line, base))));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Thinking bubble
// ═══════════════════════════════════════════════════════════════════════════

class KayaThinking extends StatelessWidget {
  const KayaThinking({super.key, required this.pal, required this.time, required this.personal});

  final OnbPalette pal;
  final ValueListenable<double> time;
  final bool personal;

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Reading your question',
      'Checking peak hours',
      if (personal) 'Looking at your saved routes',
      'Working out fares',
      'Writing a reply',
    ];
    return TickBuilder(
      valueListenable: time,
      builder: (context, t, _) {
        final step = steps[(t / 1.6).floor() % steps.length];
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
          decoration: BoxDecoration(
            color: pal.glassStrong,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(color: kayaViolet.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Transform.translate(
                  offset: Offset(0, -3 * math.max(0, math.sin(t * 7 - i * 0.8))),
                  child: Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: [kayaViolet, kayaPink, OnbPalette.gold][i],
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (r) {
                  final x = (t * 0.8) % 1.6 - 0.3;
                  return LinearGradient(
                    colors: [pal.muted, pal.text, pal.muted],
                    stops: [(x - 0.2).clamp(0.0, 1.0), x.clamp(0.0, 1.0), (x + 0.2).clamp(0.0, 1.0)],
                  ).createShader(r);
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => ClipRect(
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.9), end: Offset.zero).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                  ),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [if (current != null) current],
                  ),
                  child: Text(
                    '$step…',
                    key: ValueKey(step),
                    style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Welcome suggestion card
// ═══════════════════════════════════════════════════════════════════════════

class KayaPromptCard extends StatefulWidget {
  const KayaPromptCard({
    super.key,
    required this.pal,
    required this.icon,
    required this.color,
    required this.title,
    required this.prompt,
    required this.onTap,
  });

  final OnbPalette pal;
  final IconData icon;
  final Color color;
  final String title;
  final String prompt;
  final VoidCallback onTap;

  @override
  State<KayaPromptCard> createState() => _KayaPromptCardState();
}

class _KayaPromptCardState extends State<KayaPromptCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final pal = widget.pal;
    return Semantics(
      button: true,
      label: 'Ask: ${widget.prompt}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [widget.color.withValues(alpha: 0.14), pal.glass],
              ),
              border: Border.all(color: widget.color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: widget.color.withValues(alpha: 0.2)),
                      child: Icon(widget.icon, size: 18, color: widget.color),
                    ),
                    const Spacer(),
                    Icon(Icons.north_east_rounded, size: 16, color: pal.muted),
                  ],
                ),
                const SizedBox(height: 10),
                Text(widget.title, style: GoogleFonts.outfit(fontSize: 15.5, fontWeight: FontWeight.w700, color: pal.text)),
                const SizedBox(height: 3),
                Text(
                  widget.prompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: pal.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

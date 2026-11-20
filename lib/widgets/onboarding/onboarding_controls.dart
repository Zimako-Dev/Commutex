import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'onboarding_scene.dart';

/// Bottom controls: a "route" progress bar that a taxi drives along while you
/// swipe, plus a CTA that morphs from a round button into a full-width pill.
class OnboardingControls extends StatelessWidget {
  const OnboardingControls({
    super.key,
    required this.page,
    required this.count,
    required this.time,
    required this.pal,
    required this.nextLabel,
    required this.onNext,
    required this.onJump,
  });

  final double page;
  final int count;
  final double time;
  final OnbPalette pal;
  final String nextLabel;
  final VoidCallback onNext;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    final last = (page - (count - 2)).clamp(0.0, 1.0);
    final morph = Curves.easeInOutCubic.transform(last);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RouteProgress(page: page, count: count, time: time, pal: pal, onJump: onJump),
          const SizedBox(height: 18),
          SizedBox(
            height: 64,
            child: LayoutBuilder(builder: (context, c) {
              final bw = 64 + (c.maxWidth - 64) * morph;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    right: 84,
                    child: Opacity(
                      opacity: (1 - last * 2).clamp(0.0, 1.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEXT UP',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: pal.muted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(anim),
                                child: child,
                              ),
                            ),
                            layoutBuilder: (current, previous) => Stack(
                              alignment: Alignment.centerLeft,
                              children: [...previous, if (current != null) current],
                            ),
                            child: Text(
                              nextLabel,
                              key: ValueKey(nextLabel),
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: pal.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: bw,
                    child: MorphingCta(
                      morph: morph,
                      progress: ((page + 1) / count).clamp(0.0, 1.0),
                      time: time,
                      onTap: onNext,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class MorphingCta extends StatelessWidget {
  const MorphingCta({
    super.key,
    required this.morph,
    required this.progress,
    required this.time,
    required this.onTap,
  });

  final double morph;
  final double progress;
  final double time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: morph > 0.5 ? "Let's ride" : 'Next',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [OnbPalette.goldBright, OnbPalette.gold, OnbPalette.ember],
              stops: [0, 0.55, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: OnbPalette.gold.withValues(alpha: 0.45),
                blurRadius: 28,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _CtaPainter(progress: progress, morph: morph, time: time)),
                ),
                Opacity(
                  opacity: (1 - morph * 3).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(math.sin(time * 3) * 2.5, 0),
                    child: const Icon(Icons.arrow_forward_rounded, color: OnbPalette.ink, size: 26),
                  ),
                ),
                Opacity(
                  opacity: ((morph - 0.4) / 0.6).clamp(0.0, 1.0),
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Let's ride",
                          style: GoogleFonts.outfit(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: OnbPalette.ink,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Transform.translate(
                          offset: Offset(math.sin(time * 3) * 2.5, 0),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(color: OnbPalette.ink, shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_forward_rounded, color: OnbPalette.goldBright, size: 19),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CtaPainter extends CustomPainter {
  _CtaPainter({required this.progress, required this.morph, required this.time});

  final double progress;
  final double morph;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    // Progress ring (only while the button is round).
    final ringAlpha = (1 - morph * 2.5).clamp(0.0, 1.0);
    if (ringAlpha > 0) {
      final c = Offset(size.width - 32, size.height / 2);
      const r = 25.0;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = OnbPalette.ink.withValues(alpha: 0.14 * ringAlpha),
      );
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        progress * math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..color = OnbPalette.ink.withValues(alpha: 0.7 * ringAlpha),
      );
    }

    // Glossy sheen sweeping across the wide pill.
    if (morph > 0) {
      final x = ((time * 0.45) % 1.5 - 0.25) * size.width;
      canvas.save();
      canvas.translate(x, size.height / 2);
      canvas.rotate(0.5);
      final band = Rect.fromCenter(center: Offset.zero, width: 60, height: size.height * 3);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.4 * morph),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(band),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CtaPainter old) => true;
}

/// A dashed road with five stops; a glowing taxi rides to your current slide.
class RouteProgress extends StatelessWidget {
  const RouteProgress({
    super.key,
    required this.page,
    required this.count,
    required this.time,
    required this.pal,
    required this.onJump,
  });

  final double page;
  final int count;
  final double time;
  final OnbPalette pal;
  final ValueChanged<int> onJump;

  static const _pad = 14.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: LayoutBuilder(builder: (context, c) {
        final span = c.maxWidth - _pad * 2;
        final headX = _pad + span * (page / (count - 1));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            final i = ((d.localPosition.dx - _pad) / span * (count - 1)).round().clamp(0, count - 1);
            onJump(i);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RouteProgressPainter(page: page, count: count, time: time, pal: pal, pad: _pad),
                ),
              ),
              Positioned(
                left: headX - 16,
                top: 2,
                child: Transform.translate(
                  offset: Offset(0, math.sin(time * 7) * 0.8),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [OnbPalette.goldBright, OnbPalette.gold],
                      ),
                      boxShadow: [
                        BoxShadow(color: OnbPalette.gold.withValues(alpha: 0.7), blurRadius: 16),
                      ],
                    ),
                    child: const Icon(Icons.local_taxi_rounded, size: 17, color: OnbPalette.ink),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _RouteProgressPainter extends CustomPainter {
  _RouteProgressPainter({
    required this.page,
    required this.count,
    required this.time,
    required this.pal,
    required this.pad,
  });

  final double page;
  final int count;
  final double time;
  final OnbPalette pal;
  final double pad;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final span = size.width - pad * 2;
    final headX = pad + span * (page / (count - 1));

    final dash = Paint()
      ..color = pal.faint
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var x = pad; x < size.width - pad; x += 10) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 5, size.width - pad), y), dash);
    }

    if (headX > pad) {
      canvas.drawLine(
        Offset(pad, y),
        Offset(headX, y),
        Paint()
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..color = OnbPalette.gold.withValues(alpha: 0.22),
      );
      final r = Rect.fromLTRB(pad, y - 2, headX, y + 2);
      canvas.drawLine(
        Offset(pad, y),
        Offset(headX, y),
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(colors: [OnbPalette.ember, OnbPalette.goldBright]).createShader(r),
      );
    }

    for (var i = 0; i < count; i++) {
      final x = pad + span * i / (count - 1);
      final passed = page >= i - 0.02;
      final isLast = i == count - 1;
      if (passed) {
        canvas.drawCircle(Offset(x, y), 9, Paint()..color = OnbPalette.gold.withValues(alpha: 0.25));
        canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = OnbPalette.goldBright);
      } else {
        canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = pal.surface);
        canvas.drawCircle(
          Offset(x, y),
          4.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = pal.muted,
        );
      }
      if (isLast && !passed) {
        // Destination beacon.
        final q = (time * 0.7) % 1.0;
        canvas.drawCircle(
          Offset(x, y),
          6 + q * 12,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = OnbPalette.goldBright.withValues(alpha: (1 - q) * 0.6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RouteProgressPainter old) => true;
}

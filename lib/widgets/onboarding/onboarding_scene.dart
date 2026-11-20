import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Colours for the onboarding experience.
///
/// [day] runs from 0 (midnight scene) to 1 (sunrise scene). Every colour
/// lerps between the two so the whole UI can "dawn" smoothly.
class OnbPalette {
  const OnbPalette(this.day);

  final double day;

  static const gold = Color(0xFFFFB300);
  static const goldBright = Color(0xFFFFD54F);
  static const ember = Color(0xFFFF7A1A);
  static const teal = Color(0xFF2EE6A8);
  static const ink = Color(0xFF1B1408);

  Color get text => Color.lerp(Colors.white, ink, day)!;
  Color get muted => Color.lerp(const Color(0xA8FFFFFF), const Color(0x9E1B1408), day)!;
  Color get faint => Color.lerp(const Color(0x30FFFFFF), const Color(0x2A1B1408), day)!;
  Color get glass => Color.lerp(const Color(0x0FFFFFFF), const Color(0x8CFFFFFF), day)!;
  Color get glassStrong => Color.lerp(const Color(0x21FFFFFF), const Color(0xD9FFFFFF), day)!;
  Color get stroke => Color.lerp(const Color(0x26FFFFFF), const Color(0x1F1B1408), day)!;
  Color get surface => Color.lerp(const Color(0xFF16151A), const Color(0xFFFFF4E2), day)!;
  Color get scrim => Color.lerp(const Color(0xFF111015), const Color(0xFFFFF1DC), day)!;
}

/// Minimal premium backdrop: a deep, warm near-black (or soft cream in
/// light mode) lit by a single slowly breathing gold spotlight.
class OnboardingScenePainter extends CustomPainter {
  OnboardingScenePainter({required this.time, required this.day, required this.intro});

  final double time;
  final double day;
  final double intro;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final night = 1 - day;
    final ease = Curves.easeOutCubic.transform(intro.clamp(0.0, 1.0));

    // Base.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFF0B0B0E), const Color(0xFFFFFAF2), day)!,
            Color.lerp(const Color(0xFF131217), const Color(0xFFFFEFD9), day)!,
          ],
        ).createShader(rect),
    );

    // Gold spotlight behind the hero, gently breathing.
    final breathe = 0.5 + 0.5 * math.sin(time * 0.8);
    final spot = Offset(w * 0.5 + math.sin(time * 0.25) * w * 0.02, h * 0.32);
    final spotR = w * 0.9;
    canvas.drawCircle(
      spot,
      spotR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            OnbPalette.gold.withValues(alpha: (0.13 + 0.03 * breathe) * night + 0.3 * day),
            OnbPalette.gold.withValues(alpha: 0.04 * night + 0.08 * day),
            OnbPalette.gold.withValues(alpha: 0),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromCircle(center: spot, radius: spotR)),
    );

    // Faint warm floor glow under the call to action.
    final floor = Offset(w * 0.5, h * 1.08);
    canvas.drawCircle(
      floor,
      w * 0.9,
      Paint()
        ..shader = RadialGradient(
          colors: [
            OnbPalette.ember.withValues(alpha: 0.07 * night + 0.12 * day),
            OnbPalette.ember.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: floor, radius: w * 0.9)),
    );

    // Soft vignette.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.25),
          radius: 1.2,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35 * night)],
          stops: const [0.6, 1],
        ).createShader(rect),
    );

    if (ease < 1) {
      canvas.drawRect(rect, Paint()..color = Colors.black.withValues(alpha: (1 - ease) * 0.92));
    }
  }

  @override
  bool shouldRepaint(covariant OnboardingScenePainter old) =>
      old.time != time || old.day != day || old.intro != intro;
}

/// Rebuilds [builder] every animation tick, isolated in its own paint layer so
/// the rest of the screen is not repainted.
class TickBuilder extends StatelessWidget {
  const TickBuilder({super.key, required this.valueListenable, required this.builder});

  final ValueListenable<double> valueListenable;
  final ValueWidgetBuilder<double> builder;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: ValueListenableBuilder<double>(valueListenable: valueListenable, builder: builder));
  }
}

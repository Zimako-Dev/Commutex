import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smarttaxi/nav.dart';
import 'package:smarttaxi/widgets/onboarding/onboarding_controls.dart';
import 'package:smarttaxi/widgets/onboarding/onboarding_heroes.dart';
import 'package:smarttaxi/widgets/onboarding/onboarding_scene.dart';

class _Slide {
  const _Slide({required this.eyebrow, required this.lines, required this.body, required this.short});

  final String eyebrow;

  /// Headline lines. Wrap words in `*` to paint them in the gold gradient.
  final List<String> lines;
  final String body;
  final String short;
}

const _slides = <_Slide>[
  _Slide(
    eyebrow: 'WELCOME ABOARD',
    lines: ['Mzansi moves.', 'You move *smarter.*'],
    body: 'SmartTaxi is your co-pilot for every minibus ride across South Africa.',
    short: 'Welcome',
  ),
  _Slide(
    eyebrow: 'FARE ESTIMATOR',
    lines: ['Know the fare', '*before* you ride.'],
    body: 'Live estimates with peak-hour surge, fare splitting and tips. No surprises at the rank.',
    short: 'Fare estimator',
  ),
  _Slide(
    eyebrow: 'TRIP PLANNER',
    lines: ['Every stop,', '*perfectly* planned.'],
    body: 'Chain up to 10 stops, drag to reorder, and see distance and travel time instantly.',
    short: 'Trip planner',
  ),
  _Slide(
    eyebrow: 'OFFLINE READY',
    lines: ['No signal?', '*No stress.*'],
    body: 'Saved routes and fare estimates live on your phone, even when the network drops.',
    short: 'Works offline',
  ),
  _Slide(
    eyebrow: 'MAKE IT YOURS',
    lines: ['Pick your', '*vibe.*'],
    body: 'Tap a preview to choose light, dark or auto. You can change it anytime in Settings.',
    short: 'Your look',
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with TickerProviderStateMixin {
  final PageController _pc = PageController();
  final ValueNotifier<double> _time = ValueNotifier(0);
  // Used instead of [_time] when the system asks for reduced motion.
  final ValueNotifier<double> _still = ValueNotifier(0);
  late final Ticker _ticker;
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();
  late final AnimationController _warp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  int _index = 0;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) => _time.value = elapsed.inMicroseconds / 1e6)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _still.dispose();
    _intro.dispose();
    _warp.dispose();
    _pc.dispose();
    super.dispose();
  }

  double get _page {
    if (_pc.hasClients && _pc.position.hasContentDimensions) {
      return _pc.page ?? _index.toDouble();
    }
    return _index.toDouble();
  }

  void _goTo(int i) {
    if (_leaving) return;
    _pc.animateToPage(
      i,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _goTo(_index + 1);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    HapticFeedback.mediumImpact();
    await _warp.forward();
    if (mounted) context.go(AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final ValueListenable<double> time = reduceMotion ? _still : _time;
    // Fade out into the sign-in screen's own backdrop colour.
    final exitColor = isLightTheme ? const Color(0xFFFFFAF2) : const Color(0xFF0B0B0E);
    final count = _slides.length;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: isLightTheme ? 1 : 0),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeInOutCubic,
      builder: (context, themeDay, _) {
        double pageNow() => _page.clamp(0.0, count - 1.0);
        double lastTAt(double page) => (page - (count - 2)).clamp(0.0, 1.0);
        OnbPalette palAt(double page) => OnbPalette(themeDay * lastTAt(page));

        // The page itself only rebuilds for the intro and exit animations.
        // Swipes and per-frame motion update small, separate pieces below.
        return AnimatedBuilder(
          animation: Listenable.merge([_intro, _warp]),
          builder: (context, _) {
            final intro = _intro.value;
            final warp = Curves.easeInCubic.transform(_warp.value);

            double phase(double begin, double end) =>
                Curves.easeOutCubic.transform(((intro - begin) / (end - begin)).clamp(0.0, 1.0));
            final topIn = phase(0.35, 0.8);
            final heroIn = phase(0.2, 0.75);
            final controlsIn = phase(0.5, 1.0);

            return Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _pc,
                        builder: (context, _) {
                          final pal = palAt(pageNow());
                          return AnnotatedRegion<SystemUiOverlayStyle>(
                            value: pal.day > 0.5 ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: OnboardingScenePainter(time: 0, day: pal.day, intro: intro),
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  height: 300,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          pal.scrim.withValues(alpha: 0),
                                          pal.scrim.withValues(alpha: 0.6),
                                          pal.scrim.withValues(alpha: 0.92),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: (1 - warp * 1.4).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 1 + warp * 0.12,
                        child: SafeArea(
                          child: Column(
                            children: [
                              Opacity(
                                opacity: topIn,
                                child: Transform.translate(
                                  offset: Offset(0, -16 * (1 - topIn)),
                                  child: RepaintBoundary(
                                    child: AnimatedBuilder(
                                      animation: _pc,
                                      builder: (context, _) {
                                        final page = pageNow();
                                        return _TopBar(
                                          index: page.round(),
                                          total: count,
                                          pal: palAt(page),
                                          lastT: lastTAt(page),
                                          onSkip: _finish,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Opacity(
                                  opacity: heroIn,
                                  child: Transform.scale(
                                    scale: 0.94 + 0.06 * heroIn,
                                    child: PageView.builder(
                                      controller: _pc,
                                      // Keep the neighbouring slides built so a swipe never
                                      // has to build a whole slide mid-animation.
                                      allowImplicitScrolling: true,
                                      physics: _leaving
                                          ? const NeverScrollableScrollPhysics()
                                          : const BouncingScrollPhysics(),
                                      itemCount: count,
                                      onPageChanged: (i) {
                                        setState(() => _index = i);
                                        HapticFeedback.selectionClick();
                                      },
                                      itemBuilder: (context, i) => _SlideView(
                                        index: i,
                                        slide: _slides[i],
                                        controller: _pc,
                                        pageNow: pageNow,
                                        palAt: palAt,
                                        time: time,
                                        themeDay: themeDay,
                                        active: _index == i && intro > 0.4,
                                        // Only the last two slides change colour while swiping.
                                        colourChanges: i >= count - 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Opacity(
                                opacity: controlsIn,
                                child: Transform.translate(
                                  offset: Offset(0, 40 * (1 - controlsIn)),
                                  child: RepaintBoundary(
                                    child: AnimatedBuilder(
                                      animation: Listenable.merge([_pc, time]),
                                      builder: (context, _) {
                                        final page = pageNow();
                                        return OnboardingControls(
                                          page: page,
                                          count: count,
                                          time: time.value,
                                          pal: palAt(page),
                                          nextLabel: _slides[(page.round() + 1).clamp(0, count - 1)].short,
                                          onNext: _next,
                                          onJump: _goTo,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_warp.value > 0.5)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ColoredBox(
                          color: exitColor.withValues(alpha: ((_warp.value - 0.5) / 0.5).clamp(0.0, 1.0)),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.index,
    required this.total,
    required this.pal,
    required this.lastT,
    required this.onSkip,
  });

  final int index;
  final int total;
  final OnbPalette pal;
  final double lastT;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final mono = GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [OnbPalette.goldBright, OnbPalette.ember],
              ),
              boxShadow: [BoxShadow(color: OnbPalette.gold.withValues(alpha: 0.45), blurRadius: 16)],
            ),
            child: const Icon(Icons.local_taxi_rounded, size: 20, color: OnbPalette.ink),
          ),
          const SizedBox(width: 10),
          Text(
            'SmartTaxi',
            style: GoogleFonts.outfit(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: pal.text,
            ),
          ),
          const Spacer(),
          ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.8), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                (index + 1).toString().padLeft(2, '0'),
                key: ValueKey(index),
                style: mono.copyWith(color: pal.text),
              ),
            ),
          ),
          Text(' / ${total.toString().padLeft(2, '0')}', style: mono.copyWith(color: pal.muted)),
          const SizedBox(width: 12),
          IgnorePointer(
            ignoring: lastT > 0.5,
            child: Opacity(
              opacity: (1 - lastT).clamp(0.0, 1.0),
              child: Semantics(
                button: true,
                label: 'Skip onboarding',
                child: GestureDetector(
                  onTap: onSkip,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: pal.glass,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: pal.stroke),
                    ),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: pal.text),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.index,
    required this.slide,
    required this.controller,
    required this.pageNow,
    required this.palAt,
    required this.time,
    required this.themeDay,
    required this.active,
    required this.colourChanges,
  });

  final int index;
  final _Slide slide;
  final PageController controller;
  final double Function() pageNow;
  final OnbPalette Function(double page) palAt;
  final ValueListenable<double> time;
  final double themeDay;
  final bool active;
  final bool colourChanges;

  Widget _hero(double t, OnbPalette pal) => switch (index) {
        0 => OrbitHero(time: t, pal: pal),
        1 => FareHero(time: t, pal: pal, active: active),
        2 => RouteHero(time: t, pal: pal, active: active),
        3 => OfflineHero(time: t, pal: pal, active: active),
        _ => ThemeHero(time: t, pal: pal, themeDay: themeDay),
      };

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final animated = colourChanges ? Listenable.merge([time, controller]) : time;
    // The hero animates every frame in its own layer, but only while it is on
    // screen; pre-built neighbouring slides stay frozen until they slide in.
    final hero = RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final onScreen = (pageNow() - index).abs() < 1;
          return AnimatedBuilder(
            animation: onScreen ? animated : kAlwaysCompleteAnimation,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _hero(time.value, palAt(pageNow())),
            ),
          );
        },
      ),
    );

    // Text is built once per slide; on the colour-changing slides it follows the swipe.
    final text = RepaintBoundary(
      child: colourChanges
          ? AnimatedBuilder(
              animation: controller,
              builder: (context, _) => _SlideText(slide: slide, index: index, active: active, pal: palAt(pageNow())),
            )
          : _SlideText(slide: slide, index: index, active: active, pal: palAt(0)),
    );

    // Only cheap transforms run per swipe frame.
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // > 0 while this slide is leaving to the left, < 0 while arriving from the right.
        final offset = pageNow() - index;
        final dist = offset.abs().clamp(0.0, 1.0);
        return Column(
          children: [
            Expanded(
              child: Opacity(
                opacity: (1 - dist * 0.85).clamp(0.0, 1.0),
                // Hero lags behind the page (parallax) and swings in 3D.
                child: Transform.translate(
                  offset: Offset(offset * width * 0.5, 0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0009)
                      ..rotateY(-offset * 0.7),
                    child: Transform.scale(scale: 1 - dist * 0.22, child: hero),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(-offset * width * 0.22, 0),
              child: Opacity(
                opacity: (1 - dist * 1.6).clamp(0.0, 1.0),
                child: Padding(padding: const EdgeInsets.fromLTRB(28, 12, 28, 6), child: text),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SlideText extends StatelessWidget {
  const _SlideText({required this.slide, required this.index, required this.active, required this.pal});

  final _Slide slide;
  final int index;
  final bool active;
  final OnbPalette pal;

  @override
  Widget build(BuildContext context) {
    final target = active ? 1.0 : 0.0;
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width < 360 ? 34.0 : 40.0;
    final eyebrowColor = Color.lerp(OnbPalette.gold, const Color(0xFFB36B00), pal.day)!;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                (index + 1).toString().padLeft(2, '0'),
                style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w700, color: eyebrowColor),
              ),
              Container(
                width: 22,
                height: 1.4,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [OnbPalette.goldBright, OnbPalette.ember]),
                ),
              ),
              Text(
                slide.eyebrow,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.6,
                  color: eyebrowColor,
                ),
              ),
            ],
          )
              .animate(target: target)
              .fadeIn(duration: 450.ms)
              .slideX(begin: -0.15, curve: Curves.easeOutCubic),
          const SizedBox(height: 14),
          for (var j = 0; j < slide.lines.length; j++)
            Text.rich(
              TextSpan(children: _spans(slide.lines[j], titleSize)),
            )
                .animate(target: target)
                .fadeIn(delay: (90 + j * 120).ms, duration: 650.ms)
                .slideY(begin: 0.55, curve: Curves.easeOutQuart),
          const SizedBox(height: 14),
          Text(
            slide.body,
            style: GoogleFonts.inter(fontSize: 15.5, height: 1.55, color: pal.muted),
          )
              .animate(target: target)
              .fadeIn(delay: 360.ms, duration: 600.ms)
              .slideY(begin: 0.25, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }

  List<InlineSpan> _spans(String line, double size) {
    TextStyle style({Color? color, Paint? foreground}) => GoogleFonts.outfit(
          fontSize: size,
          fontWeight: FontWeight.w700,
          height: 1.08,
          letterSpacing: -1.2,
          color: color,
          foreground: foreground,
        );
    final parts = line.split('*');
    return [
      for (var k = 0; k < parts.length; k++)
        if (parts[k].isNotEmpty)
          TextSpan(
            text: parts[k],
            style: k.isOdd
                ? style(
                    foreground: Paint()
                      ..shader = LinearGradient(
                        // Deeper amber on the daylight sky so the word stays legible.
                        colors: [
                          Color.lerp(OnbPalette.goldBright, const Color(0xFFF08A00), pal.day)!,
                          Color.lerp(OnbPalette.gold, const Color(0xFFE06200), pal.day)!,
                          Color.lerp(OnbPalette.ember, const Color(0xFFC2410C), pal.day)!,
                        ],
                      ).createShader(Rect.fromLTWH(0, 0, size * 6, size)),
                  )
                : style(color: pal.text),
          ),
    ];
  }
}

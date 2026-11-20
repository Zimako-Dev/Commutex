import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../nav.dart';
import 'calculator_page.dart' show FarePrefill;
import '../services/saved_routes_service.dart';
import '../services/theme_provider.dart';
import '../widgets/home/home_widgets.dart';
import '../widgets/onboarding/onboarding_scene.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _time = ValueNotifier(0);
  late final Ticker _ticker;
  late final Timer _clock;
  final ScrollController _scroll = ScrollController();
  final SavedRoutesService _saved = SavedRoutesService.instance;

  DateTime _now = DateTime.now();
  bool _scrolled = false;

  // ── Sample data (the app has no trip history backend yet) ───────────────
  static const _daily = [48.5, 25.0, 61.0, 43.5, 72.5, 37.0, 25.0]; // last 7 days, today last
  static const _budget = 400.0;
  static const _trips = 12;
  static const _km = 156.4;
  static const _savedRand = 84.0;

  static const _popular = [
    PopularRoute('JHB CBD', 'Soweto', 25, 35, 0),
    PopularRoute('Sandton', 'Alexandra', 18, 20, 1),
    PopularRoute('Pretoria', 'JHB CBD', 55, 55, -1),
    PopularRoute('Randburg', 'Rosebank', 15, 15, 0),
  ];

  static const _tips = [
    CommuterTip(
      Icons.shield_outlined,
      'Stay safe',
      "Sit near the door if you're getting off soon, and keep valuables out of sight.",
      OnbPalette.teal,
    ),
    CommuterTip(
      Icons.schedule_rounded,
      'Beat the rush',
      'Taxis fill up fastest between 6 and 8 AM. Leave 15 minutes earlier to get a seat.',
      OnbPalette.gold,
    ),
    CommuterTip(
      Icons.payments_outlined,
      'Have exact change',
      'Pass your fare forward with the right amount. It keeps the ride moving for everyone.',
      homeViolet,
    ),
  ];

  static const _recent = [
    RecentTrip('JHB CBD', 'Soweto', 25.00, 'Yesterday · 17:42'),
    RecentTrip('Sandton', 'Alexandra', 18.50, 'Monday · 08:10'),
    RecentTrip('Rosebank', 'Randburg', 15.00, 'Sunday · 14:30'),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => _time.value = e.inMicroseconds / 1e6)..start();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _scroll.addListener(() {
      final s = _scroll.hasClients && _scroll.offset > 6;
      if (s != _scrolled) setState(() => _scrolled = s);
    });
    _saved.load();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.cancel();
    _time.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _greeting {
    final h = _now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  List<String> get _dayLabels => [
        for (var i = 6; i >= 0; i--)
          i == 0 ? 'Today' : DateFormat('E').format(_now.subtract(Duration(days: i))).substring(0, 1),
      ];

  void _go(String route) {
    HapticFeedback.selectionClick();
    context.push(route);
  }

  Future<void> _openSaved(SavedRouteItem item) async {
    HapticFeedback.selectionClick();
    await _saved.incrementUse(item.id);
    if (mounted) {
      context.push(AppRoutes.calculator, extra: FarePrefill(from: item.from, to: item.to, stops: item.stops));
    }
  }

  void _toast(String message, {IconData icon = Icons.info_outline_rounded}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1D1C22),
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x26FFFFFF)),
          ),
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
                  child: RepaintBoundary(
                    child: CustomPaint(painter: OnboardingScenePainter(time: 0, day: day, intro: 1)),
                  ),
                ),
                RefreshIndicator(
                  color: OnbPalette.ink,
                  backgroundColor: OnbPalette.gold,
                  edgeOffset: MediaQuery.paddingOf(context).top + 70,
                  onRefresh: () async {
                    await Future<void>.delayed(const Duration(milliseconds: 700));
                    if (mounted) setState(() => _now = DateTime.now());
                  },
                  child: LayoutBuilder(builder: (context, c) {
                    final side = c.maxWidth > 600 ? (c.maxWidth - 560) / 2 : 20.0;
                    return ListView(
                      controller: _scroll,
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: EdgeInsets.fromLTRB(side, MediaQuery.paddingOf(context).top + 84, side, 48),
                      children: _sections(pal),
                    );
                  }),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: HomeHeader(
                    pal: pal,
                    greeting: _greeting,
                    dateLabel: DateFormat('EEE, d MMM').format(_now),
                    scrolled: _scrolled,
                    time: _time,
                    onAvatar: () => _showAccountSheet(),
                    onSos: () => _showEmergencySheet(),
                    onBell: () => _toast("You're all caught up. No new notifications.", icon: Icons.notifications_none_rounded),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.3, curve: Curves.easeOutCubic),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _sections(OnbPalette pal) {
    var i = 0;
    Widget enter(Widget w) {
      final d = 80 + (i++) * 70;
      return w.animate().fadeIn(delay: d.ms, duration: 600.ms).slideY(begin: 0.12, curve: Curves.easeOutCubic);
    }

    return [
      enter(
        ListenableBuilder(
          listenable: _saved,
          builder: (context, _) {
            final shortcuts = [..._saved.items]..sort((a, b) => b.useCount.compareTo(a.useCount));
            return WhereToBar(
              pal: pal,
              onTap: () => _go(AppRoutes.calculator),
              shortcuts: shortcuts.take(4).toList(),
              onShortcut: _openSaved,
            );
          },
        ),
      ),
      const SizedBox(height: 16),
      enter(RushHourCard(pal: pal, now: _now, time: _time)),
      const SizedBox(height: 16),
      enter(
        SpendCard(
          pal: pal,
          daily: _daily,
          dayLabels: _dayLabels,
          budget: _budget,
          trips: _trips,
          km: _km,
          saved: _savedRand,
        ),
      ),
      const SizedBox(height: 28),
      enter(HomeSection(pal: pal, title: 'Get moving')),
      enter(
        ListenableBuilder(
          listenable: _saved,
          builder: (context, _) => FeatureBento(
            pal: pal,
            time: _time,
            savedCount: _saved.items.length,
            onFare: () => _go(AppRoutes.calculator),
            onPlanner: () => _go(AppRoutes.tripPlanner),
            onSaved: () => _go(AppRoutes.saved),
            onAi: () => _go(AppRoutes.aiChat),
          ),
        ),
      ),
      const SizedBox(height: 28),
      enter(HomeSection(pal: pal, title: 'Your routes', action: 'See all', onAction: () => _go(AppRoutes.saved))),
      enter(
        ListenableBuilder(
          listenable: _saved,
          builder: (context, _) {
            final items = [..._saved.items]..sort((a, b) {
                if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
                return b.useCount.compareTo(a.useCount);
              });
            return SavedRoutesCarousel(
              pal: pal,
              items: items,
              onOpen: _openSaved,
              onEmpty: () => _go(AppRoutes.saved),
            );
          },
        ),
      ),
      const SizedBox(height: 28),
      enter(HomeSection(pal: pal, title: 'Popular right now', action: 'Estimate', onAction: () => _go(AppRoutes.calculator))),
      enter(PopularRoutesPanel(
        pal: pal,
        routes: _popular,
        onTap: (r) {
          HapticFeedback.selectionClick();
          context.push(AppRoutes.calculator, extra: FarePrefill(from: r.from, to: r.to));
        },
      )),
      const SizedBox(height: 28),
      enter(HomeSection(pal: pal, title: 'Rider tips')),
      enter(TipsCarousel(pal: pal, tips: _tips)),
      const SizedBox(height: 28),
      enter(HomeSection(pal: pal, title: 'Recent journeys')),
      enter(RecentTimeline(pal: pal, trips: _recent)),
    ];
  }

  // ── Sheets & dialogs ────────────────────────────────────────────────────

  OnbPalette _palNow(BuildContext ctx) => OnbPalette(Theme.of(ctx).brightness == Brightness.light ? 1 : 0);

  Widget _sheetFrame(BuildContext ctx, {required Widget child}) {
    final pal = _palNow(ctx);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + MediaQuery.paddingOf(ctx).bottom * 0.5),
      decoration: BoxDecoration(
        color: Color.lerp(const Color(0xFF17161B), const Color(0xFFFFFAF2), pal.day),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: pal.stroke),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 40)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(color: pal.faint, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }

  void _showEmergencySheet() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final pal = _palNow(ctx);
        Widget tile(IconData icon, Color color, String title, String subtitle, String number) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Semantics(
              button: true,
              label: 'Call $title on $number',
              child: GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  final ok = await launchUrl(Uri(scheme: 'tel', path: number));
                  if (!ok && mounted) _toast("Couldn't open the dialer. Call $number directly.");
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
                        child: Icon(icon, color: Colors.white, size: 23),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: pal.text)),
                            Text(subtitle, style: GoogleFonts.inter(fontSize: 12.5, color: pal.muted)),
                          ],
                        ),
                      ),
                      Text(number, style: GoogleFonts.jetBrainsMono(fontSize: 17, fontWeight: FontWeight.w700, color: color)),
                      const SizedBox(width: 8),
                      Icon(Icons.call_rounded, color: color, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return _sheetFrame(
          ctx,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: homeDanger.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.sos_rounded, color: homeDanger, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Emergency help', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: pal.text)),
                        Text('Tap to open your dialer', style: GoogleFonts.inter(fontSize: 12.5, color: pal.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              tile(Icons.local_police_rounded, const Color(0xFF3B82F6), 'SAPS', 'Police emergency', '10111'),
              tile(Icons.medical_services_rounded, homeDanger, 'Ambulance', 'Medical & fire', '10177'),
              tile(Icons.phone_in_talk_rounded, OnbPalette.teal, 'Any network', 'Emergency from a cellphone', '112'),
            ],
          ),
        );
      },
    );
  }

  void _showAccountSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final provider = ctx.watch<ThemeProvider>();
        final pal = _palNow(ctx);
        Widget row(IconData icon, String label, {Color? color, required VoidCallback onTap}) {
          final c = color ?? pal.text;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: c, size: 21),
                  const SizedBox(width: 14),
                  Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: c))),
                  Icon(Icons.chevron_right_rounded, color: pal.muted),
                ],
              ),
            ),
          );
        }

        const modes = [
          (ThemeMode.light, 'Light', Icons.light_mode_rounded),
          (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
          (ThemeMode.system, 'Auto', Icons.brightness_auto_rounded),
        ];
        return _sheetFrame(
          ctx,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [OnbPalette.goldBright, OnbPalette.ember]),
                    ),
                    alignment: Alignment.center,
                    child: Text('C', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: OnbPalette.ink)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Commuter', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: pal.text)),
                        Text('SmartTaxi rider', style: GoogleFonts.inter(fontSize: 12.5, color: pal.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'APPEARANCE',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.8, color: pal.muted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final m in modes)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: m.$1 == ThemeMode.system ? 0 : 8),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            provider.setThemeMode(m.$1);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: provider.themeMode == m.$1
                                  ? const LinearGradient(colors: [OnbPalette.goldBright, OnbPalette.gold])
                                  : null,
                              color: provider.themeMode == m.$1 ? null : pal.glass,
                              border: Border.all(color: provider.themeMode == m.$1 ? Colors.transparent : pal.stroke),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(m.$3, size: 17, color: provider.themeMode == m.$1 ? OnbPalette.ink : pal.muted),
                                const SizedBox(width: 6),
                                Text(
                                  m.$2,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: provider.themeMode == m.$1 ? OnbPalette.ink : pal.text,
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
              const SizedBox(height: 12),
              row(Icons.settings_outlined, 'Settings', onTap: () {
                Navigator.pop(ctx);
                _go(AppRoutes.settings);
              }),
              Container(height: 1, color: pal.stroke),
              row(Icons.logout_rounded, 'Log out', color: homeDanger, onTap: () {
                Navigator.pop(ctx);
                _confirmLogout();
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) {
        final pal = _palNow(ctx);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Color.lerp(const Color(0xFF17161B), const Color(0xFFFFFAF2), pal.day),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: pal.stroke),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: homeDanger.withValues(alpha: 0.14), shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded, color: homeDanger, size: 26),
                ),
                const SizedBox(height: 14),
                Text('Log out?', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: pal.text)),
                const SizedBox(height: 6),
                Text(
                  'You can sign back in anytime. Your saved routes stay on this phone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13.5, height: 1.5, color: pal.muted),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, false),
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: pal.glass,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: pal.stroke),
                          ),
                          child: Text('Cancel', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: pal.text)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, true),
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: homeDanger, borderRadius: BorderRadius.circular(16)),
                          child: Text('Log out', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok == true && mounted) context.go(AppRoutes.auth);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../nav.dart';
import 'calculator_page.dart' show FarePrefill;
import '../services/saved_routes_service.dart';
import '../widgets/home/home_widgets.dart';
import '../widgets/onboarding/onboarding_scene.dart';
import '../widgets/saved/saved_widgets.dart';

enum _Sort { recent, mostUsed, cheapest, quickest }

extension on _Sort {
  String get label => switch (this) {
        _Sort.recent => 'Most recent',
        _Sort.mostUsed => 'Most ridden',
        _Sort.cheapest => 'Cheapest',
        _Sort.quickest => 'Quickest',
      };

  IconData get icon => switch (this) {
        _Sort.recent => Icons.schedule_rounded,
        _Sort.mostUsed => Icons.local_fire_department_rounded,
        _Sort.cheapest => Icons.savings_outlined,
        _Sort.quickest => Icons.bolt_rounded,
      };
}

const _categories = ['Daily Commute', 'Weekend', 'Family', 'Errands', 'Favorite'];

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> with SingleTickerProviderStateMixin {
  final _svc = SavedRoutesService.instance;
  final ValueNotifier<double> _time = ValueNotifier(0);
  late final Ticker _ticker;
  final _scroll = ScrollController();
  final _search = TextEditingController();

  String _query = '';
  String _category = 'All';
  _Sort _sort = _Sort.recent;
  bool _favoritesOnly = false;
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => _time.value = e.inMicroseconds / 1e6)..start();
    _svc.load();
    _svc.addListener(_onChange);
    _scroll.addListener(() {
      final s = _scroll.hasClients && _scroll.offset > 40;
      if (s != _scrolled) setState(() => _scrolled = s);
    });
  }

  @override
  void dispose() {
    _svc.removeListener(_onChange);
    _ticker.dispose();
    _time.dispose();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  List<SavedRouteItem> get _filtered {
    var list = _svc.items.toList();
    if (_favoritesOnly) list = list.where((e) => e.isFavorite).toList();
    if (_category != 'All') list = list.where((e) => e.category == _category).toList();
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((e) => e.name.toLowerCase().contains(q) || e.from.toLowerCase().contains(q) || e.to.toLowerCase().contains(q))
          .toList();
    }
    switch (_sort) {
      case _Sort.recent:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _Sort.mostUsed:
        list.sort((a, b) => b.useCount.compareTo(a.useCount));
      case _Sort.cheapest:
        list.sort((a, b) => a.fare.compareTo(b.fare));
      case _Sort.quickest:
        list.sort((a, b) => a.durationMin.compareTo(b.durationMin));
    }
    return list;
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _category = 'All';
      _favoritesOnly = false;
    });
  }

  Future<void> _ride(SavedRouteItem item) async {
    HapticFeedback.selectionClick();
    await _svc.incrementUse(item.id);
    if (mounted) {
      context.push(AppRoutes.calculator, extra: FarePrefill(from: item.from, to: item.to, stops: item.stops));
    }
  }

  void _toggleFav(SavedRouteItem item) {
    HapticFeedback.lightImpact();
    _svc.toggleFavorite(item.id);
  }

  void _delete(SavedRouteItem item) {
    HapticFeedback.mediumImpact();
    _svc.remove(item.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1D1C22),
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          duration: const Duration(seconds: 4),
          persist: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x26FFFFFF)),
          ),
          content: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: homeDanger, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '"${item.name}" deleted',
                  style: GoogleFonts.inter(fontSize: 13.5, color: Colors.white),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: OnbPalette.goldBright,
            onPressed: () => _svc.add(item),
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
            floatingActionButton: _svc.loaded && _svc.items.isNotEmpty ? _AddButton(onTap: () => _openEditor()) : null,
            body: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: OnboardingScenePainter(time: 0, day: day, intro: 1)),
                  ),
                ),
                if (!_svc.loaded)
                  const Center(child: CircularProgressIndicator(color: OnbPalette.gold))
                else
                  LayoutBuilder(builder: (context, c) {
                    final side = c.maxWidth > 600 ? (c.maxWidth - 560) / 2 : 20.0;
                    return ListView(
                      controller: _scroll,
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(side, MediaQuery.paddingOf(context).top + 76, side, 120),
                      children: _content(pal),
                    );
                  }),
                Positioned(left: 0, right: 0, top: 0, child: _header(pal)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(OnbPalette pal) {
    final top = MediaQuery.paddingOf(context).top;
    Widget circle({required IconData icon, required String tip, required VoidCallback onTap, Color? color, bool active = false}) {
      return Semantics(
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
              border: Border.all(color: active ? OnbPalette.gold.withValues(alpha: 0.6) : pal.stroke),
            ),
            child: Icon(icon, size: 21, color: color ?? pal.text),
          ),
        ),
      );
    }

    final bar = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.fromLTRB(20, top + 10, 20, 10),
      decoration: BoxDecoration(
        color: _scrolled ? pal.scrim.withValues(alpha: 0.94) : pal.scrim.withValues(alpha: 0),
        border: Border(bottom: BorderSide(color: _scrolled ? pal.stroke : Colors.transparent)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Row(
            children: [
              circle(
                icon: Icons.arrow_back_rounded,
                tip: 'Back',
                onTap: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
              ),
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _scrolled ? 1 : 0,
                  child: Text(
                    'Saved routes',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: pal.text),
                  ),
                ),
              ),
              circle(
                icon: _favoritesOnly ? Icons.star_rounded : Icons.star_outline_rounded,
                tip: _favoritesOnly ? 'Show all routes' : 'Show favourites only',
                color: _favoritesOnly ? OnbPalette.gold : null,
                active: _favoritesOnly,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _favoritesOnly = !_favoritesOnly);
                },
              ),
              const SizedBox(width: 8),
              circle(icon: Icons.swap_vert_rounded, tip: 'Sort routes', onTap: () => _openSortSheet()),
            ],
          ),
        ),
      ),
    );
    return bar;
  }

  List<Widget> _content(OnbPalette pal) {
    final all = _svc.items;
    final items = _filtered;
    var i = 0;
    Widget enter(Widget w) =>
        w.animate().fadeIn(delay: (60 + (i++) * 70).ms, duration: 550.ms).slideY(begin: 0.1, curve: Curves.easeOutCubic);

    final eyebrow = Color.lerp(OnbPalette.gold, const Color(0xFFB36B00), pal.day)!;

    final counts = <String, int>{};
    for (final e in all) {
      counts[e.category] = (counts[e.category] ?? 0) + 1;
    }
    final chips = <FilterChipData>[
      FilterChipData(
        label: 'All',
        count: all.length,
        selected: _category == 'All',
        onTap: () => setState(() => _category = 'All'),
      ),
      for (final c in _svc.categories)
        FilterChipData(
          label: c,
          count: counts[c] ?? 0,
          selected: _category == c,
          color: routeCategoryColor(c),
          icon: routeCategoryIcon(c),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _category = _category == c ? 'All' : c);
          },
        ),
    ];

    return [
      enter(Row(
        children: [
          Container(
            width: 22,
            height: 1.4,
            margin: const EdgeInsets.only(right: 10),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [OnbPalette.goldBright, OnbPalette.ember])),
          ),
          Text(
            'YOUR TRAVEL LIBRARY',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2.4, color: eyebrow),
          ),
        ],
      )),
      const SizedBox(height: 10),
      enter(Text.rich(
        TextSpan(
          style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w700, height: 1.08, letterSpacing: -1.1, color: pal.text),
          children: [
            const TextSpan(text: 'Saved '),
            TextSpan(
              text: 'routes.',
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                height: 1.08,
                letterSpacing: -1.1,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [
                      Color.lerp(OnbPalette.goldBright, const Color(0xFFF08A00), pal.day)!,
                      Color.lerp(OnbPalette.ember, const Color(0xFFC2410C), pal.day)!,
                    ],
                  ).createShader(const Rect.fromLTWH(0, 0, 160, 40)),
              ),
            ),
          ],
        ),
      )),
      const SizedBox(height: 6),
      enter(Text(
        'Your regular rides, ready to estimate in one tap.',
        style: GoogleFonts.inter(fontSize: 14.5, color: pal.muted),
      )),
      const SizedBox(height: 20),
      if (all.isNotEmpty) ...[
        enter(LibraryStatsCard(pal: pal, items: all)),
        const SizedBox(height: 22),
        enter(LibrarySearchField(
          pal: pal,
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
        )),
        const SizedBox(height: 12),
        enter(LibraryFilterRow(pal: pal, chips: chips)),
        const SizedBox(height: 16),
        enter(Row(
          children: [
            Text(
              '${items.length} ${items.length == 1 ? 'route' : 'routes'}',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: pal.text),
            ),
            if (_favoritesOnly) ...[
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded, size: 16, color: OnbPalette.gold),
            ],
            const Spacer(),
            GestureDetector(
              onTap: _openSortSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: pal.glass,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: pal.stroke),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_sort.icon, size: 15, color: homeAccentText(pal)),
                    const SizedBox(width: 6),
                    Text(_sort.label, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: pal.text)),
                    const SizedBox(width: 2),
                    Icon(Icons.expand_more_rounded, size: 18, color: pal.muted),
                  ],
                ),
              ),
            ),
          ],
        )),
        const SizedBox(height: 12),
        if (items.isEmpty)
          LibraryEmptyState(pal: pal, filtered: true, onAction: _clearFilters)
        else ...[
          for (final (idx, item) in items.indexed) ...[
            _swipeable(item, pal)
                .animate(key: ValueKey('${item.id}-$_category-$_favoritesOnly-${_sort.name}'))
                .fadeIn(delay: (40 * idx).ms, duration: 380.ms)
                .slideY(begin: 0.08, curve: Curves.easeOutCubic),
            const SizedBox(height: 14),
          ],
          if (items.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swipe_rounded, size: 15, color: pal.muted),
                  const SizedBox(width: 6),
                  Text(
                    'Swipe right to favourite · left to delete',
                    style: GoogleFonts.inter(fontSize: 12, color: pal.muted),
                  ),
                ],
              ),
            ),
        ],
      ] else
        LibraryEmptyState(pal: pal, filtered: false, onAction: () => _openEditor()),
    ];
  }

  Widget _swipeable(SavedRouteItem item, OnbPalette pal) {
    Widget bg(Alignment align, Color color, IconData icon, String label) => Container(
          alignment: align,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        );

    return Dismissible(
      key: ValueKey(item.id),
      background: bg(
        Alignment.centerLeft,
        OnbPalette.gold,
        item.isFavorite ? Icons.star_outline_rounded : Icons.star_rounded,
        item.isFavorite ? 'Unfavourite' : 'Favourite',
      ),
      secondaryBackground: bg(Alignment.centerRight, homeDanger, Icons.delete_outline_rounded, 'Delete'),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          _toggleFav(item);
          return false;
        }
        return true;
      },
      onDismissed: (_) => _delete(item),
      child: GestureDetector(
        onTap: () => _ride(item),
        child: RouteTicket(
          item: item,
          pal: pal,
          onRide: () => _ride(item),
          onFav: () => _toggleFav(item),
          onMore: () => _openActions(item),
        ),
      ),
    );
  }

  // ── Sheets ──────────────────────────────────────────────────────────────

  OnbPalette _palNow(BuildContext ctx) => OnbPalette(Theme.of(ctx).brightness == Brightness.light ? 1 : 0);

  Widget _sheetFrame(BuildContext ctx, {required Widget child}) {
    final pal = _palNow(ctx);
    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, 12 + MediaQuery.viewInsetsOf(ctx).bottom),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: pal.faint, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }

  void _openSortSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final pal = _palNow(ctx);
        return _sheetFrame(
          ctx,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sort routes', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: pal.text)),
              const SizedBox(height: 12),
              for (final s in _Sort.values)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _sort = s);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: s == _sort ? OnbPalette.gold.withValues(alpha: 0.14) : pal.glass,
                      border: Border.all(color: s == _sort ? OnbPalette.gold.withValues(alpha: 0.6) : pal.stroke),
                    ),
                    child: Row(
                      children: [
                        Icon(s.icon, size: 20, color: s == _sort ? homeAccentText(pal) : pal.muted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(s.label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: pal.text)),
                        ),
                        if (s == _sort) Icon(Icons.check_circle_rounded, size: 20, color: homeAccentText(pal)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openActions(SavedRouteItem item) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final pal = _palNow(ctx);
        Widget row(IconData icon, String label, VoidCallback onTap, {Color? color}) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.pop(ctx);
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Icon(icon, size: 21, color: color ?? pal.text),
                    const SizedBox(width: 14),
                    Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: color ?? pal.text)),
                  ],
                ),
              ),
            );
        return _sheetFrame(
          ctx,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(item.name, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: pal.text)),
              Text('${item.from} → ${item.to}', style: GoogleFonts.inter(fontSize: 13, color: pal.muted)),
              const SizedBox(height: 8),
              row(Icons.local_taxi_rounded, 'Ride again', () => _ride(item), color: homeAccentText(pal)),
              row(Icons.edit_outlined, 'Edit route', () => _openEditor(edit: item)),
              row(
                item.isFavorite ? Icons.star_outline_rounded : Icons.star_rounded,
                item.isFavorite ? 'Remove from favourites' : 'Add to favourites',
                () => _toggleFav(item),
              ),
              Container(height: 1, color: pal.stroke),
              row(Icons.delete_outline_rounded, 'Delete route', () => _delete(item), color: homeDanger),
            ],
          ),
        );
      },
    );
  }

  void _openEditor({SavedRouteItem? edit}) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.92),
        child: _sheetFrame(ctx, child: _RouteEditor(initial: edit, pal: _palNow(ctx))),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Save a new route',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 58,
          padding: const EdgeInsets.only(left: 18, right: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(29),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [OnbPalette.goldBright, OnbPalette.gold, OnbPalette.ember],
            ),
            boxShadow: [
              BoxShadow(color: OnbPalette.gold.withValues(alpha: 0.45), blurRadius: 26, offset: const Offset(0, 10), spreadRadius: -2),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: OnbPalette.ink, size: 24),
              const SizedBox(width: 8),
              Text('Save route', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: OnbPalette.ink)),
            ],
          ),
        ),
      ),
    ).animate().scale(begin: const Offset(0.6, 0.6), delay: 500.ms, duration: 600.ms, curve: Curves.elasticOut).fadeIn(delay: 500.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Add / edit sheet with a live ticket preview
// ═══════════════════════════════════════════════════════════════════════════

class _RouteEditor extends StatefulWidget {
  const _RouteEditor({required this.initial, required this.pal});

  final SavedRouteItem? initial;
  final OnbPalette pal;

  @override
  State<_RouteEditor> createState() => _RouteEditorState();
}

class _RouteEditorState extends State<_RouteEditor> {
  final _name = TextEditingController();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _fare = TextEditingController();
  final _km = TextEditingController();
  final _dur = TextEditingController();
  String _category = 'Daily Commute';
  bool _fav = false;
  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _name.text = i.name;
      _from.text = i.from;
      _to.text = i.to;
      _fare.text = i.fare.toStringAsFixed(0);
      _km.text = i.distanceKm.toStringAsFixed(1);
      _dur.text = i.durationMin.toString();
      _category = i.category;
      _fav = i.isFavorite;
    }
    for (final c in [_name, _from, _to, _fare, _km, _dur]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _from, _to, _fare, _km, _dur]) {
      c.dispose();
    }
    super.dispose();
  }

  SavedRouteItem _draft() => SavedRouteItem(
        id: widget.initial?.id ?? 'r_${DateTime.now().microsecondsSinceEpoch}',
        name: _name.text.trim(),
        from: _from.text.trim(),
        to: _to.text.trim(),
        stops: widget.initial?.stops ?? const [],
        fare: double.tryParse(_fare.text.replaceAll(',', '.')) ?? 0,
        distanceKm: double.tryParse(_km.text.replaceAll(',', '.')) ?? 0,
        durationMin: int.tryParse(_dur.text) ?? 0,
        category: _category,
        isFavorite: _fav,
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
        useCount: widget.initial?.useCount ?? 0,
      );

  Future<void> _save() async {
    final e = <String, String>{};
    if (_name.text.trim().isEmpty) e['name'] = 'Give this route a name';
    if (_from.text.trim().isEmpty) e['from'] = 'Where does it start?';
    if (_to.text.trim().isEmpty) e['to'] = 'Where does it end?';
    setState(() {
      _errors
        ..clear()
        ..addAll(e);
    });
    if (e.isNotEmpty) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.mediumImpact();
    final item = _draft();
    if (widget.initial == null) {
      await SavedRoutesService.instance.add(item);
    } else {
      await SavedRoutesService.instance.update(item);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pal = widget.pal;
    final editing = widget.initial != null;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            editing ? 'Edit route' : 'Save a new route',
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: pal.text),
          ),
          const SizedBox(height: 4),
          Text('Your ticket updates as you type.', style: GoogleFonts.inter(fontSize: 13, color: pal.muted)),
          const SizedBox(height: 16),
          RouteTicket(item: _draft(), pal: pal),
          const SizedBox(height: 20),
          _EditorField(pal: pal, controller: _name, label: 'Route name', hint: 'e.g. Home → Work', icon: Icons.label_outline_rounded, error: _errors['name']),
          _EditorField(pal: pal, controller: _from, label: 'From', hint: 'e.g. Soweto (Bara)', icon: Icons.trip_origin_rounded, error: _errors['from']),
          _EditorField(pal: pal, controller: _to, label: 'To', hint: 'e.g. Bree Taxi Rank', icon: Icons.place_outlined, error: _errors['to']),
          Row(
            children: [
              Expanded(child: _EditorField(pal: pal, controller: _fare, label: 'Fare R', icon: Icons.payments_outlined, number: true)),
              const SizedBox(width: 8),
              Expanded(child: _EditorField(pal: pal, controller: _km, label: 'Km', icon: Icons.straighten_rounded, number: true)),
              const SizedBox(width: 8),
              Expanded(child: _EditorField(pal: pal, controller: _dur, label: 'Min', icon: Icons.timer_outlined, number: true, integer: true)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'CATEGORY',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.8, color: pal.muted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _categories)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _category = c);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: _category == c ? routeCategoryColor(c).withValues(alpha: 0.18) : pal.glass,
                      border: Border.all(color: _category == c ? routeCategoryColor(c) : pal.stroke),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(routeCategoryIcon(c), size: 15, color: routeCategoryColor(c)),
                        const SizedBox(width: 6),
                        Text(c, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: pal.text)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _fav = !_fav);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: pal.glass,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: pal.stroke),
              ),
              child: Row(
                children: [
                  Icon(_fav ? Icons.star_rounded : Icons.star_outline_rounded, color: _fav ? OnbPalette.gold : pal.muted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Pin to favourites', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: pal.text)),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 50,
                    height: 30,
                    padding: const EdgeInsets.all(3),
                    alignment: _fav ? Alignment.centerRight : Alignment.centerLeft,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: _fav ? OnbPalette.gold : pal.faint,
                    ),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _fav ? OnbPalette.ink : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _save,
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(29),
                gradient: const LinearGradient(colors: [OnbPalette.goldBright, OnbPalette.gold, OnbPalette.ember]),
                boxShadow: [BoxShadow(color: OnbPalette.gold.withValues(alpha: 0.4), blurRadius: 22, offset: const Offset(0, 8))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(editing ? Icons.check_rounded : Icons.bookmark_add_rounded, color: OnbPalette.ink),
                  const SizedBox(width: 10),
                  Text(
                    editing ? 'Update route' : 'Save route',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: OnbPalette.ink),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  const _EditorField({
    required this.pal,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.error,
    this.number = false,
    this.integer = false,
  });

  final OnbPalette pal;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final String? error;
  final bool number;
  final bool integer;

  @override
  Widget build(BuildContext context) {
    const none = InputBorder.none;
    final hasError = error != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 58,
            padding: EdgeInsets.only(left: number ? 10 : 14, right: 10),
            decoration: BoxDecoration(
              color: pal.glass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: hasError ? homeDanger : pal.stroke, width: hasError ? 1.4 : 1),
            ),
            child: Row(
              children: [
                Icon(icon, size: 19, color: hasError ? homeDanger : pal.muted),
                SizedBox(width: number ? 6 : 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: number ? TextInputType.numberWithOptions(decimal: !integer) : TextInputType.text,
                    inputFormatters: number
                        ? [FilteringTextInputFormatter.allow(RegExp(integer ? r'[0-9]' : r'[0-9.,]'))]
                        : null,
                    textCapitalization: number ? TextCapitalization.none : TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    cursorColor: OnbPalette.gold,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: pal.text),
                    decoration: InputDecoration(
                      labelText: label,
                      hintText: hint,
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: pal.faint),
                      labelStyle: GoogleFonts.inter(fontSize: 14, color: pal.muted),
                      floatingLabelStyle: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: hasError ? homeDanger : homeAccentText(pal),
                      ),
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      border: none,
                      enabledBorder: none,
                      focusedBorder: none,
                      errorBorder: none,
                      focusedErrorBorder: none,
                      disabledBorder: none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
              child: Text(error!, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: homeDanger)),
            ),
        ],
      ),
    );
  }
}

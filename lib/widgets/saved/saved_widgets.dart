import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:smarttaxi/services/saved_routes_service.dart';
import 'package:smarttaxi/widgets/home/home_widgets.dart';
import 'package:smarttaxi/widgets/onboarding/onboarding_heroes.dart';
import 'package:smarttaxi/widgets/onboarding/onboarding_scene.dart';

/// Rand amounts with South African-style space grouping, e.g. R2 106.
String formatRand(double v) => 'R${NumberFormat('#,##0').format(v).replaceAll(',', ' ')}';

double _interval(double t, double begin, double end, [Curve curve = Curves.easeOutCubic]) {
  if (t <= begin) return 0;
  if (t >= end) return 1;
  return curve.transform((t - begin) / (end - begin));
}

// ═══════════════════════════════════════════════════════════════════════════
// Library stats
// ═══════════════════════════════════════════════════════════════════════════

class LibraryStatsCard extends StatelessWidget {
  const LibraryStatsCard({super.key, required this.pal, required this.items});

  final OnbPalette pal;
  final List<SavedRouteItem> items;

  @override
  Widget build(BuildContext context) {
    final spent = items.fold<double>(0, (s, e) => s + e.fare * e.useCount);
    final rides = items.fold<int>(0, (s, e) => s + e.useCount);
    final favs = items.where((e) => e.isFavorite).length;

    // Rides per category, biggest first.
    final byCat = <String, int>{};
    for (final e in items) {
      byCat[e.category] = (byCat[e.category] ?? 0) + e.useCount;
    }
    final cats = byCat.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = items.isEmpty ? null : items.reduce((a, b) => a.useCount >= b.useCount ? a : b);

    return GlassPanel(
      pal: pal,
      radius: 28,
      padding: const EdgeInsets.all(18),
      glow: OnbPalette.gold.withValues(alpha: 0.14),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1500),
        builder: (context, t, _) {
          final count = _interval(t, 0, 0.7);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'SPENT ON SAVED ROUTES',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.8, color: homeAccentText(pal)),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRand(spent * count),
                    style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1.2, height: 1.05, color: pal.text),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('across ${(rides * count).round()} rides', style: GoogleFonts.inter(fontSize: 13, color: pal.muted)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _StatPill(pal: pal, icon: Icons.alt_route_rounded, value: '${items.length}', label: 'Routes', color: homeViolet),
                  const SizedBox(width: 8),
                  _StatPill(pal: pal, icon: Icons.airport_shuttle_rounded, value: '$rides', label: 'Rides', color: OnbPalette.gold),
                  const SizedBox(width: 8),
                  _StatPill(pal: pal, icon: Icons.star_rounded, value: '$favs', label: 'Favourites', color: homeRose),
                ],
              ),
              if (cats.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Rides by category', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: pal.muted)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        for (var i = 0; i < cats.length; i++)
                          Expanded(
                            flex: math.max(1, (cats[i].value * 1000 * _interval(t, 0.15 + i * 0.08, 0.75 + i * 0.05)).round()),
                            child: Container(
                              margin: EdgeInsets.only(right: i < cats.length - 1 ? 2 : 0),
                              color: routeCategoryColor(cats[i].key),
                            ),
                          ),
                        // Unfilled remainder while the bar grows in.
                        Expanded(
                          flex: math.max(
                            0,
                            (rides * 1000 -
                                    [for (var i = 0; i < cats.length; i++) cats[i].value * 1000 * _interval(t, 0.15 + i * 0.08, 0.75 + i * 0.05)]
                                        .fold<double>(0, (a, b) => a + b))
                                .round(),
                          ),
                          child: Container(color: pal.faint),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    for (final c in cats)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: routeCategoryColor(c.key), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(c.key, style: GoogleFonts.inter(fontSize: 12, color: pal.text)),
                          const SizedBox(width: 4),
                          Text('${c.value}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: pal.muted)),
                        ],
                      ),
                  ],
                ),
              ],
              if (top != null && top.useCount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: OnbPalette.gold.withValues(alpha: 0.1),
                    border: Border.all(color: OnbPalette.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [OnbPalette.goldBright, OnbPalette.ember]),
                        ),
                        child: const Icon(Icons.emoji_events_rounded, size: 20, color: OnbPalette.ink),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Most ridden', style: GoogleFonts.inter(fontSize: 11.5, color: pal.muted)),
                            Text(
                              top.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: pal.text),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${top.useCount} rides',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: homeAccentText(pal)),
                          ),
                          if (rides > 0)
                            Text(
                              '${(top.useCount / rides * 100).round()}% of all rides',
                              style: GoogleFonts.inter(fontSize: 11, color: pal.muted),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.pal, required this.icon, required this.value, required this.label, required this.color});

  final OnbPalette pal;
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: pal.glass,
          border: Border.all(color: pal.stroke),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, height: 1.1, color: pal.text)),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 10.5, color: pal.muted)),
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
// Search + filters
// ═══════════════════════════════════════════════════════════════════════════

class LibrarySearchField extends StatelessWidget {
  const LibrarySearchField({super.key, required this.pal, required this.controller, required this.onChanged});

  final OnbPalette pal;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const none = InputBorder.none;
    return Container(
      height: 54,
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(
        color: pal.glass,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pal.stroke),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: pal.muted, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: OnbPalette.gold,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.inter(fontSize: 15, color: pal.text),
              decoration: InputDecoration(
                hintText: 'Search by name or place',
                hintStyle: GoogleFonts.inter(fontSize: 15, color: pal.muted),
                filled: false,
                isDense: true,
                border: none,
                enabledBorder: none,
                focusedBorder: none,
                errorBorder: none,
                focusedErrorBorder: none,
                disabledBorder: none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: controller.text.isEmpty
                ? const SizedBox(width: 8)
                : IconButton(
                    key: const ValueKey('clear'),
                    tooltip: 'Clear search',
                    icon: Icon(Icons.close_rounded, color: pal.muted, size: 20),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class FilterChipData {
  const FilterChipData({required this.label, required this.count, required this.selected, required this.onTap, this.color, this.icon});

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final IconData? icon;
}

class LibraryFilterRow extends StatelessWidget {
  const LibraryFilterRow({super.key, required this.pal, required this.chips});

  final OnbPalette pal;
  final List<FilterChipData> chips;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = chips[i];
          final accent = c.color ?? OnbPalette.gold;
          return Semantics(
            button: true,
            selected: c.selected,
            child: GestureDetector(
              onTap: c.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: c.selected && c.color == null
                      ? const LinearGradient(colors: [OnbPalette.goldBright, OnbPalette.gold])
                      : null,
                  color: c.selected ? (c.color == null ? null : accent.withValues(alpha: 0.18)) : pal.glass,
                  border: Border.all(
                    color: c.selected ? (c.color == null ? Colors.transparent : accent.withValues(alpha: 0.7)) : pal.stroke,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (c.icon != null) ...[
                      Icon(
                        c.icon,
                        size: 15,
                        color: c.selected && c.color == null ? OnbPalette.ink : accent,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      c.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.selected && c.color == null ? OnbPalette.ink : pal.text,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        color: c.selected && c.color == null ? OnbPalette.ink.withValues(alpha: 0.15) : pal.glass,
                      ),
                      child: Text(
                        '${c.count}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: c.selected && c.color == null ? OnbPalette.ink : pal.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Route ticket
// ═══════════════════════════════════════════════════════════════════════════

const _ticketTop = 142.0;
const _ticketStub = 74.0;

class RouteTicket extends StatelessWidget {
  const RouteTicket({super.key, required this.item, required this.pal, this.onRide, this.onFav, this.onMore});

  final SavedRouteItem item;
  final OnbPalette pal;
  final VoidCallback? onRide;
  final VoidCallback? onFav;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final color = routeCategoryColor(item.category);
    final label = GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: pal.muted);
    final interactive = onRide != null;

    return CustomPaint(
      painter: _TicketPainter(pal: pal, notchY: _ticketTop, accent: color),
      child: SizedBox(
        height: _ticketTop + _ticketStub,
        child: Column(
          children: [
            SizedBox(
              height: _ticketTop,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(99)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(routeCategoryIcon(item.category), size: 13, color: color),
                              const SizedBox(width: 5),
                              Text(
                                item.category,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color.lerp(color, Colors.black, pal.day * 0.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (item.useCount > 0)
                          Text('${item.useCount}× ridden', style: GoogleFonts.inter(fontSize: 11.5, color: pal.muted)),
                        const Spacer(),
                        if (onFav != null)
                          _FavButton(on: item.isFavorite, pal: pal, onTap: onFav!)
                        else if (item.isFavorite)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.star_rounded, color: OnbPalette.gold, size: 22),
                          ),
                        if (onMore != null)
                          IconButton(
                            tooltip: 'More actions',
                            visualDensity: VisualDensity.compact,
                            onPressed: onMore,
                            icon: Icon(Icons.more_horiz_rounded, color: pal.muted),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        item.name.isEmpty ? 'Untitled route' : item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: pal.text),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('FROM', style: label),
                                const SizedBox(height: 2),
                                Text(
                                  item.from.isEmpty ? '—' : item.from,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: pal.text),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 84,
                            height: 30,
                            child: CustomPaint(painter: _JourneyPainter(pal: pal, stops: item.stops.length)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('TO', style: label),
                                const SizedBox(height: 2),
                                Text(
                                  item.to.isEmpty ? '—' : item.to,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: pal.text),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: _ticketStub,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _StubValue(
                      label: 'FARE',
                      value: 'R${item.fare.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w700, color: homeAccentText(pal)),
                      labelStyle: label,
                    ),
                    const SizedBox(width: 16),
                    _StubValue(
                      label: 'TIME',
                      value: '${item.durationMin} min',
                      style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w700, color: pal.text),
                      labelStyle: label,
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      flex: 10,
                      child: _StubValue(
                        label: 'DIST',
                        value: '${item.distanceKm.toStringAsFixed(1)} km',
                        style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w700, color: pal.text),
                        labelStyle: label,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 8),
                    if (interactive)
                      Semantics(
                        button: true,
                        label: 'Ride ${item.name} again',
                        child: GestureDetector(
                          onTap: onRide,
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.only(left: 13, right: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              gradient: const LinearGradient(colors: [OnbPalette.goldBright, OnbPalette.gold]),
                              boxShadow: [BoxShadow(color: OnbPalette.gold.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Ride', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w800, color: OnbPalette.ink)),
                                const SizedBox(width: 8),
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(color: OnbPalette.ink, shape: BoxShape.circle),
                                  child: const Icon(Icons.arrow_forward_rounded, size: 16, color: OnbPalette.goldBright),
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
          ],
        ),
      ),
    );
  }
}

class _StubValue extends StatelessWidget {
  const _StubValue({required this.label, required this.value, required this.style, required this.labelStyle});

  final String label;
  final String value;
  final TextStyle style;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, maxLines: 1, softWrap: false, style: labelStyle),
        const SizedBox(height: 3),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
      ],
    );
  }
}

class _FavButton extends StatelessWidget {
  const _FavButton({required this.on, required this.pal, required this.onTap});

  final bool on;
  final OnbPalette pal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: on ? 'Remove from favourites' : 'Add to favourites',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: TweenAnimationBuilder<double>(
            key: ValueKey(on),
            tween: Tween(begin: on ? 0.4 : 1, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, s, child) => Transform.scale(scale: s, child: child),
            child: Icon(
              on ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 23,
              color: on ? OnbPalette.gold : pal.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketPainter extends CustomPainter {
  _TicketPainter({required this.pal, required this.notchY, required this.accent});

  final OnbPalette pal;
  final double notchY;
  final Color accent;

  Path _shape(Size size) {
    const r = 11.0;
    final body = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)));
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, notchY), radius: r))
      ..addOval(Rect.fromCircle(center: Offset(size.width, notchY), radius: r));
    return Path.combine(PathOperation.difference, body, notches);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _shape(size);
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.5 * (1 - pal.day) + 0.12), 10, false);
    final rect = Offset.zero & size;
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(const Color(0xFF232228), const Color(0xFFFFFFFF), pal.day)!,
            Color.lerp(const Color(0xFF18171C), const Color(0xFFFFF7EA), pal.day)!,
          ],
        ).createShader(rect),
    );
    // Category glow in the top-left corner.
    canvas.save();
    canvas.clipPath(path);
    canvas.drawCircle(
      const Offset(0, 0),
      size.width * 0.6,
      Paint()
        ..shader = RadialGradient(
          colors: [accent.withValues(alpha: 0.16), accent.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: size.width * 0.6)),
    );
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = pal.stroke,
    );
    // Perforation.
    final dash = Paint()
      ..color = pal.faint
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var x = 18.0; x < size.width - 18; x += 9) {
      canvas.drawLine(Offset(x, notchY), Offset(math.min(x + 4, size.width - 18), notchY), dash);
    }
  }

  @override
  bool shouldRepaint(covariant _TicketPainter old) => old.pal.day != pal.day || old.accent != accent;
}

class _JourneyPainter extends CustomPainter {
  _JourneyPainter({required this.pal, required this.stops});

  final OnbPalette pal;
  final int stops;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height - 9;
    const x0 = 10.0;
    final x1 = size.width - 10;
    final dash = Paint()
      ..color = pal.muted
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var x = x0; x < x1; x += 6) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 3, x1), y), dash);
    }
    canvas.drawCircle(Offset(x0, y), 4, Paint()..color = OnbPalette.teal);
    canvas.drawCircle(Offset(x1, y), 4, Paint()..color = OnbPalette.ember);
    for (var i = 0; i < stops; i++) {
      final x = x0 + (x1 - x0) * (i + 1) / (stops + 1);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = OnbPalette.gold);
    }
    // Taxi badge riding the line.
    final c = Offset(size.width / 2, y);
    canvas.drawCircle(c, 9, Paint()..color = OnbPalette.gold);
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.local_taxi_rounded.codePoint),
        style: TextStyle(
          fontSize: 12,
          fontFamily: Icons.local_taxi_rounded.fontFamily,
          package: Icons.local_taxi_rounded.fontPackage,
          color: OnbPalette.ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _JourneyPainter old) => old.pal.day != pal.day || old.stops != stops;
}

// ═══════════════════════════════════════════════════════════════════════════
// Empty state
// ═══════════════════════════════════════════════════════════════════════════

class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({super.key, required this.pal, required this.filtered, required this.onAction});

  final OnbPalette pal;

  /// True when routes exist but the current search/filter hides them all.
  final bool filtered;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OnbPalette.gold.withValues(alpha: 0.1),
              border: Border.all(color: OnbPalette.gold.withValues(alpha: 0.35)),
            ),
            child: Icon(
              filtered ? Icons.search_off_rounded : Icons.bookmark_add_outlined,
              size: 42,
              color: OnbPalette.gold,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            filtered ? 'No matching routes' : 'No saved routes yet',
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: pal.text),
          ),
          const SizedBox(height: 6),
          Text(
            filtered
                ? 'Try a different search or clear your filters.'
                : 'Save the trips you take often and plan them again in one tap.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: pal.muted),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onAction,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: filtered ? null : const LinearGradient(colors: [OnbPalette.goldBright, OnbPalette.gold]),
                color: filtered ? pal.glass : null,
                border: filtered ? Border.all(color: pal.stroke) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(filtered ? Icons.filter_alt_off_rounded : Icons.add_rounded, size: 19, color: filtered ? pal.text : OnbPalette.ink),
                  const SizedBox(width: 8),
                  Text(
                    filtered ? 'Clear filters' : 'Save your first route',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: filtered ? pal.text : OnbPalette.ink),
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

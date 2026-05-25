import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../services/saved_routes_service.dart';
import '../theme.dart';
import '../nav.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

enum _SavedSort { recent, mostUsed, cheapest, shortest }

class _SavedPageState extends State<SavedPage> with SingleTickerProviderStateMixin {
  final _svc = SavedRoutesService.instance;
  String _query = '';
  String _category = 'All';
  _SavedSort _sort = _SavedSort.recent;
  bool _favoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _svc.load();
    _svc.addListener(_onChange);
  }

  @override
  void dispose() {
    _svc.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  List<SavedRouteItem> get _filtered {
    var list = _svc.items.toList();
    if (_favoritesOnly) list = list.where((e) => e.isFavorite).toList();
    if (_category != 'All') list = list.where((e) => e.category == _category).toList();
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((e) =>
          e.name.toLowerCase().contains(q) ||
          e.from.toLowerCase().contains(q) ||
          e.to.toLowerCase().contains(q)).toList();
    }
    switch (_sort) {
      case _SavedSort.recent:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SavedSort.mostUsed:
        list.sort((a, b) => b.useCount.compareTo(a.useCount));
        break;
      case _SavedSort.cheapest:
        list.sort((a, b) => a.fare.compareTo(b.fare));
        break;
      case _SavedSort.shortest:
        list.sort((a, b) => a.durationMin.compareTo(b.durationMin));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_svc.loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved Routes')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final items = _filtered;
    final totalFare = _svc.items.fold<double>(0, (s, e) => s + e.fare * e.useCount);
    final totalTrips = _svc.items.fold<int>(0, (s, e) => s + e.useCount);
    final favs = _svc.items.where((e) => e.isFavorite).length;
    final cats = ['All', ..._svc.categories];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 230,
            backgroundColor: cs.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            title: const Text('Saved Routes'),
            actions: [
              IconButton(
                tooltip: _favoritesOnly ? 'Show all' : 'Favorites only',
                icon: Icon(_favoritesOnly ? Icons.star_rounded : Icons.star_border_rounded,
                    color: _favoritesOnly ? Colors.amber : null),
                onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
              ),
              PopupMenuButton<_SavedSort>(
                icon: const Icon(Icons.sort_rounded),
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: _SavedSort.recent, child: Text('Most recent')),
                  PopupMenuItem(value: _SavedSort.mostUsed, child: Text('Most used')),
                  PopupMenuItem(value: _SavedSort.cheapest, child: Text('Cheapest')),
                  PopupMenuItem(value: _SavedSort.shortest, child: Text('Shortest')),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _StatsHero(
                totalSpend: totalFare,
                totalTrips: totalTrips,
                favorites: favs,
                routes: _svc.items.length,
                isDark: isDark,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Search saved routes…',
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = cats[i];
                  final sel = c == _category;
                  return ChoiceChip(
                    label: Text(c),
                    selected: sel,
                    onSelected: (_) => setState(() => _category = c),
                    selectedColor: cs.primary,
                    labelStyle: TextStyle(
                      color: sel ? cs.onPrimary : null,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(onAdd: _openAddSheet),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 100),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => _SavedRouteCard(
                  item: items[i],
                  onTap: () => _useRoute(items[i]),
                  onFav: () => _svc.toggleFavorite(items[i].id),
                  onDelete: () => _confirmDelete(items[i]),
                  onEdit: () => _openAddSheet(edit: items[i]),
                ).animate().fadeIn(delay: (40 * i).ms, duration: 300.ms).slideY(begin: 0.08, end: 0),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Save route'),
      ),
    );
  }

  void _useRoute(SavedRouteItem item) async {
    await _svc.incrementUse(item.id);
    if (!mounted) return;
    context.push(AppRoutes.calculator);
  }

  Future<void> _confirmDelete(SavedRouteItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete route?'),
        content: Text('Remove "${item.name}" from your saved routes?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.15), foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await _svc.remove(item.id);
  }

  void _openAddSheet({SavedRouteItem? edit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _AddEditRouteSheet(initial: edit),
    );
  }
}

class _StatsHero extends StatelessWidget {
  final double totalSpend;
  final int totalTrips;
  final int favorites;
  final int routes;
  final bool isDark;

  const _StatsHero({
    required this.totalSpend,
    required this.totalTrips,
    required this.favorites,
    required this.routes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 80, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1B1B1B), const Color(0xFF2A2418)]
              : [cs.primary.withValues(alpha: 0.95), const Color(0xFFFFA000)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text('Your travel library',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _StatBox(label: 'Routes', value: '$routes', icon: Icons.alt_route_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _StatBox(label: 'Trips', value: '$totalTrips', icon: Icons.local_taxi_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _StatBox(label: 'Favorites', value: '$favorites', icon: Icons.star_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _StatBox(label: 'Spent', value: 'R${totalSpend.toStringAsFixed(0)}', icon: Icons.payments_rounded)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatBox({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
        ],
      ),
    );
  }
}

class _SavedRouteCard extends StatelessWidget {
  final SavedRouteItem item;
  final VoidCallback onTap;
  final VoidCallback onFav;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  const _SavedRouteCard({
    required this.item,
    required this.onTap,
    required this.onFav,
    required this.onDelete,
    required this.onEdit,
  });

  Color _catColor(String c) {
    switch (c) {
      case 'Daily Commute':
        return const Color(0xFF1E88E5);
      case 'Weekend':
        return const Color(0xFF8E24AA);
      case 'Family':
        return const Color(0xFFE53935);
      case 'Errands':
        return const Color(0xFF43A047);
      default:
        return const Color(0xFFFFB300);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final col = _catColor(item.category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: col.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.alt_route_rounded, color: col),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: col.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(item.category,
                              style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onFav,
                    icon: Icon(
                      item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      color: item.isFavorite ? Colors.amber : null,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Edit')])),
                      PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _RouteLine(from: item.from, to: item.to, stops: item.stops),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _MetricChip(icon: Icons.payments_rounded, label: 'R${item.fare.toStringAsFixed(0)}'),
                  const SizedBox(width: 6),
                  _MetricChip(icon: Icons.timer_outlined, label: '${item.durationMin} min'),
                  const SizedBox(width: 6),
                  _MetricChip(icon: Icons.straighten_rounded, label: '${item.distanceKm.toStringAsFixed(1)} km'),
                  const Spacer(),
                  if (item.useCount > 0)
                    Text('Used ${item.useCount}×',
                        style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.55))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  final String from;
  final String to;
  final List<String> stops;
  const _RouteLine({required this.from, required this.to, required this.stops});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final children = <Widget>[];
    children.add(_dot(const Color(0xFF43A047), from, cs));
    for (final s in stops) {
      children.add(_connector());
      children.add(_dot(const Color(0xFFFFB300), s, cs, small: true));
    }
    children.add(_connector());
    children.add(_dot(const Color(0xFFE53935), to, cs));
    return Column(children: children);
  }

  Widget _dot(Color color, String label, ColorScheme cs, {bool small = false}) {
    return Row(
      children: [
        Container(
          width: small ? 8 : 10,
          height: small ? 8 : 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: small ? 12 : 13.5,
                fontWeight: small ? FontWeight.w500 : FontWeight.w600,
                color: cs.onSurface.withValues(alpha: small ? 0.7 : 0.9),
              )),
        ),
      ],
    );
  }

  Widget _connector() => Padding(
        padding: const EdgeInsets.only(left: 4.5),
        child: Container(width: 1.5, height: 14, color: Colors.grey.withValues(alpha: 0.4)),
      );
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bookmark_border_rounded, size: 48,
                color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('No saved routes yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Save your favorite trips so you can plan them in one tap.',
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add your first route'),
          ),
        ],
      ),
    );
  }
}

class _AddEditRouteSheet extends StatefulWidget {
  final SavedRouteItem? initial;
  const _AddEditRouteSheet({this.initial});

  @override
  State<_AddEditRouteSheet> createState() => _AddEditRouteSheetState();
}

class _AddEditRouteSheetState extends State<_AddEditRouteSheet> {
  final _name = TextEditingController();
  final _from = TextEditingController();
  final _to = TextEditingController();
  final _fare = TextEditingController();
  final _km = TextEditingController();
  final _dur = TextEditingController();
  String _category = 'Favorite';
  bool _fav = false;

  static const _categories = ['Daily Commute', 'Weekend', 'Family', 'Errands', 'Favorite'];

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
  }

  @override
  void dispose() {
    _name.dispose();
    _from.dispose();
    _to.dispose();
    _fare.dispose();
    _km.dispose();
    _dur.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _from.text.trim().isEmpty || _to.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in name, from and to.')),
      );
      return;
    }
    final now = DateTime.now();
    final item = SavedRouteItem(
      id: widget.initial?.id ?? 'r_${now.microsecondsSinceEpoch}',
      name: _name.text.trim(),
      from: _from.text.trim(),
      to: _to.text.trim(),
      fare: double.tryParse(_fare.text) ?? 0,
      distanceKm: double.tryParse(_km.text) ?? 0,
      durationMin: int.tryParse(_dur.text) ?? 0,
      category: _category,
      isFavorite: _fav,
      createdAt: widget.initial?.createdAt ?? now,
      useCount: widget.initial?.useCount ?? 0,
    );
    if (widget.initial == null) {
      await SavedRoutesService.instance.add(item);
    } else {
      await SavedRoutesService.instance.update(item);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(widget.initial == null ? 'Save new route' : 'Edit route',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.md),
            _Field(controller: _name, label: 'Name', hint: 'e.g. Home → Work', icon: Icons.label_outline_rounded),
            _Field(controller: _from, label: 'From', icon: Icons.trip_origin_rounded),
            _Field(controller: _to, label: 'To', icon: Icons.place_rounded),
            Row(
              children: [
                Expanded(child: _Field(controller: _fare, label: 'Fare (R)', icon: Icons.payments_rounded, number: true)),
                const SizedBox(width: 8),
                Expanded(child: _Field(controller: _km, label: 'Km', icon: Icons.straighten_rounded, number: true)),
                const SizedBox(width: 8),
                Expanded(child: _Field(controller: _dur, label: 'Minutes', icon: Icons.timer_outlined, number: true)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: _categories.map((c) => ChoiceChip(
                label: Text(c),
                selected: _category == c,
                onSelected: (_) => setState(() => _category = c),
              )).toList(),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mark as favorite'),
              value: _fav,
              onChanged: (v) => setState(() => _fav = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(widget.initial == null ? 'Save route' : 'Update route'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool number;
  const _Field({required this.controller, required this.label, this.hint, required this.icon, this.number = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
    );
  }
}

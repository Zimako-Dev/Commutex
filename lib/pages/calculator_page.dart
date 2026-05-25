import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../data/models.dart';
import '../data/mock_data.dart';
import '../services/fare_service.dart';
import '../widgets/modern_widgets.dart';
import '../widgets/location_picker.dart';
import '../theme.dart';
import '../nav.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  Location? startLocation;
  Location? endLocation;
  final List<Location?> _stops = [];
  bool isPeak = false;
  bool _autoPeak = true;
  int _passengers = 1;
  double _tipPercent = 0;

  static const List<_QuickPair> _quickPairs = [
    _QuickPair(label: 'CBD → Soweto', fromId: 'jhb_cbd', toId: 'soweto'),
    _QuickPair(label: 'Sandton → Alex', fromId: 'sandton', toId: 'alex'),
    _QuickPair(label: 'PTA → Mamelodi', fromId: 'pta_cbd', toId: 'mamelodi'),
    _QuickPair(label: 'CT → Khayelitsha', fromId: 'ct_cbd', toId: 'khayelitsha'),
  ];

  @override
  void initState() {
    super.initState();
    _maybeApplyAutoPeak();
  }

  void _maybeApplyAutoPeak() {
    if (!_autoPeak) return;
    final h = DateTime.now().hour;
    final peakNow = (h >= 6 && h <= 9) || (h >= 16 && h <= 19);
    isPeak = peakNow;
  }

  TripResult? get _livePreview {
    if (startLocation == null || endLocation == null) return null;
    final stops = _stops.whereType<Location>().toList();
    return FareCalculatorService().calculateTrip(
      startLocation!,
      endLocation!,
      stops: stops,
      isPeak: isPeak,
    );
  }

  void _swap() {
    setState(() {
      final tmp = startLocation;
      startLocation = endLocation;
      endLocation = tmp;
    });
  }

  static const int _maxStops = 10;

  void _addStop() {
    if (_stops.length >= _maxStops) return;
    setState(() => _stops.add(null));
  }

  void _reorderStop(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _stops.removeAt(oldIndex);
      _stops.insert(newIndex, item);
    });
  }

  void _removeStop(int i) => setState(() => _stops.removeAt(i));

  void _applyQuickPair(_QuickPair pair) {
    setState(() {
      startLocation = MockData.locations.firstWhere((l) => l.id == pair.fromId);
      endLocation = MockData.locations.firstWhere((l) => l.id == pair.toId);
    });
  }

  void _calculate() {
    if (startLocation == null || endLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end locations')),
      );
      return;
    }
    final result = FareCalculatorService().calculateTrip(
      startLocation!,
      endLocation!,
      stops: _stops.whereType<Location>().toList(),
      isPeak: isPeak,
    );
    context.push(AppRoutes.results, extra: result);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _livePreview;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fare Estimator'),
        actions: [
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {
              startLocation = null;
              endLocation = null;
              _stops.clear();
              _passengers = 1;
              _tipPercent = 0;
              _maybeApplyAutoPeak();
            }),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
        children: [
          _HeroPreview(preview: preview, passengers: _passengers, tipPercent: _tipPercent),
          const SizedBox(height: AppSpacing.md),
          _RouteCard(
            start: startLocation,
            end: endLocation,
            stops: _stops,
            onStartChanged: (l) => setState(() => startLocation = l),
            onEndChanged: (l) => setState(() => endLocation = l),
            onStopChanged: (i, l) => setState(() => _stops[i] = l),
            onAddStop: _addStop,
            onRemoveStop: _removeStop,
            onReorderStop: _reorderStop,
            onSwap: _swap,
            maxStops: _maxStops,
          ),
          const SizedBox(height: AppSpacing.sm),
          _QuickRoutesStrip(pairs: _quickPairs, onTap: _applyQuickPair),
          const SizedBox(height: AppSpacing.md),
          _PassengerSelector(
            value: _passengers,
            onChanged: (v) => setState(() => _passengers = v),
          ),
          const SizedBox(height: AppSpacing.md),
          _TipSelector(
            value: _tipPercent,
            onChanged: (v) => setState(() => _tipPercent = v),
          ),
          const SizedBox(height: AppSpacing.md),
          _PeakCard(
            isPeak: isPeak,
            autoPeak: _autoPeak,
            onAutoChanged: (v) => setState(() {
              _autoPeak = v;
              if (v) _maybeApplyAutoPeak();
            }),
            onManualChanged: (v) => setState(() {
              isPeak = v;
              _autoPeak = false;
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'View Detailed Breakdown',
            fullWidth: true,
            icon: Icons.receipt_long_rounded,
            onPressed: _calculate,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HERO PREVIEW
// =============================================================================

class _HeroPreview extends StatelessWidget {
  final TripResult? preview;
  final int passengers;
  final double tipPercent;

  const _HeroPreview({
    required this.preview,
    required this.passengers,
    required this.tipPercent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final hasData = preview != null;

    final fare = preview?.totalFare ?? 0;
    final tipAmount = fare * (tipPercent / 100);
    final totalWithTip = fare + tipAmount;
    final perPerson = passengers > 0 ? totalWithTip / passengers : totalWithTip;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A2410), const Color(0xFF1A1A1A)]
              : [primary.withValues(alpha: 0.95), const Color(0xFFFFE082)],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_taxi_rounded,
                    color: Colors.black, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Live Fare Estimate',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (hasData)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${preview!.distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'R',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                hasData ? totalWithTip.toStringAsFixed(2) : '--.--',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (hasData && passengers > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'R${perPerson.toStringAsFixed(2)} pp',
                      style: TextStyle(
                          color: primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (hasData)
            Row(
              children: [
                _PreviewChip(
                  icon: Icons.schedule_rounded,
                  label: '${preview!.durationMinutes.toInt()} min',
                ),
                const SizedBox(width: 8),
                _PreviewChip(
                  icon: Icons.people_rounded,
                  label: '$passengers pax',
                ),
                if (tipPercent > 0) ...[
                  const SizedBox(width: 8),
                  _PreviewChip(
                    icon: Icons.volunteer_activism_rounded,
                    label: '+R${tipAmount.toStringAsFixed(0)} tip',
                  ),
                ],
              ],
            )
          else
            Text(
              'Pick a pickup and destination to see live pricing',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0);
  }
}

class _PreviewChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PreviewChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black87),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// =============================================================================
// ROUTE CARD with stops + swap
// =============================================================================

class _RouteCard extends StatelessWidget {
  final Location? start;
  final Location? end;
  final List<Location?> stops;
  final ValueChanged<Location> onStartChanged;
  final ValueChanged<Location> onEndChanged;
  final void Function(int, Location) onStopChanged;
  final VoidCallback onAddStop;
  final ValueChanged<int> onRemoveStop;
  final void Function(int, int) onReorderStop;
  final VoidCallback onSwap;
  final int maxStops;

  const _RouteCard({
    required this.start,
    required this.end,
    required this.stops,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onStopChanged,
    required this.onAddStop,
    required this.onRemoveStop,
    required this.onReorderStop,
    required this.onSwap,
    required this.maxStops,
  });

  @override
  Widget build(BuildContext context) {
    return SleekCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LocationPicker(
            label: 'Pickup Point',
            value: start,
            onChanged: onStartChanged,
            icon: Icons.my_location,
          ),
          if (stops.isNotEmpty)
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: onReorderStop,
              children: [
                for (int i = 0; i < stops.length; i++)
                  Padding(
                    key: ValueKey('stop_$i'),
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                            padding: EdgeInsets.only(bottom: 14, right: 4),
                            child: Icon(Icons.drag_indicator_rounded, size: 20),
                          ),
                        ),
                        Expanded(
                          child: LocationPicker(
                            label: 'Stop ${i + 1}',
                            value: stops[i],
                            onChanged: (l) => onStopChanged(i, l),
                            icon: Icons.add_location_alt_outlined,
                          ),
                        ),
                        IconButton(
                          onPressed: () => onRemoveStop(i),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Remove stop',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                Material(
                  color: Theme.of(context).colorScheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onSwap,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.swap_vert_rounded,
                          color: Colors.black, size: 20),
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          LocationPicker(
            label: 'Destination',
            value: end,
            onChanged: onEndChanged,
            icon: Icons.location_on,
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: stops.length >= maxStops ? null : onAddStop,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: Text(stops.length >= maxStops
                  ? 'Max $maxStops stops'
                  : 'Add stop (${stops.length}/$maxStops)'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// QUICK ROUTES
// =============================================================================

class _QuickPair {
  final String label;
  final String fromId;
  final String toId;
  const _QuickPair({required this.label, required this.fromId, required this.toId});
}

class _QuickRoutesStrip extends StatelessWidget {
  final List<_QuickPair> pairs;
  final ValueChanged<_QuickPair> onTap;
  const _QuickRoutesStrip({required this.pairs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Popular routes',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pairs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final p = pairs[i];
              return ActionChip(
                avatar: const Icon(Icons.flash_on_rounded, size: 16),
                label: Text(p.label),
                onPressed: () => onTap(p),
              );
            },
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PASSENGER SELECTOR (Split fare)
// =============================================================================

class _PassengerSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _PassengerSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SleekCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.groups_2_rounded,
                color: theme.colorScheme.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Split the fare',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  value == 1 ? 'Just you' : 'Splitting with $value people',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          _StepperButton(
            icon: Icons.remove_rounded,
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
          ),
          Container(
            width: 36,
            alignment: Alignment.center,
            child: Text('$value',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            onPressed: value < 8 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _StepperButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = Theme.of(context).colorScheme.primary;
    return Material(
      color: enabled
          ? color.withValues(alpha: 0.15)
          : Theme.of(context).disabledColor.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon,
              size: 18, color: enabled ? color : Theme.of(context).disabledColor),
        ),
      ),
    );
  }
}

// =============================================================================
// TIP SELECTOR
// =============================================================================

class _TipSelector extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _TipSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [0.0, 5.0, 10.0, 15.0];
    return SleekCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volunteer_activism_rounded, size: 18),
              const SizedBox(width: 8),
              Text('Driver tip',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(value == 0 ? 'No tip' : '${value.toInt()}%',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: options.map((opt) {
              final selected = value == opt;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => onChanged(opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        opt == 0 ? 'None' : '${opt.toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.black
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PEAK CARD
// =============================================================================

class _PeakCard extends StatelessWidget {
  final bool isPeak;
  final bool autoPeak;
  final ValueChanged<bool> onAutoChanged;
  final ValueChanged<bool> onManualChanged;

  const _PeakCard({
    required this.isPeak,
    required this.autoPeak,
    required this.onAutoChanged,
    required this.onManualChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SleekCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPeak
                      ? Colors.redAccent.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPeak ? Icons.trending_up_rounded : Icons.check_circle_rounded,
                  color: isPeak ? Colors.redAccent : Colors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isPeak ? 'Peak hours active' : 'Off-peak pricing',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      isPeak
                          ? '+30% surge applied to fare'
                          : 'Standard rates apply',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isPeak,
                onChanged: onManualChanged,
                activeThumbColor: theme.colorScheme.primary,
                activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Auto-detect peak (6–9 AM, 4–7 PM)',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Switch.adaptive(
                value: autoPeak,
                onChanged: onAutoChanged,
                activeThumbColor: theme.colorScheme.primary,
                activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

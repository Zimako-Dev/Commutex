import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import '../theme.dart';
import '../widgets/modern_widgets.dart';
import '../nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  // Mock user stats (would come from a service in production).
  final int _tripsThisWeek = 12;
  final double _spentThisWeek = 312.50;
  final double _savedThisWeek = 84.00;
  final double _kmTravelled = 156.4;

  final List<_PopularRoute> _popularRoutes = const [
    _PopularRoute(from: 'JHB CBD', to: 'Soweto', price: 'R25', time: '35 min', trend: 0),
    _PopularRoute(from: 'Sandton', to: 'Alex', price: 'R18', time: '20 min', trend: 1),
    _PopularRoute(from: 'Pretoria', to: 'JHB', price: 'R55', time: '55 min', trend: -1),
    _PopularRoute(from: 'Randburg', to: 'Rosebank', price: 'R15', time: '15 min', trend: 0),
  ];

  final List<_DailyTip> _tips = const [
    _DailyTip(
      icon: Icons.security_rounded,
      title: 'Stay Safe',
      body: 'Always sit near the door if you\'re alighting soon. Keep valuables out of sight.',
      color: Color(0xFF43A047),
    ),
    _DailyTip(
      icon: Icons.savings_rounded,
      title: 'Save Smart',
      body: 'Buying a weekly pass on busy routes can save you up to 20%.',
      color: Color(0xFFFFB300),
    ),
    _DailyTip(
      icon: Icons.access_time_rounded,
      title: 'Beat the Rush',
      body: 'Taxis fill up fastest between 6–8 AM. Leave 15 min earlier to grab a seat.',
      color: Color(0xFF1E88E5),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  String get _greeting {
    final h = _now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData get _greetingIcon {
    final h = _now.hour;
    if (h < 12) return Icons.wb_sunny_rounded;
    if (h < 17) return Icons.wb_cloudy_rounded;
    return Icons.nights_stay_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 600));
            if (mounted) setState(() => _now = DateTime.now());
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 100,
            ),
            children: [
              _HomeHeader(
                greeting: _greeting,
                greetingIcon: _greetingIcon,
                now: _now,
                onLogout: () => _handleLogout(context),
              ),
              const SizedBox(height: AppSpacing.md),
              _StatsHeroCard(
                trips: _tripsThisWeek,
                spent: _spentThisWeek,
                saved: _savedThisWeek,
                km: _kmTravelled,
              ),
              const SizedBox(height: AppSpacing.lg),
              _QuickActionsGrid(),
              const SizedBox(height: AppSpacing.lg),
              const _AiCompanionBanner(),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: 'Popular Routes',
                actionLabel: 'See all',
                onAction: () {},
              ),
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _popularRoutes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) => _PopularRouteCard(route: _popularRoutes[i]),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: 'Daily Tips',
                actionLabel: 'More',
                onAction: () {},
              ),
              SizedBox(
                height: 150,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.92),
                  itemCount: _tips.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _DailyTipCard(tip: _tips[i]),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: 'Recent Journeys',
                actionLabel: 'View all',
                onAction: () {},
              ),
              ..._mockRecentTrips.map((t) => _RecentTripTile(trip: t)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEmergencySheet(context),
        backgroundColor: SmartColors.error,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.sos_rounded),
        label: const Text('SOS'),
      ),
    );
  }

  static const List<_RecentTrip> _mockRecentTrips = [
    _RecentTrip(from: 'JHB CBD', to: 'Soweto', price: 'R25.00', when: 'Yesterday, 17:42'),
    _RecentTrip(from: 'Sandton', to: 'Alex', price: 'R18.50', when: 'Mon, 08:10'),
    _RecentTrip(from: 'Rosebank', to: 'Randburg', price: 'R15.00', when: 'Sun, 14:30'),
  ];

  void _handleLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go(AppRoutes.auth);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showEmergencySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emergency & Help',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            _EmergencyTile(
              icon: Icons.local_police_rounded,
              color: const Color(0xFF1E88E5),
              title: 'Call 10111',
              subtitle: 'SAPS Emergency',
            ),
            _EmergencyTile(
              icon: Icons.medical_services_rounded,
              color: const Color(0xFFE53935),
              title: 'Call 10177',
              subtitle: 'Ambulance',
            ),
            _EmergencyTile(
              icon: Icons.share_location_rounded,
              color: const Color(0xFF43A047),
              title: 'Share my live location',
              subtitle: 'Send to trusted contacts',
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HEADER
// ============================================================================
class _HomeHeader extends StatelessWidget {
  final String greeting;
  final IconData greetingIcon;
  final DateTime now;
  final VoidCallback onLogout;

  const _HomeHeader({
    required this.greeting,
    required this.greetingIcon,
    required this.now,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.6)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text('C',
              style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black,
              )),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(greetingIcon, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(greeting,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                ],
              ),
              Text('Commuter',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        _HeaderIconButton(
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          tooltip: isDark ? 'Light mode' : 'Dark mode',
          onTap: () => context.read<ThemeProvider>().toggleTheme(context),
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          icon: Icons.notifications_outlined,
          tooltip: 'Notifications',
          onTap: () {},
          badge: true,
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          onTap: () => context.push(AppRoutes.settings),
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          icon: Icons.logout_rounded,
          tooltip: 'Logout',
          onTap: onLogout,
          foreground: theme.colorScheme.error,
        ),
      ],
    ).animate().fadeIn(duration: 350.ms);
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool badge;
  final Color? foreground;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = false,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: theme.colorScheme.surfaceContainerHighest,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, size: 20, color: foreground ?? theme.colorScheme.onSurface),
              ),
            ),
          ),
          if (badge)
            Positioned(
              right: 6, top: 6,
              child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: SmartColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATS HERO
// ============================================================================
class _StatsHeroCard extends StatelessWidget {
  final int trips;
  final double spent;
  final double saved;
  final double km;

  const _StatsHeroCard({
    required this.trips,
    required this.spent,
    required this.saved,
    required this.km,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A1F00), const Color(0xFF1A1306)]
              : [const Color(0xFFFFE082), const Color(0xFFFFC107)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 24, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded,
                  color: isDark ? theme.colorScheme.primary : Colors.black87),
              const SizedBox(width: 6),
              Text('This week',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('Updated now',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black87)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('R${spent.toStringAsFixed(2)}',
                  style: theme.textTheme.displayMedium?.copyWith(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('spent',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black87)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _StatPill(icon: Icons.directions_bus_rounded, label: 'Trips', value: '$trips', dark: isDark)),
              const SizedBox(width: 8),
              Expanded(child: _StatPill(icon: Icons.savings_rounded, label: 'Saved', value: 'R${saved.toStringAsFixed(0)}', dark: isDark)),
              const SizedBox(width: 8),
              Expanded(child: _StatPill(icon: Icons.route_rounded, label: 'Distance', value: '${km.toStringAsFixed(0)}km', dark: isDark)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08, end: 0);
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool dark;
  const _StatPill({required this.icon, required this.label, required this.value, required this.dark});

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : Colors.black;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: fg, fontWeight: FontWeight.bold)),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: fg.withValues(alpha: 0.75))),
        ],
      ),
    );
  }
}

// ============================================================================
// QUICK ACTIONS GRID
// ============================================================================
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.calculate_rounded,
        label: 'Quick Fare',
        subtitle: 'Estimate cost',
        color: Theme.of(context).colorScheme.primary,
        onTap: () => context.push(AppRoutes.calculator),
      ),
      _QuickAction(
        icon: Icons.map_rounded,
        label: 'Plan Trip',
        subtitle: 'Multi-stop',
        color: const Color(0xFF1E88E5),
        onTap: () => context.push(AppRoutes.tripPlanner),
      ),
      _QuickAction(
        icon: Icons.smart_toy_rounded,
        label: 'TaxiMate AI',
        subtitle: 'Ask anything',
        color: const Color(0xFF8E24AA),
        onTap: () => context.push(AppRoutes.aiChat),
      ),
      _QuickAction(
        icon: Icons.bookmark_rounded,
        label: 'Saved',
        subtitle: 'Routes & places',
        color: const Color(0xFF43A047),
        onTap: () => context.push(AppRoutes.saved),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, i) => _QuickActionTile(action: actions[i])
          .animate().fadeIn(delay: (60 * i).ms, duration: 350.ms).slideY(begin: 0.15, end: 0),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(action.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text(action.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// AI COMPANION BANNER
// ============================================================================
class _AiCompanionBanner extends StatelessWidget {
  const _AiCompanionBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.aiChat),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E3A5F), const Color(0xFF2D1B4E)]
                : [const Color(0xFFE3F2FD), const Color(0xFFF3E5F5)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy_rounded, size: 28, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('TaxiMate AI',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text('NEW',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text('Your AI companion for fares, routes & more',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).shimmer(delay: 1200.ms, duration: 1400.ms),
    );
  }
}

// ============================================================================
// POPULAR ROUTES
// ============================================================================
class _PopularRoute {
  final String from, to, price, time;
  final int trend; // -1 down, 0 same, 1 up
  const _PopularRoute({
    required this.from,
    required this.to,
    required this.price,
    required this.time,
    required this.trend,
  });
}

class _PopularRouteCard extends StatelessWidget {
  final _PopularRoute route;
  const _PopularRouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    IconData trendIcon = Icons.remove_rounded;
    Color trendColor = Colors.grey;
    if (route.trend > 0) {
      trendIcon = Icons.trending_up_rounded;
      trendColor = SmartColors.error;
    } else if (route.trend < 0) {
      trendIcon = Icons.trending_down_rounded;
      trendColor = SmartColors.success;
    }

    return Container(
      width: 200,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.brightness == Brightness.dark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.place_rounded, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(route.from,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.arrow_downward_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(route.to,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Text(route.price,
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Icon(trendIcon, color: trendColor, size: 16),
              const Spacer(),
              Icon(Icons.schedule_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(route.time, style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DAILY TIPS
// ============================================================================
class _DailyTip {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _DailyTip({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}

class _DailyTipCard extends StatelessWidget {
  final _DailyTip tip;
  const _DailyTipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tip.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: tip.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tip.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(tip.icon, color: tip.color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(tip.body,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RECENT TRIPS
// ============================================================================
class _RecentTrip {
  final String from, to, price, when;
  const _RecentTrip({
    required this.from,
    required this.to,
    required this.price,
    required this.when,
  });
}

class _RecentTripTile extends StatelessWidget {
  final _RecentTrip trip;
  const _RecentTripTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SleekCard(
      onTap: () {},
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${trip.from} → ${trip.to}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(trip.when, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(trip.price,
                  style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
              Text('Repeat',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EMERGENCY
// ============================================================================
class _EmergencyTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _EmergencyTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {},
    );
  }
}

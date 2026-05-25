import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/theme_mode_selector.dart';
import '../theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLanguage = 'English';
  String _selectedDistanceUnit = 'Kilometres';
  bool _offlineMode = false;
  bool _fareAlerts = true;
  bool _routeUpdates = true;
  bool _hapticFeedback = true;

  final List<String> _languages = [
    'English',
    'isiZulu',
    'isiXhosa',
    'Afrikaans',
    'Sesotho',
  ];

  final List<String> _distanceUnits = ['Kilometres', 'Miles'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, isDark, primary),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProfileHeader(context, isDark, primary),
                const SizedBox(height: AppSpacing.md),
                _buildSectionLabel(context, 'Appearance'),
                _buildAppearanceCard(context, isDark),
                _buildSectionLabel(context, 'Preferences'),
                _buildPreferencesCard(context, isDark, primary),
                _buildSectionLabel(context, 'Notifications'),
                _buildNotificationsCard(context, isDark, primary),
                _buildSectionLabel(context, 'Privacy & Data'),
                _buildPrivacyCard(context, isDark, primary),
                _buildSectionLabel(context, 'Support'),
                _buildSupportCard(context, isDark, primary),
                const SizedBox(height: AppSpacing.sm),
                _buildVersionFooter(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // App Bar
  // ---------------------------------------------------------------------------

  Widget _buildAppBar(BuildContext context, bool isDark, Color primary) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: isDark
          ? SmartColors.darkBackground
          : SmartColors.lightBackground,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black12,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [SmartColors.darkBackground, SmartColors.darkSurface]
                  : [SmartColors.lightBackground, SmartColors.lightSurface],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Profile Header
  // ---------------------------------------------------------------------------

  Widget _buildProfileHeader(
      BuildContext context, bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: isDark ? 0.25 : 0.15),
            primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primary, primary.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.black,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commuter',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'South Africa · ZAR',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          _buildIconChip(
            context,
            icon: Icons.edit_rounded,
            label: 'Edit',
            primary: primary,
            onTap: () => _showSnack('Profile editing coming soon'),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOut);
  }

  Widget _buildIconChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: primary,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section Label
  // ---------------------------------------------------------------------------

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 11,
              letterSpacing: 1.4,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
            ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Appearance
  // ---------------------------------------------------------------------------

  Widget _buildAppearanceCard(BuildContext context, bool isDark) {
    return _SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            right: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: Row(
            children: [
              _iconBox(
                isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                isDark ? Colors.indigo : Colors.amber,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Theme',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                    Text('Choose your display preference',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const ThemeModeSelector(),
        const _Divider(),
        _buildSettingRow(
          context,
          icon: Icons.translate_rounded,
          iconColor: Colors.teal,
          title: 'Language',
          subtitle: _selectedLanguage,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedLanguage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4)),
            ],
          ),
          onTap: _showLanguageSheet,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Preferences
  // ---------------------------------------------------------------------------

  Widget _buildPreferencesCard(
      BuildContext context, bool isDark, Color primary) {
    return _SettingsCard(
      children: [
        _buildSettingRow(
          context,
          icon: Icons.currency_exchange_rounded,
          iconColor: Colors.green,
          title: 'Currency',
          subtitle: 'South African Rand (ZAR)',
          trailing: _lockBadge(context),
        ),
        const _Divider(),
        _buildSettingRow(
          context,
          icon: Icons.straighten_rounded,
          iconColor: Colors.blue,
          title: 'Distance Unit',
          subtitle: _selectedDistanceUnit,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedDistanceUnit == 'Kilometres' ? 'km' : 'mi',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4)),
            ],
          ),
          onTap: _showDistanceUnitSheet,
        ),
        const _Divider(),
        _buildSwitchRow(
          context,
          icon: Icons.wifi_off_rounded,
          iconColor: Colors.orange,
          title: 'Offline Mode',
          subtitle: 'Save routes for low connectivity',
          value: _offlineMode,
          onChanged: (val) {
            setState(() => _offlineMode = val);
            if (val) _showSnack('Routes saved for offline use');
          },
        ),
        const _Divider(),
        _buildSwitchRow(
          context,
          icon: Icons.vibration_rounded,
          iconColor: Colors.purple,
          title: 'Haptic Feedback',
          subtitle: 'Vibrate on interactions',
          value: _hapticFeedback,
          onChanged: (val) {
            setState(() => _hapticFeedback = val);
            if (val) HapticFeedback.mediumImpact();
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  Widget _buildNotificationsCard(
      BuildContext context, bool isDark, Color primary) {
    return _SettingsCard(
      children: [
        _buildSwitchRow(
          context,
          icon: Icons.price_change_rounded,
          iconColor: Colors.amber.shade700,
          title: 'Fare Alerts',
          subtitle: 'Get notified when fares change',
          value: _fareAlerts,
          onChanged: (val) => setState(() => _fareAlerts = val),
        ),
        const _Divider(),
        _buildSwitchRow(
          context,
          icon: Icons.directions_bus_rounded,
          iconColor: Colors.indigo,
          title: 'Route Updates',
          subtitle: 'Live updates for saved routes',
          value: _routeUpdates,
          onChanged: (val) => setState(() => _routeUpdates = val),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Privacy & Data
  // ---------------------------------------------------------------------------

  Widget _buildPrivacyCard(
      BuildContext context, bool isDark, Color primary) {
    return _SettingsCard(
      children: [
        _buildSettingRow(
          context,
          icon: Icons.location_on_rounded,
          iconColor: Colors.red,
          title: 'Location Permissions',
          subtitle: 'Manage location access',
          trailing: Icon(Icons.open_in_new_rounded,
              size: 18,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4)),
          onTap: () => _showSnack('Opening app permissions…'),
        ),
        const _Divider(),
        _buildSettingRow(
          context,
          icon: Icons.delete_sweep_rounded,
          iconColor: Colors.orange,
          title: 'Clear Cached Routes',
          subtitle: 'Free up local storage',
          trailing: Icon(Icons.chevron_right_rounded,
              size: 20,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4)),
          onTap: _showClearCacheDialog,
        ),
        const _Divider(),
        _buildSettingRow(
          context,
          icon: Icons.privacy_tip_rounded,
          iconColor: Colors.teal,
          title: 'Privacy Policy',
          subtitle: 'How we handle your data',
          trailing: Icon(Icons.open_in_new_rounded,
              size: 18,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4)),
          onTap: () => _showSnack('Opening Privacy Policy…'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Support
  // ---------------------------------------------------------------------------

  Widget _buildSupportCard(
      BuildContext context, bool isDark, Color primary) {
    return _SettingsCard(
      children: [
        _buildSettingRow(
          context,
          icon: Icons.help_outline_rounded,
          iconColor: Colors.blue,
          title: 'Help Centre',
          subtitle: 'FAQs and guides',
          trailing: Icon(Icons.chevron_right_rounded,
              size: 20,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4)),
          onTap: () => _showSnack('Opening Help Centre…'),
        ),
        const _Divider(),
        _buildSettingRow(
          context,
          icon: Icons.star_rounded,
          iconColor: Colors.amber,
          title: 'Rate Commutex',
          subtitle: 'Love the app? Leave a review',
          trailing: Icon(Icons.chevron_right_rounded,
              size: 20,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4)),
          onTap: () => _showSnack('Opening app store…'),
        ),
        const _Divider(),
        _buildSettingRow(
          context,
          icon: Icons.info_outline_rounded,
          iconColor: Colors.grey,
          title: 'About Commutex',
          subtitle: 'Version 1.0.0 · Build 1',
          trailing: Icon(Icons.chevron_right_rounded,
              size: 20,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4)),
          onTap: _showAboutDialog,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Version footer
  // ---------------------------------------------------------------------------

  Widget _buildVersionFooter(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'Commutex',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'v1.0.0 · Made with ♥ in South Africa',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.25),
                ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable row builders
  // ---------------------------------------------------------------------------

  Widget _buildSettingRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            _iconBox(icon, iconColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              )),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          _iconBox(icon, iconColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Widget _lockBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4)),
          const SizedBox(width: 4),
          Text(
            'Fixed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sheets & Dialogs
  // ---------------------------------------------------------------------------

  void _showLanguageSheet() {
    _showPickerSheet(
      title: 'Select Language',
      icon: Icons.translate_rounded,
      items: _languages,
      selected: _selectedLanguage,
      onSelect: (val) => setState(() => _selectedLanguage = val),
    );
  }

  void _showDistanceUnitSheet() {
    _showPickerSheet(
      title: 'Distance Unit',
      icon: Icons.straighten_rounded,
      items: _distanceUnits,
      selected: _selectedDistanceUnit,
      onSelect: (val) => setState(() => _selectedDistanceUnit = val),
    );
  }

  void _showPickerSheet({
    required String title,
    required IconData icon,
    required List<String> items,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? SmartColors.darkSurface
                : SmartColors.lightSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const SizedBox(width: AppSpacing.md),
                    Icon(icon,
                        color: Theme.of(ctx).colorScheme.primary,
                        size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Text(title,
                        style: Theme.of(ctx).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ...items.map((item) {
                  final isSelected = item == selected;
                  return ListTile(
                    title: Text(
                      item,
                      style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                    ),
                    trailing: AnimatedSwitcher(
                      duration: 200.ms,
                      child: isSelected
                          ? Icon(Icons.check_circle_rounded,
                              key: const ValueKey('check'),
                              color: Theme.of(ctx).colorScheme.primary)
                          : const SizedBox.shrink(
                              key: ValueKey('empty')),
                    ),
                    onTap: () {
                      onSelect(item);
                      Navigator.pop(ctx);
                    },
                  );
                }),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Clear Cached Routes'),
        content: const Text(
          'This will remove all locally saved routes and route history. You can re-download them at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSnack('Cache cleared successfully');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final primary = Theme.of(ctx).colorScheme.primary;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          contentPadding: const EdgeInsets.all(AppSpacing.lg),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.directions_bus_filled_rounded,
                  color: Colors.black,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Commutex',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
              const SizedBox(height: 6),
              Text('Version 1.0.0 · Build 1',
                  style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Navigate South African taxi routes with ease. Real-time fares, optimised trip planning, and multi-stop support.',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }
}

// =============================================================================
// Supporting widgets
// =============================================================================

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? SmartColors.darkSurface : SmartColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOut);
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 52,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
    );
  }
}

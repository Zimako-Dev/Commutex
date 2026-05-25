import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smarttaxi/services/theme_provider.dart';
import 'package:smarttaxi/theme.dart';

/// A segmented selector that lets the user pick Light, Dark, or System theme.
class ThemeModeSelector extends StatelessWidget {
  final bool compact;
  const ThemeModeSelector({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    final options = <_ModeOption>[
      _ModeOption(mode: ThemeMode.light, label: 'Light', icon: Icons.light_mode_rounded),
      _ModeOption(mode: ThemeMode.dark, label: 'Dark', icon: Icons.dark_mode_rounded),
      _ModeOption(mode: ThemeMode.system, label: 'System', icon: Icons.brightness_auto_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? SmartColors.darkSurfaceVariant : SmartColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: options.map((opt) {
          final selected = provider.themeMode == opt.mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => provider.setThemeMode(opt.mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(vertical: compact ? 10 : 14),
                decoration: BoxDecoration(
                  color: selected ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      opt.icon,
                      size: compact ? 18 : 20,
                      color: selected
                          ? Colors.black
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      opt.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: selected
                            ? Colors.black
                            : (isDark ? Colors.white70 : Colors.black54),
                        fontSize: compact ? 13 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ModeOption {
  final ThemeMode mode;
  final String label;
  final IconData icon;
  _ModeOption({required this.mode, required this.label, required this.icon});
}

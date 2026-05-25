import 'package:flutter/material.dart';

/// Manages the app-wide theme mode (light, dark, or system).
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isLight => _themeMode == ThemeMode.light;
  bool get isSystem => _themeMode == ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  /// Toggles between light and dark modes.
  void toggleTheme(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    setThemeMode(brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

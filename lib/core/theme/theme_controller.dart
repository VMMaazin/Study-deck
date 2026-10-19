import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages and persists the user's selected application theme mode.
/// Defaults to [ThemeMode.dark] to honor the royal midnight aesthetic.
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const String _prefKey = 'studydeck_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  bool _initialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isDark => isDarkMode;
  bool get isInitialized => _initialized;

  /// Resets state for testing purposes.
  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    _themeMode = ThemeMode.light;
  }

  /// Initializes the theme controller and loads persisted preference from disk.
  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == 'light') {
        _themeMode = ThemeMode.light;
      } else if (saved == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        // Default to light as requested
        _themeMode = ThemeMode.light;
      }
    } catch (_) {
      // In testing or fallback environments, default to light mode gracefully
      _themeMode = ThemeMode.light;
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  /// Toggles between light and dark theme modes and persists the choice.
  Future<void> toggleTheme() async {
    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  /// Sets an explicit theme mode and persists it.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, mode == ThemeMode.light ? 'light' : 'dark');
    } catch (_) {
      // Silently continue if persistent storage fails
    }
  }
}

/// An InheritedNotifier exposing [ThemeController] throughout the widget hierarchy.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    return scope?.notifier ?? ThemeController.instance;
  }
}

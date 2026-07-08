import 'package:flutter/material.dart';

/// Drives light / dark / system theme mode across the app.
///
/// Future dashboards should read theme mode via
/// `ThemeControllerProvider.of(context)` — never introduce a second,
/// competing source of theme-mode state.
class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeController({ThemeMode initialThemeMode = ThemeMode.dark})
      : _themeMode = initialThemeMode;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

class ThemeControllerProvider extends InheritedNotifier<ThemeController> {
  const ThemeControllerProvider({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ThemeControllerProvider>();
    assert(provider != null, 'ThemeControllerProvider was not found.');
    return provider!.notifier!;
  }
}

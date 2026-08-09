import 'package:flutter/material.dart';

import 'tour_models.dart';

/// Drives an active self-navigation spotlight tour: which step is current,
/// where each step's target currently sits on screen, and navigation
/// between steps (including pushing a route when a step's target lives on
/// a screen other than the one the tour started on).
///
/// Mirrors the app's existing hand-rolled `ChangeNotifier` + `Scope`
/// controllers (see `ThemeController`/`ThemeControllerProvider`).
class TourController extends ChangeNotifier {
  TourController({required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  final Map<String, GlobalKey> _targets = {};

  List<TourStep> _steps = const [];
  int _index = -1;
  String? _tourId;
  VoidCallback? _onFinished;
  String? _lastSyncedRoute;
  bool _replaceRoutes = false;

  bool get isActive => _index >= 0 && _index < _steps.length;
  TourStep? get currentStep => isActive ? _steps[_index] : null;
  int get currentIndex => _index;
  int get stepCount => _steps.length;
  bool get isLastStep => isActive && _index == _steps.length - 1;
  bool get isFirstStep => isActive && _index == 0;
  String? get activeTourId => _tourId;

  /// Registers (or replaces) the widget that renders [id] so the overlay
  /// can find its on-screen bounds via [rectFor].
  void registerTarget(String id, GlobalKey key) {
    _targets[id] = key;
    if (isActive && currentStep!.targetId == id) {
      notifyListeners();
    }
  }

  /// Removes a target registration, but only if [key] is still the one on
  /// file — guards against a newer widget's registration being clobbered
  /// by an older widget's disposal running after it (e.g. during a route
  /// transition where both the old and new screen briefly coexist).
  void unregisterTarget(String id, GlobalKey key) {
    if (_targets[id] == key) {
      _targets.remove(id);
    }
  }

  /// The current screen-space bounds of the widget registered under [id],
  /// or null if nothing is registered or it hasn't been laid out yet.
  Rect? rectFor(String id) {
    final key = _targets[id];
    final renderObject = key?.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return null;
    final size = renderObject.size;
    if (size.isEmpty) return null;
    final offset = renderObject.localToGlobal(Offset.zero);
    return offset & size;
  }

  void start(
    List<TourStep> steps, {
    required String tourId,
    VoidCallback? onFinished,
    bool replaceRoutes = false,
  }) {
    if (steps.isEmpty) return;
    _steps = steps;
    _tourId = tourId;
    _index = 0;
    _onFinished = onFinished;
    _lastSyncedRoute = null;
    _replaceRoutes = replaceRoutes;
    notifyListeners();
    _syncRoute();
  }

  void next() {
    if (!isActive) return;
    if (_index >= _steps.length - 1) {
      finish();
      return;
    }
    _index++;
    notifyListeners();
    _syncRoute();
  }

  void back() {
    if (!isActive || _index <= 0) return;
    _index--;
    notifyListeners();
    _syncRoute();
  }

  void skip() => finish();

  void finish() {
    if (_index < 0 && _steps.isEmpty) return;
    _steps = const [];
    _index = -1;
    _tourId = null;
    _lastSyncedRoute = null;
    _replaceRoutes = false;
    final callback = _onFinished;
    _onFinished = null;
    notifyListeners();
    callback?.call();
  }

  /// Pushes the current step's route if it isn't already the top route.
  /// Fire-and-forget: `Navigator.pushNamed`'s future only resolves when the
  /// pushed route is later popped, so it must not be awaited here. The
  /// [SpotlightOverlay] re-samples target rects every frame, so as soon as
  /// the new screen mounts and its `TourTarget` registers, the spotlight
  /// picks it up on its own — no explicit "wait for navigation" needed.
  void _syncRoute() {
    final step = currentStep;
    final routeName = step?.routeName;
    if (routeName == null) return;
    if (_lastSyncedRoute == routeName) return;
    final navContext = navigatorKey.currentContext;
    if (navContext == null) return;
    final currentRoute = ModalRoute.of(navContext)?.settings.name;
    if (currentRoute == routeName) {
      _lastSyncedRoute = routeName;
      return;
    }
    _lastSyncedRoute = routeName;
    if (_replaceRoutes) {
      Navigator.of(navContext).pushReplacementNamed(routeName);
    } else {
      Navigator.of(navContext).pushNamed(routeName);
    }
  }
}

class TourScope extends InheritedNotifier<TourController> {
  const TourScope({
    super.key,
    required TourController controller,
    required super.child,
  }) : super(notifier: controller);

  static TourController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<TourScope>();
    assert(provider != null, 'TourScope was not found in context.');
    return provider!.notifier!;
  }

  static TourController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TourScope>()?.notifier;
  }
}

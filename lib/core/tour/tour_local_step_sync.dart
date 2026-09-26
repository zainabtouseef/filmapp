import 'package:flutter/widgets.dart';

import 'tour_controller.dart';

/// Keeps a screen's own internal step/tab state in lockstep with the
/// active tour, so a [TourStep.localStep] can bring a multi-step screen
/// (a wizard, a tabbed detail view) to the exact page a tour topic
/// describes before its `TourTarget` is expected to be found.
///
/// Generalizes the same `didChangeDependencies` + `TourController`
/// listener pattern already used by
/// `lib/shared/layout/admin_screen_scaffold.dart`'s `_syncMenuWithTour`.
mixin TourLocalStepSync<T extends StatefulWidget> on State<T> {
  /// The route name this screen is shown under — a tour step only drives
  /// this screen's local state when its `routeName` matches.
  String get tourRouteName;

  /// Called with a non-null `TourStep.localStep` for the active step,
  /// whenever the tour is on this screen. Implementations should
  /// `setState` their own local index/tab to match.
  void applyTourLocalStep(Object localStep);

  TourController? _tourController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = TourScope.maybeOf(context);
    if (!identical(controller, _tourController)) {
      _tourController?.removeListener(_onTourChanged);
      _tourController = controller;
      _tourController?.addListener(_onTourChanged);
      _onTourChanged();
    }
  }

  @override
  void dispose() {
    _tourController?.removeListener(_onTourChanged);
    super.dispose();
  }

  void _onTourChanged() {
    final step = _tourController?.currentStep;
    if (step == null || step.routeName != tourRouteName) return;
    final localStep = step.localStep;
    if (localStep != null) applyTourLocalStep(localStep);
  }
}

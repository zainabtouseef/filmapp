import 'package:flutter/foundation.dart';

/// One step of a self-navigation spotlight tour.
///
/// [targetId] must match the `id` a [TourTarget] was registered under.
/// [routeName], if set, is pushed via the app's navigator before the step
/// is shown, for steps whose target lives on a different screen than the
/// one the tour was started from.
@immutable
class TourStep {
  final String id;
  final String targetId;
  final String badge;
  final String title;
  final String description;
  final String? routeName;

  /// Sub-state a multi-step/tabbed screen should show while this step is
  /// active — e.g. an `int` wizard-page index. Portal-agnostic on purpose:
  /// each screen defines its own meaning via [TourLocalStepSync]; this
  /// carrier stays a dumb data class so it never needs a feature import.
  final Object? localStep;

  const TourStep({
    required this.id,
    required this.targetId,
    required this.badge,
    required this.title,
    required this.description,
    this.routeName,
    this.localStep,
  });
}

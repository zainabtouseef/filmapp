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

  const TourStep({
    required this.id,
    required this.targetId,
    required this.badge,
    required this.title,
    required this.description,
    this.routeName,
  });
}

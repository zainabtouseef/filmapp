import 'package:flutter/animation.dart';

/// Canonical animation durations used across CineConnect screens.
///
/// Pick the token that matches what's animating rather than a bespoke
/// `Duration(milliseconds: ...)` per widget, so motion feels like one
/// system across portals.
class AppDurations {
  AppDurations._();

  /// Button/icon press feedback.
  static const press = Duration(milliseconds: 140);

  /// Hover state transitions (web/desktop).
  static const hover = Duration(milliseconds: 180);

  /// Card lift / selected-state transition.
  static const cardLift = Duration(milliseconds: 220);

  /// Page/route entrance.
  static const pageEntrance = Duration(milliseconds: 280);

  /// Bottom sheet / modal present.
  static const sheet = Duration(milliseconds: 300);

  /// Tab switch / segmented control indicator.
  static const tab = Duration(milliseconds: 220);

  /// Expand/collapse (accordion, filter panel).
  static const expand = Duration(milliseconds: 240);

  /// Status/badge transition (e.g. verification state change).
  static const status = Duration(milliseconds: 320);

  /// Skeleton shimmer loop — slow and subtle.
  static const shimmer = Duration(milliseconds: 1400);

  /// Holographic sweep on featured/selected cards — slow and limited.
  static const holographicSweep = Duration(milliseconds: 2600);

  static const Curve standardCurve = Curves.easeOutCubic;
}

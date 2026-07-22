import 'package:flutter/widgets.dart';

/// Canonical spacing scale used across CineConnect screens.
///
/// New dashboards should build layouts from these tokens instead of
/// picking arbitrary padding/gap numbers, so rhythm stays consistent.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;

  /// Standard phone-width page gutter (dashboard_screen uses 32 on tablet).
  static const double pageHorizontal = 18;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double display = 40;

  /// Gap between a section header and its content.
  static const double sectionGap = 14;

  static EdgeInsets cardPadding({bool compact = false}) => EdgeInsets.all(
        compact ? md : lg,
      );
}

import 'package:flutter/widgets.dart';

/// Canonical responsive breakpoints used across CineConnect screens.
///
/// Screens should branch layout off these constants (or the
/// [DeviceClass] helpers below) instead of picking arbitrary width
/// checks, so "mobile vs tablet vs desktop" means the same thing
/// everywhere in the app.
class AppBreakpoints {
  AppBreakpoints._();

  /// Below this: narrow phones (iPhone SE class). Tightest layout.
  static const double compactPhone = 360;

  /// Below this: phones in general. Single-column, bottom-nav shell.
  static const double phone = 600;

  /// Below this: tablets (portrait and small landscape). Two-column,
  /// collapsible side nav.
  static const double tablet = 900;

  /// Below this: laptop / narrow desktop. Full side nav, capped
  /// content width.
  static const double laptop = 1200;

  /// At or above this: wide desktop. Content stays capped via
  /// [maxContentWidth] rather than stretching further.
  static const double wideDesktop = 1440;

  /// Max width a content column should grow to on very wide screens.
  static const double maxContentWidth = 1180;
}

enum DeviceClass { mobile, tablet, desktop }

extension AppBreakpointsContext on BuildContext {
  double get _width => MediaQuery.sizeOf(this).width;

  bool get isMobileWidth => _width < AppBreakpoints.phone;
  bool get isTabletWidth =>
      _width >= AppBreakpoints.phone && _width < AppBreakpoints.laptop;
  bool get isDesktopWidth => _width >= AppBreakpoints.laptop;

  DeviceClass get deviceClass {
    if (isMobileWidth) return DeviceClass.mobile;
    if (isTabletWidth) return DeviceClass.tablet;
    return DeviceClass.desktop;
  }
}

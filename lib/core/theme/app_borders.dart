/// Canonical border widths used across CineConnect screens.
///
/// Border *colors* are theme-aware — use `context.appColors.border` /
/// `.borderMuted` / `.goldMid`. This only standardizes stroke widths.
class AppBorders {
  AppBorders._();

  /// Default hairline border (cards, chips, inputs).
  static const double hairline = 1.0;

  /// Slightly heavier stroke for emphasized/gold-outlined elements.
  static const double emphasized = 1.2;

  /// Selected/active state border (e.g. active chip, selected talent card).
  static const double active = 1.35;
}

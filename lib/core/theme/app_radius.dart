/// Canonical corner-radius scale used across CineConnect screens.
///
/// New dashboards should reach for these tokens instead of inventing a
/// new radius, so cards/chips/buttons all read as one design language.
class AppRadius {
  AppRadius._();

  /// Small controls and icon containers.
  static const double sm = 10;

  /// Buttons and input fields.
  static const double control = 12;

  /// Compact cards.
  static const double md = 14;

  /// Dashboard-kit cards and planning widgets from the portal reference.
  static const double panel = 26;

  /// Standard cards.
  static const double lg = 18;

  /// Feature cards.
  static const double xl = 28;

  /// Large section containers.
  static const double xxl = 26;

  /// Fully-rounded pills.
  static const double pill = 999;
}

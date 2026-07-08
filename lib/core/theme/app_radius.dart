/// Canonical corner-radius scale used across CineConnect screens.
///
/// New dashboards should reach for these tokens instead of inventing a
/// new radius, so cards/chips/buttons all read as one design language.
class AppRadius {
  AppRadius._();

  /// Small controls: thumbnails, filter chips.
  static const double sm = 10;

  /// Buttons, input fields.
  static const double md = 14;

  /// Trust-badge strip, glass containers.
  static const double lg = 18;

  /// Primary cards (search bar-scale glass panels).
  static const double xl = 22;

  /// Hero cards (Featured Talent).
  static const double xxl = 28;

  /// Fully-rounded pills (chips, tags, avatars).
  static const double pill = 30;
}

import 'package:flutter/foundation.dart';

import 'tour_models.dart';

/// A shell's nav destination, reduced to what a generic tour needs.
@immutable
class NavTourEntry {
  final String label;
  final String route;
  final String description;

  const NavTourEntry({
    required this.label,
    required this.route,
    this.description = 'Open this section from anywhere in the app.',
  });
}

/// Builds a generic "walk the nav" tour from a shell's own nav items, one
/// step per entry. Steps target `nav:<route>` — the id convention
/// `TourTarget`s in `bottom_nav_bar.dart`, `floating_portal_menu.dart`, and
/// each shell's sidebar register under — so this works for any portal
/// without bespoke content authoring.
List<TourStep> buildNavTourSteps(List<NavTourEntry> items) {
  return [
    for (var i = 0; i < items.length; i++)
      TourStep(
        id: 'nav.${items[i].route}',
        targetId: 'nav:${items[i].route}',
        badge: '${i + 1} / ${items.length}',
        title: items[i].label,
        description: items[i].description,
      ),
  ];
}

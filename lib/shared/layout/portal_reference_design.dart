/// Route policy for the Shortlist-inspired CineConnect screen system.
///
/// Dashboards and marketplace/browse surfaces deliberately keep their own
/// visual language. Every operational screen uses the shared editorial hero,
/// compact section surfaces, motion, and responsive rhythm.
class PortalReferenceDesign {
  PortalReferenceDesign._();

  static const _dashboardRoutes = <String>{
    '/',
    '/console',
    '/director',
    '/talent',
    '/influencer',
    '/model',
    '/location-owner',
    '/equipment-provider',
    '/crew',
    '/agency',
    '/brand',
    '/legal',
    '/insurance',
    '/distribution',
    '/public',
    '/admin/dashboard',
    '/portal/dashboard',
  };

  static bool usesOperationalUtilityHero(String? rawRoute) {
    if (rawRoute == null || rawRoute.trim().isEmpty) return false;
    final route = rawRoute.split('?').first.toLowerCase();
    return route == '/notifications' ||
        route == '/settings' ||
        route == '/review' ||
        route == '/report' ||
        route == '/profile/roles' ||
        route.startsWith('/booking/') ||
        route.startsWith('/contract') ||
        route.startsWith('/payments/') ||
        route.startsWith('/verification/');
  }

  static bool usesReference(String? rawRoute) {
    if (rawRoute == null || rawRoute.trim().isEmpty) return true;
    final route = rawRoute.split('?').first.toLowerCase();
    if (_dashboardRoutes.contains(route)) return false;
    if (route.contains('/marketplace') ||
        route == '/marketplace' ||
        route == '/discover' ||
        route.endsWith('/discover') ||
        route.endsWith('/browse') ||
        route.endsWith('/actors') ||
        route.endsWith('/models') ||
        route.endsWith('/influencers')) {
      return false;
    }
    return true;
  }
}

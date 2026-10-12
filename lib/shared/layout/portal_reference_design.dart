/// The nine body compositions used by the CineConnect operational workspace.
///
/// These values intentionally describe information architecture instead of a
/// portal. The same calendar, list, gallery, or split-view treatment is shared
/// by every role that needs it.
enum PortalBodyLayout {
  analytics,
  timeline,
  calendar,
  editorial,
  list,
  kanban,
  gallery,
  splitView,
  horizontalRail,
}

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

  /// Selects one of the nine reference layouts from the job a route performs.
  ///
  /// The match order matters: specific master-detail and media routes are
  /// resolved before broader words such as `project`, `record`, or `review`.
  /// Dashboard and marketplace routes can still be classified for diagnostics,
  /// but [usesReference] prevents this body system from styling them.
  static PortalBodyLayout layoutForRoute(String? rawRoute) {
    final route = (rawRoute ?? '').split('?').first.toLowerCase();
    final explicit = _layoutOverrides[route];
    if (explicit != null) return explicit;

    if (_containsAny(route, const [
      'cineplanner',
      '/detail',
      'projects/:id',
      'projects/create',
      '/project/',
      '/room',
      '/profile/',
      '/offers/',
      '/roles/',
      'applications/:id',
      '/opportunities/application',
      'bookings-monitor/:id',
      'contract-templates/:id',
      '/disputes/:id',
      '/verifications/:id',
      'contract-review',
      'template-review',
      'addendum-review',
      'payment-review',
      'verification/',
      'booking-request',
      'listing-wizard',
      'check-in',
      'check-out',
      'handover',
      '/return',
      'counteroffer',
      'bargaining/:id',
      'composer',
      'role-detail',
      'application-detail',
    ])) {
      return PortalBodyLayout.splitView;
    }

    if (_containsAny(route, const [
      'availability',
      '/calendar',
      '/schedule',
    ])) {
      return PortalBodyLayout.calendar;
    }

    if (_containsAny(route, const [
      '/analytics',
      '/accounts',
      '/account',
      '/reports',
      '/payments',
      '/earnings',
      'history-billing',
      '/commission',
      '/fees',
      '/revenue',
      '/ledger',
      '/performance',
    ])) {
      return PortalBodyLayout.analytics;
    }

    if (_containsAny(route, const [
      '/portfolio',
      'self-tape',
      'media-kit',
      '/cinema',
      'showreel',
    ])) {
      return PortalBodyLayout.gallery;
    }

    if (_containsAny(route, const [
      'campaign-tracker',
      'bookings-monitor',
      '/projects',
      '/workflow',
    ])) {
      return PortalBodyLayout.kanban;
    }

    if (route == '/admin/contract-templates') {
      return PortalBodyLayout.list;
    }

    if (_containsAny(route, const [
      '/contract',
      '/bargaining',
      '/negotiation',
      '/requests',
      '/bookings',
      '/release',
      '/claims',
      '/incidents',
      'safety-permits',
      '/disputes',
    ])) {
      return PortalBodyLayout.timeline;
    }

    if (_containsAny(route, const [
      '/shortlist',
      '/roster',
      '/records',
      '/inventory',
      '/applications',
      '/auditions',
      '/contacts',
      '/users',
      '/audit-logs',
      '/moderation',
      '/review-hub',
      '/verifications',
      '/support',
      '/broadcasts',
      '/payment-queue',
    ])) {
      return PortalBodyLayout.list;
    }

    if (_containsAny(route, const [
      '/opportunities',
      '/packages',
      '/ratings',
      '/reviews',
      '/campaigns',
    ])) {
      return PortalBodyLayout.horizontalRail;
    }

    return PortalBodyLayout.editorial;
  }

  static bool _containsAny(String value, List<String> fragments) {
    return fragments.any(value.contains);
  }

  /// Routes whose information job is clearer than their URL wording. Keeping
  /// these decisions explicit prevents all 13 portals from falling back to a
  /// generic card grid when a screen needs a timeline, ledger, gallery, or
  /// true master/detail workspace.
  static const _layoutOverrides = <String, PortalBodyLayout>{
    '/talent/rates': PortalBodyLayout.editorial,
    '/talent/reputation': PortalBodyLayout.horizontalRail,
    '/talent/safety': PortalBodyLayout.list,
    '/model/usage-rights': PortalBodyLayout.timeline,
    '/model/rate-by-usage': PortalBodyLayout.analytics,
    '/model/brand-safety': PortalBodyLayout.list,
    '/influencer/safety': PortalBodyLayout.list,
    '/location-owner/pricing': PortalBodyLayout.analytics,
    '/location-owner/rules': PortalBodyLayout.list,
    '/agency/selection-notes': PortalBodyLayout.splitView,
    '/equipment-provider/terms': PortalBodyLayout.timeline,
    '/legal/history-billing': PortalBodyLayout.analytics,
    '/public/account': PortalBodyLayout.analytics,
  };
}

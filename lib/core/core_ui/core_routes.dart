import 'package:flutter/material.dart';

import '../theme/app_breakpoints.dart';
import '../../screens/dashboard_screen.dart';
import '../../features/actor_talent/routes/actor_talent_routes.dart';
import '../../features/actor_talent/screens/actor_talent_portal_screen.dart';
import '../../features/brand_sponsors/routes/brand_sponsor_routes.dart';
import '../../features/brand_sponsors/screens/brand_sponsor_portal_screen.dart';
import '../../features/casting_agency/routes/casting_agency_routes.dart';
import '../../features/casting_agency/screens/casting_agency_portal_screen.dart';
import '../../features/crew_services/routes/crew_services_routes.dart';
import '../../features/crew_services/screens/crew_services_portal_screen.dart';
import '../../features/director_producer/routes/director_producer_routes.dart';
import '../../features/director_producer/screens/director_producer_portal_screen.dart';
import '../../features/distribution_partner/routes/distribution_partner_routes.dart';
import '../../features/distribution_partner/screens/distribution_partner_portal_screen.dart';
import '../../features/general_public/routes/general_public_routes.dart';
import '../../features/general_public/screens/general_public_portal_screen.dart';
import '../../features/influencer/routes/influencer_routes.dart';
import '../../features/influencer/screens/influencer_portal_screen.dart';
import '../../features/insurance_partner/routes/insurance_partner_routes.dart';
import '../../features/insurance_partner/screens/insurance_partner_portal_screen.dart';
import '../../features/legal_partner/routes/legal_partner_routes.dart';
import '../../features/legal_partner/screens/legal_partner_portal_screen.dart';
import '../../features/location_owner/routes/location_owner_routes.dart';
import '../../features/location_owner/screens/location_owner_portal_screen.dart';
import '../../features/media_equipment/routes/media_equipment_routes.dart';
import '../../features/media_equipment/screens/media_equipment_portal_screen.dart';
import '../../features/model_extension/routes/model_extension_routes.dart';
import '../../features/model_extension/screens/model_extension_portal_screen.dart';
import '../../features/role_portals/routes/role_portal_routes.dart';
import '../../features/role_portals/screens/role_portal_screen.dart';
import '../../features/super_admin/routes/super_admin_routes.dart';
import '../../features/super_admin/screens/super_admin_screens.dart';
import '../core_booking/screens/booking_chat_screen.dart';
import '../core_contract/screens/contract_viewer_screen.dart';
import '../core_payment/screens/payment_proof_screen.dart';
import '../core_payment/screens/receipts_ledger_screen.dart';
import '../core_safety/screens/ratings_review_screen.dart';
import '../core_safety/screens/report_block_screen.dart';
import '../core_settings/screens/settings_account_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/notification_center_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_role_switcher_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/utility_screens.dart';
import 'screens/verification_screens.dart';
import 'widgets/auth_split_scaffold.dart';

class CoreRoutes {
  CoreRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const roleSelection = '/roles';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const kyc = '/verification/upload';
  static const verificationStatus = '/verification/status';
  static const profileRoles = '/profile/roles';
  static const notifications = '/notifications';
  static const chat = '/booking/chat';
  static const contract = '/contract';
  static const paymentProof = '/payments/proof';
  static const ledger = '/payments/ledger';
  static const review = '/review';
  static const report = '/report';
  static const settings = '/settings';
  static const error = '/utility/error';
  static const empty = '/utility/empty';
  static const noInternet = '/utility/no-internet';
  static const forceUpdate = '/utility/force-update';
  static const maintenance = '/utility/maintenance';
  static const dashboard = '/portal/dashboard';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    final directorDeepLink = _directorProducerDeepLink(routeSettings.name);
    final generalPublicDeepLink = _generalPublicDeepLink(routeSettings.name);
    final influencerDeepLink = _influencerDeepLink(routeSettings.name);
    final actorDeepLink = _actorDeepLink(routeSettings.name);
    final superAdminDeepLink = _superAdminDeepLink(routeSettings.name);
    final contractDeepLinkId = _singleIdPath(routeSettings.name, 'contract');
    final paymentDeepLinkId = _singleIdPath(routeSettings.name, 'payment');
    Widget page;
    switch (routeSettings.name) {
      case splash:
        page = const SplashScreen();
      case onboarding:
        page = const OnboardingScreen();
      case roleSelection:
        page = const RoleSelectionScreen();
      case login:
        page = const LoginScreen();
      case signup:
        page = SignUpFlowScreen(
          selectedRole: routeSettings.arguments is String
              ? routeSettings.arguments! as String
              : 'Director / Producer',
        );
      case forgotPassword:
        page = const ForgotPasswordScreen();
      case kyc:
        page = KycVerificationScreen(
          selectedRole: routeSettings.arguments is String
              ? routeSettings.arguments! as String
              : 'Director / Producer',
        );
      case verificationStatus:
        page = const VerificationStatusScreen();
      case profileRoles:
        page = const ProfileRoleSwitcherScreen();
      case notifications:
        page = const NotificationCenterScreen();
      case chat:
        page = BookingChatScreen(
          conversationId: routeSettings.arguments is String
              ? routeSettings.arguments! as String
              : null,
        );
      case _ when contractDeepLinkId != null:
        page = ContractViewerScreen(contractId: contractDeepLinkId);
      case contract:
        page = ContractViewerScreen(
          contractId: routeSettings.arguments is String
              ? routeSettings.arguments! as String
              : routeSettings.arguments is Map
                  ? (routeSettings.arguments! as Map)['contract_id'] as String?
                  : null,
          showAddendumBanner: routeSettings.arguments is Map &&
              ((routeSettings.arguments! as Map)['addendum'] == true),
        );
      case _ when paymentDeepLinkId != null:
        page = PaymentProofUploadScreen(milestoneId: paymentDeepLinkId);
      case paymentProof:
        page = PaymentProofUploadScreen(
          milestoneId: routeSettings.arguments is String
              ? routeSettings.arguments! as String
              : routeSettings.arguments is Map
                  ? (routeSettings.arguments! as Map)['milestone_id'] as String?
                  : null,
        );
      case ledger:
        page = const ReceiptsLedgerScreen();
      case review:
        page = RatingsReviewScreen(
          bookingId: routeSettings.arguments is String
              ? routeSettings.arguments! as String
              : routeSettings.arguments is Map
                  ? (routeSettings.arguments! as Map)['booking_id'] as String?
                  : null,
        );
      case report:
        page = ReportBlockScreen(
          initialReason: routeSettings.arguments is String
              ? routeSettings.arguments! as String
              : routeSettings.arguments is Map
                  ? (routeSettings.arguments! as Map)['reason'] as String?
                  : null,
          entityType: routeSettings.arguments is Map
              ? (routeSettings.arguments! as Map)['entity_type'] as String? ??
                  'user'
              : 'user',
          entityId: routeSettings.arguments is Map
              ? (routeSettings.arguments! as Map)['entity_id'] as String?
              : null,
          reportedUserId: routeSettings.arguments is Map
              ? (routeSettings.arguments! as Map)['reported_user_id'] as String?
              : null,
        );
      case settings:
        page = const SettingsAccountScreen();
      case error:
        page = const CoreErrorScreen();
      case empty:
        page = const CoreEmptyTemplateScreen();
      case noInternet:
        page = const NoInternetScreen();
      case forceUpdate:
        page = const ForceUpdateScreen();
      case maintenance:
        page = const MaintenanceModeScreen();
      case dashboard:
        page = const DashboardScreen();
      case _ when directorDeepLink != null:
        page = DirectorProducerPortalScreen(
          routeName: directorDeepLink.routeName,
          arguments: {
            ...directorDeepLink.arguments,
            if (routeSettings.arguments is Map)
              ...(routeSettings.arguments! as Map),
            if (routeSettings.arguments is String)
              'id': routeSettings.arguments! as String,
          },
        );
      case _ when generalPublicDeepLink != null:
        page = GeneralPublicPortalScreen(
          routeName: generalPublicDeepLink.routeName,
          arguments: {
            ...generalPublicDeepLink.arguments,
            if (routeSettings.arguments is Map)
              ...(routeSettings.arguments! as Map),
            if (routeSettings.arguments is String)
              'id': routeSettings.arguments! as String,
          },
        );
      case _ when influencerDeepLink != null:
        page = InfluencerPortalScreen(
          routeName: influencerDeepLink.routeName,
          arguments: routeSettings.arguments,
        );
      case _ when actorDeepLink != null:
        page = ActorTalentPortalScreen(
          routeName: actorDeepLink.routeName,
          arguments: {
            ...actorDeepLink.arguments,
            if (routeSettings.arguments is Map)
              ...(routeSettings.arguments! as Map),
            if (routeSettings.arguments is String)
              'id': routeSettings.arguments! as String,
          },
        );
      case DirectorProducerRoutes.console:
      case DirectorProducerRoutes.projectsAlias:
      case DirectorProducerRoutes.home:
      case DirectorProducerRoutes.projects:
      case DirectorProducerRoutes.createProject:
      case DirectorProducerRoutes.projectDetail:
      case DirectorProducerRoutes.requirements:
      case DirectorProducerRoutes.marketplace:
      case DirectorProducerRoutes.discover:
      case DirectorProducerRoutes.filters:
      case DirectorProducerRoutes.profile:
      case DirectorProducerRoutes.shortlist:
      case DirectorProducerRoutes.bookingRequest:
      case DirectorProducerRoutes.bargaining:
      case DirectorProducerRoutes.negotiationThread:
      case DirectorProducerRoutes.contracts:
      case DirectorProducerRoutes.payments:
      case DirectorProducerRoutes.schedule:
      case DirectorProducerRoutes.accounts:
      case DirectorProducerRoutes.room:
      case DirectorProducerRoutes.reports:
        page = DirectorProducerPortalScreen(
          routeName: routeSettings.name ?? DirectorProducerRoutes.home,
          arguments: routeSettings.arguments,
        );
      case _ when GeneralPublicRoutes.allRoutes.contains(routeSettings.name):
        page = GeneralPublicPortalScreen(
          routeName: routeSettings.name ?? GeneralPublicRoutes.home,
          arguments: routeSettings.arguments,
        );
      case _ when InfluencerRoutes.allRoutes.contains(routeSettings.name):
        page = InfluencerPortalScreen(
          routeName: routeSettings.name ?? InfluencerRoutes.home,
          arguments: routeSettings.arguments,
        );
      case _ when ActorTalentRoutes.allRoutes.contains(routeSettings.name):
        page = ActorTalentPortalScreen(
          routeName: routeSettings.name ?? ActorTalentRoutes.dashboard,
          arguments: routeSettings.arguments,
        );
      case _ when ModelExtensionRoutes.allRoutes.contains(routeSettings.name):
        page = ModelExtensionPortalScreen(
          routeName: routeSettings.name ?? ModelExtensionRoutes.categories,
          arguments: routeSettings.arguments,
        );
      case _ when LocationOwnerRoutes.allRoutes.contains(routeSettings.name):
        page = LocationOwnerPortalScreen(
          routeName: routeSettings.name ?? LocationOwnerRoutes.home,
          arguments: routeSettings.arguments,
        );
      case _ when MediaEquipmentRoutes.allRoutes.contains(routeSettings.name):
        page = MediaEquipmentPortalScreen(
          routeName: routeSettings.name ?? MediaEquipmentRoutes.home,
          arguments: routeSettings.arguments,
        );
      case _ when CrewServicesRoutes.allRoutes.contains(routeSettings.name):
        page = CrewServicesPortalScreen(
          routeName: routeSettings.name ?? CrewServicesRoutes.home,
          arguments: routeSettings.arguments,
        );
      case _ when CastingAgencyRoutes.allRoutes.contains(routeSettings.name):
        page = CastingAgencyPortalScreen(
          routeName: routeSettings.name ?? CastingAgencyRoutes.home,
        );
      case _ when BrandSponsorRoutes.allRoutes.contains(routeSettings.name):
        page = BrandSponsorPortalScreen(
          routeName: routeSettings.name ?? BrandSponsorRoutes.home,
        );
      case _ when LegalPartnerRoutes.allRoutes.contains(routeSettings.name):
        page = LegalPartnerPortalScreen(
          routeName: routeSettings.name ?? LegalPartnerRoutes.home,
          arguments: routeSettings.arguments,
        );
      case _ when InsurancePartnerRoutes.allRoutes.contains(routeSettings.name):
        page = InsurancePartnerPortalScreen(
          routeName: routeSettings.name ?? InsurancePartnerRoutes.home,
        );
      case _
          when DistributionPartnerRoutes.allRoutes.contains(routeSettings.name):
        page = DistributionPartnerPortalScreen(
          routeName: routeSettings.name ?? DistributionPartnerRoutes.home,
        );
      case _ when RolePortalRoutes.allRoutes.contains(routeSettings.name):
        page = RolePortalScreen(
          routeName: routeSettings.name ?? RolePortalRoutes.talentHome,
        );
      case SuperAdminRoutes.loginDemo:
        page = const LoginScreen();
      case _ when superAdminDeepLink != null:
        page = SuperAdminPortalScreen(
          routeName: superAdminDeepLink.routeName,
          arguments: {
            ...superAdminDeepLink.arguments,
            if (routeSettings.arguments is Map)
              ...(routeSettings.arguments! as Map),
            if (routeSettings.arguments is String)
              'id': routeSettings.arguments! as String,
          },
        );
      case SuperAdminRoutes.dashboard:
      case SuperAdminRoutes.reviewHub:
      case SuperAdminRoutes.reviewHubPeople:
      case SuperAdminRoutes.reviewHubListings:
      case SuperAdminRoutes.reviewHubContent:
      case SuperAdminRoutes.verifications:
      case SuperAdminRoutes.verificationDetail:
      case SuperAdminRoutes.contentModeration:
      case SuperAdminRoutes.listingsModeration:
      case SuperAdminRoutes.bookingsMonitor:
      case SuperAdminRoutes.bookingDetail:
      case SuperAdminRoutes.payments:
      case SuperAdminRoutes.paymentQueue:
      case SuperAdminRoutes.paymentReview:
      case SuperAdminRoutes.paymentLedger:
      case SuperAdminRoutes.paymentRevenue:
      case SuperAdminRoutes.contractTemplates:
      case SuperAdminRoutes.contractTemplateDetail:
      case SuperAdminRoutes.fees:
      case SuperAdminRoutes.disputes:
      case SuperAdminRoutes.disputeCase:
      case SuperAdminRoutes.users:
      case SuperAdminRoutes.adminRoles:
      case SuperAdminRoutes.support:
      case SuperAdminRoutes.broadcasts:
      case SuperAdminRoutes.auditLogs:
      case SuperAdminRoutes.analytics:
        page = SuperAdminPortalScreen(
          routeName: routeSettings.name ?? SuperAdminRoutes.dashboard,
          arguments: routeSettings.arguments,
        );
      default:
        page = const CoreErrorScreen(
          title: 'Route not found',
          message: 'This CineConnect screen is not available yet.',
        );
    }

    if (_authShellRoutes.contains(routeSettings.name)) {
      final shellPage = AuthSplitScaffold(content: page);
      return PageRouteBuilder<void>(
        settings: routeSettings,
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => shellPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final wide =
              MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;
          final begin = wide ? const Offset(1, 0) : const Offset(0, 1);
          return SlideTransition(
            position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
        },
      );
    }

    return MaterialPageRoute(
      builder: (_) => page,
      settings: routeSettings,
    );
  }

  // Screens that share the persistent split brand panel — the first-run
  // account flow, not the wider portal surface.
  static const _authShellRoutes = {
    onboarding,
    roleSelection,
    login,
    signup,
    forgotPassword,
  };

  static _DirectorDeepLink? _directorProducerDeepLink(String? name) {
    final segments = _pathSegments(name);
    if (segments.isEmpty) return null;

    return switch (segments.first) {
      'console' => const _DirectorDeepLink(DirectorProducerRoutes.console),
      'projects' => const _DirectorDeepLink(DirectorProducerRoutes.projects),
      'discover' => _DirectorDeepLink(
          DirectorProducerRoutes.marketplace,
          arguments: {
            if (segments.length > 1) 'category': segments[1],
          },
        ),
      'project' when segments.length >= 2 => _DirectorDeepLink(
          DirectorProducerRoutes.projectDetail,
          arguments: {
            'projectId': segments[1],
            'id': segments[1],
            if (segments.length > 2) 'tab': segments[2],
          },
        ),
      'profile' when segments.length >= 3 && _isRealId(segments[2]) =>
        _DirectorDeepLink(
          DirectorProducerRoutes.profile,
          arguments: {
            'type': segments[1],
            'category': segments[1],
            'candidateId': segments[2],
            'id': segments[2],
          },
        ),
      'booking' when segments.length >= 2 && _isRealId(segments[1]) =>
        _DirectorDeepLink(
          DirectorProducerRoutes.bookingRequest,
          arguments: {
            'candidateId': segments[1],
            'id': segments[1],
            if (segments.length > 2) 'projectId': segments[2],
          },
        ),
      _ => null,
    };
  }

  static _GeneralPublicDeepLink? _generalPublicDeepLink(String? name) {
    final segments = _pathSegments(name);
    if (segments.isEmpty || segments.first != 'public') return null;

    if (segments.length == 1) {
      return const _GeneralPublicDeepLink(GeneralPublicRoutes.home);
    }
    return switch (segments[1]) {
      'browse' => _GeneralPublicDeepLink(
          GeneralPublicRoutes.browse,
          arguments: {
            if (segments.length > 2) 'category': segments[2],
          },
        ),
      'actors' => const _GeneralPublicDeepLink(GeneralPublicRoutes.actors),
      'models' => const _GeneralPublicDeepLink(GeneralPublicRoutes.models),
      'influencers' =>
        const _GeneralPublicDeepLink(GeneralPublicRoutes.influencers),
      'requests' => const _GeneralPublicDeepLink(GeneralPublicRoutes.requests),
      'contracts' =>
        const _GeneralPublicDeepLink(GeneralPublicRoutes.contracts),
      'payments' => const _GeneralPublicDeepLink(GeneralPublicRoutes.payments),
      'account' => const _GeneralPublicDeepLink(GeneralPublicRoutes.account),
      'profile'
          when segments.length >= 3 &&
              _isRealId(
                segments.length > 3 ? segments[3] : segments[2],
              ) =>
        _GeneralPublicDeepLink(
          GeneralPublicRoutes.profile,
          arguments: {
            if (segments.length > 3) 'type': segments[2],
            if (segments.length > 3) 'category': segments[2],
            'candidateId': segments.length > 3 ? segments[3] : segments[2],
            'id': segments.length > 3 ? segments[3] : segments[2],
          },
        ),
      'booking' when segments.length >= 3 && _isRealId(segments[2]) =>
        _GeneralPublicDeepLink(
          GeneralPublicRoutes.bookingRequest,
          arguments: {
            'candidateId': segments[2],
            'id': segments[2],
            if (segments.length > 3) 'category': segments[3],
          },
        ),
      _ => null,
    };
  }

  static _InfluencerDeepLink? _influencerDeepLink(String? name) {
    final segments = _pathSegments(name);
    if (segments.isEmpty || segments.first != 'influencer') return null;

    if (segments.length == 1) {
      return const _InfluencerDeepLink(InfluencerRoutes.home);
    }
    return switch (segments[1]) {
      'media-kit' => const _InfluencerDeepLink(InfluencerRoutes.mediaKit),
      'packages' => const _InfluencerDeepLink(InfluencerRoutes.packages),
      'campaigns' => const _InfluencerDeepLink(InfluencerRoutes.campaigns),
      'analytics' => const _InfluencerDeepLink(InfluencerRoutes.analytics),
      'portfolio' => const _InfluencerDeepLink(InfluencerRoutes.portfolio),
      'calendar' => const _InfluencerDeepLink(InfluencerRoutes.calendar),
      'contracts' => const _InfluencerDeepLink(InfluencerRoutes.contracts),
      'earnings' => const _InfluencerDeepLink(InfluencerRoutes.earnings),
      'reviews' => const _InfluencerDeepLink(InfluencerRoutes.reviews),
      'safety' => const _InfluencerDeepLink(InfluencerRoutes.safety),
      _ => null,
    };
  }

  static String? _singleIdPath(String? name, String root) {
    final segments = _pathSegments(name);
    if (segments.length != 2 || segments.first != root) return null;
    return segments[1];
  }

  static _ActorDeepLink? _actorDeepLink(String? name) {
    final segments = _pathSegments(name);
    if (segments.length != 3 || segments.first != 'talent') return null;
    final id = segments[2];
    if (id.isEmpty || id == ':id') return null;
    return switch (segments[1]) {
      'roles' => _ActorDeepLink(
          ActorTalentRoutes.roleDetail,
          arguments: {'id': id, 'roleId': id},
        ),
      'applications' => _ActorDeepLink(
          ActorTalentRoutes.applicationDetail,
          arguments: {'id': id, 'applicationId': id},
        ),
      'offers' => _ActorDeepLink(
          ActorTalentRoutes.offerDetail,
          arguments: {'id': id},
        ),
      _ => null,
    };
  }

  static _SuperAdminDeepLink? _superAdminDeepLink(String? name) {
    final segments = _pathSegments(name);
    if (segments.length != 3 || segments.first != 'admin') return null;
    final id = segments[2];
    if (id.isEmpty || id == ':id') return null;

    return switch (segments[1]) {
      'bookings-monitor' => _SuperAdminDeepLink(
          SuperAdminRoutes.bookingDetail,
          arguments: {'id': id, 'booking_id': id},
        ),
      'verifications' => _SuperAdminDeepLink(
          SuperAdminRoutes.verificationDetail,
          arguments: {'id': id, 'submission_id': id},
        ),
      'payment-review' => _SuperAdminDeepLink(
          SuperAdminRoutes.paymentReview,
          arguments: {'id': id, 'proof_id': id},
        ),
      'contract-templates' => _SuperAdminDeepLink(
          SuperAdminRoutes.contractTemplateDetail,
          arguments: {'id': id, 'template_id': id},
        ),
      'disputes' => _SuperAdminDeepLink(
          SuperAdminRoutes.disputeCase,
          arguments: {'id': id, 'dispute_id': id},
        ),
      _ => null,
    };
  }

  static List<String> _pathSegments(String? name) {
    if (name == null || !name.startsWith('/')) return const [];
    return Uri.tryParse(name)?.pathSegments ?? const [];
  }

  /// Guards deep-link id segments against the literal `:id` placeholder —
  /// reachable when a browser reloads a URL that mirrors an in-app route
  /// constant like `/talent/applications/:id` (the constant is used as a
  /// fixed route name for `Navigator.pushNamed`, with the real id carried
  /// via `arguments`, which don't survive a reload).
  static bool _isRealId(String value) => value.isNotEmpty && value != ':id';
}

class _DirectorDeepLink {
  final String routeName;
  final Map<String, Object?> arguments;

  const _DirectorDeepLink(this.routeName, {this.arguments = const {}});
}

class _GeneralPublicDeepLink {
  final String routeName;
  final Map<String, Object?> arguments;

  const _GeneralPublicDeepLink(this.routeName, {this.arguments = const {}});
}

class _InfluencerDeepLink {
  final String routeName;

  const _InfluencerDeepLink(this.routeName);
}

class _ActorDeepLink {
  final String routeName;
  final Map<String, Object?> arguments;

  const _ActorDeepLink(this.routeName, {this.arguments = const {}});
}

class _SuperAdminDeepLink {
  final String routeName;
  final Map<String, Object?> arguments;

  const _SuperAdminDeepLink(this.routeName, {this.arguments = const {}});
}

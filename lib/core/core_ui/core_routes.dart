import 'package:flutter/material.dart';

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
        page = const BookingChatScreen();
      case contract:
        page = ContractViewerScreen(
          showAddendumBanner: routeSettings.arguments is Map &&
              ((routeSettings.arguments! as Map)['addendum'] == true),
        );
      case paymentProof:
        page = const PaymentProofUploadScreen();
      case ledger:
        page = const ReceiptsLedgerScreen();
      case review:
        page = const RatingsReviewScreen();
      case report:
        page = ReportBlockScreen(
          initialReason: routeSettings.arguments is String
              ? routeSettings.arguments! as String
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
      case DirectorProducerRoutes.home:
      case DirectorProducerRoutes.projects:
      case DirectorProducerRoutes.createProject:
      case DirectorProducerRoutes.projectDetail:
      case DirectorProducerRoutes.requirements:
      case DirectorProducerRoutes.marketplace:
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
        );
      default:
        page = const CoreErrorScreen(
          title: 'Route not found',
          message: 'This CineConnect screen is not available yet.',
        );
    }

    return MaterialPageRoute(
      builder: (_) => page,
      settings: routeSettings,
    );
  }
}

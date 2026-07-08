import 'package:flutter/material.dart';

import '../../screens/dashboard_screen.dart';
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
      case SuperAdminRoutes.paymentQueue:
      case SuperAdminRoutes.paymentReview:
      case SuperAdminRoutes.contractTemplates:
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

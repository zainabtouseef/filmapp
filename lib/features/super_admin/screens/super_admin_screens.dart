import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/analytics/analytics_controller.dart';
import '../../../core/analytics/analytics_models.dart';
import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/core_booking/screens/booking_chat_screen.dart';
import '../../../core/core_payment/screens/receipts_ledger_screen.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/models/shared_models.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/payments/payment_models.dart';
import '../../../core/payments/payments_controller.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/trust_safety/trust_safety_controller.dart';
import '../../../core/trust_safety/trust_safety_models.dart';
import '../../../core/verification/verification_models.dart' as verification;
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/cards/mini_trend_card.dart';
import '../../../shared/sections/admin_action_feed_section.dart'
    as shared_action;
import '../../../shared/sections/admin_live_monitoring_section.dart';
import '../../../shared/sections/admin_quick_actions_section.dart';
import '../../../shared/sections/admin_queue_snapshot_section.dart'
    as shared_queue;
import '../../../shared/sections/admin_recent_activity_section.dart';
import '../mock_data/admin_mock_data.dart';
import '../models/admin_models.dart';
import '../routes/super_admin_routes.dart';
import '../widgets/admin_widgets.dart';

part 'admin_portal/admin_dashboard_screen.dart';
part 'admin_portal/review_hub_screen.dart';
part 'admin_portal/people_verification_queue_screen.dart';
part 'admin_portal/listings_review_queue_screen.dart';
part 'admin_portal/content_moderation_queue_screen.dart';
part 'admin_portal/user_verification_queue_screen.dart';
part 'admin_portal/kyc_review_detail_screen.dart';
part 'admin_portal/content_moderation_screen.dart';
part 'admin_portal/listings_moderation_screen.dart';
part 'admin_portal/booking_monitor_screen.dart';
part 'admin_portal/booking_detail_screen.dart';
part 'admin_portal/payments_hub_screen.dart';
part 'admin_portal/payment_verification_queue_screen.dart';
part 'admin_portal/payment_review_detail_screen.dart';
part 'admin_portal/contract_template_manager_screen.dart';
part 'admin_portal/contract_template_detail_screen.dart';
part 'admin_portal/commission_fee_screen.dart';
part 'admin_portal/receipts_ledger_admin_screen.dart';
part 'admin_portal/revenue_settings_screen.dart';
part 'admin_portal/dispute_center_screen.dart';
part 'admin_portal/dispute_case_file_screen.dart';
part 'admin_portal/user_management_screen.dart';
part 'admin_portal/admin_roles_permissions_screen.dart';
part 'admin_portal/support_crm_screen.dart';
part 'admin_portal/broadcast_announcements_screen.dart';
part 'admin_portal/audit_log_explorer_screen.dart';
part 'admin_portal/admin_analytics_screen.dart';
part 'admin_portal/admin_screen_helpers.dart';

class SuperAdminPortalScreen extends StatelessWidget {
  final String routeName;
  final Object? arguments;

  const SuperAdminPortalScreen({
    super.key,
    required this.routeName,
    this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _meta(routeName);
    return AdminShell(
      currentRoute: routeName,
      title: meta.$1,
      subtitle: meta.$2,
      child: _content(routeName),
    );
  }

  (String, String) _meta(String route) {
    return switch (route) {
      SuperAdminRoutes.reviewHub => (
          'Reviews',
          'Review people, listings and reported content before they go live.',
        ),
      SuperAdminRoutes.reviewHubPeople => (
          'People Queue',
          'Full queue for people, documents and role verification decisions.',
        ),
      SuperAdminRoutes.reviewHubListings => (
          'Listing Reviews',
          'Full queue for marketplace listings before they go live.',
        ),
      SuperAdminRoutes.reviewHubContent => (
          'Content Queue',
          'Full queue for reported content, media checks and profile safety.',
        ),
      SuperAdminRoutes.verifications => (
          'Verifications',
          'Review identity, role documents and bank details before unlocking marketplace access.',
        ),
      SuperAdminRoutes.verificationDetail => (
          'Verification Detail',
          'Inspect documents, risk signals and decision checklist.',
        ),
      SuperAdminRoutes.contentModeration => (
          'Moderation',
          'Review portfolio, location media, reported content and watermark issues.',
        ),
      SuperAdminRoutes.listingsModeration => (
          'Listings',
          'Approve locations, equipment, packages and service listings.',
        ),
      SuperAdminRoutes.bookingsMonitor => (
          'Negotiations',
          'Track booking status, negotiation progress, contracts, payments and operational risk.',
        ),
      SuperAdminRoutes.bookingDetail => (
          'Case Detail',
          'Negotiation, contract, payment status and admin actions for this booking.',
        ),
      SuperAdminRoutes.payments => (
          'Payments',
          'Verify proofs, manage ledgers, control commissions and monitor payment risk.',
        ),
      SuperAdminRoutes.paymentQueue => (
          'Payment Queue',
          'Verify uploaded proofs against contracts, milestones and agreed schedules.',
        ),
      SuperAdminRoutes.paymentReview => (
          'Payment Review',
          'Compare uploaded proof with contract schedule and bank records.',
        ),
      SuperAdminRoutes.paymentLedger => (
          'Ledger',
          'Verified, released, refunded and disputed payment records.',
        ),
      SuperAdminRoutes.paymentRevenue => (
          'Revenue',
          'Monthly revenue, fee rules and settlement release controls.',
        ),
      SuperAdminRoutes.contractTemplates => (
          'Contracts',
          'Control templates, clauses, required fields and version publishing.',
        ),
      SuperAdminRoutes.contractTemplateDetail => (
          'Contract Detail',
          'Clause list, mandatory rule checks and publish controls.',
        ),
      SuperAdminRoutes.fees => (
          'Fees',
          'Manage platform commissions, subscription plans and featured-listing pricing.',
        ),
      SuperAdminRoutes.disputes => (
          'Disputes',
          'Manage payment, completion, cancellation, damage and safety cases.',
        ),
      SuperAdminRoutes.disputeCase => (
          'Dispute Detail',
          'Evidence room, timeline and final decision workspace.',
        ),
      SuperAdminRoutes.users => (
          'Users',
          'Search, inspect and control user access, roles, trust and risk.',
        ),
      SuperAdminRoutes.adminRoles => (
          'Admin Management',
          'Manage staff roles, protected permissions, sessions and 2FA.',
        ),
      SuperAdminRoutes.support => (
          'Support',
          'Handle reports, help requests, moderation follow-ups and disputes.',
        ),
      SuperAdminRoutes.broadcasts => (
          'Notifications',
          'Compose segmented in-app, push, email, SMS and WhatsApp announcements.',
        ),
      SuperAdminRoutes.auditLogs => (
          'Activity Log',
          'Read-only forensic event log for trust, money, safety and admin actions.',
        ),
      SuperAdminRoutes.analytics => (
          'Analytics',
          'Investor-ready marketplace, trust, revenue and retention intelligence.',
        ),
      _ => (
          'Admin Dashboard',
          'Unified control. Real-time insights. Smarter decisions.',
        ),
    };
  }

  Widget _content(String route) {
    return switch (route) {
      SuperAdminRoutes.reviewHub => const ReviewHubScreen(),
      SuperAdminRoutes.reviewHubPeople => const PeopleVerificationQueueScreen(),
      SuperAdminRoutes.reviewHubListings => const ListingsReviewQueueScreen(),
      SuperAdminRoutes.reviewHubContent => const ContentModerationQueueScreen(),
      SuperAdminRoutes.verifications => const UserVerificationQueueScreen(),
      SuperAdminRoutes.verificationDetail => KycReviewDetailScreen(
          submissionId: arguments is String ? arguments! as String : null,
        ),
      SuperAdminRoutes.contentModeration => const ContentModerationScreen(),
      SuperAdminRoutes.listingsModeration => const ListingsModerationScreen(),
      SuperAdminRoutes.bookingsMonitor => const BookingMonitorScreen(),
      SuperAdminRoutes.bookingDetail => const BookingDetailScreen(),
      SuperAdminRoutes.payments => const PaymentsHubScreen(),
      SuperAdminRoutes.paymentQueue => const PaymentVerificationQueueScreen(),
      SuperAdminRoutes.paymentReview => PaymentReviewDetailScreen(
          proofId: arguments is String ? arguments! as String : null,
        ),
      SuperAdminRoutes.paymentLedger => const ReceiptsLedgerAdminScreen(),
      SuperAdminRoutes.paymentRevenue => const RevenueSettingsScreen(),
      SuperAdminRoutes.contractTemplates =>
        const ContractTemplateManagerScreen(),
      SuperAdminRoutes.contractTemplateDetail =>
        const ContractTemplateDetailScreen(),
      SuperAdminRoutes.fees => const CommissionFeeScreen(),
      SuperAdminRoutes.disputes => const DisputeCenterScreen(),
      SuperAdminRoutes.disputeCase => const DisputeCaseFileScreen(),
      SuperAdminRoutes.users => const UserManagementScreen(),
      SuperAdminRoutes.adminRoles => const AdminRolesPermissionsScreen(),
      SuperAdminRoutes.support => const SupportCrmScreen(),
      SuperAdminRoutes.broadcasts => const BroadcastAnnouncementsScreen(),
      SuperAdminRoutes.auditLogs => const AuditLogExplorerScreen(),
      SuperAdminRoutes.analytics => const AdminAnalyticsScreen(),
      _ => const AdminDashboardScreen(),
    };
  }
}

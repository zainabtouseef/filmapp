import 'package:flutter/material.dart';

import '../../../core/core_contract/screens/contract_viewer_screen.dart';
import '../../../core/core_payment/screens/payment_proof_screen.dart';
import '../../../core/core_payment/screens/receipts_ledger_screen.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_shell.dart';
import 'dp_bargaining_center_screen.dart';
import 'dp_booking_request_form_screen.dart';
import 'dp_calendar_schedule_screen.dart';
import 'dp_contract_center_screen.dart';
import 'dp_create_project_wizard_screen.dart';
import 'dp_home_dashboard_screen.dart';
import 'dp_marketplace_discovery_screen.dart';
import 'dp_negotiation_thread_screen.dart';
import 'dp_payment_center_screen.dart';
import 'dp_project_accounts_screen.dart';
import 'dp_project_detail_screen.dart';
import 'dp_project_room_screen.dart';
import 'dp_projects_list_screen.dart';
import 'dp_reports_export_screen.dart';
import 'dp_requirement_builder_screen.dart';
import 'dp_shortlist_board_screen.dart';
import 'dp_smart_filters_sheet.dart';
import 'dp_stakeholder_profile_screen.dart';

class DirectorProducerPortalScreen extends StatelessWidget {
  final String routeName;
  final Object? arguments;

  const DirectorProducerPortalScreen({
    super.key,
    required this.routeName,
    this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    return DPShell(
      title: _title(routeName),
      currentRoute: routeName,
      child: _content(routeName),
    );
  }

  String _title(String route) {
    return switch (route) {
      DirectorProducerRoutes.home => 'Dashboard',
      DirectorProducerRoutes.projects => 'Projects',
      DirectorProducerRoutes.createProject => 'Create Project',
      DirectorProducerRoutes.projectDetail => 'Project Hub',
      DirectorProducerRoutes.requirements => 'Requirements',
      DirectorProducerRoutes.marketplace => 'Marketplace',
      DirectorProducerRoutes.filters => 'Smart Filters',
      DirectorProducerRoutes.profile => 'Stakeholder Profile',
      DirectorProducerRoutes.shortlist => 'Shortlist',
      DirectorProducerRoutes.bookingRequest => 'Booking Request',
      DirectorProducerRoutes.bargaining => 'Bargaining',
      DirectorProducerRoutes.negotiationThread => 'Negotiation Detail',
      DirectorProducerRoutes.contracts => 'Contracts',
      DirectorProducerRoutes.payments => 'Payments',
      DirectorProducerRoutes.schedule => 'Calendar',
      DirectorProducerRoutes.accounts => 'Accounts',
      DirectorProducerRoutes.room => 'Project Room',
      DirectorProducerRoutes.reports => 'Reports',
      _ => 'Director / Producer Portal',
    };
  }

  Widget _content(String route) {
    final id = arguments is String ? arguments as String : null;
    return switch (route) {
      DirectorProducerRoutes.projects => const DPProjectsListScreen(),
      DirectorProducerRoutes.createProject =>
        const DPCreateProjectWizardScreen(),
      DirectorProducerRoutes.projectDetail =>
        DPProjectDetailScreen(projectId: id),
      DirectorProducerRoutes.requirements => const DPRequirementBuilderScreen(),
      DirectorProducerRoutes.marketplace =>
        const DPMarketplaceDiscoveryScreen(),
      DirectorProducerRoutes.filters => const DPSmartFiltersSheet(),
      DirectorProducerRoutes.profile =>
        DPStakeholderProfileScreen(candidateId: id),
      DirectorProducerRoutes.shortlist => const DPShortlistBoardScreen(),
      DirectorProducerRoutes.bookingRequest =>
        const DPBookingRequestFormScreen(),
      DirectorProducerRoutes.bargaining => const DPBargainingCenterScreen(),
      DirectorProducerRoutes.negotiationThread =>
        DPNegotiationThreadScreen(negotiationId: id),
      DirectorProducerRoutes.contracts => const DPContractCenterScreen(),
      DirectorProducerRoutes.payments => const DPPaymentCenterScreen(),
      DirectorProducerRoutes.schedule => const DPCalendarScheduleScreen(),
      DirectorProducerRoutes.accounts => const DPProjectAccountsScreen(),
      DirectorProducerRoutes.room => const DPProjectRoomScreen(),
      DirectorProducerRoutes.reports => const DPReportsExportScreen(),
      _ => const DPHomeDashboardScreen(),
    };
  }
}

Widget dpContractPlaceholder() {
  return const ContractViewerScreen();
}

Widget dpPaymentProofPlaceholder() {
  return const PaymentProofUploadScreen();
}

Widget dpReceiptPlaceholder() {
  return const ReceiptsLedgerScreen();
}

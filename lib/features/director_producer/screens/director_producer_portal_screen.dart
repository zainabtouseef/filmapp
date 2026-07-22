import 'package:flutter/material.dart';

import '../../../core/core_contract/screens/contract_viewer_screen.dart';
import '../../../core/core_payment/screens/payment_proof_screen.dart';
import '../../../core/core_payment/screens/receipts_ledger_screen.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/projects/projects_controller.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dashboard/dp_assistant_orb.dart';
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

  bool get _isDashboard =>
      routeName == DirectorProducerRoutes.console ||
      routeName == DirectorProducerRoutes.home;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.maybeOf(context);
    final content = DPShell(
      title: _title(routeName),
      currentRoute: routeName,
      showHeading: !_isDashboard,
      floatingActionBuilder: _isDashboard
          ? (context, wide, bottomInset) =>
              DPAssistantOrb(bottomInset: bottomInset)
          : null,
      child: _content(routeName),
    );
    if (auth == null) return content;
    return ProjectsScope(
      controller: ProjectsController.fromClient(auth.apiClient),
      child: content,
    );
  }

  String _title(String route) {
    return switch (route) {
      DirectorProducerRoutes.console => 'Dashboard',
      DirectorProducerRoutes.home => 'Dashboard',
      DirectorProducerRoutes.projectsAlias => 'Projects',
      DirectorProducerRoutes.projects => 'Projects',
      DirectorProducerRoutes.createProject => 'Create Project',
      DirectorProducerRoutes.projectDetail => 'Project Hub',
      DirectorProducerRoutes.requirements => 'Requirements',
      DirectorProducerRoutes.discover => 'Marketplace',
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
    final id = _stringArg('id') ??
        _stringArg('projectId') ??
        _stringArg('candidateId') ??
        (arguments is String ? arguments as String : null);
    final projectId = _stringArg('projectId') ??
        (route == DirectorProducerRoutes.projectDetail ? id : null);
    final candidateId = _stringArg('candidateId') ??
        (route == DirectorProducerRoutes.profile ? id : null);
    final category = _stringArg('category') ?? _stringArg('type');
    final tab = _stringArg('tab');
    return switch (route) {
      DirectorProducerRoutes.console => const DPHomeDashboardScreen(),
      DirectorProducerRoutes.projectsAlias => const DPProjectsListScreen(),
      DirectorProducerRoutes.projects => const DPProjectsListScreen(),
      DirectorProducerRoutes.createProject =>
        const DPCreateProjectWizardScreen(),
      DirectorProducerRoutes.projectDetail =>
        DPProjectDetailScreen(projectId: projectId, initialTab: tab),
      DirectorProducerRoutes.requirements =>
        DPRequirementBuilderScreen(projectId: id),
      DirectorProducerRoutes.discover => DPMarketplaceDiscoveryScreen(
          initialCategory: category,
          projectId: projectId,
        ),
      DirectorProducerRoutes.marketplace => DPMarketplaceDiscoveryScreen(
          initialCategory: category,
          projectId: projectId,
        ),
      DirectorProducerRoutes.filters => const DPSmartFiltersSheet(),
      DirectorProducerRoutes.profile => DPStakeholderProfileScreen(
          candidateId: candidateId,
          profileType: category,
          projectId: projectId,
        ),
      DirectorProducerRoutes.shortlist => const DPShortlistBoardScreen(),
      DirectorProducerRoutes.bookingRequest => DPBookingRequestFormScreen(
          candidateId: candidateId,
          projectId: projectId,
          category: category,
        ),
      DirectorProducerRoutes.bargaining => const DPBargainingCenterScreen(),
      DirectorProducerRoutes.negotiationThread =>
        DPNegotiationThreadScreen(negotiationId: id),
      DirectorProducerRoutes.contracts => const DPContractCenterScreen(),
      DirectorProducerRoutes.payments => const DPPaymentCenterScreen(),
      DirectorProducerRoutes.schedule => const DPCalendarScheduleScreen(),
      DirectorProducerRoutes.accounts => const DPProjectAccountsScreen(),
      DirectorProducerRoutes.room => DPProjectRoomScreen(projectId: id),
      DirectorProducerRoutes.reports => const DPReportsExportScreen(),
      _ => const DPHomeDashboardScreen(),
    };
  }

  String? _stringArg(String key) {
    final args = arguments;
    if (args is Map && args[key] is String) return args[key] as String;
    return null;
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

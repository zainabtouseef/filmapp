import 'package:flutter/material.dart';

import '../routes/legal_partner_routes.dart';
import '../widgets/legal_partner_shell.dart';
import 'lg01_legal_dashboard_screen.dart';
import 'lg02_contract_review_detail_screen.dart';
import 'lg03_template_review_screen.dart';
import 'lg04_addendum_review_screen.dart';
import 'lg05_review_history_billing_screen.dart';

class LegalPartnerPortalScreen extends StatelessWidget {
  final String routeName;

  const LegalPartnerPortalScreen({
    super.key,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return LegalPartnerShell(
      routeName: routeName,
      title: LegalPartnerRoutes.titleFor(routeName),
      screenId: LegalPartnerRoutes.screenIdFor(routeName),
      child: _screenFor(routeName),
    );
  }

  Widget _screenFor(String route) {
    return switch (route) {
      LegalPartnerRoutes.contractReview =>
        const LG02ContractReviewDetailScreen(),
      LegalPartnerRoutes.templateReview => const LG03TemplateReviewScreen(),
      LegalPartnerRoutes.addendumReview => const LG04AddendumReviewScreen(),
      LegalPartnerRoutes.billing => const LG05ReviewHistoryBillingScreen(),
      _ => const LG01LegalDashboardScreen(),
    };
  }
}

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
  final Object? arguments;

  const LegalPartnerPortalScreen({
    super.key,
    required this.routeName,
    this.arguments,
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
    final id = arguments is String ? arguments as String : null;
    return switch (route) {
      LegalPartnerRoutes.contractReview =>
        LG02ContractReviewDetailScreen(reviewId: id),
      LegalPartnerRoutes.templateReview => const LG03TemplateReviewScreen(),
      LegalPartnerRoutes.addendumReview => const LG04AddendumReviewScreen(),
      LegalPartnerRoutes.billing => const LG05ReviewHistoryBillingScreen(),
      _ => const LG01LegalDashboardScreen(),
    };
  }
}

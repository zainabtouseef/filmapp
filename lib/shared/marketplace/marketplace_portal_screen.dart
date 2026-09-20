import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/core_ui/core_back_navigation.dart';
import '../../core/core_ui/core_logout.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../features/director_producer/screens/dp_marketplace_discovery_screen.dart';
import '../../features/director_producer/screens/dp_stakeholder_profile_screen.dart';
import '../../features/director_producer/routes/director_producer_routes.dart';
import '../../features/director_producer/screens/director_producer_portal_screen.dart';
import '../../features/general_public/routes/general_public_routes.dart';
import '../../features/general_public/screens/general_public_portal_screen.dart';
import '../layout/admin_screen_scaffold.dart';
import '../layout/admin_top_bar.dart';
import 'marketplace_routes.dart';

/// The same director marketplace presentation, backed by approved public
/// listings, is available from every role's portal menu.
class MarketplacePortalScreen extends StatelessWidget {
  final String routeName;
  final Object? arguments;

  const MarketplacePortalScreen({
    super.key,
    required this.routeName,
    this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    final profile = routeName == MarketplaceRoutes.profile;
    if (!profile) {
      final role = AuthScope.maybeOf(context)?.user?.primaryRole?.code;
      if (role == 'director_producer' ||
          role == 'casting_agency' ||
          role == 'brand_sponsor') {
        return const DirectorProducerPortalScreen(
          routeName: DirectorProducerRoutes.marketplace,
        );
      }
      if (role == 'general_public') {
        return const GeneralPublicPortalScreen(
          routeName: GeneralPublicRoutes.browse,
        );
      }
    }
    final args = arguments;
    final id = args is String
        ? args
        : args is Map
            ? (args['candidateId'] ?? args['id']) as String?
            : null;
    final category = args is Map ? args['category'] as String? : null;
    return AdminScreenScaffold(
      title: profile ? 'Marketplace Profile' : 'Marketplace',
      currentRoute: routeName,
      showHeading: false,
      showKycStatusBanner: false,
      topBarBuilder: (context, wide, onMenuTap) => AdminTopBarFrame(
        compact: !wide,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back to portal',
              onPressed: () => navigateCoreBack(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 8),
            Icon(Icons.storefront_outlined, color: context.appColors.goldDark),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                profile ? 'Marketplace Profile' : 'CineConnect Marketplace',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Logout',
              onPressed: () => logoutToLogin(context),
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
      ),
      onRouteSelected: (context, route) => Navigator.pushNamed(context, route),
      child: profile
          ? DPStakeholderProfileScreen(
              candidateId: id,
              profileType: category,
              publicBuyerMode: true,
              browseOnly: true,
            )
          : const DPMarketplaceDiscoveryScreen(browseOnly: true),
    );
  }
}

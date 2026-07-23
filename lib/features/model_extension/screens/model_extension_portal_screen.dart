import 'package:flutter/material.dart';

import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../actor_talent/widgets/actor_talent_shell.dart';
import '../routes/model_extension_routes.dart';
import 'md01_campaign_categories_screen.dart';
import 'md02_usage_rights_screen.dart';
import 'md03_portfolio_categories_screen.dart';
import 'md04_rate_by_usage_screen.dart';
import 'md05_brand_safety_screen.dart';

const _modelBottomDestinations = [
  CineBottomNavDestination(label: 'Categories', icon: Icons.category_outlined),
  CineBottomNavDestination(label: 'Usage', icon: Icons.policy_outlined),
  CineBottomNavDestination(
      label: 'Portfolio', icon: Icons.photo_library_outlined),
  CineBottomNavDestination(label: 'Rates', icon: Icons.price_change_outlined),
  CineBottomNavDestination(label: 'Safety', icon: Icons.shield_outlined),
];

const _modelMenuEntries = <ActorShellMenuEntry>[
  (
    route: ModelExtensionRoutes.categories,
    screenId: 'MD-01',
    label: 'Campaign Categories',
    icon: Icons.category_outlined,
  ),
  (
    route: ModelExtensionRoutes.usageRights,
    screenId: 'MD-02',
    label: 'Usage Rights',
    icon: Icons.policy_outlined,
  ),
  (
    route: ModelExtensionRoutes.portfolio,
    screenId: 'MD-03',
    label: 'Portfolio Categories',
    icon: Icons.photo_library_outlined,
  ),
  (
    route: ModelExtensionRoutes.rateByUsage,
    screenId: 'MD-04',
    label: 'Rate by Usage',
    icon: Icons.price_change_outlined,
  ),
  (
    route: ModelExtensionRoutes.brandSafety,
    screenId: 'MD-05',
    label: 'Brand Safety',
    icon: Icons.shield_outlined,
  ),
];

class ModelExtensionPortalScreen extends StatelessWidget {
  final String routeName;
  final Object? arguments;

  const ModelExtensionPortalScreen({
    super.key,
    required this.routeName,
    this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    return ActorTalentShell(
      routeName: routeName,
      title: ModelExtensionRoutes.titleFor(routeName),
      screenId: ModelExtensionRoutes.screenIdFor(routeName),
      portalLabel: 'Model Extension',
      menuTitle: 'Model extension screens',
      navRoutes: ModelExtensionRoutes.primaryNav,
      navDestinations: _modelBottomDestinations,
      menuEntries: _modelMenuEntries,
      workspaceLayout: true,
      workspaceTitle: 'Model Workspace',
      workspaceSectionLabel: 'MODEL / CAMPAIGNS',
      workspaceBadgeLabel: 'Model',
      workspaceStatusSubtitle:
          'Campaign fit, usage rights, portfolio and brand safety',
      workspaceSearchHint: 'Search campaign settings and usage rights...',
      workspaceSearchRoute: ModelExtensionRoutes.usageRights,
      workspaceProfileRoute: ModelExtensionRoutes.categories,
      workspaceIcon: Icons.style_outlined,
      workspaceEyebrow: _modelEyebrow,
      child: _screenFor(routeName),
    );
  }

  Widget _screenFor(String route) {
    return switch (route) {
      ModelExtensionRoutes.categories => const MD01CampaignCategoriesScreen(),
      ModelExtensionRoutes.usageRights => const MD02UsageRightsScreen(),
      ModelExtensionRoutes.portfolio => const MD03PortfolioCategoriesScreen(),
      ModelExtensionRoutes.rateByUsage => const MD04RateByUsageScreen(),
      ModelExtensionRoutes.brandSafety => const MD05BrandSafetyScreen(),
      _ => const MD01CampaignCategoriesScreen(),
    };
  }
}

String _modelEyebrow(String route) {
  return switch (route) {
    ModelExtensionRoutes.categories => 'Model workspace · campaign fit',
    ModelExtensionRoutes.usageRights => 'Licensing · territories · exclusivity',
    ModelExtensionRoutes.portfolio => 'Portfolio · categories · visibility',
    ModelExtensionRoutes.rateByUsage => 'Commercial rates · usage scope',
    ModelExtensionRoutes.brandSafety => 'Boundaries · restrictions · review',
    _ => 'Model campaign workspace',
  };
}

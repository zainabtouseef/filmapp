import 'package:flutter/material.dart';
import '../shared/marketplace/marketplace_portal_screen.dart';
import '../shared/marketplace/marketplace_routes.dart';

/// Compatibility entry point for old bookmarks. All data comes from the live marketplace.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const MarketplacePortalScreen(routeName: MarketplaceRoutes.browse);
}

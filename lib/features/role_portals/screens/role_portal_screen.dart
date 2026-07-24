import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../models/role_portal_models.dart';
import '../routes/role_portal_routes.dart';
import '../widgets/role_portal_components.dart';
import '../widgets/role_portal_shell.dart';

class RolePortalScreen extends StatelessWidget {
  final String routeName;

  const RolePortalScreen({
    super.key,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    final portal = _portalForRoute(routeName);
    final screen = _screenForRoute(routeName, portal);
    return RolePortalShell(
      portal: portal,
      screen: screen,
      child: PortalTwoColumn(
        left: PortalPanel(
          title: screen.title,
          icon: screen.icon,
          child: CoreEmptyState(
            icon: screen.icon,
            title: 'Legacy generic portal disabled',
            message:
                'This generic role portal no longer renders static demo records. Use the dedicated live portal for this role, or add a database-backed API/DTO before enabling this legacy surface again.',
            actionLabel: 'Go home',
            onAction: () => Navigator.pushNamed(context, '/'),
          ),
        ),
        right: const PortalPanel(
          title: 'Cleanup status',
          icon: Icons.cleaning_services_outlined,
          child: CoreEmptyState(
            icon: Icons.cleaning_services_outlined,
            title: 'Static feed removed',
            message:
                'This route now needs a live DTO and database-backed data before records, metrics, media, or workflow actions are shown again.',
          ),
        ),
      ),
    );
  }
}

RolePortalSpec _portalForRoute(String route) {
  final group = _groupForRoute(route);
  return RolePortalSpec(
    id: group.id,
    label: group.label,
    shortLabel: group.shortLabel,
    description: 'Legacy generic ${group.label} portal placeholder.',
    icon: group.icon,
    homeRoute: group.homeRoute,
    screens: [
      _screenForRoute(route, null),
    ],
  );
}

RolePortalScreenSpec _screenForRoute(String route, RolePortalSpec? portal) {
  final group = _groupForRoute(route);
  return RolePortalScreenSpec(
    id: _screenId(route),
    navLabel: _titleForRoute(route),
    title: _titleForRoute(route),
    subtitle: 'Legacy generic route cleaned of static demo data.',
    route: route,
    icon: _iconForRoute(route, group.icon),
    kind: route == group.homeRoute
        ? PortalScreenKind.dashboard
        : PortalScreenKind.manager,
    primaryAction: 'Use dedicated portal',
    secondaryAction: 'Add live API',
    mediaCategory: 'none',
  );
}

_RoleGroup _groupForRoute(String route) {
  if (route.startsWith('/talent')) {
    return const _RoleGroup(
      id: 'talent',
      label: 'Talent Portal',
      shortLabel: 'Talent',
      homeRoute: RolePortalRoutes.talentHome,
      icon: Icons.theater_comedy_outlined,
    );
  }
  if (route.startsWith('/model')) {
    return const _RoleGroup(
      id: 'model',
      label: 'Model Extension',
      shortLabel: 'Model',
      homeRoute: RolePortalRoutes.modelHome,
      icon: Icons.face_retouching_natural_outlined,
    );
  }
  if (route.startsWith('/location-owner')) {
    return const _RoleGroup(
      id: 'location',
      label: 'Location Owner',
      shortLabel: 'Location',
      homeRoute: RolePortalRoutes.locationHome,
      icon: Icons.location_city_outlined,
    );
  }
  if (route.startsWith('/equipment-provider')) {
    return const _RoleGroup(
      id: 'equipment',
      label: 'Equipment Provider',
      shortLabel: 'Gear',
      homeRoute: RolePortalRoutes.equipmentHome,
      icon: Icons.camera_alt_outlined,
    );
  }
  if (route.startsWith('/crew')) {
    return const _RoleGroup(
      id: 'crew',
      label: 'Crew Services',
      shortLabel: 'Crew',
      homeRoute: RolePortalRoutes.crewHome,
      icon: Icons.groups_2_outlined,
    );
  }
  if (route.startsWith('/agency')) {
    return const _RoleGroup(
      id: 'agency',
      label: 'Casting Agency',
      shortLabel: 'Agency',
      homeRoute: RolePortalRoutes.agencyHome,
      icon: Icons.diversity_3_outlined,
    );
  }
  if (route.startsWith('/brand')) {
    return const _RoleGroup(
      id: 'brand',
      label: 'Brand Sponsor',
      shortLabel: 'Brand',
      homeRoute: RolePortalRoutes.brandHome,
      icon: Icons.campaign_outlined,
    );
  }
  if (route.startsWith('/legal')) {
    return const _RoleGroup(
      id: 'legal',
      label: 'Legal Partner',
      shortLabel: 'Legal',
      homeRoute: RolePortalRoutes.legalHome,
      icon: Icons.gavel_outlined,
    );
  }
  if (route.startsWith('/insurance')) {
    return const _RoleGroup(
      id: 'insurance',
      label: 'Insurance Partner',
      shortLabel: 'Insurance',
      homeRoute: RolePortalRoutes.insuranceHome,
      icon: Icons.health_and_safety_outlined,
    );
  }
  if (route.startsWith('/distribution')) {
    return const _RoleGroup(
      id: 'distribution',
      label: 'Distribution Partner',
      shortLabel: 'Distribution',
      homeRoute: RolePortalRoutes.distributionHome,
      icon: Icons.public_outlined,
    );
  }
  return const _RoleGroup(
    id: 'role',
    label: 'Role Portal',
    shortLabel: 'Role',
    homeRoute: RolePortalRoutes.talentHome,
    icon: Icons.dashboard_customize_outlined,
  );
}

String _titleForRoute(String route) {
  final last = route.split('/').where((part) => part.isNotEmpty).lastOrNull;
  if (last == null) return 'Role Portal';
  return last
      .replaceAll('-', ' ')
      .split(' ')
      .map((part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _screenId(String route) {
  final group = _groupForRoute(route);
  final index = RolePortalRoutes.allRoutes.indexOf(route) + 1;
  return '${group.shortLabel.toUpperCase()}-${index.toString().padLeft(2, '0')}';
}

IconData _iconForRoute(String route, IconData fallback) {
  if (route.contains('profile')) return Icons.badge_outlined;
  if (route.contains('portfolio')) return Icons.video_library_outlined;
  if (route.contains('availability')) return Icons.calendar_month_outlined;
  if (route.contains('request') || route.contains('offer')) {
    return Icons.handshake_outlined;
  }
  if (route.contains('contract')) return Icons.description_outlined;
  if (route.contains('payment') || route.contains('earning')) {
    return Icons.payments_outlined;
  }
  if (route.contains('safety') || route.contains('incident')) {
    return Icons.health_and_safety_outlined;
  }
  if (route.contains('report') || route.contains('performance')) {
    return Icons.analytics_outlined;
  }
  return fallback;
}

class _RoleGroup {
  final String id;
  final String label;
  final String shortLabel;
  final String homeRoute;
  final IconData icon;

  const _RoleGroup({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.homeRoute,
    required this.icon,
  });
}

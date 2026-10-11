import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/auth/role_mapper.dart';
import 'package:cineconnect/features/actor_talent/routes/actor_talent_routes.dart';
import 'package:cineconnect/features/brand_sponsors/routes/brand_sponsor_routes.dart';
import 'package:cineconnect/features/brand_sponsors/widgets/brand_sponsor_shell.dart';
import 'package:cineconnect/features/casting_agency/routes/casting_agency_routes.dart';
import 'package:cineconnect/features/casting_agency/widgets/casting_agency_shell.dart';
import 'package:cineconnect/features/crew_services/routes/crew_services_routes.dart';
import 'package:cineconnect/features/crew_services/widgets/crew_services_shell.dart';
import 'package:cineconnect/features/director_producer/routes/director_producer_routes.dart';
import 'package:cineconnect/features/director_producer/widgets/dp_shell.dart';
import 'package:cineconnect/features/distribution_partner/routes/distribution_partner_routes.dart';
import 'package:cineconnect/features/distribution_partner/widgets/distribution_partner_shell.dart';
import 'package:cineconnect/features/general_public/routes/general_public_routes.dart';
import 'package:cineconnect/features/general_public/screens/general_public_portal_screen.dart';
import 'package:cineconnect/features/influencer/routes/influencer_routes.dart';
import 'package:cineconnect/features/insurance_partner/routes/insurance_partner_routes.dart';
import 'package:cineconnect/features/insurance_partner/widgets/insurance_partner_shell.dart';
import 'package:cineconnect/features/legal_partner/routes/legal_partner_routes.dart';
import 'package:cineconnect/features/legal_partner/widgets/legal_partner_shell.dart';
import 'package:cineconnect/features/location_owner/routes/location_owner_routes.dart';
import 'package:cineconnect/features/media_equipment/routes/media_equipment_routes.dart';
import 'package:cineconnect/features/media_equipment/widgets/media_equipment_shell.dart';
import 'package:cineconnect/features/model_extension/routes/model_extension_routes.dart';
import 'package:cineconnect/features/super_admin/routes/super_admin_routes.dart';
import 'package:cineconnect/features/super_admin/widgets/admin_widgets.dart';

void main() {
  test('every role login lands on its dashboard or console', () {
    const expectedRoutes = {
      'director_producer': DirectorProducerRoutes.console,
      'actor_talent': ActorTalentRoutes.dashboard,
      'model': ModelExtensionRoutes.categories,
      'influencer': InfluencerRoutes.home,
      'general_public': GeneralPublicRoutes.home,
      'location_owner': LocationOwnerRoutes.home,
      'equipment_provider': MediaEquipmentRoutes.home,
      'crew_service': CrewServicesRoutes.home,
      'casting_agency': CastingAgencyRoutes.home,
      'brand_sponsor': BrandSponsorRoutes.home,
      'legal_partner': LegalPartnerRoutes.home,
      'insurance_partner': InsurancePartnerRoutes.home,
      'distribution_partner': DistributionPartnerRoutes.home,
      'super_admin': SuperAdminRoutes.dashboard,
    };

    for (final entry in expectedRoutes.entries) {
      expect(
        RoleMapper.portalRouteForCode(entry.key),
        entry.value,
        reason: '${entry.key} must open its dashboard after login',
      );
    }
  });

  test('public portal menus expose the dashboard first', () {
    expect(DPShell.navItems.first.route, DirectorProducerRoutes.console);
    expect(DPShell.navItems.first.label, 'Console');
    expect(agencyMenuEntries.first.route, CastingAgencyRoutes.home);
    expect(crewMenuEntries.first.route, CrewServicesRoutes.home);
    expect(brandSponsorMenuEntries.first.route, BrandSponsorRoutes.home);
    expect(distributionMenuEntries.first.route, DistributionPartnerRoutes.home);
    expect(insuranceMenuEntries.first.route, InsurancePartnerRoutes.home);
    expect(legalMenuEntries.first.route, LegalPartnerRoutes.home);
    expect(mediaEquipmentMenuEntries.first.route, MediaEquipmentRoutes.home);
    expect(GeneralPublicShell.navItems.first.route, GeneralPublicRoutes.home);
    expect(GeneralPublicShell.navItems.first.label, 'Dashboard');
    expect(adminNavItems.first.route, SuperAdminRoutes.dashboard);
    expect(adminNavItems.first.label, 'Dashboard');
  });

  test('mobile primary routes start with each portal dashboard', () {
    expect(ActorTalentRoutes.primaryNav.first, ActorTalentRoutes.dashboard);
    expect(CastingAgencyRoutes.primaryNav.first, CastingAgencyRoutes.home);
    expect(CrewServicesRoutes.primaryNav.first, CrewServicesRoutes.home);
    expect(BrandSponsorRoutes.primaryNav.first, BrandSponsorRoutes.home);
    expect(DistributionPartnerRoutes.primaryNav.first,
        DistributionPartnerRoutes.home);
    expect(InfluencerRoutes.primaryNav.first, InfluencerRoutes.home);
    expect(
        InsurancePartnerRoutes.primaryNav.first, InsurancePartnerRoutes.home);
    expect(LegalPartnerRoutes.primaryNav.first, LegalPartnerRoutes.home);
    expect(LocationOwnerRoutes.primaryNav.first, LocationOwnerRoutes.home);
    expect(MediaEquipmentRoutes.primaryNav.first, MediaEquipmentRoutes.home);
    expect(
        ModelExtensionRoutes.primaryNav.first, ModelExtensionRoutes.categories);
  });

  test('private shell menus and bottom bars label the dashboard first', () {
    const checks = <({String path, String menu, String bottom, String route})>[
      (
        path: 'lib/features/actor_talent/widgets/actor_talent_shell.dart',
        menu: 'const _actorMenuEntries',
        bottom: 'const _actorBottomDestinations',
        route: 'ActorTalentRoutes.dashboard',
      ),
      (
        path: 'lib/features/influencer/screens/influencer_portal_screen.dart',
        menu: 'const _influencerMenuEntries',
        bottom: 'const _influencerBottomDestinations',
        route: 'InfluencerRoutes.home',
      ),
      (
        path:
            'lib/features/model_extension/screens/model_extension_portal_screen.dart',
        menu: 'const _modelMenuEntries',
        bottom: 'const _modelBottomDestinations',
        route: 'ModelExtensionRoutes.categories',
      ),
      (
        path: 'lib/features/location_owner/widgets/location_owner_shell.dart',
        menu: 'const _locationMenuEntries',
        bottom: 'const _locationBottomDestinations',
        route: 'LocationOwnerRoutes.home',
      ),
    ];

    for (final check in checks) {
      final source = File(check.path).readAsStringSync();
      final menuSource = source.substring(source.indexOf(check.menu));
      final firstMenuRoute = menuSource.indexOf('route:');
      final firstMarketplace = menuSource.indexOf('MarketplaceRoutes.browse');
      expect(firstMenuRoute, greaterThanOrEqualTo(0));
      expect(
        menuSource.substring(firstMenuRoute, firstMenuRoute + 100),
        contains(check.route),
        reason: '${check.path} must put its dashboard first in the side menu',
      );
      expect(firstMenuRoute, lessThan(firstMarketplace));

      final bottomSource = source.substring(source.indexOf(check.bottom));
      final firstLabel = bottomSource.indexOf('label:');
      expect(
        bottomSource.substring(firstLabel, firstLabel + 80),
        contains("'Dashboard'"),
        reason: '${check.path} must label its first mobile tab Dashboard',
      );
    }
  });

  test('director mobile Console opens the same first navigation route', () {
    final source = File(
      'lib/features/director_producer/widgets/dp_shell.dart',
    ).readAsStringSync();
    final bottomNav = source.substring(source.indexOf('class _DPBottomNav'));
    expect(bottomNav, contains("label: 'Console'"));
    expect(
      bottomNav,
      contains('case 0:\n            '
          'onRouteTap(DirectorProducerRoutes.console);'),
    );
  });
}

import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/features/actor_talent/screens/actor_talent_portal_screen.dart';
import 'package:cineconnect/features/brand_sponsors/routes/brand_sponsor_routes.dart';
import 'package:cineconnect/features/brand_sponsors/screens/brand_sponsor_portal_screen.dart';
import 'package:cineconnect/features/casting_agency/screens/casting_agency_portal_screen.dart';
import 'package:cineconnect/features/crew_services/screens/crew_services_portal_screen.dart';
import 'package:cineconnect/features/director_producer/routes/director_producer_routes.dart';
import 'package:cineconnect/features/director_producer/screens/director_producer_portal_screen.dart';
import 'package:cineconnect/features/distribution_partner/screens/distribution_partner_portal_screen.dart';
import 'package:cineconnect/features/general_public/routes/general_public_routes.dart';
import 'package:cineconnect/features/general_public/screens/general_public_portal_screen.dart';
import 'package:cineconnect/features/influencer/screens/influencer_portal_screen.dart';
import 'package:cineconnect/features/insurance_partner/screens/insurance_partner_portal_screen.dart';
import 'package:cineconnect/features/legal_partner/screens/legal_partner_portal_screen.dart';
import 'package:cineconnect/features/location_owner/screens/location_owner_portal_screen.dart';
import 'package:cineconnect/features/media_equipment/screens/media_equipment_portal_screen.dart';
import 'package:cineconnect/features/model_extension/screens/model_extension_portal_screen.dart';
import 'package:cineconnect/shared/layout/portal_page_header.dart';
import 'package:cineconnect/shared/marketplace/marketplace_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _PortalFactory = Widget Function();

void main() {
  final portals = <String, _PortalFactory>{
    'director': () => const DirectorProducerPortalScreen(
          routeName: DirectorProducerRoutes.marketplace,
        ),
    'public': () => const GeneralPublicPortalScreen(
          routeName: GeneralPublicRoutes.browse,
        ),
    'brand': () => const BrandSponsorPortalScreen(
          routeName: BrandSponsorRoutes.marketplace,
        ),
    'actor': () => const ActorTalentPortalScreen(
          routeName: MarketplaceRoutes.browse,
        ),
    'model': () => const ModelExtensionPortalScreen(
          routeName: MarketplaceRoutes.browse,
        ),
    'influencer': () => const InfluencerPortalScreen(
          routeName: MarketplaceRoutes.browse,
        ),
    'location': () => const LocationOwnerPortalScreen(
          routeName: MarketplaceRoutes.browse,
        ),
    'equipment': () => const MediaEquipmentPortalScreen(
          routeName: MarketplaceRoutes.browse,
        ),
    'crew': () => const CrewServicesPortalScreen(
          routeName: MarketplaceRoutes.browse,
        ),
    'agency': () => const CastingAgencyPortalScreen(
          routeName: MarketplaceRoutes.browse,
        ),
    'legal': () => const LegalPartnerPortalScreen(
          routeName: MarketplaceRoutes.browse,
        ),
    'insurance': () => const InsurancePartnerPortalScreen(
          routeName: MarketplaceRoutes.browse,
        ),
    'distribution': () => const DistributionPartnerPortalScreen(
          routeName: MarketplaceRoutes.browse,
        ),
  };

  for (final portal in portals.entries) {
    for (final viewport in const {
      'mobile': Size(390, 844),
      'desktop': Size(1440, 1000),
    }.entries) {
      testWidgets(
        '${portal.key} Marketplace uses the shared surface on ${viewport.key}',
        (tester) async {
          tester.view.physicalSize = viewport.value;
          tester.view.devicePixelRatio = 1;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            ThemeControllerProvider(
              controller: ThemeController(
                initialThemeMode:
                    viewport.key == 'mobile' ? ThemeMode.light : ThemeMode.dark,
              ),
              child: MaterialApp(
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode:
                    viewport.key == 'mobile' ? ThemeMode.light : ThemeMode.dark,
                home: portal.value(),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 650));

          expect(find.byType(PortalPageHeader), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(PortalPageHeader),
              matching: find.textContaining('Marketplace'),
            ),
            findsOneWidget,
          );
          final exception = tester.takeException();
          expect(exception, isNull, reason: 'Unexpected exception: $exception');
        },
      );
    }
  }
}
